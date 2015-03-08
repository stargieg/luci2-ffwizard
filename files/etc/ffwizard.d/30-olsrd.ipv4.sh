
setup_olsrbase() {
	local cfg=$1
	uci_set olsrd $cfg AllowNoInt "yes"
	uci_set olsrd $cfg NatThreshold "0.75"
	uci_set olsrd $cfg LinkQualityAlgorithm "etx_ff"
	uci_set olsrd $cfg FIBMetric "flat"
	uci_set olsrd $cfg TcRedundancy "2"
	uci_set olsrd $cfg Pollrate "0.025"
}

setup_InterfaceDefaults() {
	local cfg=$1
	uci_set olsrd $cfg MidValidityTime "500.0"
	uci_set olsrd $cfg TcInterval "2.0"
	uci_set olsrd $cfg HnaValidityTime "125.0"
	uci_set olsrd $cfg HelloValidityTime "125.0"
	uci_set olsrd $cfg TcValidityTime "500.0"
	uci_set olsrd $cfg Ip4Broadcast "255.255.255.255"
	uci_set olsrd $cfg MidInterval "25.0"
	uci_set olsrd $cfg HelloInterval "3.0"
	uci_set olsrd $cfg HnaInterval "10.0"
}

setup_Plugins() {
	local cfg=$1
	config_get library $cfg library
	case $library in
		*json* )
			uci_set olsrd $cfg accept "127.0.0.1"
			uci_set olsrd $cfg ignore "0"
		;;
		*watchdog*)
			uci_set olsrd $cfg file "/var/run/olsrd.watchdog.ipv4"
			uci_set olsrd $cfg interval "30"
		;;
		*nameservice*)
			uci_set olsrd $cfg services_file "/var/etc/services.olsr.ipv4"
			uci_set olsrd $cfg latlon_file "/var/run/latlon.js.ipv4"
			uci_set olsrd $cfg hosts_file "/tmp/hosts/olsr.ipv4"
			uci_set olsrd $cfg suffix ".olsr"
		;;
		*)
			uci_set olsrd $cfg ignore "1"
		;;
	esac
}

setup_ether() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get mesh_ip $cfg mesh_ip "0"
	[ "$mesh_ip" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	logger -t "ffwizard_olsrd_ether" "Setup $cfg"
	uci_add olsrd Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd "$iface_sec" interface "$device"
	uci_set olsrd "$iface_sec" ignore "0"
	# only with LinkQualityAlgorithm=etx_ffeth
	#uci_set olsrd "$iface_sec" Mode "ether"
	# only with LinkQualityAlgorithm=etx_ff
	uci_set olsrd "$iface_sec" Mode "mesh"
	olsr_enabled=1
}

setup_wifi() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get mesh_ip $cfg mesh_ip "0"
	[ "$mesh_ip" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	logger -t "ffwizard_olsrd_wifi" "Setup $cfg"
	uci_add olsrd Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd "$iface_sec" interface "$device"
	uci_set olsrd "$iface_sec" ignore "0"
	#Shoud be mesh with LinkQualityAlgorithm=etx_ffeth
	#and LinkQualityAlgorithm=etx_ff
	uci_set olsrd "$iface_sec" Mode "mesh"
	olsr_enabled=1
}

remove_Interface() {
	local cfg=$1
	uci_remove olsrd $cfg
}

#Remove wifi ifaces
config_load olsrd
config_foreach remove_Interface Interface
local olsr_enabled=0
#Setup ether and wifi
config_load ffwizard
config_foreach setup_iface ether
config_foreach setup_wifi wifi

if [ $olsr_enabled == "1" ] ; then
	#Setup olsrd
	config_load olsrd
	config_foreach setup_olsrbase olsrd
	#Setup InterfaceDefaults
	config_foreach setup_InterfaceDefaults InterfaceDefaults
	#Setup Plugin or disable
	config_foreach setup_Plugins LoadPlugin
	uci_commit olsrd
	/etc/init.d/olsrd enable
else
	/sbin/uci revert olsrd
	/etc/init.d/olsrd disable
fi
