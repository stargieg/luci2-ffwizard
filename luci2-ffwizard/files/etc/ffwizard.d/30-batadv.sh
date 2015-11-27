
log_batadv() {
	logger -s -t ffwizard_batadv $@
}

setup_bat_base() {
	local cfg="$1"
	local mode="$2"
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
}

setup_ether() {
	local cfg="$1"
	local bat_ifc="$2"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	config_get bat_mesh $cfg bat_mesh "0"
	[ "$bat_mesh" == "0" ] && return
	log_batadv "Setup ether mesh $cfg"
	uci_set network $cfg proto "batadv"
	uci_set network $cfg mesh "$bat_ifc"
	bat_enabled=1
}

setup_wifi() {
	local cfg="$1"
	local bat_ifc="$2"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	config_get bat_mesh $cfg bat_mesh "0"
	[ "$bat_mesh" == "0" ] && return
	log_batadv "Setup wifi $cfg"
	uci_set network $device proto "batadv"
	uci_set network $device mesh "$bat_ifc"
	uci_set network $device mtu "1532"
	bat_enabled=1
}

remove_section() {
	local cfg="$1"
	uci_remove batman-adv "$cfg"
}

local br_ifaces
local br_name="fflandhcp"
local bat_br_name="mesh"
local bat_iface="bat0"
local bat_mode="client"

if ! [ -f /etc/config/batman-adv ] ; then
	touch /etc/config/batman-adv
fi

config_load batman-adv
#Remove mesh sections
config_foreach remove_section mesh

local bat_enabled=0
#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether "$bat_iface"
config_foreach setup_wifi wifi "$bat_iface"

if [ "$bat_enabled" == "1" ] ; then
	#Setup batman-adv
	config_get br ffwizard br "0"
	if [ "$br" == "1" ] ; then
		#Setup fflandhcp batman bridge
		br_ifaces="$(uci_get network $br_name ifname)"
		#Add bat0 interface to fflandhcp bridge
		br_ifaces="$br_ifaces $bat_iface"
		uci_set network $br_name ifname "$br_ifaces"
		#Remove batman mesh bridge
		uci_remove network "$bat_br_name" 2>/dev/null
		config_get ipaddr ffwizard dhcp_ip "0"
		if [ "$ipaddr" != 0 ] ; then
			bat_mode="server"
		fi
	else
		#Setup fflandhcp batman bridge
		if ! uci_get network "$bat_br_name" >/dev/null ; then
			uci_add network interface "$bat_br_name"
			uci_set network $bat_br_name proto "static"
			uci_set network $bat_br_name ip6assign "64"
			uci_set network $bat_br_name mtu "1532"
			uci_set network $bat_br_name force_link "1"
			uci_set network $bat_br_name type "bridge"
		fi
		#Set only bat0 interface to batman bridge
		uci_set network $bat_br_name ifname "$bat_iface"
	fi
	setup_bat_base "$bat_iface" "$bat_mode"
	uci_commit batman-adv
	uci_commit network
else
	/sbin/uci revert batman-adv
	/sbin/uci revert network
fi
