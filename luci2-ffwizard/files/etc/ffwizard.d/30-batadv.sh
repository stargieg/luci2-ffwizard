uci_add_list() {
        local PACKAGE="$1"
        local CONFIG="$2"
        local OPTION="$3"
        local VALUE="$4"

        /sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_batadv() {
	logger -s -t ffwizard_batadv $@
}

setup_bat_base() {
	local cfg="$1"
	local mode="$2"
	if [ "$compat" == "1" ] ; then
		uci_add batman-adv mesh "$cfg"
		uci_set batman-adv $cfg aggregated_ogms
		uci_set batman-adv $cfg ap_isolation
		uci_set batman-adv $cfg bonding
		uci_set batman-adv $cfg fragmentation
		uci_set batman-adv $cfg gw_mode "$mode"
		if [ $mode == "client" ] ; then
			uci_set batman-adv $cfg gw_mode "client"
			uci_remove batman-adv $cfg gw_bandwidth
		elif [ $mode == "server" ] ; then
			uci_set batman-adv $cfg gw_mode "server"
			uci_set batman-adv $cfg gw_bandwidth "50mbit/50mbit"
		fi
		uci_set batman-adv $cfg gw_sel_class
		uci_set batman-adv $cfg log_level
		uci_set batman-adv $cfg orig_interval
		uci_set batman-adv $cfg vis_mode
		uci_set batman-adv $cfg bridge_loop_avoidance "1"
		uci_set batman-adv $cfg distributed_arp_table "1"
		uci_set batman-adv $cfg network_coding
		uci_set batman-adv $cfg hop_penalty
	else
		if ! uci_get network "$cfg" 2>/dev/null ; then
			uci_add network interface "$cfg"
		fi
		uci_set network $cfg proto 'batadv'
		uci_set network $cfg aggregated_ogms
		uci_set network $cfg ap_isolation
		uci_set network $cfg bonding
		uci_set network $cfg fragmentation
		uci_set network $cfg gw_mode "$mode"
		if [ $mode == "client" ] ; then
			uci_set network $cfg gw_mode "client"
			uci_remove network $cfg gw_bandwidth 2>/dev/null
		elif [ $mode == "server" ] ; then
			uci_set network $cfg gw_mode "server"
			uci_set network $cfg gw_bandwidth "50mbit/50mbit"
		fi
		uci_set network $cfg gw_sel_class
		uci_set network $cfg log_level
		uci_set network $cfg orig_interval
		uci_set network $cfg vis_mode
		uci_set network $cfg bridge_loop_avoidance "1"
		uci_set network $cfg distributed_arp_table "1"
		uci_set network $cfg network_coding
		uci_set network $cfg hop_penalty
	fi
}

setup_ether() {
	local cfg="$1"
	local bat_ifc="$2"
	config_get enabled $cfg enabled "0" 2>/dev/null
	[ "$enabled" == "0" ] && return
	config_get bat_mesh $cfg bat_mesh "0" 2>/dev/null
	[ "$bat_mesh" == "0" ] && return
	config_get device $cfg device "0" 2>/dev/null
	[ "$device" == "0" ] && return
	log_batadv "Setup ether mesh $cfg"
	if [ "$compat" == "1" ] ; then
		uci_set network $cfg proto "batadv"
		uci_set network $cfg mesh "$bat_ifc"
	else
		uci_set network $cfg proto "batadv_hardif"
		uci_set network $cfg master "$bat_ifc"
	fi
	bat_enabled=1
}

setup_wifi() {
	local cfg="$1"
	local bat_ifc="$2"
	config_get enabled $cfg enabled "0" 2>/dev/null
	[ "$enabled" == "0" ] && return
	config_get bat_mesh $cfg bat_mesh "0" 2>/dev/null
	[ "$bat_mesh" == "0" ] && return
	config_get idx $cfg phy_idx "-1" 2>/dev/null
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	log_batadv "Setup wifi $cfg"
	if [ "$compat" == "1" ] ; then
		uci_set network $device proto "batadv"
		uci_set network $device mesh "$bat_ifc"
		uci_set network $device mtu "1532"
	else
		uci_set network $device proto "batadv_hardif"
		uci_set network $device master "$bat_ifc"
	fi
	bat_enabled=1
}

remove_section() {
	local cfg="$1"
	uci_remove batman-adv "$cfg"
}

br_ifaces=""
br_name="fflandhcp"
bat_br_name="mesh"
bat_iface="bat0"
bat_mode="client"

if [ "$compat" == "1" ] ; then
	if ! [ -f /etc/config/batman-adv ] ; then
		touch /etc/config/batman-adv
	fi

	config_load batman-adv
	#Remove mesh sections
	config_foreach remove_section mesh
else
	uci_remove network "bat0" 2>/dev/null
fi

bat_enabled=0
#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether "$bat_iface"
config_foreach setup_wifi wifi "$bat_iface"

if [ "$bat_enabled" == "1" ] ; then
	#Setup batman-adv
	config_get br ffwizard br "0" 2>/dev/null
	if [ "$br" == "1" ] ; then
		#Setup fflandhcp batman bridge
		if [ "$compat" == "1" ] ; then
			br_ifaces="$(uci_get network $br_name ifname 2>/dev/null)"
			#Add bat0 interface to fflandhcp bridge
			br_ifaces="$br_ifaces $bat_iface"
			uci_set network $br_name ifname "$br_ifaces"
			#Remove batman mesh bridge
			uci_remove network "$bat_br_name" 2>/dev/null
		else
			uci_add_list network br$br_name ports $bat_iface
		fi
		config_get ipaddr ffwizard dhcp_ip "0" 2>/dev/null
		if [ "$ipaddr" != 0 ] ; then
			bat_mode="server"
		fi
	else
		#Setup fflandhcp batman bridge
		if ! uci_get network "$bat_br_name" 2>/dev/null ; then
			uci_add network interface "$bat_br_name"
		fi
		uci_set network $bat_br_name proto "static"
		uci_set network $bat_br_name ip6assign "64"
		uci_set network $bat_br_name mtu "1532"
		uci_set network $bat_br_name force_link "1"
		if [ "$compat" == "1" ] ; then
			uci_set network $bat_br_name type "bridge"
			#Set only bat0 interface to batman bridge
			uci_set network $bat_br_name ifname "$bat_iface"
		else
			uci_set network $bat_br_name device "br-$bat_br_name"
			if ! uci_get network br$bat_br_name 2>/dev/null ; then
				uci_add network device "br$bat_br_name"
			fi
			uci_set network br$cfg name "br-$bat_br_name"
			uci_set network br$cfg type "bridge"
			#for batman
			uci_set network br$cfg bridge_empty "1"
			uci_set network br$cfg mtu "1532"
			#TODO
			#uci_set network br$cfg macaddr "$random"?
		fi
	fi
	setup_bat_base "$bat_iface" "$bat_mode"
	if [ "$compat" == "1" ] ; then
		uci_commit batman-adv
	fi
	uci_commit network
else
	log_batadv "disabled"
	if [ "$compat" == "1" ] ; then
		/sbin/uci revert batman-adv
	fi
	/sbin/uci revert network
fi
