#!/bin/bash
# fetch-kernel.sh — obtiene Linux 4.4.186 vanilla con verificación
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
KERNEL_VERSION="4.4.186"
DL_DIR="${TFL_DL_DIR:-$ROOT/downloads}"
KERNEL_TAR_XZ="$DL_DIR/linux-$KERNEL_VERSION.tar.xz"

# Fuente primaria: tarball local ya validado (Toolchains/R36SX)
LOCAL_TARBALL=/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186/source/linux-$KERNEL_VERSION.tar.xz
# SHA256 del tarball vanilla kernel.org (registrado en KERNEL_SOURCE_44186_MANIFEST.txt local;
# pendiente verificación independiente contra kernel.org — docs/known-gaps.md #7)
EXPECTED_SHA256="0b1273d35c0664234e069f1ba894161b466679f6e1053f44fcf4098290937984"
# kernel.org URL para verificación/download si no existe local
KERNELORG_URL="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz"

mkdir -p "$DL_DIR"

fetch() {
  if [ -f "$KERNEL_TAR_XZ" ]; then
    echo "[fetch] ya existe: $KERNEL_TAR_XZ"
    return
  fi
  if [ -f "$LOCAL_TARBALL" ]; then
    echo "[fetch] usando tarball local: $LOCAL_TARBALL"
    cp "$LOCAL_TARBALL" "$KERNEL_TAR_XZ"
  else
    echo "[fetch] descargando kernel.org: $KERNELORG_URL"
    curl -fL --retry 3 -o "$KERNEL_TAR_XZ" "$KERNELORG_URL"
  fi
}

verify() {
  echo "[verify] sha256..."
  ACTUAL=$(sha256sum "$KERNEL_TAR_XZ" | awk '{print $1}')
  if [ "$ACTUAL" != "$EXPECTED_SHA256" ]; then
    echo "ERROR: sha256 mismatch"
    echo "  expected: $EXPECTED_SHA256"
    echo "  actual:   $ACTUAL"
    exit 1
  fi
  echo "[verify] OK: $ACTUAL"
  echo "$ACTUAL  linux-$KERNEL_VERSION.tar.xz" > "$DL_DIR/SHA256SUMS"
}

extract() {
  cd "$DL_DIR"
  if [ -d "linux-$KERNEL_VERSION" ]; then
    echo "[extract] ya extraído: $DL_DIR/linux-$KERNEL_VERSION"
  else
    echo "[extract] tar xf..."
    tar -xf "linux-$KERNEL_VERSION.tar.xz"
  fi
}

fetch
verify
extract
echo "[done] $DL_DIR/linux-$KERNEL_VERSION"
