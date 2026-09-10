# Testing (FASE E — protocolo de pruebas en hardware)

## Principios

1. Toda prueba física usa la SD de pruebas (G:) — JAMÁS flash interna (AGENTS.md §4.5).
2. Cada deploy genera `docs/test-runs/YYYY-MM-DD_HHMM_<board>.md` (lo hace deploy-sd.sh).
3. Boot log y síntomas se registran DESPUÉS de cada prueba física, no de memoria.
4. Un solo cambio variable por prueba (kernel; DTB; después rootfs).

## Secuencia de bring-up (milestone 1 → FASE E)

| # | Prueba | Criterio de éxito | Registro |
|---|---|---|---|
| 1 | Kernel nuestro + rootfs stock (SD restaurada stock + solo sustituir `cubegm/vmlinux.uImage`) | Consola llega al shell/login/menú stock (rootfs ramfs carga) | test-runs/… |
| 2 | idem + `dtb.bin` nuestro (byte-identico al stock = riesgo nulo) | idem | test-runs/… |
| 3 | Consola serie/virtuart: capturar boot log completo | log > shell prompt | test-runs/… |
| 4 | Subsistemas: storage SD, framebuffer, input, USB, audio | cada uno verificado | docs/… |

## Diagnóstico si no arranca

- ¿Pantalla queda en logo? → hcboot no cargó el kernel: revisar CRC del uImage (header CRC + data CRC los recalcula mkimage; hcboot puede verificarlos), tamaño máximo que acepta hcboot, nombre exacto del archivo.
- ¿Pantalla negra tras logo? → kernel cargó pero murió temprano: revisar entry (stock 0x803337c0 vs nuestro 0x803e3200 — ambos son kernel_entry válidos dentro del ELF; el entry del uImage debe apuntar al kernel_entry del payload), y sobre todo el `.config` (el nuestro es más pequeño que el stock).
- ¿Congelación a mitad de boot? → drivers: comparar config con el stock (dmesg si hay serial).
- Rollback SIEMPRE disponible: `backups-treelinux/<ts>_<board>/` en la propia SD.

## Serial console

R36SX: `console=tty1` (framebuffer) en bootargs stock; `stdout-path serial0:115200n8`
apunta a `/hcrtos/virtuart` (UART virtual hacia AVP) — sin evidencia aún de pads
UART físicos expuestos. FASE E: investigar virtuart/getevent para logs.
