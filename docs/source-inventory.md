# Inventario de fuentes locales

Fecha: 2026-09-09. Todo verificado desde WSL contra los archivos reales.

## 1. `/mnt/d/GitHub/KERNEL/`

| Archivo/dir | Qué es | Clasificación | SHA256 | Versionado en repo? |
|---|---|---|---|---|
| `hclinux-2024.02.y.2.tar.gz` (2.1 GB) | SDK HCLinux completo (Buildroot externo + submodules). Incluye `.git` del repo `gitlab.hichiptech.com/sw/hclinux_sdk/hclinux.git` con TODAS las ramas `hclinux-2022.03.y` → `hclinux-2024.02.y.dev` y tags | **Fuente vendor primaria** | `e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` | NO (2.1 GB). Referenciado. Piezas redistribuibles se importan selectivamente |
| `patches.7z` (313 KB) | Parches Hichip 4.4.186 (38) + 5.12.4 (21) + árbol yaffs2 (706 files). Contenido == `patches/linux-*` del SDK (verificado: solo diferencias CRLF en 8 archivos de test de yaffs2) | Patches vendor | `fa154f64584768429facc27d0894c97ad59e39b3ac87e2343aa992fbc01d0414` | Sí: copiados a `patches/linux-4.4.186/` |
| `hcdrivers/` | Working tree de `SOURCE/linux-drivers` (SOLO la porción `drivers/hcdrivers/` + Kconfig/Makefile top). Verificado idéntico por `diff -rq` contra el git del SDK | Código vendor | — | Sí: `vendor/hichip/linux-drivers/` |
| `linux-4.4.186/` (dir) | 38 patches Hichip para 4.4.186 + yaffs2/ (idem patches.7z) | Patches vendor | — | Sí: `patches/linux-4.4.186/` |
| `linux-5.12.4/` (dir) | 21 patches Hichip para 5.12.4 | Patches vendor (FUTURO, fase 4) | — | Referenciado (no se integran aún) |
| `hclinux_user_manual.pdf` | Manual oficial del SDK (inglés) | Documentación vendor | `18e505ea1ba0fcb739e4ae276ed6c0a6f33ffc8db38781d8e7a7e269649435f7` | NO subido (PDF 4.2 MB, redistribución pendiente de evaluar) |
| `hclinux_user_manual_es.pdf` | Traducción al español del manual (201 KB) | Documentación derivada | — | NO subido (mismo criterio) |

## 2. `/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186/`

| Material | Qué es | Nota |
|---|---|---|
| `source/linux-4.4.186.tar.xz` | Tarball vanilla kernel.org 4.4.186 | MANIFEST local: `ARCHIVE_SHA256=0b1273d35c0664234e069f1ba894161b466679f6e1053f44fcf4098290937984` (verificar contra kernel.org en FASE C) |
| `source/linux-4.4.186/` | Árbol vanilla ya extraído | Limpio: NO contiene `arch/mips/hc16xx` |
| `KERNEL_SOURCE_44186_MANIFEST.txt` | Manifiesto del árbol vanilla | Preparado 2026-07-28 para el port LGPT |

## 3. Toolchain (WSL home, NO mover)

- `~/sf3000-work/sf3000toolchain/mipsel-buildroot-linux-gnu_sdk-buildroot/` — Codescape GNU Tools 2018.09-02 for MIPS MTI Linux, **GCC 6.3.0**, prefijo `mips-mti-linux-gnu`, binarios en `bin/`. Verificado: produce **ELF32 MIPS little-endian**, `-march=mips32r2`, ABI o32 (default). Coincide con `CONFIG_CPU_LITTLE_ENDIAN=y` del kernel-config del SDK.
- Nombre del directorio (`mipsel-buildroot-...`) es engañoso: el prefijo real de los binarios es `mips-mti-linux-gnu` (little-endian). Documentado para no confundir en FASE C.

## 4. SDK HCLinux 2024.02.y.2 — contenido verificado (relevantes)

Extraído de `hclinux-2024.02.y.2.tar.gz` (60755 entradas):

| Componente | Ruta dentro del SDK | Estado |
|---|---|---|
| Patches kernel 4.4.186 | `patches/linux-4.4.186/` (38 .patch + yaffs2/) | ✅ verificado, == local |
| Patches kernel 5.12.4 | `patches/linux-5.12.4/` (21 .patch) | ✅ presente (fase futura) |
| `SOURCE/linux-drivers` (submodule) | `.git/modules/SOURCE/linux-drivers` (tag `tag-hclinux-2024.02.y.2` = commit `dd572de`) | ✅ restaurado: 197 archivos + submodule `hcuapi` (62 headers UAPI, commit `8013c93`) |
| DTS boards | `board/hichip/hc16xx/**/dts/` + `common/dts/` (~40 DTS/DTSI: a3100, a3200, a3300, a5100, b300, b3100, b3120, c300, c3000, c3100, c5200, d3000, d3100, d3101, d5200...) | ✅ presente |
| Kernel configs | `board/hichip/hc16xx/common/kernel-configs/4.4.186/kernel-{squashfs,initramfs,squashfs-jffs2,squashfs-jffs2-tiny,squashfs-carlink}.config` | ✅ presente |
| hcboot-configs / avp-configs | `board/hichip/hc16xx/common/{hcboot,avp}-configs/` | ✅ presente (referencia; NO se reemplazan) |
| Buildroot defconfigs | `configs/hichip_hc16xx_*.defconfig` (42) | ✅ presente |
| Glue buildroot | `linux/linux-ext-{patch-hichip-driver,fixup-load-addr,prepare-patch-as-per-version,elf-append-dtb}.mk`, `linux/update_physical_start.sh`, `hcbuild.env`, `boot/hcboot/hcboot.mk` | ✅ presente — define el build REAL del fabricante |
| SOURCE/avp (submodule HCRTOS) | `.git/modules/SOURCE/avp` | Presente en tarball; NO se toca (AVP stock se conserva) |
| document/ | PDFs técnicos Hichip (GPIO, ADC, PWM, UART, flash...) | Referencia |

## 5. Conclusiones de procedencia

1. **El material local es suficiente** para reconstruir el BSP 4.4.186 completo: patches + linux-drivers (incluidas las piezas que una auditoría previa marcaba "posiblemente faltantes": `arch/mips/hc16xx/`, `drivers/clk/hc16xx/`, `drivers/clocksource/timer-hc16xx.c`, `include/uapi/hcuapi/`, DTS, configs, `linux-ext-fixup-load-addr.mk`). Ver matriz completa en `docs/bsp-reconstruction.md`.
2. `hcdrivers/` local == `linux-drivers@2024.02.y.2` del SDK (porción drivers/hcdrivers). El repo tarball es la fuente más completa (incluye arch/, clk/, timer, hcuapi).
3. La licencia del kernel Linux es GPLv2. linux-drivers/hcdrivers: archivos con headers GPL/Hichip — se importan como vendor con procedencia documentada; no se ha encontrado LICENSE explícito del árbol linux-drivers (ver `docs/known-gaps.md`).
4. Material que NO debe versionarse: tarball SDK (2.1 GB), PDFs vendor (redistribución dudosa), toolchain, dumps.
