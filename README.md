# treefrog-linux

Linux kernel/BSP para consolas basadas en Hichip HC16xx que ejecutan TreeFrogUI
(R36SX, R36HD, SF3000, SF3000 HD, SF3100, SF3500, GB350...).

**Objetivo:** que TreeFrogUI arranque directamente sobre nuestro propio Linux,
sin depender del hijack del firmware original — conservando inicialmente
BootROM/hcboot/AVP stock y sustituyendo progresivamente kernel + DTB + rootfs.

## Estado

Ver `docs/status.md`. Proyecto en FASE A/B (bootstrap + inventario).

## Arquitectura del ecosistema (HC16xx, dual-core)

```
BootROM stock -> hcboot stock -> [core main: Linux | core AVP: HCRTOS] (AMPRPC)
```

- Baseline kernel: **Linux 4.4.186** + patches Hichip + linux-drivers (hcdrivers + arch/mips/hc16xx + hcuapi)
- Toolchain: Codescape GNU 2018.09-02, GCC 6.3.0, `mips-mti-linux-gnu` (MIPS32r2, little-endian)
- Diferencias por board modeladas en Device Tree (memoria Linux/AVP/MMZ, panel, pinmux, particiones)

## Estructura

```
AGENTS.md          reglas del proyecto (obligatorio leer)
docs/              documentación técnica e inventario de fuentes
patches/           patches Hichip por versión de kernel
vendor/hichip/     material vendor importado (linux-drivers, DTS, configs)
boards/            perfiles de placa (DTS por consola)
configs/           configuraciones base de kernel
scripts/           fetch / apply-patches / build / deploy-sd
out/               artefactos de build con manifest.json (ignorado)
```

## Reproducir el build (cuando esté listo en FASE C/D)

```
scripts/fetch-kernel.sh          # obtiene Linux 4.4.186 vanilla
scripts/apply-patches.sh         # aplica patches Hichip + linux-drivers
scripts/build-kernel.sh <board>  # compila kernel + DTB + manifest
scripts/deploy-sd.sh <board>     # deploy reversible a la SD G:
```

## Reglas

- Todo el desarrollo desde WSL. Ver `AGENTS.md`.
- No se flashea hardware interno sin autorización. Pruebas solo por SD.
- Nada se inventa: todo hallazgo con evidencia en `docs/research-log.md`.
