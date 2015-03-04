
setup_iface() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
}

setup_vap() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_vap" "Setup $cfg"
}

setup_adhoc() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_adhoc" "Setup $cfg"
}

 
config_load ffwizard
config_foreach setup_iface ether
config_foreach setup_vap wifi
config_foreach setup_adhoc wifi
