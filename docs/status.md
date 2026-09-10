# Status — treefrog-linux

Actualizado: 2026-09-09 19:35 (FASE A/B/C/D completadas — deploy físico realizado)

## Working

- Entorno WSL verificado (Ubuntu-24.04, gh auth ozkaoz, git 2.x).
- Repo local `/mnt/d/GitHub/treefrog-linux` + remoto https://github.com/ozkaoz/treefrog-linux (main pusheada).
- AGENTS.md (constitución) + README + .gitignore + docs base.
- Inventario de `/mnt/d/GitHub/KERNEL` completo con hashes (`docs/source-inventory.md`).
- Matriz BSP presentes/faltantes (`docs/bsp-reconstruction.md`): TODAS las piezas críticas localizadas.
- FASE C: pipeline reproducible completo — fetch (kernel.org verificado) → 41 patches + linux-drivers + yaffs2 → vmlinux + manifest. Smoke test a3100 OK.
- FASE D (R36SX):
  - Kernel stock analizado (vermagic/toolchain/formato idénticos a nuestro pipeline).
  - DTB stock decompilado → `boards/r36sx/` board profile completo con round-trip BYTE-IDENTICO.
  - `out/r36sx/vmlinux.uImage` propio (2.7 MB, Load 0x80000000, entry 0x803e3200, gcc 6.3.0 Codescape).
  - Matriz de dispositivos TreeFrogUI (`docs/device-matrix.md`).
  - `scripts/deploy-sd.sh` seguro con DRY-RUN/backup/rollback/registro test-runs.
  - **DEPLOY FÍSICO REALIZADO (2026-09-09 19:34):** kernel nuestro en `G:\cubegm\vmlinux.uImage`
    (sha `875854cb...`), dtb.bin idéntico al stock, backup completo en `G:\backups-treelinux\2026-09-09_1934_r36sx\`,
    checksums verificados post-copia. avp.uImage/bootloader intactos. Registro: `docs/test-runs/2026-09-09_1934_r36sx.md`.

## In progress

- **PRUEBA FÍSICA EN CONSOLA:** insertar la SD en la R36SX y arrancar. El usuario debe
  hacerlo físicamente y reportar el resultado (boot log / síntomas) para completar el test-run.

## Blocked

- (nada técnico; solo falta la acción física del usuario)

## Missing

- `docs/known-gaps.md` (gaps 1,2,4,5,6,7,9 cerrados para R36SX; pendientes: config exacto stock, validación CRC hcboot — se resolverá empíricamente con este primer boot, DTB resto de consolas, licencia blobs .o).

## Next

1. Usuario prueba la SD en la R36SX y reporta resultado (logo negro/congela/arranca menú).
2. Completar `docs/test-runs/2026-09-09_1934_r36sx.md` con boot log/síntomas.
3. Si arranca: FASE E bring-up por subsistemas. Si no: iterar config (ver docs/testing.md diagnóstico).
4. FASE F: initramfs propio BusyBox → rootfs TreeFrog → FrogUI directo.
5. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (backups stock identificados en docs/device-matrix.md).

## Last known bootable commit

- (pendiente de la prueba física; candidato: 81ecf9a con out/r36sx, deployado 2026-09-09 19:34)

## Last tested board

- R36SX (deploy en SD realizado; boot físico pendiente)

## Last test result

- Deploy OK: kernel nuestro en SD, checksums verificados, backup stock disponible para rollback.
  Boot físico: PENDIENTE (requiere acción del usuario).
