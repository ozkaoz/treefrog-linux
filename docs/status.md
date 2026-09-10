# Status — treefrog-linux

Actualizado: 2026-09-10 13:25 (test #7 BOOT OK → medio validado; test #8 decisivo desplegado)

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

- **TEST #8 (2026-09-10 13:17): DECISIVO — k2 JOYDEV `fe16c9c4` sobre FAT validada.**
  Test #7 BOOT OK (100% stock + TreeFrogUI v1.0.15 en tarjeta B reformateada) →
  medio validado; baseline runtime stock capturado
  (`docs/test-runs/log-2026-09-10_stock-fatk2.txt`). Deploy de k2 vía deploy-sd.sh
  con backup del stock golden en `backups-treelinux/2026-09-10_1317_r36sx/` de la SD.
  Éxito = MILESTONE del proyecto (kernel nuestro + input funcional). Ver
  `docs/test-runs/2026-09-10_1317_r36sx.md`.

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

1. Usuario prueba test #8 (k2 joydev en FAT validada): menú navegable = MILESTONE.
2. MILESTONE → FASE E bring-up (audio/AVP, poweroff, USB por subsistemas) + runtime
   K0 completo (dmesg, /proc/*) vía zhijack/frogshell; luego FASE F (initramfs propio
   BusyBox → rootfs TreeFrog → FrogUI directo sin rkgame/zhijack).
3. Fallo test #8 → consola serie virtual (zhijack + frogshell realterm,
   `D:\R36S\PORT LPTRACKER\BACKUPS\sd-prfix-20260910`) para ver dónde muere k2.
4. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (backups stock identificados en docs/device-matrix.md).

## Last known bootable commit

- **81ecf9a** + build k1 `875854cb...` (kernel #1 — ÚNICO boot físico confirmado con
  kernel nuestro, test #1 tarjeta A: sistema completo arriba, menú renderizado, input
  muerto sin joydev).
- k2 `fe16c9c4` (joydev): tests #2/#5 = congela en tarjeta B vieja (0 escrituras);
  k1 = congela en tarjeta B vieja (test #6) → medio culpable, kernels exculpados.
- Test #7 en curso: 100% STOCK sobre tarjeta B reformateada (validación del medio).

## Last tested board

- R36SX (boot k1 confirmado test #1/tarjeta A; test #7 en curso: stock/tarjeta B nueva)

## Last test result

- Kernel #1 (81ecf9a): BOOT OK, menú renderizado, input muerto (joydev) → fix aplicado.
- Kernel #2 (JOYDEV, `fe16c9c4...`): deploy en sistema completo, PENDIENTE test físico (#5).
- Test #3/#4 (SD kernel-only, FAT reformateada): `Please insert TF card` — no arrancable.
