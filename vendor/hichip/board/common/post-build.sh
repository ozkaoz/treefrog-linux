#!/bin/bash

. $BR2_CONFIG > /dev/null 2>&1
export BR2_CONFIG

current_dir=$(dirname $0)
PYPATH=/usr/bin:/usr/local/bin:$PATH
FDTINFO=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/getfdt
BINMODIFY=${BR2_EXTERNAL_HCLINUX_PATH}/support/scripts/binmodify.py
GENBOOTMEDIA=${BR2_EXTERNAL_HCLINUX_PATH}/support/scripts/genbootmedia
GENSFBIN=${BR2_EXTERNAL_HCLINUX_PATH}/support/scripts/gensfbin.py
HCPROGINI=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/gen_hcprogini
GENFLASHBIN=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/gen_flashbin
FIXUP_PART_FNAME=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/fixup_part_filename
GET_PART_FNAME=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/get_part_filename
GENPERSISTENTMEM=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/genpersistentmem/genpersistentmem
DDRCONFIGMODIFY=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/ddrconfig_modify
DTB2DTS=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/dtb2dts.py
DTS2DTB=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/dts2dtb.py
MKYAFFS2IMAGE=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/mkyaffs2image
HCFOTAGEN=${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/fdt/HCFota_Generator
DTB=${BINARIES_DIR}/dtb.bin
if [ -f ${HOST_DIR}/bin/hcprecomp2 ] ; then
	HCPRECOMP2=${HOST_DIR}/bin/hcprecomp2
else
	HCPRECOMP2=${TOPDIR}/build/tools/hcprecomp2
fi
if [ -f ${HOST_DIR}/bin/mkimage ] ; then
	MKIMAGE=${HOST_DIR}/bin/mkimage
else
	MKIMAGE=${TOPDIR}/build/tools/mkimage
fi
make -C $(dirname ${GENPERSISTENTMEM})
make -C $(dirname ${HCPROGINI})

mkdir -p ${BINARIES_DIR}/for-{factory,upgrade,upgrade-withboot,debug}

message()
{
	echo -e "\033[47;30m>>> $1\033[0m"
}

hcprogrammer_support_usb0=0
hcprogrammer_support_usb1=0
hcprogrammer_usb_irq_detect_timeout=0
hcprogrammer_usb_sync_detect_timeout=0
if [ "${BR2_EXTERNAL_HCPROGRAMMER_SUPPORT}" = "y" ] ; then
	if [ "${BR2_EXTERNAL_HCPROGRAMMER_SUPPORT_USB0}" = "y" ] ; then
		hcprogrammer_support_usb0=1
	else
		hcprogrammer_support_usb0=0
	fi
	if [ "${BR2_EXTERNAL_HCPROGRAMMER_SUPPORT_USB1}" = "y" ] ; then
		hcprogrammer_support_usb1=1
	else
		hcprogrammer_support_usb1=0
	fi
	if [ "${BR2_EXTERNAL_HCPROGRAMMER_USB_IRQ_DETECT_TIMEOUT}" != "" ]; then
		hcprogrammer_usb_irq_detect_timeout=${BR2_EXTERNAL_HCPROGRAMMER_USB_IRQ_DETECT_TIMEOUT}
	fi
	if [ "${BR2_EXTERNAL_HCPROGRAMMER_USB_SYNC_DETECT_TIMEOUT}" != "" ]; then
		hcprogrammer_usb_sync_detect_timeout=${BR2_EXTERNAL_HCPROGRAMMER_USB_SYNC_DETECT_TIMEOUT}
	fi
fi

gensfburnini()
{
cat << EOF > $1
[Project]
RunMode=0
InitMode=0
RunAddr=$2
FileNum=2
[File0]
File=$3
Type=1
Addr=0xA1000000
[File1]
File=hc16xx_jtag_updater.out
Type=5
Addr=$4
[AutoRun]
AutoRun0=wm 0x800001F0 $(printf 0x%08x $5)
AutoRun1=wm 0x800001F4 0x81000000
AutoRun3=wm 0xb8818504 0x0
EOF
}

if [ -f ${BINARIES_DIR}/vmlinux ] ; then
	vmlinux_ep_noncache=$(readelf -h ${BINARIES_DIR}/vmlinux | grep Entry | awk '{print $NF}' | sed 's/0x8/0xa/')
	vmlinux_ep=$(readelf -h ${BINARIES_DIR}/vmlinux | grep Entry | awk '{print $NF}')
	vmlinux_load_noncache=$(nm -n ${BINARIES_DIR}/vmlinux | awk '/T _text/ {print "0x"$1}' | sed 's/0x8/0xa/')
	vmlinux_load=$(nm -n ${BINARIES_DIR}/vmlinux | awk '/T _text/ {print "0x"$1}')
fi

if [ -f ${BINARIES_DIR}/avp.out ] ; then
	avp_ep_noncache=$(readelf -h ${BINARIES_DIR}/avp.out | grep Entry | awk '{print $NF}' | sed 's/0x8/0xa/')
	avp_ep=$(readelf -h ${BINARIES_DIR}/avp.out | grep Entry | awk '{print $NF}')
	avp_load_noncache=$(nm -n ${BINARIES_DIR}/avp.out | awk '/T _start/ {print "0x"$1}' | sed 's/0x8/0xa/')
	avp_load=$(nm -n ${BINARIES_DIR}/avp.out | awk '/T _start/ {print "0x"$1}')
fi

# Generate download.ini for GDB download debug
if [ -f ${BINARIES_DIR}/vmlinux ] && [ -f ${BINARIES_DIR}/avp.out ] ; then
	message "Generating download.ini ..."
	cat << EOF > ${BINARIES_DIR}/download.ini
[Project]
RunMode=0
InitMode=0
RunAddr=${vmlinux_ep_noncache}
FileNum=3
[File0]
File=vmlinux
Type=5
Addr=${vmlinux_load_noncache}
[File1]
File=avp.out
Type=6
Addr=${avp_load_noncache}
[File2]
File=dtb.bin
Type=1
Addr=0xa5ff0000
[AutoRun]
AutoRun0=wm 0xb8800004 0x85ff0000
EOF
	message "Generating download.ini done!"
fi

if [ -f ${BINARIES_DIR}/vmlinux ]; then
	message "Generating download-vmlinux.ini ..."
	cat << EOF > ${BINARIES_DIR}/download-vmlinux.ini
[Project]
RunMode=0
InitMode=0
RunAddr=${vmlinux_ep_noncache}
FileNum=2
[File0]
File=vmlinux
Type=5
Addr=${vmlinux_load_noncache}
[File1]
File=dtb.bin
Type=1
Addr=0xa5ff0000
[AutoRun]
AutoRun0=wm 0xb8800004 0x85ff0000
EOF
	message "Generating download-vmlinux.ini done!"
fi

if [ -f ${BINARIES_DIR}/avp.out ] ; then
	message "Generating download-avp.ini ..."
	cat << EOF > ${BINARIES_DIR}/download-avp.ini
[Project]
RunMode=0
InitMode=0
RunAddr=${avp_ep_noncache}
FileNum=2
[File0]
File=avp.out
Type=5
Addr=${avp_load_noncache}
[File1]
File=dtb.bin
Type=1
Addr=0xa5ff0000
[AutoRun]
AutoRun0=wm 0xb8800004 0x85ff0000
EOF
	message "Generating download-avp.ini done!"
fi

BOOT=""
BOOTBIN=""
if [ "$BR2_TARGET_UBOOT" = "y" ] && [ -f ${BINARIES_DIR}/u-boot ] && [ -f ${BINARIES_DIR}/u-boot.bin ] && [ -f "${BR2_EXTERNAL_BOARD_DDRINIT_FILE}" ] ; then
	BOOT=u-boot
	BOOTBIN=u-boot.bin
elif [ "$BR2_TARGET_HCBOOT" = "y" ] && [ -f ${BINARIES_DIR}/hcboot.out ] && [ -f ${BINARIES_DIR}/hcboot.bin ] && [ -f "${BR2_EXTERNAL_BOARD_DDRINIT_FILE}" ] ; then
	BOOT=hcboot.out
	BOOTBIN=hcboot.bin
fi

if [ $BOOT != "" ]; then
	message "Generating bootloader.bin ..."
	fddrinit=$(basename ${BR2_EXTERNAL_BOARD_DDRINIT_FILE})
	boot_sz=$(wc -c ${BINARIES_DIR}/$BOOTBIN | awk '{print $1}')
	boot_ep=$(readelf -h ${BINARIES_DIR}/$BOOT | grep Entry | awk '{print $NF}')
	if [ "${BR2_EXTERNAL_BOOT_TYPE_SPINAND}" = "y" ]; then
		${DDRCONFIGMODIFY} --input ${BR2_EXTERNAL_BOARD_DDRINIT_FILE} --output ${BINARIES_DIR}/${fddrinit} \
		--size ${boot_sz} \
		--entry ${boot_ep} \
		--from 0xafc03000 \
		--to ${boot_ep} \
		--nand \
		--pagesize ${BR2_EXTERNAL_BOOT_SPINAND_PAGESIZE} \
		--erasesize ${BR2_EXTERNAL_BOOT_SPINAND_ERASESIZE} \
		--dtb ${DTB} \
		--portA ${hcprogrammer_support_usb0} \
		--portB ${hcprogrammer_support_usb1} \
		--irq ${hcprogrammer_usb_irq_detect_timeout} \
		--sync ${hcprogrammer_usb_sync_detect_timeout}
	else
		${DDRCONFIGMODIFY} --input ${BR2_EXTERNAL_BOARD_DDRINIT_FILE} --output ${BINARIES_DIR}/${fddrinit} \
		--size ${boot_sz} \
		--entry ${boot_ep} \
		--from 0xafc03000 \
		--to ${boot_ep} \
		--dtb ${DTB} \
		--portA ${hcprogrammer_support_usb0} \
		--portB ${hcprogrammer_support_usb1} \
		--irq ${hcprogrammer_usb_irq_detect_timeout} \
		--sync ${hcprogrammer_usb_sync_detect_timeout}
	fi

	cat ${BINARIES_DIR}/${fddrinit} ${BINARIES_DIR}/$BOOTBIN > ${BINARIES_DIR}/bootloader.bin
	message "Generating bootloader.bin done!"
fi

if [ -f ${BINARIES_DIR}/vmlinux.bin ] ; then
	message "Generating vmlinux.uImage ..."
	if [ "${BR2_EXTERNAL_FW_COMPRESS_GZIP}" = "y" ]; then
		gzip -kf9 ${BINARIES_DIR}/vmlinux.bin > ${BINARIES_DIR}/vmlinux.bin.gz
		${MKIMAGE} -A mips -O linux -T kernel -C gzip -n vmlinux -e ${vmlinux_ep} -a ${vmlinux_load} -d ${BINARIES_DIR}/vmlinux.bin.gz ${BINARIES_DIR}/vmlinux.uImage
	elif [ "${BR2_EXTERNAL_FW_COMPRESS_LZMA}" = "y" ]; then
		lzma -zkf -c ${BINARIES_DIR}/vmlinux.bin > ${BINARIES_DIR}/vmlinux.bin.lzma
		${MKIMAGE} -A mips -O linux -T kernel -C lzma -n vmlinux -e ${vmlinux_ep} -a ${vmlinux_load} -d ${BINARIES_DIR}/vmlinux.bin.lzma ${BINARIES_DIR}/vmlinux.uImage
	elif [ "${BR2_EXTERNAL_FW_COMPRESS_LZO1X}" = "y" ]; then
		${HCPRECOMP2} ${BINARIES_DIR}/vmlinux.bin ${BINARIES_DIR}/vmlinux.bin.lzo
		${MKIMAGE} -A mips -O linux -T kernel -C lzo -n vmlinux -e ${vmlinux_ep} -a ${vmlinux_load} -d ${BINARIES_DIR}/vmlinux.bin.lzo ${BINARIES_DIR}/vmlinux.uImage
	fi
	message "Generating vmlinux.uImage done"
fi

if [ -f ${BINARIES_DIR}/avp.bin ] ; then
	message "Generating avp.uImage ..."
	if [ "${BR2_EXTERNAL_FW_COMPRESS_GZIP}" = "y" ]; then
		gzip -kf9 ${BINARIES_DIR}/avp.bin > ${BINARIES_DIR}/avp.bin.gz
		${MKIMAGE} -A mips -O u-boot -T standalone -C gzip -n avp -e ${avp_ep} -a ${avp_load} -d ${BINARIES_DIR}/avp.bin.gz ${BINARIES_DIR}/avp.uImage
	elif [ "${BR2_EXTERNAL_FW_COMPRESS_LZMA}" = "y" ]; then
		lzma -zkf -c ${BINARIES_DIR}/avp.bin > ${BINARIES_DIR}/avp.bin.lzma
		${MKIMAGE} -A mips -O u-boot -T standalone -C lzma -n avp -e ${avp_ep} -a ${avp_load} -d ${BINARIES_DIR}/avp.bin.lzma ${BINARIES_DIR}/avp.uImage
	elif [ "${BR2_EXTERNAL_FW_COMPRESS_LZO1X}" = "y" ]; then
		${HCPRECOMP2} ${BINARIES_DIR}/avp.bin ${BINARIES_DIR}/avp.bin.lzo
		${MKIMAGE} -A mips -O u-boot -T standalone -C lzo -n avp -e ${avp_ep} -a ${avp_load} -d ${BINARIES_DIR}/avp.bin.lzo ${BINARIES_DIR}/avp.uImage
	fi

	message "Generating avp.uImage done!"
fi

if [ -f "${BR2_EXTERNAL_BOOTMEDIA_FILE}" ] ; then
	message "Generating logo.hc ....."
	mkdir -p ${BINARIES_DIR}/romfs-root
	${GENBOOTMEDIA} -i ${BR2_EXTERNAL_BOOTMEDIA_FILE} -o ${BINARIES_DIR}/romfs-root/logo.hc
	message "Generating logo.hc done!"
fi

if [ -d ${BINARIES_DIR}/romfs-root -a "`ls -A ${BINARIES_DIR}/romfs-root`" != "" ] ; then
	message "Generating romfs.img ....."
	genromfs -f ${BINARIES_DIR}/romfs.img -d ${BINARIES_DIR}/romfs-root/ -v "romfs"
	message "Generating romfs.img done!"
fi

firmware_version=$(date +%y%m%d%H%M)

message "Generating persistentmem.bin ....."
tvtype=$(${FDTINFO} ${DTB} /hcrtos/de-engine u32 tvtype)
volume=$(${FDTINFO} ${DTB} /hcrtos/i2so u32 volume)
persistentmem_fs=$(${FDTINFO} ${DTB} /hcrtos/persistentmem string fs-type)
if [ "${persistentmem_fs}" == "yaffs2" ] || [ "${persistentmem_fs}" == "littlefs" ] ; then
	mkdir -p ${BINARIES_DIR}/yaffs2-root
	${GENPERSISTENTMEM} -v ${firmware_version} -p ${BR2_EXTERNAL_PRODUCT_NAME} -V ${volume} -t ${tvtype} -f -o ${BINARIES_DIR}/yaffs2-root/persistentmem-0.bin
else
	${GENPERSISTENTMEM} -v ${firmware_version} -p ${BR2_EXTERNAL_PRODUCT_NAME} -V ${volume} -t ${tvtype} -o ${BINARIES_DIR}/persistentmem.bin
fi
if [ "${persistentmem_fs}" == "yaffs2" ] ; then
	yaffs2img=$(${GET_PART_FNAME} -i ${DTB} -l "yaffs2")
	${MKYAFFS2IMAGE} ${BINARIES_DIR}/yaffs2-root ${BINARIES_DIR}/${yaffs2img} ${BR2_EXTERNAL_BOOT_SPINAND_PAGESIZE} ${BR2_EXTERNAL_BOOT_SPINAND_ERASESIZE}
elif [ "${persistentmem_fs}" == "littlefs" ] ; then
	echo "TO BE SUPPORTED TO GENERATE LITTLEFS"
fi
message "Generating persistentmem.bin done"

message "Generating hcprog.ini ....!"
${HCPROGINI} --output ${BINARIES_DIR}/hcprog.ini \
	--dtb ${DTB} \
	--chip H16XX \
	--product ${BR2_EXTERNAL_PRODUCT_NAME} \
	--draminit $(basename ${BR2_EXTERNAL_BOARD_DDRINIT_FILE}) \
	--version ${firmware_version} \
	--updater "hc16xx_jtag_updater.bin"
message "Generating hcprog.ini done"

message "Generating flash binary ....."
${GENFLASHBIN} --wkdir ${BINARIES_DIR} --dtb ${DTB} --outdir ${BINARIES_DIR}/for-factory
[ $? != 0 ] && exit 1;
message "Generating flash binary done!"

if [ -f ${BINARIES_DIR}/hcprog.ini ];then
	message "Generating ${BR2_EXTERNAL_HCFOTA_FILENAME} .....!"
	rm -vf ${BINARIES_DIR}/for-{upgrade,upgrade-withboot,debug}/$(basename ${BR2_EXTERNAL_HCFOTA_FILENAME} .bin)*
	cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.bin ${BINARIES_DIR}/
	${HCFOTAGEN} --dtb ${DTB} --ini ${BINARIES_DIR}/hcprog.ini -o ${BINARIES_DIR}/for-upgrade/${BR2_EXTERNAL_HCFOTA_FILENAME} -u \
		-r "${BR2_EXTERNAL_BOARD_DDRINIT_FILE}" -p "${BINARIES_DIR}/hc16xx_jtag_updater.bin"
	${HCFOTAGEN} --dtb ${DTB} --ini ${BINARIES_DIR}/hcprog.ini -o ${BINARIES_DIR}/for-upgrade-withboot/${BR2_EXTERNAL_HCFOTA_FILENAME} \
		-r "${BR2_EXTERNAL_BOARD_DDRINIT_FILE}" -p "${BINARIES_DIR}/hc16xx_jtag_updater.bin" --versioncheck 1
	${HCFOTAGEN} --dtb ${DTB} --ini ${BINARIES_DIR}/hcprog.ini -o ${BINARIES_DIR}/for-debug/${BR2_EXTERNAL_HCFOTA_FILENAME} \
		-r "${BR2_EXTERNAL_BOARD_DDRINIT_FILE}" -p "${BINARIES_DIR}/hc16xx_jtag_updater.bin"
	message "Generating ${BR2_EXTERNAL_HCFOTA_FILENAME} done!"

	message "Generating sfburn.ini ....."
	updater_ep_noncache=$(readelf -h ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.out | grep Entry | awk '{print $NF}' | sed 's/0x8/0xa/')
	updater_load_noncache=$(nm -n ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.out | awk '/T _start/ {print "0x"$1}' | sed 's/0x8/0xa/')

	md5=$(md5sum ${BINARIES_DIR}/for-upgrade/${BR2_EXTERNAL_HCFOTA_FILENAME} | awk '{print $1}' | cut -c1-5)
	fota_size=$(wc -c ${BINARIES_DIR}/for-upgrade/${BR2_EXTERNAL_HCFOTA_FILENAME} | awk '{print $1}' | xargs -i printf "0x%08x" {})
	cp -f ${BINARIES_DIR}/for-upgrade/${BR2_EXTERNAL_HCFOTA_FILENAME} ${BINARIES_DIR}/for-upgrade/${BR2_EXTERNAL_HCFOTA_FILENAME}.${md5}
	gensfburnini ${BINARIES_DIR}/for-upgrade/sfburn.ini ${updater_ep_noncache} ${BR2_EXTERNAL_HCFOTA_FILENAME}.${md5} ${updater_load_noncache} ${fota_size}

	md5=$(md5sum ${BINARIES_DIR}/for-upgrade-withboot/${BR2_EXTERNAL_HCFOTA_FILENAME} | awk '{print $1}' | cut -c1-5)
	fota_size=$(wc -c ${BINARIES_DIR}/for-upgrade-withboot/${BR2_EXTERNAL_HCFOTA_FILENAME} | awk '{print $1}' | xargs -i printf "0x%08x" {})
	cp -f ${BINARIES_DIR}/for-upgrade-withboot/${BR2_EXTERNAL_HCFOTA_FILENAME} ${BINARIES_DIR}/for-upgrade-withboot/${BR2_EXTERNAL_HCFOTA_FILENAME}.${md5}
	gensfburnini ${BINARIES_DIR}/for-upgrade-withboot/sfburn.ini ${updater_ep_noncache} ${BR2_EXTERNAL_HCFOTA_FILENAME}.${md5} ${updater_load_noncache} ${fota_size}

	md5=$(md5sum ${BINARIES_DIR}/for-debug/${BR2_EXTERNAL_HCFOTA_FILENAME} | awk '{print $1}' | cut -c1-5)
	fota_size=$(wc -c ${BINARIES_DIR}/for-debug/${BR2_EXTERNAL_HCFOTA_FILENAME} | awk '{print $1}' | xargs -i printf "0x%08x" {})
	cp -f ${BINARIES_DIR}/for-debug/${BR2_EXTERNAL_HCFOTA_FILENAME} ${BINARIES_DIR}/for-debug/${BR2_EXTERNAL_HCFOTA_FILENAME}.${md5}
	gensfburnini ${BINARIES_DIR}/for-debug/sfburn.ini ${updater_ep_noncache} ${BR2_EXTERNAL_HCFOTA_FILENAME}.${md5} ${updater_load_noncache} ${fota_size}

	message "Generating sfburn.ini done!"
fi

cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.out ${BINARIES_DIR}/for-upgrade
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.out ${BINARIES_DIR}/for-upgrade-withboot
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.out ${BINARIES_DIR}/for-debug
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/hc16xx_jtag_updater.bin ${BINARIES_DIR}/
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/HCProgrammer.exe ${BINARIES_DIR}/for-upgrade
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/HCProgrammer.exe ${BINARIES_DIR}/for-upgrade-withboot
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/HCProgrammer.exe ${BINARIES_DIR}/for-debug
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/HCProgram_bridge.exe ${BINARIES_DIR}/
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/HCFota_Generator.exe ${BINARIES_DIR}/
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/HCFota_Generator.pdb ${BINARIES_DIR}/
cp -vf ${BR2_EXTERNAL_HCLINUX_PATH}/support/tools/updater.bin ${BINARIES_DIR}/

GEN_UPG_DIR=$(dirname $0)
chmod +x ${GEN_UPG_DIR}/gen_upgrade_pkt.sh
source ${GEN_UPG_DIR}/gen_upgrade_pkt.sh ${BINARIES_DIR} ${BR2_CONFIG} ${BR2_EXTERNAL_PRODUCT_NAME} ${firmware_version}
