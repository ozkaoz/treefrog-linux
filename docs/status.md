# Status — treefrog-linux

Actualizado: 2026-09-10 13:00 (test #5 falló sin escrituras; test #6 bisección en curso)

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

- **TEST #6 (2026-09-10 13:00): BISECCIÓN k1 sobre tarjeta B.** Test #5 (k2 JOYDEV
  sobre sistema completo en tarjeta B) = logo quieto con CERO escrituras en SD (logs
  byte-idénticos al backup → userland nunca corrió). k1/k2 difieren SOLO en joydev
  (verificado con diff de configs efectivos; k2 gunzip OK; dumpimage OK).
  Deployado k1 `875854cb` (único kernel nuestro con boot físico demostrado, test #1)
  sobre la tarjeta B actual: si boota → culpable k2/joydev-build; si congela →
  culpable la tarjeta B (geometría FAT 32K/inactiva/60GB). Ver
  `docs/test-runs/2026-09-10_1300_r36sx-k1bisect.md`.

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

1. Usuario prueba test #6 en la R36SX (k1 en tarjeta B) y reporta: menú tras ~30-60 s
   (input muerto = esperado) o logo quieto.
2. Boot OK → culpable = k2/joydev-build → siguiente: serial console real (bootargs
   `console=tty1` — sin UART log) para ver dónde muere k2, o rebuild k2 bisecando el delta.
3. Congela → culpable = tarjeta B → recuperar tarjeta A original o reformatear B
   (clúster 4K + partición activa, con backup previo).
4. Completar test-run #6 con evidencia; FASE E bring-up por subsistemas tras boot estable.
5. FASE F: initramfs propio BusyBox → rootfs TreeFrog → FrogUI directo.
6. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (backups stock identificados en docs/device-matrix.md).

## Last known bootable commit

- **81ecf9a** + build k1 `875854cb...` (kernel #1 — ÚNICO boot físico confirmado,
  sistema completo arriba, menú renderizado, input muerto sin joydev; test #1, tarjeta A).
- Deploy actual en SD (tarjeta B): k1 `875854cb` (test #6 bisección, PENDIENTE).
- k2 `fe16c9c4` (joydev): test #2 y #5 = congela, 0 escrituras (NO bootable hasta ahora).

## Last tested board

- R36SX (boot confirmado con k1 en test #1/tarjeta A; test #6 en curso en tarjeta B)

## Last test result

- Kernel #1 (81ecf9a): BOOT OK, menú renderizado, input muerto (joydev) → fix aplicado.
- Kernel #2 (JOYDEV, `fe16c9c4...`): deploy en sistema completo, PENDIENTE test físico (#5).
- Test #3/#4 (SD kernel-only, FAT reformateada): `Please insert TF card` — no arrancable.
