/*
 * R36SX memory map defines (evidence-based)
 *
 * Source: stock dtb.bin (boards/r36sx/stock/r36sx-stock.dtb,
 * SHA256 1258f1eba809e43540c581b815c815c87815540a9e5897a4e8584363ab7de5cc27bb)
 * Extracted with dtc -I dtb -O dts (see docs/boards/r36sx.md):
 *
 *   /memory reg              = <0x0 0xaf91e50>       (Linux low mem)
 *   /soc/fb0 buffer-phy-static = <0xaf91e50 0xe11000> (framebuffer static)
 *   /hcrtos/memory-mapping/sysmem reg = <0xbda2e50 0xb53600> (HCRTOS sysmem)
 *   /hcrtos/memory-mapping/mmz0 reg   = <0xcda2e50 0x325d1b0>
 *   /hcrtos/memory-mapping/mmz1 reg   = <0xc8f6450 0x4aca00> (kshm)
 *   /hcrtos/board label = "hc1600a@dbE3100v20"
 *
 * Total RAM 0x10000000 (256 MB).
 * These follow the vendor define scheme used by linux-ext-fixup-load-addr.mk.
 */
#define CONFIG_MEMORY_SIZE 0x10000000

#define CONFIG_FRAMEBUFFER_STATIC_MEM_SIZE 0xe11000
#define CONFIG_LINUX_MEMORY_OFFSET 0x0
#define CONFIG_LINUX_MEMORY_SIZE 0xaf91e50
#define CONFIG_FRAMEBUFFER_STATIC_PHYS 0xaf91e50

#define HCRTOS_SYSMEM_OFFSET 0xbda2e50
#define HCRTOS_SYSMEM_SIZE 0xb53600
#define HCRTOS_MMZ0_OFFSET 0xcda2e50
#define HCRTOS_MMZ0_SIZE 0x325d1b0
#define HCRTOS_MMZ1_OFFSET 0xc8f6450
#define HCRTOS_MMZ1_SIZE 0x4aca00
