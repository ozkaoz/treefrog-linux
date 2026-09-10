#!/bin/bash
# extract-stock-initramfs.sh — extrae el initramfs embebido del kernel stock R36SX
#
# EVIDENCIA (R30): el vmlinux.uImage stock (53b3e0b3, entry 0x803337c0) lleva un
# initramfs CPIO newc SIN compresion embebido en su payload raw (tras el vmlinux
# binario), ~3.85 MB, 380 archivos: init, linuxrc->bin/busybox, bin/, etc/, dev/,
# lib/, rootfs-bind-mount script (mount --bind /media/${MNTDIR}/rootfs/...).
# Los kernels k1/k2 (kernel-squashfs.config del SDK) NO lo llevan
# (CONFIG_INITRAMFS_SOURCE vacio en la variante squashfs).
# El DTS r36sx exige: bootargs "root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc".
# => sin initramfs embebido, el kernel no tiene raiz: muere en init => 0 escrituras
#    en SD => logo eterno. Este script reconstruye el cpio para incrustarlo en k3.
#
# Uso: scripts/extract-stock-initramfs.sh [uImage-stock] [salida.cpio]
#   por defecto: golden /mnt/d/GitHub/lgpt-r36sx-port/physical-evidence/stock-kernel-golden/vmlinux.uImage.stock
#   salida:      build/stock-initramfs.cpio
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
STOCK="${1:-/mnt/d/GitHub/lgpt-r36sx-port/physical-evidence/stock-kernel-golden/vmlinux.uImage.stock}"
OUT="${2:-$ROOT/build/stock-initramfs.cpio}"

[ -f "$STOCK" ] || { echo "ERROR: no existe $STOCK"; exit 1; }
mkdir -p "$(dirname "$OUT")"

# 1. quitar cabecera uImage (64 bytes) y descomprimir el payload gzip
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dd if="$STOCK" of="$TMP/payload.gz" bs=64 skip=1 2>/dev/null
gunzip -c "$TMP/payload.gz" > "$TMP/vmlinux.bin"
echo "payload raw: $(stat -c %s "$TMP/vmlinux.bin") bytes"

# 2. localizar el cpio newc MAS GRANDE (el initramfs real; hay falsos positivos
#    '070701' dentro de datos) y extraerlo hasta TRAILER!!! inclusive
python3 - "$TMP/vmlinux.bin" "$OUT" <<'EOF'
import sys

src, dst = sys.argv[1], sys.argv[2]
data = open(src, 'rb').read()

def parse_cpio(data, off):
    """Parse cpio newc desde off hasta TRAILER!!!. Devuelve (fin, nfiles, ok)."""
    n = 0
    pos = off
    while pos + 110 <= len(data):
        if data[pos:pos+6] != b'070701':
            return pos, n, False
        try:
            filesize = int(data[pos+54:pos+62], 16)
            namesize = int(data[pos+94:pos+102], 16)
        except ValueError:
            return pos, n, False
        name = data[pos+110:pos+110+namesize-1].decode('utf-8', 'replace')
        hname = (110 + namesize + 3) & ~3
        pos2 = pos + hname + ((filesize + 3) & ~3)
        if name == 'TRAILER!!!':
            return pos2, n, True
        n += 1
        pos = pos2
    return pos, n, False

best = None  # (start, end, nfiles)
i = 0
while True:
    j = data.find(b'070701', i)
    if j < 0:
        break
    end, n, ok = parse_cpio(data, j)
    if ok and n > 100 and (best is None or n > best[2]):
        best = (j, end, n)
    i = j + 1

if not best:
    print('ERROR: no se encontro cpio newc valido (>100 archivos)')
    sys.exit(1)
start, end, n = best
open(dst, 'wb').write(data[start:end])
print(f'cpio extraido: {n} archivos, {end-start} bytes -> {dst}')
EOF

# 3. verificacion: el cpio debe listar linuxrc y busybox
#    NOTA: no usar 'grep -q' en pipe con pipefail (grep -q cierra el pipe al primer
#    match -> SIGPIPE a cpio -> pipeline 'falla' aunque el archivo este). Lista primero.
CPIO_LIST="$(mktemp)"
cpio -it < "$OUT" 2>/dev/null > "$CPIO_LIST" || true
if grep -a -q linuxrc "$CPIO_LIST"; then
  echo "OK: linuxrc presente en el cpio"
  rm -f "$CPIO_LIST"
else
  echo "ERROR: linuxrc no encontrado en el cpio extraido"; rm -f "$CPIO_LIST"; exit 1
fi
N=$(cpio -it < "$OUT" 2>/dev/null | wc -l)
echo "OK: $N entradas. SHA256:"
sha256sum "$OUT"
