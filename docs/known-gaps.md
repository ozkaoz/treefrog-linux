# Known gaps — lo que NO se sabe (al 2026-09-10, post-test #5)

Todo lo listado aquí es DESCONOCIDO hasta que exista evidencia en `docs/research-log.md`.
Prohibido rellenar con suposiciones.

## Por board (consolas reales TreeFrog)

1. ~~DTB stock R36SX~~ — **CERRADO (R18):** extraído, decompilado y board profile byte-identico.
   PENDIENTE: DTB stock del resto de consolas (R36HD, SF3000/HD, SF3100, SF3500, GB350) — backups stock de referencia identificados en docs/device-matrix.md (no descargados aún).
2. ~~Ruta del kernel en la SD R36SX~~ — **CERRADO (R17):** `cubegm/vmlinux.uImage` + `avp.uImage` + `dtb.bin` (manifiesto físico). PENDIENTE: layout exacto del resto de consolas (presumiblemente igual — sin evidencia).
3. **Si hcboot valida CRC/hash** del kernel que carga (el uImage legacy lleva CRC32 header+data en el propio formato; desconocido si hcboot lo verifica o si exige tamaño máximo).
4. ~~vermagic stock R36SX~~ — **CERRADO (R15):** `4.4.186-release`, builder linsen.chen@hichip01, gcc 6.3.0 Codescape 2018.09-02. El `.config` exacto del stock sigue sin extraerse (IKCFG ausente) — el kernel-squashfs.config del SDK es la base documentada; la diferencia de entry point (0x803337c0 stock vs 0x803e3200 nuestro) y tamaño (3.9MB vs 2.7MB) indica config stock más grande. Acción: en FASE E comparar `Module.symvers`/símbolos o pedir config; probar primero el nuestro (formato-compatible).
5. **SoC exacto por consola** — R36SX CERRADO (HC1600A, board label dbE3100v20). Resto pendiente.
6. ~~Matriz TreeFrogUI~~ — **CERRADO (docs/device-matrix.md):** 7 targets + revisiones; R36HD usa kernel/DTB propios (no R36SX).
7. ~~SHA256 tarball vanilla vs kernel.org~~ — **CERRADO (R13):** descarga directa kernel.org, hash idéntico al manifest local.
8. **Licencia explícita del árbol `linux-drivers`** — sin LICENSE propio; blobs .o (hc-p2p, adc) excluidos del repo. Pendiente decisión de redistribución (STOP condition si se quiere publicar).
9. ~~Compatibilidad toolchain stock~~ — **CERRADO (R15/R19):** stock compilado con el mismo GCC 6.3.0 Codescape 2018.09-02 que usamos.
10. **Baseline kernel del resto de consolas** (¿5.12.4 en alguna?) — sin evidencia. Los strings del stock R36SX confirman 4.4.186.
11. **avp_entry del stock**: nuestro fixup derivó `0xabda4000` (sysmem 0xbda2e50 + 0x1000 → page-aligned KSEG1). Cómo calcula el stock real su entry AVP no se ha verificado binariamente (irrelevante para el kernel Linux; el AVP stock se conserva igual).
12. **Comportamiento del init=/linuxrc stock** (ramfs): qué monta/lanza exactamente (rkgame/menu stock → hook FrogUI). Sin dumps del rootfs aún (FASE E/F).
13. **Requisitos de geometría FAT/MBR de hcboot para montar la SD**: los test #3/#4 (SD kernel-only con FAT reformateada por Windows: offset partición 1 MB, clúster 32 KB, partición MBR `IsActive=False`) dieron `Please insert TF card` aunque la FAT estaba sana y los archivos corectos. Hipótesis: hcboot necesita la partición activa y/o geometría FAT distinta (4 KB) y/o el sistema `cubegm/` completo. En test #5 se restaura el sistema completo sobre el FAT actual para aislar si el contenido es co-causa. Definición de la partición "callável" por hcboot sigue SIN evidencia binaria (el driver FAT vive en el hcrtos/hcboot submodule, no extraído del tar).

## Procedimiento para cerrar un gap

1. Investigar (comando + archivo + output).
2. Registrar en `docs/research-log.md` con hash si aplica.
3. Mover el punto de aquí al documento técnico correspondiente.
