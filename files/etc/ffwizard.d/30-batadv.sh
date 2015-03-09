
setup_batbase() {
	local cfg=$1
	uci_add batman-adv mesh $cfg
	uci_set batman-adv $cfg aggregated_ogms
	uci_set batman-adv $cfg ap_isolation
	uci_set batman-adv $cfg bonding
	uci_set batman-adv $cfg fragmentation
	uci_set batman-adv $cfg gw_bandwidth
	#uci_set batman-adv $cfg gw_bandwidth '50mbit/50mbit'
	#TODO Select Server/Client
	uci_set batman-adv $cfg gw_mode 'client'
	#uci_set batman-adv $cfg gw_mode 'server'
	uci_set batman-adv $cfg gw_sel_class
	uci_set batman-adv $cfg log_level
	uci_set batman-adv $cfg orig_interval
	uci_set batman-adv $cfg vis_mode
	uci_set batman-adv $cfg bridge_loop_avoidance '1'
	uci_set batman-adv $cfg distributed_arp_table '1'
	uci_set batman-adv $cfg network_coding
	uci_set batman-adv $cfg hop_penalty
}

setup_bridge_bat() {
	local cfg=$1
	local ifc=$2
	cfg_iface=$(uci_get network $cfg ifname
	uci_set network $cfg ifname "$cfg_iface $ifc"
}


setup_ether() {
	local cfg=$1
	local br=$2
	local bat_ifc=$3
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	config_get bat_mesh $cfg bat_mesh "0"
	if [ -n $br ]; then
		logger -t "ffwizard_bat_ether_br" "Setup $cfg"
		ifname=$(uci_get network $cfg ifname)
		bat_ifaces="$bat_ifaces $ifname"
		uci_set network $cfg proto none
		bat_enabled=1
	elif [ $bat_mesh == "1" ]; then
		logger -t "ffwizard_bat_ether_mesh" "Setup $cfg"
		uci_set network $cfg proto batadv
		uci_set network $cfg mesh "$bat_ifc"
		bat_enabled=1
	fi
}

setup_wifi() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	config_get bat_mesh $cfg bat_mesh "0"
	[ "$device" == "0" ] && return
	logger -t "ffwizard_bat_wifi" "Setup $cfg"
	uci_set network $cfg proto batadv
	uci_set network $cfg mesh "$bat_ifc"
	uci_set network $cfg mtu "1532"
	bat_enabled=1
}

remove_section() {
	local cfg=$1
	uci_remove batman-adv $cfg
}

config_load batman-adv
#Remove mesh sections
config_foreach remove_section mesh

local bat_enabled=0
#Setup ether and wifi
config_load ffwizard
config_foreach setup_iface ether fflandhcp bat0
config_foreach setup_wifi wifi

setup_bridge_bat fflandhcp "$bat_ifaces"

if [ $bat_enabled == "1" ] ; then
	#Setup batman-adv
	config_load batman-adv
	setup_batbase bat0
	uci_commit batman-adv
	uci_commit network
	#/etc/init.d/batman enable
else
	/sbin/uci revert batman-adv
	/sbin/uci revert network
	#/etc/init.d/batman disable
fi
