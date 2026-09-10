# Status — treefrog-linux

Actualizado: 2026-09-10 15:05 (MILESTONE test #9; k4 fix batería desplegado, test #10)

## Working

- Entorno WSL verificado (Ubuntu-24.04, gh auth ozkaoz, git 2.x).
- Repo local `/mnt/d/GitHub/treefrog-linux` + remoto https://github.com/ozkaoz/treefrog-linux (main pusheada).
- AGENTS.md (constitución) + README + .gitignore + docs base.
- Inventario de `/mnt/d/GitHub/KERNEL` completo con hashes (`docs/source-inventory.md`).
- Matriz BSP presentes/faltantes (`docs/bsp-reconstruction.md`): TODAS las piezas críticas localizadas.
- FASE C: pipeline reproducible completo — fetch (kernel.org verificado) → 41 patches + linux-drivers + yaffs2 → vmlinux + manifest. Smoke test a3100 OK.
- FASE D (R36SX): kernel stock analizado, DTB stock byte-identico, board profile,
  deploy-sd.sh seguro, matriz dispositivos TreeFrogUI.
- **FASE D COMPLETA — MILESTONE (test #9, 2026-09-10): PRIMER BOOT FÍSICO CON
  KERNEL NUESTRO (k3 `795b9da4`, commit abc0595): TreeFrogUI bootea y NAVEGA con
  botones. 24001+ frames de menú en log. Esquema: initramfs stock embebido (R30)
  + joydev.**
- Extractor reproducible del initramfs stock: `scripts/extract-stock-initramfs.sh`
  (cpio 380 archivos sha deb48ce7).
- Variante `ramfs` en build-kernel.sh (esquema real de la consola).

## In progress

- **TEST #10 (2026-09-10 15:02): k4 = k3 + CONFIG_CHECK_ADC (fix batería)** sobre
  FAT validada. Root cause batería (R31): sin driver hc16xx-check-adc no existen
  /dev/check_adc1/5 → driver.so stock lee 0% → "batería agotándose" + poweroff.
  k4 sha `2dda38ab...`, entry `0x803e5780`, verificado con strings check_adc.
  Esperado: menú navegable SIN aviso de batería. Ver
  `docs/test-runs/2026-09-10_1502_r36sx.md`.

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

1. Usuario prueba test #10 (k4): esperado menú navegable SIN aviso de batería.
2. OK → FASE E formal: poweroff/reboot limpios, audio/AVP, USB, dmesg runtime
   via zhijack; FASE F (initramfs TreeFrog propio → rootfs → FrogUI directo).
3. Persiste aviso → calibración ADC: capturar dmesg + lecturas check_adc y comparar.
4. FASE G: caracterizar R36HD/SF3000/SF3500/GB350 (docs/device-matrix.md).

## Last known bootable commit

- **abc0595** + build k3 `795b9da4...` (test #9, 2026-09-10): **PRIMER BOOT FÍSICO
  CONFIRMADO con kernel nuestro** — TreeFrogUI bootea, navega con botones, 24001+
  frames, sesión estable ~7 min (cortada por bug batería, no por el kernel).
- Deploy actual en SD: k4 `2dda38ab...` (k3+CHECK_ADC, test #10 PENDIENTE).
- Backups en SD: k3 (1502), k2 (1437), stock golden (1317).

## Last tested board

- R36SX (boot k3 CONFIRMADO test #9; k4 en curso, test #10)

## Last test result

- **MILESTONE test #9:** boot completo + input OK; fallo residual batería (R31).

## Last test result

- Kernel #1 (81ecf9a): BOOT OK, menú renderizado, input muerto (joydev) → fix aplicado.
- Kernel #2 (JOYDEV, `fe16c9c4...`): deploy en sistema completo, PENDIENTE test físico (#5).
- Test #3/#4 (SD kernel-only, FAT reformateada): `Please insert TF card` — no arrancable.
