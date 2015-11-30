
log_fw() {
	logger -s -t ffwizard_fw $@
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	log_fw "Setup ether $cfg"
	ff_ifaces="$device $ff_ifaces"
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	log_fw "Setup wifi $cfg"
	ff_ifaces="$device $ff_ifaces"
}

zone_iface_add() {
	local cfg="$1"
	local zone="$2"
	local network="$1"
	config_get name $cfg name
	if [ "$name" == "$zone" ] ; then
		uci_set firewall "$cfg" network "$network"
	fi
}


local br_name="fflandhcp"
local ff_ifaces=""

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

#Add Bridge interface to Zone freifunk
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	ff_ifaces="$br_name $ff_ifaces"
fi

#Add interfaces to Zone freifunk
config_load firewall
config_foreach zone_iface_set zone "freifunk" "$ff_ifaces"

uci_commit firewall
