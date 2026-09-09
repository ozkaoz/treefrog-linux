define LINUX_PATCH_HICHIP_DRIVERS
	rsync -au --chmod=u=rwX,go=rX $(RSYNC_VCS_EXCLUSIONS) $(call qstrip,$(BR2_EXTERNAL_HCLINUX_PATH)/SOURCE/linux-drivers)/ $(LINUX_DIR)
	mkdir -p $(LINUX_DIR)/arch/mips/boot/dts/include
	mkdir -p $(LINUX_DIR)/scripts/dtc/include-prefixes
	ln -sf ../../../../../include/uapi $(LINUX_DIR)/arch/mips/boot/dts/include/uapi
	ln -sf ../../../include/uapi $(LINUX_DIR)/scripts/dtc/include-prefixes/uapi
	cd $(BR2_EXTERNAL_HCLINUX_PATH)/patches/linux/yaffs2 && $(BR2_EXTERNAL_HCLINUX_PATH)/patches/linux/yaffs2/patch-ker.sh c m $(LINUX_DIR)
endef

ifneq ($(BR2_LINUX_KERNEL_OVERRIDE_SOURCE),y)
LINUX_PRE_PATCH_HOOKS += LINUX_PATCH_HICHIP_DRIVERS
LINUX_PRE_BUILD_HOOKS += LINUX_PATCH_HICHIP_DRIVERS
endif

LINUX_INSTALL_STAGING = YES
define LINUX_INSTALL_STAGING_HCUAPI
	install -d -m 0775 $(STAGING_DIR)/usr/include/hcuapi
	cp -rf $(@D)/include/uapi/hcuapi/* $(STAGING_DIR)/usr/include/hcuapi/
endef
LINUX_POST_INSTALL_STAGING_HOOKS += LINUX_INSTALL_STAGING_HCUAPI
