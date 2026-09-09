
define LINUX_PHYSICAL_START_FROM_DTS
	-rm -rf $(LINUX_DIR)/.tmp-for-load-addr
	mkdir -p $(LINUX_DIR)/.tmp-for-load-addr
	$(foreach dts,$(call qstrip,$(BR2_LINUX_KERNEL_CUSTOM_DTS_PATH)),
		cp -f $(dts) $(LINUX_DIR)/.tmp-for-load-addr/
	)
	echo "" >> $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dts
	echo "unsigned int linux_load_addr = (CONFIG_LINUX_MEMORY_OFFSET);" >> $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dts
	echo "unsigned int avp_load_addr = (HCRTOS_SYSMEM_OFFSET + 0x1000);" >> $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dts
	gcc -O2 -I$(LINUX_DIR)/include -E -Wp,-MMD,$(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dtb.d.pre.tmp -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dtb.dts.tmp $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dts
	cat $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dtb.dts.tmp | grep linux_load_addr > $(LINUX_DIR)/.tmp-for-load-addr/main.c
	cat $(LINUX_DIR)/.tmp-for-load-addr/$(strip $(LINUX_DTS_NAME)).dtb.dts.tmp | grep avp_load_addr >> $(LINUX_DIR)/.tmp-for-load-addr/main.c
	echo -e " \
#include <stdio.h>\n \
int main(int argc, char **argv) \
{ \
	if (argc == 1) \
		printf(\"0xffffffff%x\", linux_load_addr | 0x80000000); \
	else if (argc == 2) \
		printf(\"0x%08x\", linux_load_addr); \
	else if (argc == 3) \
		printf(\"0x%08x\", ((avp_load_addr | 0xa0000000) + 0xfff) & 0xfffff000); \
	return 0; \
}" >> $(LINUX_DIR)/.tmp-for-load-addr/main.c
	gcc -o $(LINUX_DIR)/.tmp-for-load-addr/a.out $(LINUX_DIR)/.tmp-for-load-addr/main.c
	$(BR2_EXTERNAL_HCLINUX_PATH)/linux/update_physical_start.sh CONFIG_PHYSICAL_START $(LINUX_DIR)/.tmp-for-load-addr/a.out $(@D)/.config $(@D)/arch/mips/include/asm/mach-hc16xx/spaces.h $(@D)/arch/mips/include/asm/mach-hc16xx/kernel-entry-init.h
endef

LINUX_PRE_BUILD_HOOKS += LINUX_PHYSICAL_START_FROM_DTS
