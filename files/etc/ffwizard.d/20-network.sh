
setup_iface() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
	config_get ipaddr $cfg mesh_ip
	if [ -n "$ipaddr" ]; then
		eval "$(ipcalc.sh $ipaddr)"
		uci set network.$cfg.proto=static
		uci set network.$cfg.ipaddr=$IP
		uci set network.$cfg.netmask=$NETMASK
		uci set network.$cfg.ip6assign=64
		uci commit
	fi
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
