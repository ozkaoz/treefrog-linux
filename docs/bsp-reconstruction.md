# Matriz de reconstrucción del BSP (FASE B)

Fecha: 2026-09-09. Auditoría contra `/mnt/d/GitHub/KERNEL` (SDK 2024.02.y.2 + local).

## Matriz componente/origen/estado

| Componente | Origen verificado | Encontrado? | Versión | Compatibilidad | Acción necesaria |
|---|---|---|---|---|---|
| Patches arch support (Kbuild.platforms, Kconfig, clk/Makefile, clocksource/Makefile) | `KERNEL/linux-4.4.186/0001-*.patch` == SDK `patches/linux-4.4.186/` | ✅ | serie 38 patches para 4.4.186 | 4.4.186 exacto | Copiar a `patches/linux-4.4.186/` del repo; aplicar en orden |
| Parches musb/nand/sdio/usb/etc | `0002..0055` | ✅ | idem | 4.4.186 | idem |
| yaffs2 | `patches/linux-4.4.186/yaffs2/` (706 archivos, `patch-ker.sh c m`) | ✅ | yaffs2 vendor | 4.4 (Kconfig_multi/single) | Copiar; aplicar via patch-ker.sh como hace el SDK |
| `arch/mips/hc16xx/*` (board, cmdline, init, irq, prom, serial, time, Platform, Makefile) | SDK `.git/modules/SOURCE/linux-drivers` @ dd572de | ✅ (la auditoría previa que decía "falta" era incorrecta) | tag-hclinux-2024.02.y.2 | 4.4/5.12 | Importar a `vendor/hichip/linux-drivers/` |
| `arch/mips/include/asm/mach-hc16xx/{spaces.h,kernel-entry-init.h,dma-coherence.h}` | idem | ✅ | idem | — | idem |
| `drivers/clk/hc16xx/*` (7 archivos) | idem | ✅ | idem | — | idem |
| `drivers/clocksource/timer-hc16xx.c` | idem | ✅ | idem | — | idem |
| `drivers/hcdrivers/*` (33 subdirs: adc, amprpc, avp-proxy, fbdev, ge, gpio, i2c, input, kshm, kumsgq, lvds, mmz, musb, nand, pinctrl, pwm, rc, rtc, sdio, spi, spi-sf, usb/gadget, virtuart, watchdog...) | `KERNEL/hcdrivers/` == SDK linux-drivers/drivers/hcdrivers | ✅ verificado idéntico por diff | tag-hclinux-2024.02.y.2 | 4.4 (nand-hc-4.x.c) y 5.12 (nand-hc-5.x.c) separados | Importar |
| `include/uapi/hcuapi/` (62 headers) | SDK `.git/modules/SOURCE/linux-drivers/modules/hcuapi` @ 8013c93 | ✅ | tag-hclinux-2024.02.y.2 | UAPI estable | Importar |
| DTS boards de referencia (a3100 v10/v20, a3200, a3300, a5100, b300, b3100, b3120, c300, c3000, c3100, c5200, d3000, d3100/v20/v30, d3101, d5200...) | SDK `board/hichip/hc16xx/**` | ✅ | 2024.02.y.2 | Plantillas para boards TreeFrog (las consolas reales NO son devboards: requieren DTS propios extraídos de firmware stock) | Importar como referencia |
| `hc16xx-common.dtsi` + AVP dtsi por board | SDK `board/hichip/hc16xx/common/dts/` | ✅ | idem | — | Importar como referencia |
| Kernel configs 4.4.186 | SDK `board/hichip/hc16xx/common/kernel-configs/4.4.186/kernel-*.config` (5 variantes) | ✅ | 4.4.186 | — | Importar como base de configs/ |
| `linux-ext-*.mk` (patch-hichip-driver, fixup-load-addr, prepare-patch-as-per-version, elf-append-dtb) + `update_physical_start.sh` | SDK `linux/` | ✅ | 2024.02.y.2 | Glue Buildroot | Portar su lógica a nuestros scripts |
| `hcbuild.env` (hcbuild/hcconfig/submodule helpers) | SDK raíz | ✅ | idem | — | Referencia para build.sh |
| Linux 4.4.186 vanilla | `/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186/source/` (tarball + árbol) | ✅ | 4.4.186 | — | `scripts/fetch-kernel.sh` usa tarball local; sha contra kernel.org |
| Toolchain | `~/sf3000-work/sf3000toolchain/.../bin/mips-mti-linux-gnu-*` | ✅ | Codescape 2018.09-02, GCC 6.3.0, MIPS32r2 LE, o32 | Requerido por SDK (toolchain-external-codescape-mti-mips) | Usar tal cual; documentar versiones |
| `linux-ext-fixup-load-addr.mk` (derivación CONFIG_PHYSICAL_START desde DTS) | SDK `linux/` | ✅ | idem | — | Reimplementar en `scripts/build-kernel.sh` |

## Piezas marcadas como faltantes en auditoría previa — verificación REAL

| Pieza "faltante" | Realidad verificada | Dónde |
|---|---|---|
| `arch/mips/hc16xx/` | **NO falta** — viene dentro de `SOURCE/linux-drivers` (submodule del SDK) | SDK tarball git modules + restaurado en scratch |
| `drivers/clk/hc16xx/` | **NO falta** — idem | idem |
| `drivers/clocksource/timer-hc16xx.c` | **NO falta** — idem | idem |
| `include/uapi/hcuapi/` | **NO falta** — submodule anidado `hcuapi` del linux-drivers | idem |
| DTS originales | **NO faltan** — `board/hichip/hc16xx/**` | SDK tarball |
| Kernel configs originales | **NO faltan** — `kernel-configs/4.4.186/` (5 variantes) | SDK tarball |
| `linux-ext-fixup-load-addr.mk` | **NO falta** | SDK tarball `linux/` |

**Conclusión:** TODAS las piezas supuestamente faltantes están presentes en el SDK
hclinux-2024.02.y.2.tar.gz local. El BSP 4.4.186 puede reconstruirse íntegramente
con material local + kernel vanilla.

## Lo que SÍ falta (real)

1. **DTB/kernel stock de las consolas TreeFrog reales** (R36SX, SF3000, etc.): los DTS del SDK son de devboards Hichip. Los perfiles reales requieren extraer DTB del firmware stock de cada consola (FASE D, `docs/boards/`).
2. **Verificación del sha256 del tarball vanilla contra kernel.org** (FASE C).
3. **Defconfig exacto de cada consola real** — partir de `kernel-squashfs.config` del SDK y ajustar con evidencia del firmware stock.
