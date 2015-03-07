
setup_iface() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
}

setup_wifi() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	logger -t "ffwizard_wifi" "Setup $cfg"
}

remove_Interface() {
	local cfg=$1
	uci_remove olsrd $cfg
}

#Remove wifi ifaces
config_load olsrd
config_foreach remove_Interface Interface

#Setup ether and wifi
config_load ffwizard
config_foreach setup_iface ether
config_foreach setup_wifi wifi

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$enabled" == "1" ] ; then
	config_get ipaddr ffwizard br_ip
	setup_bridge fflandhcp $ipaddr
fi
