# SD deployment (G:) — protocolo

La herramienta es `scripts/deploy-sd.sh <board> [--apply]` (DRY-RUN por defecto).

## Qué hace (en orden)

1. Verifica que `/mnt/g` exista/monte (si no: instrucciones `sudo mount -t drvfs G: /mnt/g`).
2. Verifica filesystem, espacio (>10 MB) y que exista `cubegm/` (sanity: es una SD TreeFrog, no un disco cualquiera). **Rechaza escribir si la estructura no coincide.**
3. Verifica artefactos del build en `out/<board>/` (vmlinux.uImage, dtb.bin, manifest.json).
4. Muestra SHA256 de todo y el archivo actual en la SD (el que será sustituido).
5. `--apply`: backup a `/mnt/g/backups-treelinux/<ts>_<board>/` (con SHA256SUMS) →
   copia SOLO `vmlinux.uImage` y `dtb.bin` a `cubegm/` → `sync` → verificación de
   checksums post-copia → registro en `docs/test-runs/<ts>_<board>.md`.
6. Nunca toca: `avp.uImage`, bootloader, flash interna, particiones, dispositivos raw.

## Rollback

```bash
# desde WSL, con la SD montada:
cp /mnt/g/backups-treelinux/<ts>_<board>/vmlinux.uImage /mnt/g/cubegm/
cp /mnt/g/backups-treelinux/<ts>_<board>/dtb.bin        /mnt/g/cubegm/
sync
```

## Estado actual

- 2026-09-09: `/mnt/g` VACÍO (sin SD montada). Primer deploy pendiente de que el
  usuario inserte la SD de pruebas R36SX y se monte desde WSL.
