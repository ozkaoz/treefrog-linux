#!/bin/bash
# deploy-sd.sh — deploy REVERSIBLE y seguro de artefactos a la SD de pruebas (G:)
#
# Contrato (AGENTS.md §4.6):
#   - verifica /mnt/g (montado, fs, espacio, estructura esperada);
#   - NUNCA escribe dispositivos raw ni flash interna;
#   - SOLO copia archivos esperados (vmlinux.uImage, dtb.bin) a cubegm/;
#   - crea backup previo con timestamp + SHA256;
#   - sync + verificación de checksums post-copia;
#   - genera registro docs/test-runs/YYYY-MM-DD_HHMM_<board>.md;
#   - imprime exactamente lo realizado y cómo hacer rollback.
#
# Uso: scripts/deploy-sd.sh <board> [--apply]
#   sin --apply: modo DRY-RUN (verifica todo y muestra el plan, NO copia)
#   con --apply:  ejecuta la copia
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUT_BASE="$ROOT/out"
SD="/mnt/g"
SD_BOOT_DIR="$SD/cubegm"

BOARD="${1:?uso: deploy-sd.sh <board> [--apply]}"
APPLY="${2:-}"

BOARD_OUT="$OUT_BASE/$BOARD"
for f in vmlinux.uImage dtb.bin manifest.json; do
  [ -f "$BOARD_OUT/$f" ] || { echo "ERROR: falta $BOARD_OUT/$f (ejecuta build-kernel.sh $BOARD)"; exit 1; }
done

echo "== 1. verificación de la SD (/mnt/g) =="
if ! mountpoint -q "$SD" 2>/dev/null && [ ! -d "$SD" ]; then
  echo "ERROR: /mnt/g no existe ni está montado."
  echo "  Monta la SD desde WSL:  sudo mkdir -p /mnt/g && sudo mount -t drvfs G: /mnt/g"
  exit 1
fi
[ -d "$SD" ] || { echo "ERROR: /mnt/g no es un directorio accesible"; exit 1; }

echo "--- filesystem ---"
df -h "$SD" | tail -1
echo "--- espacio libre mínimo requerido: 10 MB ---"
FREE_KB=$(df -k "$SD" | tail -1 | awk '{print $4}')
[ "$FREE_KB" -gt 10240 ] || { echo "ERROR: espacio insuficiente ($FREE_KB KB)"; exit 1; }

echo "--- estructura esperada (cubegm/) ---"
if [ ! -d "$SD_BOOT_DIR" ]; then
  echo "ERROR: $SD_BOOT_DIR no existe — ¿es esta la SD de pruebas correcta?"
  echo "Contenido actual de /mnt/g:"; ls -la "$SD" | head -10
  echo "REFUSANDO continuar (no es la SD de una consola TreeFrog con layout conocido)."
  exit 1
fi
ls -la "$SD_BOOT_DIR" | head -8

echo "--- archivo actual vmlinux.uImage en la SD (a sustituir) ---"
STOCK_SD_KERNEL="$SD_BOOT_DIR/vmlinux.uImage"
if [ -f "$STOCK_SD_KERNEL" ]; then
  echo "presente: $(stat -c%s "$STOCK_SD_KERNEL") bytes"
  sha256sum "$STOCK_SD_KERNEL"
else
  echo "ADVERTENCIA: no hay vmlinux.uImage previo en la SD (primera instalación?)"
fi

echo
echo "== 2. artefactos a desplegar =="
sha256sum "$BOARD_OUT/vmlinux.uImage" "$BOARD_OUT/dtb.bin" "$BOARD_OUT/manifest.json"
cat "$BOARD_OUT/manifest.json" | head -12

if [ "$APPLY" != "--apply" ]; then
  echo
  echo "== DRY-RUN: nada copiado. Usa --apply para ejecutar. =="
  echo "Plan: "
  echo "  1. backup -> $SD/backups-treelinux/<ts>/"
  echo "  2. cp $BOARD_OUT/vmlinux.uImage $SD_BOOT_DIR/vmlinux.uImage"
  echo "  3. cp $BOARD_OUT/dtb.bin        $SD_BOOT_DIR/dtb.bin"
  echo "  4. sync + verificación SHA256"
  exit 0
fi

echo
echo "== 3. backup de los archivos actuales =="
TS=$(date +%Y-%m-%d_%H%M)
BK="$SD/backups-treelinux/${TS}_${BOARD}"
mkdir -p "$BK"
for f in vmlinux.uImage dtb.bin avp.uImage; do
  if [ -f "$SD_BOOT_DIR/$f" ]; then
    cp -p "$SD_BOOT_DIR/$f" "$BK/$f"
    echo "backup: $f -> $BK/$f"
  fi
done
( cd "$BK" && sha256sum * > SHA256SUMS ) 2>/dev/null || true
cat "$BK/SHA256SUMS" 2>/dev/null

echo
echo "== 4. copia de artefactos (SOLO kernel y dtb; avp/bootloader NO se tocan) =="
cp "$BOARD_OUT/vmlinux.uImage" "$SD_BOOT_DIR/vmlinux.uImage"
cp "$BOARD_OUT/dtb.bin" "$SD_BOOT_DIR/dtb.bin"
sync
echo "copiado + sync."

echo
echo "== 5. verificación post-copia =="
sha256sum "$SD_BOOT_DIR/vmlinux.uImage" "$SD_BOOT_DIR/dtb.bin"
A=$(sha256sum "$BOARD_OUT/vmlinux.uImage" | awk '{print $1}')
B=$(sha256sum "$SD_BOOT_DIR/vmlinux.uImage" | awk '{print $1}')
C=$(sha256sum "$BOARD_OUT/dtb.bin" | awk '{print $1}')
D=$(sha256sum "$SD_BOOT_DIR/dtb.bin" | awk '{print $1}')
[ "$A" = "$B" ] || { echo "ERROR: checksum kernel mismatch post-copia"; exit 1; }
[ "$C" = "$D" ] || { echo "ERROR: checksum dtb mismatch post-copia"; exit 1; }
echo "CHECKSUMS OK."

echo
echo "== 6. registro de test-run =="
TR="$ROOT/docs/test-runs/${TS}_${BOARD}.md"
mkdir -p "$(dirname "$TR")"
GIT_COMMIT=$(cd "$ROOT" && git rev-parse HEAD)
cat > "$TR" <<EOF
# Test run: $BOARD — $TS

- commit probado: \`$GIT_COMMIT\`
- board: $BOARD
- artefactos: vmlinux.uImage ($(stat -c%s "$BOARD_OUT/vmlinux.uImage") B), dtb.bin ($(stat -c%s "$BOARD_OUT/dtb.bin") B)
- SHA256 kernel: $A
- SHA256 dtb: $C
- uImage: Load 0x80000000, Entry $(grep -o '"uimage_entry": "[^"]*"' "$BOARD_OUT/manifest.json" | cut -d'"' -f4)
- archivos sustituidos en SD: cubegm/vmlinux.uImage, cubegm/dtb.bin
- backup: $BK (con SHA256SUMS)
- avp.uImage / bootloader: NO tocados (stock)
- rollback: copiar $BK/vmlinux.uImage y $BK/dtb.bin de vuelta a $SD_BOOT_DIR/ y sync

## Resultado

- (pendiente de prueba física)

## Boot log

- (pendiente)

## Síntomas / siguiente acción

- (pendiente)
EOF
echo "registro: $TR"

echo
echo "== DONE. Rollback: restaurar $BK/* a $SD_BOOT_DIR/ =="
