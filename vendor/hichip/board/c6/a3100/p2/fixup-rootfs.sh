#!/bin/bash

. $BR2_CONFIG > /dev/null 2>&1
export BR2_CONFIG

current_dir=$(dirname $0)

message()
{
	echo -e "\033[47;30m>>> $1\033[0m"
}

message "Fixup rootfs ....."
mv ${TARGET_DIR} ${TARGET_DIR}.backup
mkdir -p ${TARGET_DIR}
cp -rvf ${current_dir}/rootfs_initramfs/* ${TARGET_DIR}/

message "Fixup rootfs done!"
