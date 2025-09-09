#!/bin/sh

# collectd - collectd-mod-ip-neigh.sh
# Copyright (C) 2025  Patrick Grimm
# need root perm :-(

. /lib/functions.sh
. /lib/functions/network.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(cat /proc/sys/kernel/hostname)}"
COLLECTD_INTERVAL="$(echo $COLLECTD_INTERVAL | cut -d '.' -f 1)"
INTERVAL="${COLLECTD_INTERVAL:-60}"

function read_dhcpleases() {
	local plugin=dhcpleases
	local type=count
	local iface_list="$1"
	local ret_sum
	local ident="$HOSTNAME/$plugin/$type"
	for iface in $iface_list ; do                                           
        network_get_physdev iface_l2 "$iface"
		ret=$(ip neigh show dev "$iface_l2" | grep REACHABLE | cut -d ' ' -f 3 | sort | uniq | wc -w)
		ret_sum=$((ret_sum+ret))
	done
	echo "PUTVAL \"$ident\" interval=$INTERVAL N:$ret_sum"
}

function read_neigh() {
  local plugin=dhcpleases
  #local plugin=neigh
  local plugin_instance="$1"
  local type="count"
  local type_instance="$2"
  local iface="$3"
  
  local ident="$HOSTNAME/$plugin-$plugin_instance/$type"
  
  local ret

  case $type_instance in
    combined)
      ident="$ident-${type_instance}"
      ret=$(ip neigh show dev "$iface" | grep REACHABLE | cut -d ' ' -f 3 | sort | uniq | wc -w)
      ;;
    ipv4)
      ident="$ident-${type_instance}"
      ret=$(ip -4 neigh show dev "$iface" | grep REACHABLE | cut -d ' ' -f 3 | sort | uniq | wc -w)
      ;;
    ipv6)
      ident="$ident-${type_instance}"
      ret=$(ip -6 neigh show dev "$iface" | grep REACHABLE | cut -d ' ' -f 3 | sort | uniq | wc -w)
      ;;
  esac
  echo "PUTVAL \"$ident\" interval=$INTERVAL N:$ret"

}


get_dhcp_iface() {
	log "iface_list()"
	local cfg=$1
	config_get ignore $cfg ignore
	[ "$ignore" == "1" ] && return
	config_get dhcpv4 $cfg dhcpv4
	config_get dhcpv6 $cfg dhcpv6
	config_get ra $cfg ra
	[ "$dhcpv4" == "disabled" ] && [ "$dhcpv6" == "disabled" ] && [ "$ra" == "disabled" ] && return
	config_get interface $cfg interface
	iface_list="$interface $iface_list"
}


iface_list=""
config_load dhcp
config_foreach get_dhcp_iface dhcp

while true
do
	read_dhcpleases "$iface_list"

	for iface in $iface_list ; do
		network_get_physdev iface_l2 "$iface"
		read_neigh "$iface" "combined" "$iface_l2"
		read_neigh "$iface" "ipv4" "$iface_l2"
		read_neigh "$iface" "ipv6" "$iface_l2"
	done

	sleep "$INTERVAL"
done

exit 0
