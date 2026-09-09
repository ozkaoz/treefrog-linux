#!/bin/bash

. $BR2_CONFIG > /dev/null 2>&1
export BR2_CONFIG

current_dir=$(dirname $0)
mkdir -p ${BINARIES_DIR}/romfs-root/
cp -vf ${current_dir}/popup.bmp.gz ${BINARIES_DIR}/romfs-root/
