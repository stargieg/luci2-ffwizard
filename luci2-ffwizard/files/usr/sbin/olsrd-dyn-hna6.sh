#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -s -t olsrd-dyn-hna6 $@
}

update_hna6() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	config_get interface $cfg interface
	if [ "$interface" == "wan6" ] ; then
		config_get cfg_address $cfg netaddr
		if [ "$cfg_address" != "$address" ] ; then
			log "uci_set $uci_olsrd $cfg netaddr $address"
			#uci_set $uci_olsrd "$cfg" prefix "$mask"
			uci_set $uci_olsrd "$cfg" netaddr "$address"
			uci_commit $uci_olsrd
			reload=1
		fi
		wan6_prefix=1
	fi
}

update_rule6() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	config_get interface $cfg interface
	if [ "$interface" == "wan6" ] ; then
		config_get cfg_address $cfg src
		if [ "$cfg_address" != "$address/$mask" ] ; then
			log "uci_set network $cfg src $address/$mask"
			uci_set network "$cfg" src "$address/$mask"
			uci_commit $uci_olsrd
			reload=1
		fi
		rule6_prefix=1
	fi
}

list_hosts() {
	val=$1
	cfg=$2
	address=$3
	hostname="$(cat /proc/sys/kernel/hostname)"
	case $val in
		*pre1.$hostname)
			/sbin/uci add_list $uci_olsrd.$cfg.hosts="$address""1 pre1.$hostname"
		;;
		*)
			/sbin/uci add_list $uci_olsrd.$cfg.hosts="$val"
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
				uci_remove $uci_olsrd $cfg hosts
				config_list_foreach $cfg hosts list_hosts $cfg $address $mask
			;;
	esac
}


address=0
mask=0
wan6_prefix=0
rule6_prefix=0
reload=0
uci_olsrd="olsrd"

if uci -q get olsrd6 ; then 
	uci_olsrd="olsrd6"
fi

#get wan6 ip status
wan6_data=`ubus call network.interface.wan6 status`

json_load "$wan6_data"
json_get_keys wan6_res
json_get_var ip6table ip6table
json_select "ipv6_prefix"
json_select "1"
json_get_var address address
json_get_var mask mask

if [ $address != 0 -a $mask != 0 ] ; then
	if [ -n "$ip6table" ] ; then
		config_load network
		config_foreach update_rule6 rule6 $address $mask
		if [ $rule6_prefix == 0 ] ; then
			#add Hna6 for Host Interfaces
			uci_add network rule6 ; rule_sec="$CONFIG_SECTION"
			uci_set network "$rule_sec" lookup "$ip6table"
			uci_set network "$rule_sec" priority "20000"
			uci_set network "$rule_sec" interface "wan6"
			uci_set network "$rule_sec" src "$address/$mask"
			uci_commit network
			reload=1
		fi
	fi
	config_load $uci_olsrd
	config_foreach update_hna6 Hna6 $address $mask
	if [ $wan6_prefix == 0 ] ; then
		log "uci_add $uci_olsrd wan6 prefix $address/$mask"
		#add Hna6 for Host Interfaces
		uci_add $uci_olsrd Hna6 ; hna_sec="$CONFIG_SECTION"
		uci_set $uci_olsrd "$hna_sec" prefix "62"
		uci_set $uci_olsrd "$hna_sec" netaddr "$address"
		uci_set $uci_olsrd "$hna_sec" interface "wan6"
		#add Hna6 for auto configuration
		uci_add $uci_olsrd Hna6 ; hna_sec="$CONFIG_SECTION"
		uci_set $uci_olsrd "$hna_sec" prefix "$mask"
		uci_set $uci_olsrd "$hna_sec" netaddr "$address"
		uci_set $uci_olsrd "$hna_sec" interface "wan6"
		#add Hna6 as default gateway
		uci_add $uci_olsrd Hna6 ; hna_sec="$CONFIG_SECTION"
		uci_set $uci_olsrd "$hna_sec" prefix "0"
		uci_set $uci_olsrd "$hna_sec" netaddr "::"
		config_foreach update_hosts LoadPlugin "$address"
		uci_commit $uci_olsrd
		
		reload=1
	fi
	
	if [ $reload != 0 ] ; then
		ubus call uci "reload_config"
		#/etc/init.d/network reload
		#sleep 3
		#/etc/init.d/$uci_olsrd restart
	fi
fi
