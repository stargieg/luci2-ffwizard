
log_olsr6() {
	logger -s -t ffwizard_olsrd6 $@
}


setup_olsrbase() {
	local cfg="$1"
	uci_set olsrd6 $cfg IpVersion "6"
	uci_set olsrd6 $cfg AllowNoInt "yes"
	uci_set olsrd6 $cfg LinkQualityAlgorithm "etx_ffeth"
	uci_set olsrd6 $cfg FIBMetric "flat"
	uci_set olsrd6 $cfg TcRedundancy "2"
	uci_set olsrd6 $cfg Pollrate "0.025"
}

setup_InterfaceDefaults() {
	uci_add olsrd6 InterfaceDefaults ; cfg="$CONFIG_SECTION"
	uci_set olsrd6 $cfg MidValidityTime "500.0"
	uci_set olsrd6 $cfg TcInterval "2.0"
	uci_set olsrd6 $cfg HnaValidityTime "125.0"
	uci_set olsrd6 $cfg HelloValidityTime "125.0"
	uci_set olsrd6 $cfg TcValidityTime "500.0"
	uci_set olsrd6 $cfg MidInterval "25.0"
	uci_set olsrd6 $cfg HelloInterval "3.0"
	uci_set olsrd6 $cfg HnaInterval "10.0"
}

setup_Plugin_json() {
	local cfg="$1"
	uci_set olsrd6 $cfg accept "::1"
	uci_set olsrd6 $cfg ipv6only "true"
	uci_set olsrd6 $cfg ignore "0"
}

setup_Plugin_watchdog() {
	local cfg="$1"
	uci_set olsrd6 $cfg file "/var/run/olsrd.watchdog.ipv6"
	uci_set olsrd6 $cfg interval "30"
	uci_set olsrd6 $cfg ignore "1"
}
setup_Plugin_nameservice() {
	local cfg="$1"
	uci_set olsrd6 $cfg services_file "/var/etc/services.olsr.ipv6"
	uci_set olsrd6 $cfg latlon_file "/var/run/latlon.js.ipv6"
	uci_set olsrd6 $cfg hosts_file "/tmp/hosts/olsr.ipv6"
	uci_set olsrd6 $cfg suffix ".olsr"
	uci_set olsrd6 $cfg ignore "0"
}

setup_Plugins() {
	local cfg="$1"
	config_get library $cfg library
	case $library in
		*json* )
			setup_Plugin_json $cfg
			olsr_json=1
		;;
		*watchdog*)
			setup_Plugin_watchdog $cfg
			olsr_watchdog=1
		;;
		*nameservice*)
			setup_Plugin_nameservice $cfg
			olsr_nameservice=1
		;;
		*)
			uci_set olsrd6 $cfg ignore "1"
		;;
	esac
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	[ "$dhcp_br" == "0" ] || return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	log_olsr6 "Setup ether $cfg"
	uci_add olsrd6 Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd6 "$iface_sec" interface "$device"
	uci_set olsrd6 "$iface_sec" ignore "0"
	# only with LinkQualityAlgorithm=etx_ffeth
	uci_set olsrd6 "$iface_sec" Mode "ether"
	# only with LinkQualityAlgorithm=etx_ff
	#uci_set olsrd6 "$iface_sec" Mode "mesh"
	olsr_enabled=1
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
	log_olsr6 "Setup wifi $cfg"
	uci_add olsrd6 Interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd6 "$iface_sec" interface "$device"
	uci_set olsrd6 "$iface_sec" ignore "0"
	#Shoud be mesh with LinkQualityAlgorithm=etx_ffeth
	#and LinkQualityAlgorithm=etx_ff
	uci_set olsrd6 "$iface_sec" Mode "mesh"
	olsr_enabled=1
}

remove_section() {
	local cfg="$1"
	uci_remove olsrd6 $cfg
}

#Load olsrd6 config
config_load olsrd6
#Remove InterfaceDefaults
config_foreach remove_section InterfaceDefaults
#Remove wifi ifaces
config_foreach remove_section Interface
#Remove Hna's
config_foreach remove_section Hna6

local olsr_enabled=0
local olsr_json=0
local olsr_watchdog=0
local olsr_nameservice=0

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

ula_prefix="$(uci_get network globals ula_prefix 0)"
if [ "$ula_prefix" != 0 ] ; then
	NETMASK="${ula_prefix#*/}"
	#BUG ON Fill with Zeros and :
	NETWORK="${ula_prefix%:*}"":"
	#BUG OFF
	uci_add olsrd6 Hna6 ; hna_sec="$CONFIG_SECTION"
	uci_set olsrd6 "$hna_sec" prefix "$NETMASK"
	uci_set olsrd6 "$hna_sec" netaddr "$NETWORK"
fi

if [ "$olsr_enabled" == "1" ] ; then
	#If olsrd is disabled then start olsrd before write config
	#read new olsrd config via ubus call uci "reload_config" in ffwizard
	if ! [ -s /etc/rc.d/S*olsrd6 ] ; then
		/etc/init.d/olsrd6 enable
		/etc/init.d/olsrd6 restart
	fi
	#Setup olsrd6
	config_load olsrd6
	config_foreach setup_olsrbase olsrd
	#Setup InterfaceDefaults
	setup_InterfaceDefaults
	#Setup Plugin or disable
	config_foreach setup_Plugins LoadPlugin
	if [ "$olsr_json" == 0 -a -n "$(opkg status olsrd-mod-jsoninfo)" ] ; then
		library="$(find /usr/lib/olsrd_jsoninfo.so* | cut -d '/' -f 4)"
		uci_add olsrd6 LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd6 "$sec" library "$library"
		setup_Plugin_json $sec
		crontab -l | grep -q 'olsrd-dyn-addr' || crontab -l | { cat; echo '*/4 * * * * /usr/sbin/olsrd-dyn-addr.sh'; } | crontab -
	fi
	if [ "$olsr_watchdog" == 0 -a -n "$(opkg status olsrd-mod-watchdog)" ] ; then
		library="$(find /usr/lib/olsrd_watchdog.so* | cut -d '/' -f 4)"
		uci_add olsrd6 LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd6 "$sec" library "$library"
		setup_Plugin_watchdog $sec
	fi
	if [ "$olsr_nameservice" == 0 -a -n "$(opkg status olsrd-mod-nameservice)" ] ; then
		library="$(find /usr/lib/olsrd_nameservice.so* | cut -d '/' -f 4)"
		uci_add olsrd6 LoadPlugin ; sec="$CONFIG_SECTION"
		uci_set olsrd6 "$sec" library "$library"
		setup_Plugin_nameservice $sec
		#add cron entry
		crontab -l | grep -q 'dnsmasq' || crontab -l | { cat; echo '* * * * * killall -HUP dnsmasq'; } | crontab -
	fi
	#TODO remove it from freifunk-common luci package
	crontab -l | grep -q 'ff_olsr_watchdog' || crontab -l | sed -e '/.*ff_olsr_watchdog.*/d' | crontab -
	#TODO
	#if ipv6 internet gateway then
	#	grep -q 'olsrd-dyn-hna6' /etc/crontabs/root || echo '*/8 * * * * /usr/sbin/olsrd-dyn-hna6.sh' >> /etc/crontabs/root
	#fi
	uci_commit olsrd6
else
	/sbin/uci revert olsrd6
	if [ -s /etc/rc.d/S*olsrd6 ] ; then
		/etc/init.d/olsrd6 stop
		/etc/init.d/olsrd6 disable
	fi
fi
