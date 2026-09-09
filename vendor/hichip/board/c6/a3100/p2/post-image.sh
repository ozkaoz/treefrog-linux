#!/bin/bash

. $BR2_CONFIG > /dev/null 2>&1
export BR2_CONFIG

current_dir=$(dirname $0)

message()
{
	echo -e "\033[47;30m>>> $1\033[0m"
}

message "Restore target ....."
echo "rm -rf ${TARGET_DIR}"
rm -rf ${TARGET_DIR}
echo "mv ${TARGET_DIR}.backup ${TARGET_DIR}"
mv ${TARGET_DIR}.backup ${TARGET_DIR}
message "Restore target done!"
