# Status — treefrog-linux

Actualizado: 2026-09-10 13:15 (test #6: medio culpable; test #7 stock sobre FAT nueva)

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

- **TEST #7 (2026-09-10 13:10): STOCK + TreeFrogUI v1.0.15 sobre tarjeta B reformateada.**
  Test #6 cerró la bisección: k1 (boot probado en test #1) TAMBIÉN congela en la
  tarjeta B → kernels k1/k2 exculpados; culpable = el MEDIO. El usuario reformateó la
  tarjeta B e instaló TreeFrogUI v1.0.15 limpio — la instalación trajo la triada
  STOCK completa (verificada por hashes: kernel `53b3e0b3`, avp `a9788995`,
  dtb `1258f1eb`). Este estado ES el test #7: 100% stock sobre la FAT nueva.
  Boot OK → tarjeta validada → test #8 = k2 (joydev) decisivo.
  Fallo → tarjeta B incompatible → recuperar tarjeta A o tercera tarjeta.
  Ver `docs/test-runs/2026-09-10_1310_r36sx-stockfat.md`.

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

1. Usuario prueba test #7 (STOCK sobre FAT nueva): menú navegable = tarjeta validada.
2. Boot OK → **test #8 decisivo**: deploy k2 `fe16c9c4` (joydev) sobre esta FAT con
   deploy-sd.sh → si boota = MILESTONE (boot completo + input propio).
3. Fallo test #7 → tarjeta B incompatible a nivel hardware → recuperar tarjeta A
   original del test #1 (SD stock 2026-08-24, paradero por confirmar) o tercera tarjeta.
4. Con boot estable de k2: FASE E bring-up + runtime K0 (dmesg, /proc/*) + FASE F
   (initramfs propio → rootfs TreeFrog → FrogUI directo).
5. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (backups stock identificados en docs/device-matrix.md).

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
