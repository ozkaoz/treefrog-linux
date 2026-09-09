#!/bin/bash
# build-kernel.sh — compila vmlinux para una board de referencia del SDK
# Replica: config de kernel del SDK + fixup CONFIG_PHYSICAL_START/PHYS_OFFSET/AVP_ENTRY
# desde el DTS (update_physical_start.sh) + DTB + vmlinux gzip con DTB appended.
#
# Uso: scripts/build-kernel.sh <dts-name> [config-variant]
#   <dts-name>          nombre base del DTS en vendor/hichip/board (ej: hc16xx-db-a3100-v10)
#   [config-variant]    squashfs (default) | initramfs | squashfs-jffs2 | squashfs-jffs2-tiny | squashfs-carlink
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
KERNEL_VERSION="4.4.186"
KERNEL_DIR="${TFL_KERNEL_DIR:-$ROOT/downloads/linux-$KERNEL_VERSION}"
VENDOR_BOARD="$ROOT/vendor/hichip/board/common"
OUT_BASE="${TFL_OUT_DIR:-$ROOT/out}"

TOOLCHAIN_BIN="${TFL_TOOLCHAIN_BIN:-$HOME/sf3000-work/sf3000toolchain/mipsel-buildroot-linux-gnu_sdk-buildroot/bin}"
CROSS_COMPILE="$TOOLCHAIN_BIN/mips-mti-linux-gnu-"
ARCH=mips

DTS_NAME="${1:?uso: build-kernel.sh <dts-name> [config-variant]}"
CONFIG_VARIANT="${2:-squashfs}"
BOARD_OUT="$OUT_BASE/$DTS_NAME"

DTS_FILE=$(find "$VENDOR_BOARD/dts" -maxdepth 1 -name "$DTS_NAME.dts" | head -1)
[ -n "$DTS_FILE" ] || { echo "ERROR: no encuentro $DTS_NAME.dts en $VENDOR_BOARD/dts"; exit 1; }
KERNEL_CONFIG="$VENDOR_BOARD/kernel-configs/$KERNEL_VERSION/kernel-$CONFIG_VARIANT.config"
[ -f "$KERNEL_CONFIG" ] || { echo "ERROR: no existe $KERNEL_CONFIG"; exit 1; }

mkdir -p "$BOARD_OUT"
cd "$KERNEL_DIR"

echo "== preparando config (kernel-$CONFIG_VARIANT.config) =="
cp "$KERNEL_CONFIG" .config
# resolver simbolos nuevos (ej: RC_KEYMAP choice del hcdrivers) con defaults,
# igual que hace Buildroot (flujo vendor); gcc host >=10 necesita -fcommon (dtc 4.4)
HOSTFLAGS='HOSTCFLAGS="-O2 -fcommon -std=gnu89"'
make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" olddefconfig 2>&1 | tail -2
make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" HOSTCFLAGS="-O2 -fcommon -std=gnu89" prepare scripts 2>&1 | tail -2

echo "== fixup load address desde DTS (linux-ext-fixup-load-addr.mk) =="
# replica exacta del mecanismo del SDK
TMPDIR_LA=".tmp-for-load-addr"
rm -rf "$TMPDIR_LA"; mkdir -p "$TMPDIR_LA"
cp "$DTS_FILE" "$TMPDIR_LA/$DTS_NAME.dts"
# el dts referencia includes del board dir
CFLAGS_DTS="-I$(dirname "$DTS_FILE")"
{
  echo ""
  echo "unsigned int linux_load_addr = (CONFIG_LINUX_MEMORY_OFFSET);"
  echo "unsigned int avp_load_addr = (HCRTOS_SYSMEM_OFFSET + 0x1000);"
} >> "$TMPDIR_LA/$DTS_NAME.dts"
gcc -O2 -I"$KERNEL_DIR/include" -I"$KERNEL_DIR/arch/mips/boot/dts/include" $CFLAGS_DTS -E -Wp,-MMD,"$TMPDIR_LA/$DTS_NAME.dtb.d.pre.tmp" -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o "$TMPDIR_LA/$DTS_NAME.dtb.dts.tmp" "$TMPDIR_LA/$DTS_NAME.dts"
grep linux_load_addr "$TMPDIR_LA/$DTS_NAME.dtb.dts.tmp" > "$TMPDIR_LA/main.c"
grep avp_load_addr "$TMPDIR_LA/$DTS_NAME.dtb.dts.tmp" >> "$TMPDIR_LA/main.c"
cat >> "$TMPDIR_LA/main.c" <<'CEOF'
#include <stdio.h>
int main(int argc, char **argv)
{
	if (argc == 1)
		printf("0xffffffff%x", linux_load_addr | 0x80000000);
	else if (argc == 2)
		printf("0x%08x", linux_load_addr);
	else if (argc == 3)
		printf("0x%08x", ((avp_load_addr | 0xa0000000) + 0xfff) & 0xfffff000);
	return 0;
}
CEOF
gcc -o "$TMPDIR_LA/a.out" "$TMPDIR_LA/main.c"
ADDR=$("$TMPDIR_LA/a.out")
PHYS_OFF=$("$TMPDIR_LA/a.out" 1)
AVP_ENTRY=$("$TMPDIR_LA/a.out" 1 2)
echo "  linux load:  $ADDR"
echo "  phys offset: $PHYS_OFF"
echo "  avp entry:   $AVP_ENTRY"
bash "$ROOT/vendor/hichip/sdk-glue/update_physical_start.sh" CONFIG_PHYSICAL_START "$TMPDIR_LA/a.out" "$KERNEL_DIR/.config" "$KERNEL_DIR/arch/mips/include/asm/mach-hc16xx/spaces.h" "$KERNEL_DIR/arch/mips/include/asm/mach-hc16xx/kernel-entry-init.h"
grep CONFIG_PHYSICAL_START "$KERNEL_DIR/.config"

echo "== compilando DTB (regla %.dtb del kernel 4.4; DTS en arch/mips/boot/dts plano, como el SDK) =="
DTS_SRC_DIR="arch/mips/boot/dts"
mkdir -p "$DTS_SRC_DIR"
cp "$VENDOR_BOARD/dts/"*.dts "$DTS_SRC_DIR/" 2>/dev/null || true
cp "$VENDOR_BOARD/dts/"*.dtsi "$DTS_SRC_DIR/" 2>/dev/null || true
make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" HOSTCFLAGS="-O2 -fcommon -std=gnu89" "$DTS_NAME.dtb" 2>&1 | tail -3
DTB_PATH="$DTS_SRC_DIR/$DTS_NAME.dtb"
[ -f "$DTB_PATH" ] || { echo "ERROR: DTB no generado"; exit 1; }

echo "== compilando vmlinux =="
make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" -j"$(nproc)" vmlinux 2>&1 | tail -5

echo "== empaquetando vmlinux.bin (gzip + DTB appended, linux-ext-elf-append-dtb.mk) =="
cp vmlinux "$BOARD_OUT/vmlinux"
# el config vendor usa MIPS_NO_APPENDED_DTB (hcboot pasa el DTB); el mk del SDK appendea
# la seccion como conveniencia -> usamos add-section si el ELF no la tiene, update si existe
if "$TOOLCHAIN_BIN/mips-mti-linux-gnu-readelf" -S vmlinux | grep -q '\.appended_dtb'; then
  "$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" --update-section .appended_dtb="$DTB_PATH" vmlinux
else
  "$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" --add-section .appended_dtb="$DTB_PATH" vmlinux
fi
gzip -9 -c vmlinux > "$BOARD_OUT/vmlinux.gz"
"$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" -O binary vmlinux "$BOARD_OUT/vmlinux.bin"
install -m 0644 "$DTB_PATH" "$BOARD_OUT/dtb.bin"
# restaurar vmlinux sin dtb para no ensuciar el árbol
git checkout -- vmlinux 2>/dev/null || true

echo "== manifest =="
GIT_COMMIT=$(cd "$ROOT" && git rev-parse HEAD)
GCC_VER=$("$TOOLCHAIN_BIN/mips-mti-linux-gnu-gcc" -dumpversion | head -1)
{
  echo "{"
  echo "  \"git_commit\": \"$GIT_COMMIT\","
  echo "  \"kernel\": \"$KERNEL_VERSION\","
  echo "  \"toolchain\": \"Codescape GNU 2018.09-02 GCC $GCC_VER mips-mti-linux-gnu\","
  echo "  \"board\": \"$DTS_NAME\","
  echo "  \"config_variant\": \"$CONFIG_VARIANT\","
  echo "  \"physical_start\": \"$ADDR\","
  echo "  \"phys_offset\": \"$PHYS_OFF\","
  echo "  \"avp_entry\": \"$AVP_ENTRY\","
  echo "  \"config_sha256\": \"$(sha256sum "$KERNEL_CONFIG" | awk '{print $1}')\","
  echo "  \"dts_sha256\": \"$(sha256sum "$DTS_FILE" | awk '{print $1}')\","
  echo "  \"dtb_sha256\": \"$(sha256sum "$BOARD_OUT/dtb.bin" | awk '{print $1}')\","
  echo "  \"vmlinux_bin_sha256\": \"$(sha256sum "$BOARD_OUT/vmlinux.bin" | awk '{print $1}')\","
  echo "  \"built_at\": \"$(date -Iseconds)\""
  echo "}"
} > "$BOARD_OUT/manifest.json"
cat "$BOARD_OUT/manifest.json"

echo "== done: $BOARD_OUT =="
ls -la "$BOARD_OUT"
