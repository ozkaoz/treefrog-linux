# Research log — hallazgos con evidencia

Formato: fecha / hallazgo / evidencia (comando + archivo + output + hash).

## 2026-09-09 — FASE A/B

### R1. WSL y entorno operativo
- `wsl.exe -l -v` → `Ubuntu-24.04 Stopped` (WSL1). `uname -a` → `Linux DFNK 4.4.0-26100-Microsoft`.
- `which git gh` → `/usr/bin/git`, `/usr/bin/gh`. `gh auth status` → `✓ Logged in to github.com account ozkaoz`, scopes repo/workflow.
- `df -h /mnt/d` → 375G disponibles.

### R2. /mnt/g existe pero está VACÍO
- `ls -la /mnt/g` → solo `.` `..` (dir de root, 512B, mtime Jul 24). G: no está montada como drvfs ahora mismo, o no hay media. NO asumir su contenido. Antes de cualquier deploy: verificar montaje y contenido (AGENTS.md §2).
- Múltiples montajes de SD previos existen bajo /mnt (r36sx_sd*, sd, etc. — WSL1 auto-mounts).

### R3. Material KERNEL clasificado
- Inventario completo: `docs/source-inventory.md`.
- Tarball SDK 2.1GB: `sha256sum` → `e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d`.
- `tar -tzf | wc -l` → 60755 entradas.

### R4. Patches Hichip 4.4.186 completos y verificados
- Local `KERNEL/linux-4.4.186/` (38 patches + yaffs2/ 706 archivos) == SDK `patches/linux-4.4.186/`.
- Verificación: `diff -rq` → solo 8 archivos de test yaffs2 difieren (EOL CRLF vs LF, tamaños idénticos en listado 7z). Los 38 .patch son iguales.

### R5. Las "piezas faltantes" de la auditoría previa NO faltan
- `SOURCE/linux-drivers` (submodule git dentro del tarball, tag-hclinux-2024.02.y.2 = commit `dd572de`) contiene: `arch/mips/hc16xx/` (12 archivos), `arch/mips/include/asm/mach-hc16xx/` (3 headers), `drivers/clk/hc16xx/` (7), `drivers/clocksource/timer-hc16xx.c`, `drivers/hcdrivers/**` (173), `include/hc_clk_gate.h`.
- Submodule anidado `hcuapi` (commit `8013c93`) → 62 headers UAPI restaurables.
- Comando: `GIT_DIR=<tarball>/.git/modules/SOURCE/linux-drivers git ls-tree dd572de` + `git --work-tree=... checkout -f dd572de -- .` → 197 archivos restaurados y listados.
- `KERNEL/hcdrivers/` local == `linux-drivers/drivers/hcdrivers` del SDK verificado con `diff -rq` (cero diferencias).

### R6. Flujo de build del fabricante (la fuente de verdad del BSP)
- Archivos: `hclinux/linux/linux-ext-{patch-hichip-driver,fixup-load-addr,prepare-patch-as-per-version,elf-append-dtb}.mk`, `hclinux/linux/update_physical_start.sh`, `hclinux/hcbuild.env`, `hclinux/boot/hcboot/hcboot.mk` (extraídos del tarball, texto completo en scratch y resumido en `docs/hichip-sdk.md`).
- Hecho clave: CONFIG_PHYSICAL_START / PHYS_OFFSET / AVP_ENTRY_ADDR se derivan del DTS de la board en cada build (mecanismo completo documentado en `docs/hichip-sdk.md` §flujo).

### R7. Kernel configs reales del SDK
- `board/hichip/hc16xx/common/kernel-configs/4.4.186/kernel-squashfs.config` extraído y leído: `CONFIG_HICHIP_HC16XX=y`, `CONFIG_CPU_LITTLE_ENDIAN=y`, `CONFIG_CPU_MIPS32_R2=y`, `CONFIG_PHYSICAL_START=0xffffffff80000000` (valor default; lo reescribe fixup por board), `CONFIG_MIPS_CMDLINE_FROM_DTB=y`, `CONFIG_MIPS_NO_APPENDED_DTB=y` (¡el config dice no appended DTB pero el .mk lo appendea vía objcopy — el flag Kconfig no manda en este flujo!), squashfs root.
- 5 variantes: squashfs, initramfs, squashfs-jffs2, squashfs-jffs2-tiny, squashfs-carlink.

### R8. Toolchain verificado
- `~/sf3000-work/sf3000toolchain/mipsel-buildroot-linux-gnu_sdk-buildroot/bin/mips-mti-linux-gnu-gcc --version` → `Codescape GNU Tools 2018.09-02 for MIPS MTI Linux, 6.3.0`.
- Test endian: compiló `/tmp/endian_test.c` → `readelf -h`: `Class: ELF32, Data: 2's complement little endian, Machine: MIPS R3000`. `-march=mips32r2` OK.
- NOTA: el nombre de directorio dice "mipsel" pero el prefijo es `mips-mti-linux-gnu`; es LE (verificado en R8). El SDK usa exactamente este toolchain (package `toolchain-external-codescape-mti-mips`).

### R9. Kernel vanilla 4.4.186 local
- `/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186/source/linux-4.4.186/` árbol vanilla (sin hc16xx) + `linux-4.4.186.tar.xz`.
- Manifest local `KERNEL_SOURCE_44186_MANIFEST.txt`: `ARCHIVE_SHA256=0b1273d35c0664234e069f1ba894161b466679f6e1053f44fcf4098290937984` (pendiente verificar contra kernel.org — gap #7).
- `head Makefile` → `VERSION=4 PATCHLEVEL=4 SUBLEVEL=186 NAME="Blurry Fish Butt"`.

### R10. Repo remoto creado
- `gh repo create ozkaoz/treefrog-linux --public` → https://github.com/ozkaoz/treefrog-linux (no existía antes: `gh repo view` devolvía GraphQL error).

### R11. DTS de boards de referencia
- ~40 DTS/DTSI en `board/hichip/hc16xx/**/dts/`. Modelo: `<board>.dts` incluye `hc16xx-common.dtsi` + `<board>-avp.dtsi`; define particiones de memoria y bootargs (ejemplo completo en `docs/hichip-sdk.md`).
- SoC compatible string: `"Hichip,1600"` / `"hichip,hc16xx"`. CPU `"MIPS 74Kc"` @ PLL 900MHz.

### R12. Yaffs2 con blobs precompilados
- `drivers/hcdrivers/hc-p2p/{4.4.186,5.12.4}/p2p.o, p2p-dev.o` — .o precompilados del vendor. `drivers/hcdrivers/adc/get_adc_default_val*.o` también. → No redistribuir públicamente sin decisión de licencia (AGENTS.md §4.9, known-gaps #8).

### R13. FASE C ejecutada: patches + drivers + yaffs2 aplicados limpios (2026-09-09)
- `scripts/fetch-kernel.sh`: descarga kernel.org `linux-4.4.186.tar.xz` (83.5 MB), `sha256sum` == `0b1273d35c0664234e069f1ba894161b466679f6e1053f44fcf4098290937984` == manifest local de Toolchains. Gap #7 CERRADO (verificado contra kernel.org directamente).
- `scripts/apply-patches.sh`: 41/41 .patch aplicados sin conflicto (`patch -p1 --dry-run` antes de cada uno; orden numérico = orden Buildroot). rsync linux-drivers OK (arch/mips/hc16xx presente, Kconfig HICHIP_OK, hcuapi OK). yaffs2 `patch-ker.sh c m` integró fs/yaffs2 + fs/Kconfig + fs/Makefile.
- Fix propio documentado: `sed -i ... -fcommon` en `scripts/dtc/Makefile` del árbol (gcc host 13 de Ubuntu 24.04 rompe dtc 4.4 con `yylloc` multiple-definition; -fcommon es el fix estándar). Se aplica en apply-patches.sh paso 2.

### R14. FASE C smoke build SUPERADO (2026-09-09 18:42)
- `scripts/build-kernel.sh hc16xx-db-a3100-v10 squashfs`:
  - fixup load addr desde DTS funcionó igual que el SDK: `CONFIG_PHYSICAL_START=0xffffffff80000000`, `phys_offset=0x00000000`, `avp_entry=0xa4f34000` (el script update_physical_start.sh del vendor corrió verbatim sobre .config + spaces.h + kernel-entry-init.h).
  - DTB compilado (27849 B) con regla `%.dtb` de arch/mips/Makefile:365 (DTS en `arch/mips/boot/dts/` plano). Warnings dtc solo `avoid_default_addr_size` (benignos, presentes también en builds vendor).
  - vmlinux: `make ... vmlinux` OK → `readelf -h`: `ELF32 LSB EXEC MIPS R3000, Entry 0x803e3200`, linkeado @0x80000000.
  - `Linux version 4.4.186-release (dafunknoise@DFNK) (gcc version 6.3.0 (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux)) #2 PREEMPT` — compilador del fabricante.
  - Manifest completo en out/hc16xx-db-a3100-v10/manifest.json (commit ff9ee22, sha256 de config/dts/dtb/vmlinux.bin).
  - Nota: config vendor trae `MIPS_NO_APPENDED_DTB` (hcboot pasa DTB). El append del SDK es conveniencia: objcopy --add-section si el ELF no tiene `.appended_dtb` (nuestro flujo), --update-section si la tiene. Resultado: vmlinux.bin 5804684 B.
- Artifact SHA256 (manifest): vmlinux_bin `80833da6ad8072b7fd9772fd61e66a43585bd6931aab646d4d187face6f081ea`, dtb `bae8b4640e281fd51ec2e2128277ef2a441dcecac1a29185b9e65087f1e2ebc6`.
