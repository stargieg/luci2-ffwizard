#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

update_hna6() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	config_get interface $cfg interface
	if [ "$interface" == "wan6" ] ; then
		config_get cfg_address $cfg netaddr
		if [ "$cfg_address" != "$address" ] ; then
			#uci_set olsrd6 "$cfg" prefix "$mask"
			uci_set olsrd6 "$cfg" netaddr "$address"
			uci_commit olsrd6
			local reload=1
		fi
		wan6_prefix=1
	fi
}

list_hosts() {
	val=$1
	cfg=$2
	address=$3
	hostname="$(cat /proc/sys/kernel/hostname)"
	case $val in
		*pre1.$hostname)
			/sbin/uci add_list olsrd6.$cfg.hosts="$address""1 pre1.$hostname"
		;;
		*)
			/sbin/uci add_list olsrd6.$cfg.hosts="$val"
		;;
	esac
}

update_hosts() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	config_get library $cfg library
	case $library in
			olsrd_nameservice*)
				config_get hosts $cfg hosts
				uci_remove olsrd6 $cfg hosts
				config_list_foreach $cfg hosts list_hosts $cfg $address $mask
			;;
	esac
}


local address=0
local mask=0
local wan6_prefix=0
local reload=0

#get wan6 ip status
wan6_data=`ubus call network.interface.wan6 status`

json_load "$wan6_data"
json_get_keys wan6_res
json_select "ipv6_prefix"
json_select "1"
json_get_var address address
json_get_var mask mask
echo "$address/$mask"

if [ $address != 0 -a $mask != 0 ] ; then
	config_load olsrd6
	config_foreach update_hna6 Hna6 $address $mask
	logger -t "olsrd_dyn_hna6" "olsrd6 wan6 prefix $address/$mask"
	if [ $wan6_prefix == 0 ] ; then
		#add Hna6 for Host Interfaces
		uci_add olsrd6 Hna6 ; hna_sec="$CONFIG_SECTION"
		uci_set olsrd6 "$hna_sec" prefix "62"
		uci_set olsrd6 "$hna_sec" netaddr "$address"
		uci_set olsrd6 "$hna_sec" interface "wan6"
		#add Hna6 for auto configuration
		uci_add olsrd6 Hna6 ; hna_sec="$CONFIG_SECTION"
		uci_set olsrd6 "$hna_sec" prefix "$mask"
		uci_set olsrd6 "$hna_sec" netaddr "$address"
		uci_set olsrd6 "$hna_sec" interface "wan6"
		#add Hna6 as default gateway
		uci_add olsrd6 Hna6 ; hna_sec="$CONFIG_SECTION"
		uci_set olsrd6 "$hna_sec" prefix "0"
		uci_set olsrd6 "$hna_sec" netaddr "::"
		config_foreach update_hosts LoadPlugin "$address"
		uci_commit olsrd6
		
		local reload=1
	fi
	
	if [ $reload != 0 ] ; then
		ubus call uci "reload_config"
	fi
fi
