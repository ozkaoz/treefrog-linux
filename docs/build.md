# Build (FASE C/D — guía de reproducibilidad)

Entorno verificado: WSL Ubuntu-24.04, GCC host para helpers, toolchain target
Codescape GNU 2018.09-02 (GCC 6.3.0) `mips-mti-linux-gnu` (MIPS32r2, LE, o32).

```bash
# 0. toolchain (ya presente, NO mover):
#    ~/sf3000-work/sf3000toolchain/mipsel-buildroot-linux-gnu_sdk-buildroot/bin/

# 1. Obtener Linux 4.4.186 vanilla (kernel.org; sha256 gate)
scripts/fetch-kernel.sh

# 2. Aplicar el flujo Hichip real: 41 patches + rsync linux-drivers + yaffs2
scripts/apply-patches.sh

# 3a. Board REAL (R36SX) — DTS con includes vendor (gcc -E + dtc), uImage stock-format:
scripts/build-kernel.sh r36sx squashfs
# genera out/r36sx/: vmlinux.uImage (legacy gzip, load 0x80000000), dtb.bin (byte-identico
# al stock), vmlinux, vmlinux.bin, manifest.json

# 3b. Devboard de referencia del SDK (smoke test): hc16xx-db-a3100-v10, etc.
scripts/build-kernel.sh hc16xx-db-a3100-v10 squashfs

# 4. Deploy a SD de pruebas (G:) — DRY-RUN primero, --apply para ejecutar
scripts/deploy-sd.sh r36sx            # plan + verificaciones, no copia
scripts/deploy-sd.sh r36sx --apply    # backup + copia + sync + registro test-run
```

## Qué replica cada script (fidelidad al SDK)

| Paso | Script | Equivalente SDK 2024.02.y.2 |
|---|---|---|
| Descarga vanilla + sha | fetch-kernel.sh | BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE=4.4.186 |
| Patches ordenados | apply-patches.sh §1 | linux-ext-prepare-patch-as-per-version.mk + buildroot linux.mk |
| rsync drivers | apply-patches.sh §2 | linux-ext-patch-hichip-driver.mk |
| yaffs2 in-tree | apply-patches.sh §3 | patch-ker.sh c m (desde patches/linux-4.4.186/yaffs2 local) |
| Config board | build-kernel.sh | kernel-configs/4.4.186/kernel-*.config |
| PHYSICAL_START desde DTS | build-kernel.sh | linux-ext-fixup-load-addr.mk + update_physical_start.sh (usado verbatim) |
| DTB board real | build-kernel.sh (gcc -E + dtc) | hcboot CONFIG_CUSTOM_DTS_PATH (mismo preprocesado) |
| vmlinux | build-kernel.sh | make vmlinux |
| uImage | build-kernel.sh | **formato stock consola**: legacy uImage gzip payload vmlinux.bin, load 0x80000000 (evidencia R15: el stock NO lleva DTB embebido; hcboot carga dtb.bin aparte) |

## Diferencias actuales respecto al build del fabricante

1. No usamos Buildroot completo (ni rootfs/hcboot/AVP) — solo kernel. Es la unidad mínima del milestone 1.
2. Los blobs `.o` vendor (hc-p2p, adc) NO se importaron al repo (licencia de redistribución dudosa). El rsync del paso 2 los copia desde vendor/ si están; si el config de la board no activa HC_P2P, no se enlazan. Para activarlos: copiarlos del SDK local y documentarlo.
3. yaffs2 se toma del SDK local (`/mnt/d/GitHub/KERNEL/linux-4.4.186/yaffs2`) porque no se versiona en el repo (706 archivos con mezcla GPL; se valorará importar solo lo necesario).
4. Nuestro uImage R36SX (2.7 MB) es más pequeño que el stock (3.9 MB): el config base del SDK no incluye todos los drivers del stock. Formato/load/toolchain/DTB equivalentes (ver `docs/research-log.md` R19).

## Registro de verificaciones del build

Cada build produce `out/<board>/manifest.json` con commit, hashes y direcciones derivadas del DTS.
El primer build de smoke test con board de devboard (`hc16xx-db-a3100-v10`) valida que el BSP
compila; NO sirve para flashear consolas reales (eso requiere el board profile real, FASE D).
