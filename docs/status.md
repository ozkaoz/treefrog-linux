# Status — treefrog-linux

Actualizado: 2026-09-09 (FASE A/B/C-smoke completadas)

## Working

- Entorno WSL verificado (Ubuntu-24.04, gh auth ozkaoz, git 2.x).
- Repo local `/mnt/d/GitHub/treefrog-linux` + remoto https://github.com/ozkaoz/treefrog-linux (origin configurado).
- AGENTS.md (constitución) + README + .gitignore + docs base.
- Inventario de `/mnt/d/GitHub/KERNEL` completo con hashes (`docs/source-inventory.md`).
- Matriz BSP presentes/faltantes (`docs/bsp-reconstruction.md`): TODAS las piezas críticas localizadas.
- **FASE C smoke test SUPERADO:** pipeline completo reproducible:
  - `scripts/fetch-kernel.sh` — Linux 4.4.186 vanilla (kernel.org descargado, sha256 verificado `0b1273d...`)
  - `scripts/apply-patches.sh` — 41/41 patches Hichip aplicados limpios + linux-drivers rsync + yaffs2 in-tree
  - `scripts/build-kernel.sh hc16xx-db-a3100-v10 squashfs` — **vmlinux.bin + dtb.bin + manifest.json**
  - vmlinux: ELF32 LSB MIPS32r2, entry 0x803e3200, `Linux version 4.4.186-release (gcc 6.3.0 Codescape 2018.09-02)`
  - out/hc16xx-db-a3100-v10/: vmlinux.bin (5.8 MB), vmlinux.gz (35 MB), dtb.bin (27849 B, FDT d00dfeed OK), manifest con sha256 + commit

## In progress

- FASE D: board real (R36SX): extraer kernel/DTB stock de backups SD, comparar contra nuestro build.

## Blocked

- (nada)

## Missing

- Ver `docs/known-gaps.md` (DTB stock por consola, rutas boot en SD, vermagic stock, licencia blobs .o).

## Next

1. Push del trabajo de FASE A/B/C a origin.
2. FASE D-1: inspeccionar SD de backups existentes (`/mnt/d/R36SX`, `/mnt/d/R36S/PORT LPTRACKER/BACKUPS/`) para localizar kernel/DTB stock R36SX.
3. FASE D-2: comparar ELF/vermagic/config del stock vs nuestro build.
4. FASE D-3: board profile `boards/r36sx/` con DTS propio (a partir del stock, nunca editando stock.dts).
5. FASE D-4: `scripts/deploy-sd.sh` seguro (verificación de /mnt/g, backup, solo archivos esperados, sync, checksums, log en docs/test-runs/).

## Last known bootable commit

- (ninguno aún — ningún kernel probado en hardware real)

## Last tested board

- (ninguno — solo smoke test de compilación con devboard de referencia)

## Last test result

- Smoke build OK: out/hc16xx-db-a3100-v10/manifest.json (commit ff9ee22, kernel 4.4.186+Hichip, GCC 6.3.0)
