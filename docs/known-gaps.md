# Known gaps — lo que NO se sabe (al 2026-09-09)

Todo lo listado aquí es DESCONOCIDO hasta que exista evidencia en `docs/research-log.md`.
Prohibido rellenar con suposiciones.

## Por board (consolas reales TreeFrog)

1. **DTB stock de cada consola** (R36SX y revisiones, R36HD, SF3000, SF3000 HD, SF3100, SF3500, GB350): todavía no extraídos del firmware stock. Necesario para: memoria exacta (total/Linux/AVP/MMZ), pinmux, panel, ADC keys, particiones.
2. **Nombre/ruta del archivo de kernel que carga hcboot** en la SD de cada consola (¿`kernel` en FAT? ¿partición?). Evidencia pendiente de inspección de la SD real (G:) y de las SD de backup existentes (`/mnt/d/R36SX`, `/mnt/d/R36S/PORT LPTRACKER/BACKUPS/`).
3. **Si hcboot valida integridad/firma** del kernel que carga.
4. **vermagic/`uname -r` del kernel stock** de cada consola y su `.config` exacto (extraer del firmware).
5. **SoC exacto por consola** (HC1600A u otro; los DTS del SDK son devboards a3100/d3100/etc. — la correspondencia real console↔devboard aún no está establecida).
6. Revisión de hardware y diferencias de pantalla/controles entre consolas (matriz TreeFrogUI pendiente — FASE B avanzada).

## Técnico

7. **SHA256 oficial del tarball `linux-4.4.186.tar.xz` de kernel.org** — el local tiene `0b1273d35c...` (manifest de Toolchains); verificar contra kernel.org en FASE C antes de confiar.
8. **Licencia explícita del árbol `linux-drivers`** vendor: archivos individuales tienen headers GPL/copyright Hichip, pero no se encontró LICENSE propio del repo. Los .o binarios (hc-p2p, get_adc_default_val*) son blobs precompilados — decidir si se importan (probablemente NO redistribuibles; mantener fuera del repo público si hay duda).
9. **Compatibilidad exacta Codescape 6.3.0 ↔ kernel stock de consolas TreeFrog** — pendiente comparar vermagic/ABI del stock contra nuestro build (FASE D, §24 del plan).
10. ¿Consolas con kernel 5.12.4? (SF3500/GB350 podrían usar otro baseline que R36SX — sin evidencia aún.)

## Procedimiento para cerrar un gap

1. Investigar (comando + archivo + output).
2. Registrar en `docs/research-log.md` con hash si aplica.
3. Mover el punto de aquí al documento técnico correspondiente.
