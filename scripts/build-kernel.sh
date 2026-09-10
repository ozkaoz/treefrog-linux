#!/bin/bash
# build-kernel.sh — compila vmlinux para una board
# Replica: config de kernel del SDK + fixup CONFIG_PHYSICAL_START/PHYS_OFFSET/AVP_ENTRY
# desde el DTS (update_physical_start.sh) + DTB + artefactos de consola.
#
# Uso: scripts/build-kernel.sh <board> [config-variant]
#   <board>            boards/<board>/dts/<board>.dts (board real, ej: r36sx)
#                     o DTS de devboard del SDK en vendor/hichip/board/common/dts (ej: hc16xx-db-a3100-v10)
#   [config-variant]  squashfs (default) | initramfs | ramfs | treefrog | kernelonly
#                     ramfs    = initramfs stock embebido (esquema real de la consola,
#                                R30): fragment <board>-ramfs.fragment.config
#                     treefrog = initramfs PROPIO (FASE F, linuxrc TreeFrog):
#                                fragment <board>-treefrog.fragment.config +
#                                build/treefrog-initramfs.cpio (build-initramfs.sh)
#                     ambos requieren build/stock-initramfs.cpio (extract-stock-initramfs.sh)
#
# Artefactos en out/<board>/:
#   vmlinux          ELF completo
#   vmlinux.bin      raw binary (objcopy -O binary)
#   vmlinux.uImage   legacy uImage gzip, load 0x80000000, entry del ELF — formato stock consola
#   dtb.bin          Device Tree Blob de la board
#   manifest.json    commit + hashes + direcciones derivadas
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

DTS_NAME="${1:?uso: build-kernel.sh <board> [config-variant]}"
CONFIG_VARIANT="${2:-squashfs}"
BOARD_OUT="$OUT_BASE/$DTS_NAME"

# resolución del DTS: primero board real (boards/), luego devboard vendor
if [ -f "$ROOT/boards/$DTS_NAME/dts/$DTS_NAME.dts" ]; then
  DTS_FILE="$ROOT/boards/$DTS_NAME/dts/$DTS_NAME.dts"
  BOARD_KIND="custom"
elif [ -f "$VENDOR_BOARD/dts/$DTS_NAME.dts" ]; then
  DTS_FILE="$VENDOR_BOARD/dts/$DTS_NAME.dts"
  BOARD_KIND="vendor"
else
  echo "ERROR: no encuentro $DTS_NAME.dts ni en boards/$DTS_NAME/dts/ ni en $VENDOR_BOARD/dts"; exit 1
fi
# kernel-only experiment: fragment alternativo + initramfs propio embebido.
# Uso: build-kernel.sh <board> kernelonly  (base = kernel-squashfs.config + fragment propio)
KERNEL_ONLY=0
BASE_VARIANT="$CONFIG_VARIANT"
FRAGMENT=""
STOCK_INITRAMFS="$ROOT/build/stock-initramfs.cpio"
case "$CONFIG_VARIANT" in
  kernelonly)
    KERNEL_ONLY=1
    BASE_VARIANT="squashfs"
    FRAGMENT="$ROOT/boards/$DTS_NAME/config/$DTS_NAME-kernelonly.fragment.config"
    [ -f "$FRAGMENT" ] || { echo "ERROR: falta $FRAGMENT"; exit 1; }
    ;;
  ramfs)
    # esquema REAL de la consola (R30): initramfs stock embebido en el kernel
    BASE_VARIANT="squashfs"
    FRAGMENT="$ROOT/boards/$DTS_NAME/config/$DTS_NAME-ramfs.fragment.config"
    [ -f "$FRAGMENT" ] || { echo "ERROR: falta $FRAGMENT"; exit 1; }
    [ -f "$STOCK_INITRAMFS" ] || { echo "ERROR: falta $STOCK_INITRAMFS — ejecuta scripts/extract-stock-initramfs.sh"; exit 1; }
    ;;
  treefrog)
    # FASE F: initramfs PROPIO (linuxrc TreeFrog -> FrogUI directo)
    BASE_VARIANT="squashfs"
    FRAGMENT="$ROOT/boards/$DTS_NAME/config/$DTS_NAME-treefrog.fragment.config"
    [ -f "$FRAGMENT" ] || { echo "ERROR: falta $FRAGMENT"; exit 1; }
    TF_INITRAMFS="$ROOT/build/treefrog-initramfs.cpio"
    [ -f "$TF_INITRAMFS" ] || { echo "ERROR: falta $TF_INITRAMFS — ejecuta scripts/build-initramfs.sh"; exit 1; }
    ;;
  *)
    if [ -f "$ROOT/boards/$DTS_NAME/config/$DTS_NAME.fragment.config" ]; then
      FRAGMENT="$ROOT/boards/$DTS_NAME/config/$DTS_NAME.fragment.config"
    fi
    ;;
esac
KERNEL_CONFIG="$VENDOR_BOARD/kernel-configs/$KERNEL_VERSION/kernel-$BASE_VARIANT.config"
[ -f "$KERNEL_CONFIG" ] || { echo "ERROR: no existe $KERNEL_CONFIG"; exit 1; }
INITRAMFS_CPIO="$ROOT/build/initramfs-$DTS_NAME/tf-initramfs.cpio.gz"
if [ "$KERNEL_ONLY" = "1" ] && [ ! -f "$INITRAMFS_CPIO" ]; then
  echo "ERROR: falta $INITRAMFS_CPIO — constrúyelo primero"; exit 1
fi

INITRAMFS_CPIO="$ROOT/build/initramfs-$DTS_NAME/tf-initramfs.cpio.gz"
if [ "$KERNEL_ONLY" = "1" ] && [ ! -f "$INITRAMFS_CPIO" ]; then
  echo "ERROR: falta $INITRAMFS_CPIO — constrúyelo primero"; exit 1
fi

mkdir -p "$BOARD_OUT"
cd "$KERNEL_DIR"

echo "== preparando config (kernel-$CONFIG_VARIANT.config) =="
cp "$KERNEL_CONFIG" .config
if [ "$KERNEL_ONLY" = "1" ]; then
  # experimento kernel-only: initramfs propio embebido (esquema de la variante
  # vendor kernel-initramfs.config: INITRAMFS_SOURCE=<cpio> + ELF_APPENDED_DTB)
  if [ -f "$INITRAMFS_CPIO" ]; then
    cat >> .config <<EOF
CONFIG_INITRAMFS_SOURCE="$INITRAMFS_CPIO"
EOF
  else
    echo "ERROR: falta $INITRAMFS_CPIO — constrúyelo primero (rootfs/tfinit + make_initramfs)"; exit 1
  fi
fi
if [ -n "$FRAGMENT" ]; then
  echo "  + fragment: $FRAGMENT"
  # merge_config del kernel: aplica el fragment sobre .config con 'make alldefconfig' final
  bash scripts/kconfig/merge_config.sh -m .config "$FRAGMENT"
fi
# resolver simbolos nuevos (ej: RC_KEYMAP choice del hcdrivers) con defaults,
# igual que hace Buildroot (flujo vendor); gcc host >=10 necesita -fcommon (dtc 4.4)
make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" olddefconfig 2>&1 | tail -2
if [ -n "$FRAGMENT" ]; then
  # verificar que las opciones del fragment quedaron activas (merge_config + olddefconfig
  # pueden revertir dependencias no satisfechas)
  echo "  verificación del fragment:"
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue;; esac
    opt="${line%%=*}"
    grep -q "^$line\$" .config || echo "    ADVERTENCIA: $line no quedó activo tras olddefconfig"
    grep -q "^$line\$" .config && echo "    ok: $line"
  done < "$FRAGMENT"
fi
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

echo "== compilando DTB =="
DTS_SRC_DIR="arch/mips/boot/dts"
mkdir -p "$DTS_SRC_DIR"
if [ "$BOARD_KIND" = "custom" ]; then
  # board real: DTS con includes vendor-style -> preprocesar con gcc -E (como el SDK/hcboot)
  # y compilar dtc directamente (round-trip verificado en boards/<board>/)
  INCS="-I$(dirname "$DTS_FILE") -I$KERNEL_DIR/include -I$KERNEL_DIR/arch/mips/boot/dts/include"
  gcc -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp $INCS -o "$BOARD_OUT/$DTS_NAME.pp.dts" "$DTS_FILE"
  dtc -q -I dts -O dtb -o "$BOARD_OUT/dtb.bin" "$BOARD_OUT/$DTS_NAME.pp.dts"
  # DTB de board custom NO se copia al arbol del kernel (el kernel no lo necesita in-tree:
  # el config usa MIPS_NO_APPENDED_DTB y hcboot carga dtb.bin aparte)
else
  cp "$VENDOR_BOARD/dts/"*.dts "$DTS_SRC_DIR/" 2>/dev/null || true
  cp "$VENDOR_BOARD/dts/"*.dtsi "$DTS_SRC_DIR/" 2>/dev/null || true
  make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" HOSTCFLAGS="-O2 -fcommon -std=gnu89" "$DTS_NAME.dtb" 2>&1 | tail -3
  install -m 0644 "$DTS_SRC_DIR/$DTS_NAME.dtb" "$BOARD_OUT/dtb.bin"
fi
[ -f "$BOARD_OUT/dtb.bin" ] || { echo "ERROR: DTB no generado"; exit 1; }
DTB_PATH="$BOARD_OUT/dtb.bin"

echo "== compilando vmlinux =="
make ARCH=$ARCH CROSS_COMPILE="$CROSS_COMPILE" -j"$(nproc)" vmlinux 2>&1 | tail -5

echo "== empaquetando artefactos de consola =="
cp vmlinux "$BOARD_OUT/vmlinux"
# 1) vmlinux.bin: raw binary (formato del SDK)
"$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" -O binary vmlinux "$BOARD_OUT/vmlinux.bin"
# 2) vmlinux.uImage: legacy uImage gzip — EXACTO al formato stock de las consolas:
#    payload = vmlinux.bin gzipeado. En modo normal SIN DTB (hcboot carga dtb.bin
#    aparte; evidencia del stock: payload raw, DTB separado en SD).
#    En modo kernelonly (initramfs): DTB embebido en el ELF via objcopy
#    --update-section .appended_dtb (esquema de la variante vendor kernel-initramfs
#    con CONFIG_MIPS_ELF_APPENDED_DTB) porque el initramfs NO puede depender de
#    que hcboot entregue el DTB de la SD.
if [ "$KERNEL_ONLY" = "1" ]; then
  if "$TOOLCHAIN_BIN/mips-mti-linux-gnu-readelf" -S vmlinux | grep -q '\.appended_dtb'; then
    "$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" --update-section .appended_dtb="$DTB_PATH" vmlinux
  else
    "$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" --add-section .appended_dtb="$DTB_PATH" vmlinux
  fi
  "$TOOLCHAIN_BIN/mips-mti-linux-gnu-objcopy" -O binary vmlinux "$BOARD_OUT/vmlinux.bin"
fi
gzip -9 -c "$BOARD_OUT/vmlinux.bin" > "$BOARD_OUT/vmlinux.bin.gz"
ENTRY_ADDR=$("$TOOLCHAIN_BIN/mips-mti-linux-gnu-readelf" -h vmlinux | awk '/Entry point address/{print $4}')
mkimage -A mips -O linux -T kernel -C gzip -a 0x80000000 -e "$ENTRY_ADDR" \
  -n "vmlinux" -d "$BOARD_OUT/vmlinux.bin.gz" "$BOARD_OUT/vmlinux.uImage"
# restaurar (por si el árbol se ensucia con .appended_dtb del modo vendor)
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
  if [ -n "$FRAGMENT" ]; then
    echo "  \"config_fragment_sha256\": \"$(sha256sum "$FRAGMENT" | awk '{print $1}')\","
  fi
  if [ -n "$FRAGMENT" ]; then
    echo "  \"config_fragment_sha256\": \"$(sha256sum "$FRAGMENT" | awk '{print $1}')\","
  fi
  echo "  \"dts_sha256\": \"$(sha256sum "$DTS_FILE" | awk '{print $1}')\","
  echo "  \"dtb_sha256\": \"$(sha256sum "$BOARD_OUT/dtb.bin" | awk '{print $1}')\","
  echo "  \"vmlinux_bin_sha256\": \"$(sha256sum "$BOARD_OUT/vmlinux.bin" | awk '{print $1}')\","
  echo "  \"vmlinux_uimage_sha256\": \"$(sha256sum "$BOARD_OUT/vmlinux.uImage" | awk '{print $1}')\","
  echo "  \"uimage_entry\": \"$ENTRY_ADDR\","
  echo "  \"built_at\": \"$(date -Iseconds)\""
  echo "}"
} > "$BOARD_OUT/manifest.json"
echo "--- manifest ---"
cat "$BOARD_OUT/manifest.json"

echo "== done: $BOARD_OUT =="
ls -la "$BOARD_OUT"
