# Status — treefrog-linux

Actualizado: 2026-09-10 15:35 (test #10 PASS: batería OK; k4 = golden propio; FASE F iniciada)

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

- **FASE F (iniciada): initramfs TreeFrog propio.** k4 es el golden de referencia
  (boot+input+batería OK, 118k+ frames, poweroff limpio). Siguiente paso: BusyBox
  MIPS mínimo propio montando la SD y lanzando el userland TreeFrogUI sin el
  initramfs stock extraído (independencia del firmware) → después rootfs propio.
  Experimento previo de referencia: `boards/r36sx/config/r36sx-kernelonly.fragment.config`
  + `rootfs/tfinit` (test #3, SD kernel-only — falló por falta de cubegm/, NO del
  initramfs: hcboot exige sistema completo en SD; con cubegm/ presente funcionará).

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

- **b70b98b** + build k4 `2dda38ab...` (test #10, PASS TOTAL): kernel de referencia
  propio — boot completo, input funcional, batería OK, poweroff limpio, 118k+ frames.
- Historia: k3 `795b9da4` (abc0595, test #9 MILESTONE, primer boot propio, bug batería).
- Backups en SD: k4 deployado (1502 backup = k3), k2 (1437), stock golden (1317).

## Last tested board

- R36SX (k4 CONFIRMADO: boot + navegación + batería OK, test #10)

## Last test result

- **PASS TOTAL test #10:** sin aviso de batería; 33 min de sesión estable;
  poweroff voluntario limpio. FASE D/E de facto completadas.

## Last test result

- Kernel #1 (81ecf9a): BOOT OK, menú renderizado, input muerto (joydev) → fix aplicado.
- Kernel #2 (JOYDEV, `fe16c9c4...`): deploy en sistema completo, PENDIENTE test físico (#5).
- Test #3/#4 (SD kernel-only, FAT reformateada): `Please insert TF card` — no arrancable.
