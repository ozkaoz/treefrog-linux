# Matriz de dispositivos TreeFrogUI (FASE D)

Fecha: 2026-09-09. Fuente: TreeFrogUI upstream (README + install.md) y
evidencia física local (R36SX).

## Dispositivos soportados por TreeFrogUI

| Consola | Revisiones | install_first | Panel (nativo) | Notas kernel/DTB |
|---|---|---|---|---|
| **R36SX** | v2.6, v2.7 (bootloader protected) | `r36sx` | 640×480 | Nuestro board profile `boards/r36sx` (derivado del DTB stock físico). v2.7 protegido: no flashear menú stock |
| **R36HD** | (clon R36SX) | `r36sx` (mismo hook) | 640×480 | Corre kernel/DTB DISTINTOS al R36SX — requiere caracterización propia en FASE G |
| **SF3000** | (V3 anunciada) | `sf3000` | 854×480 | Pendiente de caracterizar (backups stock de Q-ta-s) |
| **SF3000 HD** | variante HDMI-out | `sf3000hd` | 854×480 | Comparte display+driver con SF3500; se reporta como SF3500 |
| **SF3100** | — | `sf3100` | 854×480 (clase SF3500) | Mismo panel+driver que SF3500; se reporta como SF3500 |
| **SF3500** | v1.0 + v1.1 (hw revisions distintas) | `sf3500` | 854×480 | Dos revisiones de hardware → posible divergencia DTB |
| **GB350** | — | `gb350` | 640×480 | Pendiente de caracterizar |

## Observaciones estructurales (de install.md)

1. **Todos los dispositivos** arrancan desde SD con el mismo layout (`cubegm/` con
   `rkgame`, kernel, device tree, AVP image y scripts de arranque) — la cita literal:
   "Its `rkgame`, kernel, device tree, AVP image and startup scripts match" (contexto clones).
2. El mecanismo TreeFrogUI actual es un **hook sobre el firmware stock**: instala
   `install_first/<device>/` que redirige el arranque del menú stock hacia FrogUI.
   NO sustituye kernel/AVP — exactamente lo que treefrog-linux quiere reemplazar a largo plazo.
3. **R36HD y clones**: "run a different kernel/DTB" — evidencia de que cada familia
   necesita su board profile propio (nuestro modelo boards/<x>/dts es el correcto).
4. Backups stock de referencia (no redistribuir aquí; documentados para FASE G):
   R36SX v2.6/v2.7 (Google Drive), R36HD (H.OS_stock_backup release), SF3000/SF3000HD/
   SF3100/SF3500/GB350 (releases de Q-ta-s).

## Estado de board profiles en treefrog-linux

| Board | Estado | Evidencia |
|---|---|---|
| `boards/r36sx` | ✅ completo (DTS byte-identico al stock, memmap verificado) | PHYSICAL_GOLDEN_20260824 + stock-kernel-golden |
| `boards/r36hd` | pendiente (kernel/DTB propios, no R36SX) | — |
| `boards/sf3000` | pendiente | — |
| `boards/sf3000hd` | pendiente | — |
| `boards/sf3100` | pendiente | — |
| `boards/sf3500` | pendiente (ojo: 2 revisions hw) | — |
| `boards/gb350` | pendiente | — |

## Diferencias conocidas entre dispositivos (hasta FASE G profundice)

- Panel: 640×480 (R36SX/R36HD/GB350) vs 854×480 (familia SF3000/SF3500)
- HDMI-out: SF3000 HD (variante con salida)
- Kernel/DTB: al menos R36SX vs clones divergen; SF-family presumiblemente otro mapa
  (SIN EVIDENCIA todavía — no asumir; caracterizar en FASE G con los backups stock).
- Bootloader protection: R36SX v2.7 (menú stock protegido; bootloader NO tocar).
