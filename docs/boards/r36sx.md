# Board: R36SX (FunKey/SF-style handheld, HC1600A)

Fecha de caracterización: 2026-09-09. Toda la evidencia proviene de los archivos
stock físicos preservados en `lgpt-r36sx-port/physical-evidence/PHYSICAL_GOLDEN_20260824/`
(copiados del estado real de la SD de la consola, 2026-08-24) y del golden kernel
`stock-kernel-golden/vmlinux.uImage.stock`.

## Identidad

| Campo | Valor | Evidencia |
|---|---|---|
| Nombre comercial | R36SX (clones: R36HD usa otro kernel/DTB) | treefrog-ui-r36sx/install.md |
| SoC | Hichip HC1600A | DTS stock: board label `"hc1600a@dbE3100v20"`, compatible `"Hichip,1600"` |
| Devboard de origen del vendor | dbE3100v20 | DTS stock `/hcrtos/board/label` |
| Kernel stock | Linux 4.4.186-release, `#7 PREEMPT Thu Dec 18 16:55:03 CST 2025`, builder `linsen.chen@hichip01` | strings del vmlinux.uImage.stock |
| Toolchain del stock | gcc 6.3.0 (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux) | ídem — **idéntico al nuestro** |
| Formato de kernel | u-boot legacy uImage, gzip; Load 0x80000000, Entry 0x803337c0 | `dumpimage -l` |
| DTB stock | 33137 B, SHA256 `1258f1eb...c27bb` | `boards/r36sx/stock/r36sx-stock.dtb` |

## Archivos de boot en la SD (G:) — evidencia PHYSICAL_GOLDEN_MANIFEST.txt

| Archivo | Tamaño | SHA256 |
|---|---|---|
| `cubegm/vmlinux.uImage` | 3905970 | `53b3e0b3d57fcdbef40d448ae2d3a00159bc84f2fd5be4c10a826827c7f2e01e` |
| `cubegm/avp.uImage` | 1381604 | `a9788995db80197db6d743b8b237eadbfd3c424fcf1ab448fcd99c003b0950b2` |
| `cubegm/dtb.bin` | 33137 | `1258f1eba809e43540c581b815c87815540a9e5897a4e8584363ab7de5cc27bb` |

## Mapa de memoria (del DTB stock — verificado con dtc)

```
RAM total: 0x10000000 (256 MB)

Linux (memory node):      0x00000000 – 0x0af91e50  (~176 MB)
Framebuffer estático:    0x0af91e50 – 0x0bda2e50  (0xe11000 = 14.07 MB, fb0 buffer-phy-static)
  -> fb0: 720x1280 (xres_virtual 720, yres_virtual 5120), scale -> 1920x1080, 32bpp
  -> fb1: 640x480 OSD, buffer-source "system"
HCRTOS sysmem (AVP):     0x0bda2e50 – 0x0c8d6450  (0xb53600)
  (nota del stock: 0xbda2e50 = sysmem; 0xc8f6450 aparece como mmz1 base)
HCRTOS mmz0:             0x0cda2e50 – 0x10000000 (0x325d1b0)
HCRTOS mmz1 (kshm):      0x0c8f6450 + 0x4aca00
bootmem AVP:             0x09da0000 + 0x2000000
```

Defines para el build (`boards/r36sx/dts/r36sx-memmap.h`): CONFIG_MEMORY_SIZE=0x10000000,
CONFIG_LINUX_MEMORY_OFFSET=0x0, CONFIG_LINUX_MEMORY_SIZE=0xaf91e50,
CONFIG_FRAMEBUFFER_STATIC_PHYS=0xaf91e50, HCRTOS_SYSMEM_OFFSET=0xbda2e50, etc.

## Bootargs del stock

```
root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc console=tty1 earlycon= no_console_suspend noirqdebug
```
stdout-path `serial0:115200n8` (virtuart hacia el AVP; la consola real es tty1/framebuffer).
El kernel y rootfs (ramfs) los carga hcboot desde `cubegm/` de la SD.

## Flash SPI interna (particiones del DTS stock)

| Partición | reg | Contenido |
|---|---|---|
| nor | 0x0 + 0x80000 (512 KB) | contenedor |
| boot | 0x0 + 0x6c000 | bootloader.bin (hcboot) |
| eromfs | 0x6c000 + 0x4000 | romfs.img |
| persistentmem | 0x70000 + 0x10000 | persistentmem.bin |

(NOTA: el layout de arranque real de la consola usa la SD `cubegm/` para kernel+AVP+DTB;
la flash interna aloja bootloader/romfs/persistentmem. NO tocar flash interna — AGENTS.md.)

## Input (del DTS stock)

- key_adc3 activo: `hichip, hc16xx-key-adc`, adc_ref_voltage 0x762 (1.9V?),
  key-map = <200,500|103,601|850,602|1096,105|1100,608|1300,352|1301,1500|1670,141|1671,1790|174>
  (valores ADC → keycodes del gamepad)
- Resto de key_adc0..2,4..5 y check_adc0..: `status = "disabled"`.

## Rotación / pantalla

- fb0 720x1280 (vertical nativo del panel) escalado a 1920x1080 HDMI-scale.
- LCD-width 0x280 (640) en ramas de TVO/LCD del hcrtos (segunda salida).

## Verificación de fidelidad (round-trip)

`boards/r36sx/dts/r36sx.dts` (nuestra copia limpia, con includes vendor-style) compila a un
DTB **byte-identico** al stock (33137 B, `cmp` = idéntico):
```
gcc -E (memmap.h + stock dts) -> dtc -> r36sx.dtb == stock dtb  ✓ BYTE-IDENTICO
```

## Pendiente / desconocido para esta board

- .config exacto del stock (IKCFG no embebido — no extraíble del binario; usamos el
  kernel-squashfs.config del SDK como base, que produce el mismo vermagic/compilador).
- Revisión hardware específica de esta unidad (v26 vs otras) — por caracterizar en FASE G.
- Si hcboot valida CRC/hash de vmlinux.uImage (el uImage lleva CRCs propios en el header).
