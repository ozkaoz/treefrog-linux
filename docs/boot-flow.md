# Boot flow HC16xx (verificado contra SDK 2024.02.y.2)

```
BootROM (stock, no tocable)
  -> hcboot (bootloader Hichip; configs en board/hichip/hc16xx/common/hcboot-configs/)
     -> carga AVP (HCRTOS firmware, entry en HCRTOS_SYSMEM_OFFSET + 0x1000, KSEG1)
     -> carga kernel Linux (vmlinux.bin gzip con .appended_dtb embebido)
     -> arranca core main (MIPS32r2) en CONFIG_PHYSICAL_START
  Linux:
    - MIPS no usa bootloader protocol: DTB embebido en el ELF (.appended_dtb)
    - cmdline desde DTB (CONFIG_MIPS_CMDLINE_FROM_DTB=y)
    - earlycon=uart8250,mmio,0x18818300 (UART0), console=ttyS0,115200
    - root=/dev/mtdblock5 squashfs init=/linuxrc (typo devboard)
  AVP (core RTOS): vídeo/audio/display/HDMI; Linux le habla via AMPRPC
    (drivers amprpc/avp-proxy/kshm/kumsgq/virtuart + userspace SOURCE/applications)
```

## Reglas del proyecto sobre este flow

1. **No reemplazamos** BootROM/hcboot/AVP en la fase 1.
2. Nuestro kernel debe ser **byte-compatible en formato** con el stock:
   ELF32 LE MIPS32r2 → vmlinux gzip → DTB appended → vmlinux.bin.
3. La primera prueba física se hace sustituyendo SOLO el archivo de kernel en la SD
   (path exacto según board — documentar en `docs/boards/<board>.md` tras inspección
   del firmware stock) y conservando backup + rollback.
4. Punto desconocido por ahora (ver `docs/known-gaps.md`): si hcboot de las consolas
   TreeFrog valida hashes/firmas de los blobs que carga, y los nombres de archivo /
   rutas de boot exactas en la SD de cada consola.
