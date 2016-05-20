
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
	uci_add olsrd2 domain ; dom_sec="$CONFIG_SECTION"
	uci_set olsrd2 "$dom_sec" table "192"
	uci_set olsrd2 "$dom_sec" srcip_routes 1
	uci_set olsrd2 "$dom_sec" protocol "100"
	uci_set olsrd2 "$dom_sec" distance 2
}

setup_loop() {
	log_olsr "Setup loopback interface"
	uci_add olsrd2 interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd2 "$iface_sec" ifname "loopback"
	uci_add_list olsrd2 "$iface_sec" bindto "-0.0.0.0/0"
	uci_add_list olsrd2 "$iface_sec" bindto "-::1/128"
	uci_add_list olsrd2 "$iface_sec" bindto "default_accept"
	uci_set olsrd2 "$iface_sec" ignore "0"
}

setup_lan_import() {
	log_olsr "Setup Lan Import"
	uci_add olsrd2 lan_import lan ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd2 "$iface_sec" domain 0
	uci_add olsrd2 "$iface_sec" matches "::/0"
	uci_set olsrd2 "$iface_sec" prefix_length "-1"
	#uci_set olsrd2 "$iface_sec" interface "olsrd.ipv6"
	uci_set olsrd2 "$iface_sec" table 254
	uci_set olsrd2 "$iface_sec" protocol 0
	uci_set olsrd2 "$iface_sec" metric 0
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
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	log_olsr "Setup ether $cfg"
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

local olsr_enabled=0

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
	#Setup loopback interface
	#setup_lan_import
	#Setup loopback interface
	setup_loop
	#Setup Domain Table
	setup_domain
	#Setup olsrd2
	config_load olsrd2
	config_foreach setup_olsrv2 olsrv2 $ula_prefix
	uci_commit olsrd2
else
	/sbin/uci revert olsrd2
	if [ -s /etc/rc.d/S*olsrd2 ] ; then
		/etc/init.d/olsrd2 stop
		/etc/init.d/olsrd2 disable
	fi
fi
