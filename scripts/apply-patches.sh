#!/bin/bash
# apply-patches.sh — replica el flujo de patching del SDK HCLinux para 4.4.186:
#   1) .patch en orden numérico (buildroot: patches/linux-$(VERSION))
#   2) rsync linux-drivers sobre el árbol (linux-ext-patch-hichip-driver.mk)
#   3) yaffs2 patch-ker.sh (modo in-tree del fabricante)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
KERNEL_VERSION="4.4.186"
KERNEL_DIR="${TFL_KERNEL_DIR:-$ROOT/downloads/linux-$KERNEL_VERSION}"
PATCHES_DIR="$ROOT/patches/linux-$KERNEL_VERSION"
LINUX_DRIVERS="$ROOT/vendor/hichip/linux-drivers"
YAFFS2_DIR="${TFL_YAFFS2_DIR:-$ROOT/downloads/yaffs2-4.4.186}"
SDK_YAFFS2=/mnt/d/GitHub/KERNEL/linux-4.4.186/yaffs2

[ -d "$KERNEL_DIR" ] || { echo "ERROR: falta $KERNEL_DIR — ejecuta scripts/fetch-kernel.sh"; exit 1; }
[ -d "$LINUX_DRIVERS" ] || { echo "ERROR: falta vendor/hichip/linux-drivers"; exit 1; }

cd "$KERNEL_DIR"

echo "== 1/3: patches Hichip $KERNEL_VERSION (en orden) =="
applied=0
for p in "$PATCHES_DIR"/*.patch; do
  [ -e "$p" ] || { echo "no hay patches"; break; }
  if git apply --check "$p" 2>/dev/null || patch -p1 --dry-run --silent -N < "$p" >/dev/null 2>&1; then
    patch -p1 --silent -N < "$p"
    applied=$((applied+1))
    echo "  ok: $(basename "$p")"
  else
    if grep -q "$(basename "$p")" .applied-patches 2>/dev/null; then
      echo "  ya aplicado (registro): $(basename "$p")"
    else
      echo "  ya aplicado (dry-run falla): $(basename "$p")"
    fi
  fi
  basename "$p" >> .applied-patches
done
echo "aplicados ahora: $applied"

echo
echo "== 2/3: rsync linux-drivers (linux-ext-patch-hichip-driver.mk) =="
rsync -a --chmod=u=rwX,go=rX "$LINUX_DRIVERS"/ .
mkdir -p arch/mips/boot/dts/include
mkdir -p scripts/dtc/include-prefixes
ln -sf ../../../../../include/uapi arch/mips/boot/dts/include/uapi
ln -sf ../../../include/uapi scripts/dtc/include-prefixes/uapi
echo "rsync ok"

# TreeFrog fix: gcc host >= 10 (Ubuntu 24.04) rompe el dtc de 4.4 (yylloc multiple definition)
# -fcommon en HOSTCFLAGS_DTC del Makefile de dtc (equivalente al fix upstream dtc)
sed -i 's|HOSTCFLAGS_DTC := -I\$(src) -I\$(src)/libfdt|HOSTCFLAGS_DTC := -I$(src) -I$(src)/libfdt -fcommon|' scripts/dtc/Makefile
rm -f scripts/dtc/*.o scripts/dtc/dtc
echo "dtc -fcommon fix ok"

echo
echo "== 3/3: yaffs2 in-tree (patch-ker.sh c m) =="
if [ -d "$YAFFS2_DIR" ]; then
  :
elif [ -d "$SDK_YAFFS2" ]; then
  echo "  usando yaffs2 del SDK local: $SDK_YAFFS2"
  YAFFS2_DIR="$SDK_YAFFS2"
else
  echo "  ADVERTENCIA: yaffs2 no disponible — saltando (kernel compila sin yaffs2 si config no lo exige)"
  YAFFS2_DIR=""
fi
if [ -n "$YAFFS2_DIR" ]; then
  ( cd "$YAFFS2_DIR" && "$YAFFS2_DIR/patch-ker.sh" c m "$OLDPWD" )
  echo "  yaffs2 integrado"
fi

echo
echo "== verificación rápida =="
ls arch/mips/hc16xx/ >/dev/null 2>&1 && echo "arch/mips/hc16xx OK" || echo "FALTA arch/mips/hc16xx"
grep -q HICHIP_HC16XX arch/mips/Kconfig && echo "Kconfig HICHIP_HC16XX OK" || echo "FALTA Kconfig HICHIP"
ls include/uapi/hcuapi >/dev/null 2>&1 && echo "hcuapi OK" || echo "FALTA hcuapi"
echo "done."
