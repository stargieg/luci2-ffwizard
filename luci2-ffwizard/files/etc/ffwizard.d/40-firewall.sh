
uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_fw() {
	logger -s -t ffwizard_fw $@
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	[ "$dhcp_br" == "0" ] || return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	log_fw "Setup ether $cfg"
	ff_ifaces="$cfg $ff_ifaces"
	case $cfg in
		lan) lan_iface="";;
		wan) wan_iface="";;
	esac
	config_get ipaddr $cfg dhcp_ip "0" 2>/dev/null
	if [ "$ipaddr" != "0" ] ; then
		cfg_dhcp=$cfg"_dhcp"
		ff_ifaces="$cfg_dhcp $ff_ifaces"
	fi
	config_get bat_mesh $cfg bat_mesh "0" 2>/dev/null
	[ "$bat_mesh" == "1" ] && bat_enabled=1
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0" 2>/dev/null
	config_get bat_mesh $cfg bat_mesh "0" 2>/dev/null
	config_get vap $cfg vap "0" 2>/dev/null
	if [ "$olsr_mesh" == "1" -o "$bat_mesh" == "1" ] ; then
		local device="radio"$idx"_mesh"
		log_fw "Setup wifi $cfg"
		ff_ifaces="$device $ff_ifaces"
	fi
	if [ "$vap" == "1" ] ; then
		local cfg_vap=$cfg"_vap"
		log_fw "Setup wifi $cfg_vap"
		ff_ifaces="$cfg_vap $ff_ifaces"
	fi
	if "$bat_mesh" == "1" ] ; then
		bat_enabled=1
	fi
}

zone_iface_add() {
	local cfg="$1"
	local zone="$2"
	local networks="$3"
	config_get name $cfg name

	if [ "$name" == "$zone" ] ; then
		for network in $networks ; do
			uci_add_list firewall "$cfg" network $network
		done
	fi
}

zone_iface_del() {
	local cfg="$1"
	local zone="$2"
	config_get name $cfg name

	if [ "$name" == "$zone" ] ; then
		uci_remove firewall "$cfg" network 2>/dev/null
	fi
}

br_name="fflandhcp"
ff_ifaces=""
lan_iface="lan"
wan_iface="wan wan6"
bat_enabled=0

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

#Add Bridge interface to Zone freifunk
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	ff_ifaces="$br_name $ff_ifaces"
fi

#Add bat0 interface to Zone freifunk
if [ "$bat_enabled" == "1" ] ; then
	ff_ifaces="bat0 $ff_ifaces"
fi

#Add interfaces to Zone freifunk
config_load firewall
config_foreach zone_iface_del zone "freifunk"
config_foreach zone_iface_add zone "freifunk" "$ff_ifaces"
#Add interface lan to Zone lan if not an freifunk interface
config_foreach zone_iface_del zone "lan"
if [ -n "$lan_iface" ] ; then
	config_foreach zone_iface_add zone "lan" "$lan_iface"
fi

#Add interface wan to Zone wan if not an freifunk interface
config_foreach zone_iface_del zone "wan"
if [ -n "$wan_iface" ] ; then
	config_foreach zone_iface_add zone "wan" "$wan_iface"
fi

uci_commit firewall

mkdir -p /tmp/ff
touch /tmp/ff/firewall