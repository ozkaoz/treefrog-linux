# Status — treefrog-linux

Actualizado: 2026-09-10 02:35 (FASE A/B/C/D completadas; test #5 en curso)

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

- **TEST #5 (2026-09-10 02:30):** sistema TreeFrogUI completo + nuestro kernel #2 JOYDEV.
  Restaurado el estado 21:39 (que booteó en test #1) + `out/r36sx/vmlinux.uImage`
  `fe16c9c4...` (joydev). Ver `docs/test-runs/2026-09-10_0230_r36sx.md`.
  Conclusión de test #3/#4: una SD con SOLO kernel+AVP+DTB (kernel-only) no arranca —
  hcboot requiere el sistema `cubegm/` completo. El mensaje `Please insert TF card`
  aparece al no poder montar la FAT (geometría/causa aún por confirmar en test #5).

## Blocked

- (nada; esperando prueba física del test #5)

## Missing

- `docs/known-gaps.md` (gaps 1,2,4,5,6,7,9 cerrados para R36SX; gap #3 parcialmente respondido:
  hcboot ACEPTA nuestro uImage sin validación que lo rechace — booteó 2 veces).
- Pendiente: config exacto stock (más opciones que joydev pueden diferir — se iterará por
  evidencia), licencia blobs .o.

## Next

1. Usuario prueba la SD en la R36SX y reporta resultado (logo negro/congela/arranca menú).
2. Completar `docs/test-runs/2026-09-09_1934_r36sx.md` con boot log/síntomas.
3. Si arranca: FASE E bring-up por subsistemas. Si no: iterar config (ver docs/testing.md diagnóstico).
4. FASE F: initramfs propio BusyBox → rootfs TreeFrog → FrogUI directo.
5. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (backups stock identificados en docs/device-matrix.md).

## Last known bootable commit

- **ac04c73** + build `fe16c9c4...` (kernel #2 JOYDEV, deploy test #5, PENDIENTE confirmación).
- Boot anterior confirmado físicamente: 81ecf9a (kernel #1 — sistema completo arriba,
  menú renderizado, input muerto por falta de joydev; test-run 1934).

## Last tested board

- R36SX (boot confirmado con nuestro kernel en test #1; test #5 en curso)

## Last test result

- Kernel #1 (81ecf9a): BOOT OK, menú renderizado, input muerto (joydev) → fix aplicado.
- Kernel #2 (JOYDEV, `fe16c9c4...`): deploy en sistema completo, PENDIENTE test físico (#5).
- Test #3/#4 (SD kernel-only, FAT reformateada): `Please insert TF card` — no arrancable.
