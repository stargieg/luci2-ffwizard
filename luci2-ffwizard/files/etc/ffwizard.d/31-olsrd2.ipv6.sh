
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
	log_olsr "Setup olsrv2"
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
	uci_add_list olsrd2 $cfg routable "-0.0.0.0/0"
	uci_add_list olsrd2 $cfg routable "-::1/128"
	uci_add_list olsrd2 $cfg routable "default_accept"
	uci_remove olsrd2 $cfg originator
	uci_add_list olsrd2 $cfg originator "-0.0.0.0/0"
	uci_add_list olsrd2 $cfg originator "-::1/128"
	uci_add_list olsrd2 $cfg originator "default_accept"
}

setup_domain() {
	log_olsr "Setup Domain IP Table"
	uci_add olsrd2 domain ; cfg="$CONFIG_SECTION"
	uci_set olsrd2 "$cfg" name "0"
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

setup_olsrv2_lan() {
	log_olsr "Setup $1 prefix $2"
	uci_add olsrd2 olsrv2_lan ; cfg="$CONFIG_SECTION"
	uci_set olsrd2 "$cfg" name "$1"
	uci_set olsrd2 "$cfg" prefix "$2"
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

	# /sys/class/net/<iface>/speed
	# Indicates the interface latest or current speed value. Value is
	# an integer representing the link speed in Mbits/sec.
	local speed="0"
	if [ "$compat" == "1" ] ; then
		for i in $(uci_get network.$device.ifname) ; do 
			local speed_get=""
			speed_get="$(cat /sys/class/net/$i/speed 2>/dev/null)"
			[ -n "$speed_get" ] && [ $speed_get -gt 0 ] && [ $speed_get -gt $speed ] && speed=$speed_get
		done
	else
		devicename="$(uci_get network.$device.device)"
		j=0
		while name="$(uci_get network.@device[$j].name)" ; do
			if [ "$name" == "$devicename" ] ; then
				for i in $(uci_get network.@device[$j].ports) ; do
					local speed_get=""
					speed_get="$(cat /sys/class/net/$i/speed 2>/dev/null)"
					[ -n "$speed_get" ] && [ $speed_get -gt 0 ] && [ $speed_get -gt $speed ] && speed=$speed_get
				done
			fi
			j=$((j+1))
		done
		if [ "$speed" == "0" ] ; then
			local speed_get=""
			speed_get="$(cat /sys/class/net/$devicename/speed 2>/dev/null)"
			[ -n "$speed_get" ] && [ $speed_get -gt 0 ] && [ $speed_get -gt $speed ] && speed=$speed_get
		fi
	fi
	if [ "$speed" -gt "0" ] ; then
		speed="$speed""M"
	else
		speed="1G"
	fi

	uci_add olsrd2 interface ; iface_sec="$CONFIG_SECTION"
	uci_set olsrd2 "$iface_sec" ifname "$device"
	uci_add_list olsrd2 "$iface_sec" bindto "-0.0.0.0/0"
	uci_add_list olsrd2 "$iface_sec" bindto "-::1/128"
	uci_add_list olsrd2 "$iface_sec" bindto "default_accept"
	uci_set olsrd2 "$iface_sec" rx_bitrate "$speed"
	uci_set olsrd2 "$iface_sec" tx_bitrate "$speed"
	uci_set olsrd2 "$iface_sec" ignore "0"
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
#Remove ula and lan prefix
config_foreach remove_section olsrv2_lan
#Remove lan prefix from loopback
uci_remove network loopback srcip6prefix 2>/dev/null
uci_remove network loopback ip6prefix 2>/dev/null
uci_remove network loopback ip6addr
uci_add_list network loopback ip6addr "::1/128"
uci_commit network

olsr_enabled=0

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

ula_prefix="$(uci_get network globals ula_prefix 0)"

if [ "$olsr_enabled" == "1" ] ; then
	if ! [ -s /etc/rc.d/S*olsrd2 ] ; then
		/etc/init.d/olsrd2 enable
	fi
	mkdir -p /tmp/ff
	touch /tmp/ff/olsrd2
	touch /tmp/ff/cron
	#Setup OLSR1 IPv6 routen import
	#setup_lan_import
	#Setup loopback interface
	setup_loop
	#Setup Domain Table
	setup_domain
	#Setup Domain Table
	setup_telnet
	#Add ula prefix
	setup_olsrv2_lan ula $ula_prefix
	#Setup IP6 Prefix
	config_get ip6prefix ffwizard ip6prefix 2>/dev/null
	if [ -n "$ip6prefix" ] ; then
		setup_olsrv2_lan lan "$ip6prefix"
	fi
	#Setup olsrd2
	config_load olsrd2
	config_foreach setup_olsrv2 olsrv2
	uci_commit olsrd2
	#Cron search for public prefix greater than 56
	grep -q 'olsrv2-dyn-addr' /etc/crontabs/root || echo '*/8 * * * * /usr/sbin/olsrv2-dyn-addr.sh' >> /etc/crontabs/root
	grep -q "olsrneighbor2hosts.sh" /etc/crontabs/root || \
		echo "*/5 * * * *     /usr/sbin/olsrneighbor2hosts.sh" >> /etc/crontabs/root
	grep -q "olsrnode2hosts.sh" /etc/crontabs/root || \
		echo "*/10 * * * *      /usr/sbin/olsrnode2hosts.sh" >> /etc/crontabs/root

	#Disable olsrd6
	ubus call rc init '{"name":"olsrd6","action":"stop"}' 2>/dev/null || /etc/init.d/olsrd6 stop 2>/dev/null 
	ubus call rc init '{"name":"olsrd6","action":"disable"}' 2>/dev/null || /etc/init.d/olsrd6 disable 2>/dev/null 
else
	/sbin/uci revert olsrd2
	ubus call rc init '{"name":"olsrd2","action":"stop"}' 2>/dev/null || /etc/init.d/olsrd2 stop
	ubus call rc init '{"name":"olsrd2","action":"disable"}' 2>/dev/null || /etc/init.d/olsrd2 disable
	crontab -l | grep -q 'olsrneighbor2hosts' && crontab -l | sed -e '/.*olsrneighbor2hosts.*/d' | crontab -
	crontab -l | grep -q 'olsrnode2hosts' && crontab -l | sed -e '/.*olsrnode2hosts.*/d' | crontab -
	crontab -l | grep -q 'olsrv2-dyn-addr' && crontab -l | sed -e '/.*olsrv2-dyn-addr.*/d' | crontab -
fi
