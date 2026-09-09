# Status — treefrog-linux

Actualizado: 2026-09-09 (FASE A/B completada)

## Working

- Entorno WSL verificado (Ubuntu-24.04, gh auth ozkaoz, git 2.x).
- Repo local `/mnt/d/GitHub/treefrog-linux` + remoto https://github.com/ozkaoz/treefrog-linux (origin configurado).
- AGENTS.md (constitución) + README + .gitignore + docs base.
- Inventario de `/mnt/d/GitHub/KERNEL` completo con hashes (`docs/source-inventory.md`).
- Matriz BSP presentes/faltantes (`docs/bsp-reconstruction.md`): TODAS las piezas críticas localizadas.

## In progress

- FASE C: reconstrucción del BSP 4.4.186 (importación vendor + pipeline patches + build).

## Blocked

- (nada bloqueado de momento)

## Missing

- Ver `docs/known-gaps.md` (DTB stock por consola, rutas boot en SD, vermagic stock, sha kernel.org, licencia blobs .o).

## Next

1. Commit bootstrap + push a origin.
2. FASE C-1: importar `patches/linux-4.4.186` (38 patches, sin yaffs2 aún) al repo con hashes.
3. FASE C-2: importar `vendor/hichip/linux-drivers` (197 archivos + hcuapi 62) — excluyendo blobs .o dudosos (decisión de licencia pendiente).
4. FASE C-3: `scripts/fetch-kernel.sh` (tarball local + verificación sha contra kernel.org).
5. FASE C-4: `scripts/apply-patches.sh` + integración linux-drivers (replicando `linux-ext-patch-hichip-driver.mk`) + yaffs2 patch-ker.
6. FASE C-5: build vmlinux con `kernel-squashfs.config` de referencia (a3100 como smoke test de compilación) con manifest.
7. FASE D: elegir board real (R36SX), extraer DTB/kernel stock de backups SD existentes, board profile.

## Last known bootable commit

- (ninguno aún — el proyecto no ha producido kernel)

## Last tested board

- (ninguno)

## Last test result

- (ninguno)
