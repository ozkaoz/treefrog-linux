#!/bin/bash

DTB=${BINARIES_DIR}/dtb.bin

if [ -d ${DATA_DIR} ] ; then
    echo "Generating data.img ....."
    echo "1" > ${DATA_DIR}/.tmp

    PARTINFO_ENV=/usr/bin:/usr/local/bin:$PATH
    PARTINFO=${BR2_EXTERNAL_HCLINUX_PATH}/support/scripts/partinfo.py
    SIZE=$(PATH=$PARTINFO_ENV ${PARTINFO} --dtb ${DTB} --partname data --get-size true)

    echo "data partition size is ${SIZE}"
    mkfs.jffs2 -r ${DATA_DIR} -o ${BINARIES_DIR}/data.img -e 0x4000 -pad ${SIZE} -n
    echo "Generating data.img done"
fi
