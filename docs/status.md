# Status — treefrog-linux

Actualizado: 2026-09-10 14:45 (R30 ROOT CAUSE: initramfs stock ausente en k1/k2; k3 desplegado)

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

- **TEST #9 (2026-09-10 14:37): k3 = initramfs stock embebido + JOYDEV** sobre FAT
  validada. ROOT CAUSE (R30) del logo eterno resuelto binariamente: el kernel stock
  lleva un initramfs de 3.85 MB (380 archivos, init/linuxrc/bind-mounts) que k1/k2
  NO tenían → kernel sin raíz → moría en init → 0 escrituras. El "boot" del test #1
  era un log stale del stock (k1 NUNCA booteó; el único aporte del test #1 fue que
  hcboot acepta nuestro formato uImage). k3 embeds el cpio stock byte-exacto
  (`deb48ce7`) vía nueva variante `ramfs` de build-kernel.sh + fragment ramfs.
  k3 sha `795b9da4...`, entry `0x803e4ee0`. Ver `docs/test-runs/2026-09-10_1437_r36sx.md`.

## Blocked

- (nada; esperando prueba física del test #6 — bisección k1 vs tarjeta B)

## Missing

- `docs/known-gaps.md` (gaps 1,2,4,5,6,7,9 cerrados para R36SX; gap #3 parcialmente respondido:
  hcboot ACEPTA nuestro uImage sin validación que lo rechace — booteó 2 veces).
- Pendiente: config exacto stock (más opciones que joydev pueden diferir — se iterará por
  evidencia), licencia blobs .o.
- **Tarjeta A original del test #1 (SD stock 2026-08-24): paradero por confirmar** — sería
  el medio conocido-bueno para separar kernel de tarjeta si test #6 congela.

## Next

1. Usuario prueba test #9 (k3 en FAT validada): menú navegable = MILESTONE histórico
   (primer kernel propio con boot completo). Reportar y reinsertar SD para forense.
2. MILESTONE → FASE E bring-up + runtime K0 (dmesg, /proc/*) + FASE F (initramfs
   TreeFrog propio → rootfs → FrogUI directo sin rkgame/zhijack).
3. Fallo con escrituras nuevas → userland parcial: diagnóstico por logs.
4. Fallo con 0 escrituras → serie virtual (frogshell realterm/tfusbhost) para ver
   dónde muere k3 pre-userland; comparar entry/alloca vs stock.
5. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (docs/device-matrix.md).

## Last known bootable commit

- **NINGUNO todavía** — ningún kernel nuestro ha booteado físicamente (corregido en
  R30: el test #1 era log stale del stock; solo probó que hcboot acepta el formato).
- k3 `795b9da4` (ramfs+joydev, initramfs stock embebido): test #9 en curso —
  candidato de fidelidad máxima al stock.
- Deploy actual en SD: k3 (test #9). Backups en la SD: k2 (1437) y stock (1317).

## Last tested board

- R36SX (stock bootea OK en tarjeta B reformateada = test #7; k3 en curso, test #9)

## Last test result

- Kernel #1 (81ecf9a): BOOT OK, menú renderizado, input muerto (joydev) → fix aplicado.
- Kernel #2 (JOYDEV, `fe16c9c4...`): deploy en sistema completo, PENDIENTE test físico (#5).
- Test #3/#4 (SD kernel-only, FAT reformateada): `Please insert TF card` — no arrancable.
