#!/bin/bash
# build-initramfs.sh — genera el initramfs TreeFrog PROPIO (FASE F)
#
# PROPÓSITO: reemplazar el initramfs stock extraído (que arranca icube→rkgame→
# zhijack) por uno NUESTRO que lanza picoarch+FrogUI DIRECTAMENTE:
#   linuxrc propio (monta dev/proc/sys, SD en /mnt/sdcard, hcdaemon, cubevol,
#   CPU governor, TF_DEVICE env, loop picoarch<->frogui con protocolo
#   /tmp/frogui_launch.txt idéntico al de zhijack.sh — ver docs/zhijack-r36sx)
#
# COMPONENTES (reutilizados del initramfs stock — corren desde el firmware
# original de la SD; el proyecto no los redistribuye, los EMPaqueta en build):
#   bin/busybox (MIPS32r2, del cpio stock) — shell + coreutils
#   lib/ld.so.1 libc.so.6 libcrypt.so.1 libdl.so.2 libpthread.so.0 — runtime
#   usr/bin/hcdaemon — puente AMPRPC hacia el AVP stock (obligatorio: audio/
#   display pasan por él; sin hcdaemon no hay sonido ni driver .so)
#   usr/bin/cubevol — daemon input: gpio/ADC -> /tmp/joy_key (picoarch lo lee)
#
# NUESTRO: linuxrc (rootfs/treefrog/linuxrc) — init script propio.
#
# Uso: scripts/build-initramfs.sh
#   genera: build/treefrog-initramfs.cpio (para CONFIG_INITRAMFS_SOURCE)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
STOCK_CPIO="$ROOT/build/stock-initramfs.cpio"
OUT_DIR="$ROOT/build/treefrog-initramfs-root"
OUT_CPIO="$ROOT/build/treefrog-initramfs.cpio"
LINUXRC="$ROOT/rootfs/treefrog/linuxrc"

[ -f "$STOCK_CPIO" ] || { echo "ERROR: falta $STOCK_CPIO — ejecuta scripts/extract-stock-initramfs.sh primero"; exit 1; }
[ -f "$LINUXRC" ] || { echo "ERROR: falta $LINUXRC"; exit 1; }

echo "== 1. extraer initramfs stock (componentes base) =="
# NOTA: cpio devuelve rc!=0 por no poder mknod dev/* sin root (WSL) — irrelevante:
# nuestro linuxrc monta devtmpfs al arranque, los device nodes del cpio no se usan.
rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"
(cd "$OUT_DIR" && cpio -idm --no-absolute-filenames < "$STOCK_CPIO" >/dev/null 2>&1) || true

echo "== 2. limpiar lo que NO usamos (S-scripts stock, inittab stock) =="
# NOTA (R35): el kernel 4.4 con initramfs ejecuta /init PRIMERO (init/main.c:1023-1027:
# ramdisk_execute_command="/init"; si no existe -> NULL -> prepare_namespace() y el
# init= de bootargs NO se evalúa en ese path -> pánico silencioso sin /init).
# El stock lleva /init (script exec /sbin/init). Nuestro flujo: /init = linuxrc propio.
rm -rf "$OUT_DIR/etc/init.d" "$OUT_DIR/etc/inittab" "$OUT_DIR/linuxrc" "$OUT_DIR/init"

echo "== 3. instalar linuxrc TreeFrog propio como /init (y /linuxrc alias) =="
install -m 0755 "$LINUXRC" "$OUT_DIR/init"
install -m 0755 "$LINUXRC" "$OUT_DIR/linuxrc"

echo "== 4. conservar del stock: busybox + symlinks, lib/, hcdaemon, hotplug_helper =="
# (bin/ lib/ usr/ sbin/ ya están del paso 1; verificación abajo)
# NOTA: cubevol NO está en el initramfs stock — vive en la SD (rootfs/usr/bin/,
# bindeado por S99app); nuestro linuxrc lo lanza desde /mnt/sdcard tras montar.
for f in bin/busybox lib/ld.so.1 lib/libc.so.6 usr/bin/hcdaemon bin/hotplug_helper; do
  [ -e "$OUT_DIR/$f" ] || { echo "ERROR: falta componente stock $f"; exit 1; }
done
echo "  componentes verificados: busybox, ld.so, libc, hcdaemon, hotplug_helper"

echo "== 5. generar cpio =="
(cd "$OUT_DIR" && find . -print0 | cpio --null -o --format=newc > "$OUT_CPIO" 2>/dev/null)
N=$(cd "$OUT_DIR" && find . | wc -l)
echo "  $N entradas, $(stat -c %s "$OUT_CPIO") bytes"
sha256sum "$OUT_CPIO"
echo "== done: $OUT_CPIO =="
