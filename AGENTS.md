# AGENTS.md — Constitución del proyecto treefrog-linux

**Versión:** 1.0
**Fecha:** 2026-09-09
**Repositorio:** https://github.com/ozkaoz/treefrog-linux
**Rama principal:** `main`
**Alcance:** contrato operativo para cualquier agente de IA que trabaje en este repo.

---

## 1. PROTOCOLO DE INICIO

Antes de realizar cualquier trabajo sustancial, el agente DEBE:

1. **Leer en orden:**
   - `AGENTS.md` (este archivo) — reglas permanentes
   - `docs/status.md` — estado actual del proyecto
   - `docs/known-gaps.md` — lo que NO se sabe
   - `docs/research-log.md` — evidencia de hallazgos
2. **Verificar estado real desde Git:**
   ```bash
   git branch --show-current && git rev-parse HEAD && git status --short --branch
   ```
3. **Confirmar objetivo y clase de cambio antes de editar.**

## 2. ENTORNO (CONTRATO INVIOLABLE)

- **TODO el desarrollo se hace desde WSL** (Ubuntu-24.04). No se usan herramientas Windows para git, compilación, análisis binario, montaje de unidades, checksums ni transferencias a SD.
- **Repo principal:** `/mnt/d/GitHub/treefrog-linux` (= `D:\GitHub\treefrog-linux`). No se trabaja desde `~/` como repo principal.
- **SD de pruebas:** letra Windows `G:` → se accede como `/mnt/g` desde WSL. Verificar SIEMPRE su contenido antes de escribir (filesystem, espacio, estructura, correspondencia con la SD esperada).
- **Toolchain:** Codescape GNU Tools 2018.09-02 (GCC 6.3.0) `mips-mti-linux-gnu` en `~/sf3000-work/sf3000toolchain/mipsel-buildroot-linux-gnu_sdk-buildroot/bin/`. **NO mover, NO sustituir sin evidencia.**
- **Material fuente local:** `/mnt/d/GitHub/KERNEL` (tarball SDK HCLinux 2.1 GB, patches, hcdrivers) y `/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186` (kernel vanilla). No duplicarlos dentro del repo: se referencian por hash en `docs/source-inventory.md`.
- **Scratch de compilación/investigación:** `~/tf-scratch` (WSL home, no versionado).

## 3. JERARQUÍA DE FUENTES DE VERDAD

1. **Código/fuentes del SDK** — verdad absoluta
2. **Evidencia física** (dumpimage, readelf, dtc, strings, hashes) — `docs/research-log.md`
3. `docs/status.md` — estado operativo
4. Resto de `docs/` — documentación derivada
5. Este archivo

**Regla:** si la documentación contradice el código o la evidencia, gana el código/evidencia. Entonces se corrige la documentación.

## 4. INVARIANTES PERMANENTES

1. **Baseline Linux 4.4.186.** No se salta a 5.12.4 hasta que 4.4.186 arranque en hardware real (FASE 4).
2. **No reemplazar simultáneamente** bootloader + AVP + kernel + rootfs. Estrategia: BootROM stock → hcboot stock → AVP stock → kernel nuestro → rootfs stock (primero).
3. **NO INVENTAR NADA.** Direcciones, GPIO, load addresses, particiones, resoluciones, clock rates, compat strings: solo con evidencia (archivo + comando + output + hash). Lo desconocido se documenta en `docs/known-gaps.md` como desconocido.
4. **Device Tree es el modelo de diferencias entre boards.** Prohibido introducir cadenas `if board == X` en el kernel cuando la información pertenece al DTS.
5. **No flash interno prematuro.** NOR/SPI/eMMC/bootloader/AVP solo con autorización expresa del usuario. Todas las pruebas por SD.
6. **Deploy reversible:** antes de sustituir cualquier archivo de boot en la SD → backup + SHA256 + tamaño + path documentado en `docs/test-runs/`.
7. **Todo artefacto de build tiene manifest** (commit, hashes de config/DTB/kernel, toolchain) en `out/<board>/manifest.json`.
8. **Commit pequeño y lógico.** Nunca un commit gigante. Nunca subir firmware propietario, dumps, toolchains, credenciales ni output de compilación.
9. **Procedencia y licencias:** código Hichip se incorpora identificado como vendor, con hashes de origen. Nada de redistribución dudosa sin detenerse a pedir confirmación.
10. **Método de trabajo autónomo-conservador:** crear/compilar/documentar/commitear/copia reversible a G: = autónomo. Escribir flash interna, reparticionar, borrar backups, publicar material de licencia dudosa = PARAR y preguntar.

## 5. FLUJO DE BUILD DEL BSP HICHIP (verificado contra el SDK 2024.02.y.2)

El proceso real del fabricante (documentado en `docs/hichip-sdk.md`):
1. Linux 4.4.186 vanilla de kernel.org
2. `patches/linux-4.4.186/*.patch` en orden numérico (series de 38 patches + yaffs2)
3. `rsync SOURCE/linux-drivers/` sobre el árbol (incluye `arch/mips/hc16xx/`, `drivers/clk/hc16xx/`, `drivers/clocksource/timer-hc16xx.c`, `drivers/hcdrivers/`, `include/uapi/hcuapi/`)
4. `yaffs2/patch-ker.sh` aplicado desde `patches/linux-4.4.186/yaffs2`
5. Config de board: `board/hichip/hc16xx/common/kernel-configs/4.4.186/kernel-*.config`
6. DTS de board (Define el reparto de memoria Linux/AVP/MMZ; `linux-ext-fixup-load-addr.mk` deriva CONFIG_PHYSICAL_START y el AVP entry del DTS via `update_physical_start.sh`)
7. Compilación vmlinux → gzip → append DTB (`linux-ext-elf-append-dtb.mk`)

**Regla:** reproducir este flujo real antes de abstraerlo en `build.sh <board>`.

## 6. STOP CONDITIONS

Detener y pedir intervención humana cuando:
- un cambio pueda perder trabajo no pusheado;
- se vaya a escribir flash interna / bootloader persistente / dispositivos raw;
- se pretenda eliminar material clasificado como irrepetible;
- la evidencia contradiga la documentación estructural;
- la licencia de algo que se va a publicar sea dudosa.

## 7. HANDOFF

```
REPO= CHANGE_CLASS= FILES_CHANGED= HEAD= CHECKS_RUN= DEVICE_EVIDENCE= BLOCKER= NEXT_EXACT_ACTION= STOP_CONDITION=
```

## 8. DIRECTORIO DE REFERENCIA (fuente de materiales, no versionado)

| Material | Ruta | SHA256 (parcial) |
|----------|------|------------------|
| SDK HCLinux 2024.02.y.2 (tarball, incluye .git con todos los branches 2022.03→2024.02.y.2) | `/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz` | `e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` |
| Patches Hichip 4.4.186 + 5.12.4 + yaffs2 (7z) | `/mnt/d/GitHub/KERNEL/patches.7z` | `fa154f64584768429facc27d0894c97ad59e39b3ac87e2343aa992fbc01d0414` |
| hcdrivers working tree (local) | `/mnt/d/GitHub/KERNEL/hcdrivers/` | — (= `linux-drivers` del SDK tag 2024.02.y.2, verificado por diff) |
| Kernel vanilla 4.4.186 | `/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186/source/linux-4.4.186` | fuente upstream 4.4.186 |
| Manual SDK (PDF) | `/mnt/d/GitHub/KERNEL/hclinux_user_manual.pdf` | `18e505...` ver `docs/source-inventory.md` |

## 9. MANTENIMIENTO DE CONTEXTO

- Actualizar `docs/status.md` tras cada sesión significativa.
- Registrar hallazgos con evidencia en `docs/research-log.md`.
- Cada deploy de prueba = un archivo `docs/test-runs/YYYY-MM-DD_HHMM_<board>.md`.
- Antes de cada fase importante: releer este archivo por si ha cambiado.
