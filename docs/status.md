# Status — treefrog-linux

Actualizado: 2026-09-09 19:30 (FASE A/B/C/D-build completadas)

## Working

- Entorno WSL verificado (Ubuntu-24.04, gh auth ozkaoz, git 2.x).
- Repo local `/mnt/d/GitHub/treefrog-linux` + remoto https://github.com/ozkaoz/treefrog-linux (main pusheada).
- AGENTS.md (constitución) + README + .gitignore + docs base.
- Inventario de `/mnt/d/GitHub/KERNEL` completo con hashes (`docs/source-inventory.md`).
- Matriz BSP presentes/faltantes (`docs/bsp-reconstruction.md`): TODAS las piezas críticas localizadas.
- FASE C: pipeline reproducible completo — fetch (kernel.org verificado) → 41 patches + linux-drivers + yaffs2 → vmlinux + manifest. Smoke test a3100 OK.
- **FASE D (R36SX):**
  - Kernel stock analizado (vermagic/toolchain/formato idénticos a nuestro pipeline).
  - DTB stock decompilado → `boards/r36sx/` board profile completo con round-trip BYTE-IDENTICO.
  - `out/r36sx/vmlinux.uImage` propio (2.7 MB, Load 0x80000000, entry 0x803e3200, gcc 6.3.0 Codescape).
  - Matriz de dispositivos TreeFrogUI (`docs/device-matrix.md`).
  - `scripts/deploy-sd.sh` seguro con DRY-RUN/backup/rollback/registro test-runs.

## In progress

- FASE D final: prueba física en consola R36SX (requiere SD G: montada — ahora vacía) y registro de boot log.

## Blocked

- **Prueba física:** /mnt/g está vacío (no hay SD montada ahora). El deploy está listo; falta insertar/montar la SD de pruebas desde WSL y correr `scripts/deploy-sd.sh r36sx --apply`.

## Missing

- `docs/known-gaps.md` actualizado (gaps 1,2,4,5,6,7,9 cerrados para R36SX; pendientes: config exacto stock, validación CRC hcboot, DTB del resto de consolas, licencia blobs .o).

## Next

1. Usuario inserta SD R36SX → montar /mnt/g desde WSL (`sudo mount -t drvfs G: /mnt/g`).
2. `scripts/deploy-sd.sh r36sx` (DRY-RUN) → revisar plan → `--apply`.
3. Probar en consola; capturar síntomas/boot log; completar `docs/test-runs/<ts>_r36sx.md`.
4. Si arranca: FASE E bring-up por subsistemas (storage/framebuffer/input). Si no: comparar config (entry point distinto sugiere config stock más grande) → iterar.
5. FASE F: initramfs propio BusyBox.
6. FASE G: repetir caracterización para R36HD/SF3000/SF3500/GB350 (backups stock identificados).

## Last known bootable commit

- (ninguno aún — primer kernel propio compilado pero no probado en hardware: commit 81ecf9a, out/r36sx/)

## Last tested board

- (ninguno físicamente; R36SX es el primero en cola)

## Last test result

- Build R36SX: OK. DTB byte-identico al stock; uImage format-compatible (gzip, load 0x80000000); pendiente boot físico.
