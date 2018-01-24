
uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_olsr() {
	logger -s -t ffwizard_olsrd2 $@
}


setup_olsrv2() {
	local cfg="$1"
	local ula="$2"
	log_olsr "Setup olsrv2 with ula $ula"
	uci_remove olsrd2 $cfg lan
	uci_add_list olsrd2 $cfg lan "$ula"
	#Setup IP6 Prefix
	config_get ip6prefix ffwizard ip6prefix
	if [ -n "$ip6prefix" ] ; then
		uci_add_list olsrd2 $cfg lan "$ip6prefix"
	fi
	uci_set olsrd2 $cfg tc_interval "5.0"
	uci_set olsrd2 $cfg tc_validity "300.0"
	uci_set olsrd2 $cfg forward_hold_time "300.0"
	uci_set olsrd2 $cfg processing_hold_time "300.0"
	uci_remove olsrd2 $cfg routable
	uci_add_list olsrd2 $cfg routable "$ula"
	uci_add_list olsrd2 $cfg routable "-0.0.0.0/0"
	uci_add_list olsrd2 $cfg routable "-::1/128"
	uci_add_list olsrd2 $cfg routable "default_accept"
	uci_remove olsrd2 $cfg originator
	uci_add_list olsrd2 $cfg originator "$ula"
	uci_add_list olsrd2 $cfg originator "-0.0.0.0/0"
	uci_add_list olsrd2 $cfg originator "-::1/128"
	uci_add_list olsrd2 $cfg originator "default_accept"
}

setup_domain() {
	log_olsr "Setup Domain IP Table"
	uci_add olsrd2 domain ; cfg="$CONFIG_SECTION"
	uci_set olsrd2 "$cfg" table "254"
	uci_set olsrd2 "$cfg" srcip_routes 1
	uci_set olsrd2 "$cfg" protocol "100"
	uci_set olsrd2 "$cfg" distance 2
}

setup_telnet() {
	log_olsr "Setup Telnet interface"
	uci_add olsrd2 telnet ; cfg="$CONFIG_SECTION"
	uci_set olsrd2 "$cfg" port "2009"
	uci_add_list olsrd2 "$cfg" bindto "::1"
	uci_add_list olsrd2 "$cfg" bindto "default_reject"
}

setup_loop() {
	log_olsr "Setup loopback interface"
	uci_add olsrd2 interface ; cfg="$CONFIG_SECTION"
	uci_set olsrd2 "$cfg" ifname "loopback"
	uci_add_list olsrd2 "$cfg" bindto "-0.0.0.0/0"
	uci_add_list olsrd2 "$cfg" bindto "-::1/128"
	uci_add_list olsrd2 "$cfg" bindto "default_accept"
	uci_set olsrd2 "$cfg" ignore "0"
}

setup_lan_import() {
	log_olsr "Setup Lan Import"
	uci_add olsrd2 lan_import lan ; cfg="$CONFIG_SECTION"
	uci_set olsrd2 "$cfg" domain 0
	uci_add olsrd2 "$cfg" matches "::/0"
	uci_set olsrd2 "$cfg" prefix_length "-1"
	#uci_set olsrd2 "$cfg" interface "olsrd.ipv6"
	uci_set olsrd2 "$cfg" table 254
	uci_set olsrd2 "$cfg" protocol 0
	uci_set olsrd2 "$cfg" metric 0
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
	log_olsr "Setup ether $cfg"
	uci_add olsrd2 interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd2 "$iface_sec" ifname "$device"
	uci_add_list olsrd2 "$iface_sec" bindto "-0.0.0.0/0"
	uci_add_list olsrd2 "$iface_sec" bindto "-::1/128"
	uci_add_list olsrd2 "$iface_sec" bindto "default_accept"
	uci_set olsrd2 "$iface_sec" rx_bitrate "1G"
	uci_set olsrd2 "$iface_sec" tx_bitrate "1G"
	uci_set olsrd2 "$iface_sec" ignore "0"
	olsr_enabled=1
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	[ "$dhcp_br" == "0" ] || return
	config_get olsr_mesh $cfg olsr_mesh "0"
	[ "$olsr_mesh" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	log_olsr "Setup wifi $cfg"
	uci_add olsrd2 interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd2 "$iface_sec" ifname "$device"
	uci_add_list olsrd2 "$iface_sec" bindto "-0.0.0.0/0"
	uci_add_list olsrd2 "$iface_sec" bindto "-::1/128"
	uci_add_list olsrd2 "$iface_sec" bindto "default_accept"
	uci_set olsrd2 "$iface_sec" ignore "0"
	olsr_enabled=1
}

remove_section() {
	local cfg="$1"
	uci_remove olsrd2 $cfg
}

#Load olsrd2 config
config_load olsrd2
#Remove interface
config_foreach remove_section interface
#Remove domain
config_foreach remove_section domain
#Remove telnet
config_foreach remove_section telnet

olsr_enabled=0

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

ula_prefix="$(uci_get network globals ula_prefix 0)"

if [ "$olsr_enabled" == "1" ] ; then
	#If olsrd is disabled then start olsrd before write config
	#read new olsrd config via ubus call uci "reload_config" in ffwizard
	if ! [ -s /etc/rc.d/S*olsrd2 ] ; then
		/etc/init.d/olsrd2 enable
	fi
	#Setup OLSR1 IPv6 routen import
	#setup_lan_import
	#Setup loopback interface
	setup_loop
	#Setup Domain Table
	setup_domain
	#Setup Domain Table
	setup_telnet
	#Setup olsrd2
	config_load olsrd2
	config_foreach setup_olsrv2 olsrv2 $ula_prefix
	uci_commit olsrd2
	#Disable olsrd6
	if [ -s /etc/rc.d/S*olsrd6 ] ; then
		/etc/init.d/olsrd6 stop
		/etc/init.d/olsrd6 disable
	fi
else
	/sbin/uci revert olsrd2
	if [ -s /etc/rc.d/S*olsrd2 ] ; then
		/etc/init.d/olsrd2 stop
		/etc/init.d/olsrd2 disable
	fi
fi
