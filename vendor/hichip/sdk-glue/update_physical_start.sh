#!/bin/bash
addr=$($2)
phy_offset=$($2 1)
avp_entry=$($2 1 2)
sed -i -e "/\\<$1\\>/d" $3
echo "$1=${addr}" >> $3

old=$(cat $4 | grep "_AC($phy_offset,UL)")

if [ "$old" == "" ]; then
	awk "\$2~/PHYS_OFFSET/{\$3=\"_AC($phy_offset,UL)\"}1" $4 > $4.tmp && mv $4.tmp $4
fi

old=$(cat $5 | grep "AVP_ENTRY_ADDR" | grep "$avp_entry")
if [ "$old" == "" ]; then
	awk "\$2~/AVP_ENTRY_ADDR/{\$3=\"$avp_entry\"}1" $5 > $5.tmp && mv $5.tmp $5
fi
