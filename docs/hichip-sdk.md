# El SDK Hichip HCLinux (hallazgos verificados)

Fecha: 2026-09-09. Fuente: `/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz`
(SHA256 `e3211b41...f8d5d`). Mirror del repo git privado
`gitlab.hichiptech.com:62443/sw/hclinux_sdk/hclinux.git`, rama `hclinux-2024.02.y.2`
(commit `8a08de57ab933dc26700fe807440f1226f0b8eeb` en packed-refs).

## Qué es

Buildroot externo (`BR2_EXTERNAL`) para SoC Hichip HC16xx (MIPS32r2, dual-core
asimétrico):

- **Core main:** Linux (4.4.186 o 5.12.4, seleccionable por defconfig)
- **Core AVP:** HCRTOS (submodule `SOURCE/avp` = hcrtos) — vídeo/audio/display
- **Comunicación inter-core:** AMPRPC (drivers `amprpc`, `avp-proxy`, `kshm`, `kumsgq`, `virtuart`)
- **Bootloader:** hcboot (submodule propio, configs en `board/hichip/hc16xx/common/hcboot-configs/`)

## Flujo de build del kernel (el REAL, verificado en los .mk)

1. **Descarga Linux vanilla** (`BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="4.4.186"`) desde kernel.org.
2. **`linux-ext-prepare-patch-as-per-version.mk`:** enlaza `patches/linux` → `patches/linux-$(LINUX_VERSION)`. Buildroot aplica `*.patch` en orden alfabético/numérico.
3. **`linux-ext-patch-hichip-driver.mk`** (PRE_PATCH + PRE_BUILD hooks):
   - `rsync SOURCE/linux-drivers/` sobre el árbol del kernel. Esto vuelca:
     - `arch/mips/hc16xx/` (board.c, cmdline.c, init.c, irq.c, prom.c, serial.c, time.c, Platform, Makefile)
     - `arch/mips/include/asm/mach-hc16xx/` (spaces.h, kernel-entry-init.h, dma-coherence.h)
     - `drivers/clk/hc16xx/`, `drivers/clocksource/timer-hc16xx.c`
     - `drivers/hcdrivers/**` (33 componentes) + hook en drivers/Makefile+Kconfig (patch 0007)
     - `include/uapi/hcuapi/` (62 headers UAPI; se instalan a staging para userspace)
   - symlinks `include/uapi` para compilar DTS con includes del kernel
   - `patches/linux/yaffs2/patch-ker.sh c m $(LINUX_DIR)` — integra yaffs2 in-tree
4. **`linux-ext-fixup-load-addr.mk`** (PRE_BUILD):
   - Copia el DTS elegido a un dir temporal, le añade `unsigned int linux_load_addr = (CONFIG_LINUX_MEMORY_OFFSET);` y `avp_load_addr = (HCRTOS_SYSMEM_OFFSET + 0x1000);`
   - Lo preprocesa con gcc `-E -nostdinc -D__DTS__` (resolviendo los `#define CONFIG_*` del DTS)
   - Compila un mini-programa C host que imprime las direcciones
   - `update_physical_start.sh` reescribe:
     - `CONFIG_PHYSICAL_START` en el `.config` del kernel
     - `PHYS_OFFSET` `_AC(...)` en `arch/mips/include/asm/mach-hc16xx/spaces.h`
     - `AVP_ENTRY_ADDR` en `arch/mips/include/asm/mach-hc16xx/kernel-entry-init.h`
   - Es decir: **la dirección física de carga del Linux y el entry del AVP se derivan del DTS de la board** en cada build. Dos boards con distinto reparto de memoria NO comparten binario.
5. **Config:** `BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG_FILE` = `board/hichip/hc16xx/common/kernel-configs/$(LINUX_VERSION)/kernel-squashfs.config` (o initramfs/jffs2/...).
6. **Imagen:** `vmlinux` + GZIP (`BR2_LINUX_KERNEL_VMLINUX` + `BR2_LINUX_KERNEL_GZIP`), luego `linux-ext-elf-append-dtb.mk`:
   - `objcopy --update-section .appended_dtb=<board>.dtb vmlinux`
   - `objcopy -O binary vmlinux vmlinux.bin` (ELF gzip con DTB embebido)
   - `install ... dtb.bin` → `$(BINARIES_DIR)/dtb.bin`

## Reparto de memoria (modelo DTS, verificado en hc16xx-db-a3100-v10.dts)

```dts
#define CONFIG_AVP_MEMORY_SIZE (HCRTOS_SYSMEM_SIZE + HCRTOS_MMZ0_SIZE + HCRTOS_MMZ1_SIZE)
#define CONFIG_FRAMEBUFFER_STATIC_MEM_SIZE (0)
#define CONFIG_LINUX_MEMORY_SIZE (CONFIG_MEMORY_SIZE - CONFIG_AVP_MEMORY_SIZE - ...)
#define CONFIG_LINUX_MEMORY_OFFSET (0)
#define CONFIG_FRAMEBUFFER_STATIC_PHYS (CONFIG_LINUX_MEMORY_OFFSET + CONFIG_LINUX_MEMORY_SIZE)
memory { reg = <CONFIG_LINUX_MEMORY_OFFSET CONFIG_LINUX_MEMORY_SIZE>; };
bootargs = "root=/dev/mtdblock5 rw rootfstype=squashfs init=/linuxrc console=ttyS0,115200N8 earlycon=uart8250,mmio,0x18818300,115200n8 ...";
```

Los tamaños `CONFIG_MEMORY_SIZE`/`HCRTOS_SYSMEM_SIZE`/`HCRTOS_MMZ*` llegan vía
includes del dtsi de la board (definidos en su propio DTS/AVP dtsi).

## Toolchain del SDK

`toolchain/toolchain-external-codescape-mti-mips` (Buildroot package) — coincide
con el Codescape GCC 6.3.0 ya presente en WSL. Fixup de symlinks libstdc++.

## Defconfigs de boards (42) y su kernel

Todos los defconfigs examinados usan `BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="4.4.186"`.
El SDK 2024.02.y.2 también contiene configs para 5.12.4 (`kernel-configs/5.12.4/`).

## Comandos de verificación usados

```bash
sha256sum /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz
tar -tzf ... > list; grep/awk por componente
tar -xzf ... .gitmodules linux/ board/hichip/hc16xx/common ...
GIT_DIR=.git/modules/SOURCE/linux-drivers git ls-tree dd572de   # 197 archivos
GIT_DIR=.git/modules/.../modules/hcuapi git ls-tree HEAD         # 62 headers
diff -rq /mnt/d/GitHub/KERNEL/hcdrivers <tarball>/drivers/hcdrivers   # idéntico
readelf -h test.o   # toolchain: ELF32, little endian, MIPS
```
