
setup_ip() {
	local cfg=$1
	local ipaddr=$2
	if ! uci -q get network.$cfg>/dev/null ; then
		uci set network.$cfg=interface
	fi
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci set network.$cfg.ipaddr=$IP
		uci set network.$cfg.netmask=$NETMASK
	fi
	uci set network.$cfg.proto=static
	uci set network.$cfg.ip6assign=64
	uci commit
}

setup_iface() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
	config_get ipaddr $cfg mesh_ip
	setup_ip $cfg $ipaddr
}

setup_vap() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get vap $cfg vap "0"
	[ "$vap" == "0" ] && return
	logger -t "ffwizard_vap" "Setup $cfg"
	config_get ipaddr $cfg vap_ip
	if [ -n "$ipaddr" ] ; then
		cfg_name="$cfg"_ap
		setup_ip $cfg_name $ipaddr
	fi
}

setup_adhoc() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_adhoc" "Setup $cfg"
	config_get ipaddr $cfg mesh_ip
	cfg_name="$cfg"_mesh
	setup_ip $cfg_name $ipaddr
}


config_load ffwizard
config_foreach setup_iface ether
config_foreach setup_vap wifi
config_foreach setup_adhoc wifi
