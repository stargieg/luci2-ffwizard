#!/bin/sh

# collectd - collectd-mod-ip-neigh.sh
# Copyright (C) 2025  Patrick Grimm

HOSTNAME="${COLLECTD_HOSTNAME:-$(cat /proc/sys/kernel/hostname)}"
COLLECTD_INTERVAL="$(echo $COLLECTD_INTERVAL | cut -d '.' -f 1)"
INTERVAL="${COLLECTD_INTERVAL:-60}"

iface_list="$@"

function read_dhcpleases() {
	local plugin=dhcpleases
	#local plugin=neigh
	local type=count
	local iface_list="$1"
	local ret_sum
	local ident="$HOSTNAME/$plugin/$type"
	for iface in $iface_list ; do
		iface_l2="$iface"
		ret=$(ip neigh show dev "$iface_l2" | grep REACHABLE | cut -d ' ' -f 3 | sort | uniq | wc -w)
		ret_sum=$((ret_sum+ret))
	done
	echo "PUTVAL \"$ident\" interval=$INTERVAL N:$ret_sum"
}


while sleep "$INTERVAL"
do
	read_dhcpleases "$iface_list"
done

exit 0
