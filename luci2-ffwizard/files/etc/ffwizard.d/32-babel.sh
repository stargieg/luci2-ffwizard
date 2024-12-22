
uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_babel() {
	logger -s -t ffwizard_babeld $@
}

setup_filter_redistribute() {
	local ip="$1"
	log_babel "Setup filter_redistribute"
	local eq=$(echo $ip | cut -d '/' -f 2)
	uci_add babeld filter ; cfg="$CONFIG_SECTION"
	uci_set babeld $cfg type "redistribute"
	uci_set babeld $cfg ip "$ip"
	uci_set babeld $cfg eq "$eq"
	#uci_set babeld $cfg proto '4'
	#uci_set babeld $cfg action 'metric 128'
	#uci_set babeld $cfg if "$iface"
}

setup_filter_redistribute_local() {
	log_babel "Setup filter_redistribute local"
	uci_add babeld filter ; cfg="$CONFIG_SECTION"
	uci_set babeld $cfg type "redistribute"
	uci_set babeld $cfg local "true"
	uci_set babeld $cfg eq "128"
	uci_set babeld $cfg action "deny"
	uci_add babeld filter ; cfg="$CONFIG_SECTION"
	uci_set babeld $cfg type "redistribute"
	uci_set babeld $cfg local "true"
	uci_set babeld $cfg action "allow"
}

setup_babel() {
	log_babel "Setup babeld"
	uci_add babeld general ; cfg="$CONFIG_SECTION"
	uci_set babeld $cfg local_port '33123'
	uci_set babeld $cfg ipv6_subtrees 'true'
	uci_set babeld $cfg ubus_bindings 'true'
	#uci_set babeld $cfg export_table '11'
}

setup_filter_in() {
	local iface="$1"
	log_babel "Setup filter_in"
	uci_add babeld filter ; cfg="$CONFIG_SECTION"
	uci_set babeld $cfg type "in"
	uci_set babeld $cfg action 'metric 128'
	uci_set babeld $cfg if "$iface"
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	[ "$dhcp_br" == "0" ] || return
	config_get babel_mesh $cfg babel_mesh "0"
	[ "$babel_mesh" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	config_get dhcp_ip6 $cfg dhcp_ip6 2>/dev/null
	log_babel "Setup ether $cfg $dhcp_ip6"

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

	uci_add babeld interface ; iface_sec="$CONFIG_SECTION"
	uci_set babeld "$iface_sec" ifname "$device"
	#uci_set babeld "$iface_sec" rx_bitrate "$speed"
	#uci_set babeld "$iface_sec" tx_bitrate "$speed"
	uci_set babeld "$iface_sec" type "wired"
	#babeld.j2
	uci_set babeld "$iface_sec" split_horizon "true"
	uci_set babeld "$iface_sec" link_quality "false"
	uci_set babeld "$iface_sec" rxcost "96"
	setup_filter_in "$device"
	#Setup IP6 Prefix
	if [ ! -z "$dhcp_ip6" ] ; then
		setup_filter_redistribute "$dhcp_ip6"
	fi
	babel_enabled=1
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get babel_mesh $cfg babel_mesh "0"
	[ "$babel_mesh" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio"$idx"_mesh"
	log_babel "Setup wifi $cfg"
	uci_add babeld interface ; iface_sec="$CONFIG_SECTION"
	uci_set babeld "$iface_sec" ifname "$device"
	if [ "$compat" == "1" ] ; then
		mode=$(uci_get network.$device.mode)
	else
		mode=$(uci_get network.br$device.type)
	fi
	if [ "$iface_mode" == "bridge" ] ; then
		uci_set babeld "$iface_sec" type "wired"
		#babeld.j2
		uci_set babeld "$iface_sec" split_horizon "true"
		uci_set babeld "$iface_sec" link_quality "false"
		uci_set babeld "$iface_sec" rxcost "256"
	else
		uci_set babeld "$iface_sec" type "wireless"
		#babeld.j2
		uci_set babeld "$iface_sec" split_horizon "false"
		uci_set babeld "$iface_sec" link_quality "true"
		uci_set babeld "$iface_sec" rxcost "256"
	fi
	setup_filter_in "$device"
	babel_enabled=1
}

remove_section() {
	local cfg="$1"
	uci_remove babeld $cfg
}

addrc() {
    local cmd="$1"
    grep -v exit /etc/rc.local > /tmp/rc.local
    echo "$cmd" >> /tmp/rc.local
    echo 'exit 0' >> /tmp/rc.local
    mv /tmp/rc.local /etc/rc.local
    $cmd
}

get_seed() {
	dd if=/dev/urandom bs=2 count=1 2>&- | hexdump | if read -r line
	then
		echo "0x${line#* }"
	fi
}

#Load babeld config
config_load babeld
#Remove interface
config_foreach remove_section interface
#Remove general
config_foreach remove_section general
#Remove filter
config_foreach remove_section filter

babel_enabled=0

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

if [ "$babel_enabled" == "1" ] ; then
	if ! [ -s /etc/rc.d/S*babeld ] ; then
		/etc/init.d/babeld enable
	fi
	mkdir -p /tmp/ff
	touch /tmp/ff/babeld
	#Setup IP6 Prefix
	config_get ip6prefix ffwizard ip6prefix 2>/dev/null
	if [ ! -z "$ip6prefix" ] ; then
		setup_filter_redistribute "$ip6prefix"
	else
		setup_filter_redistribute
	fi

	setup_filter_redistribute_local

	#Setup babeld
	setup_babel
	uci_commit babeld

	crontab -l | grep -q 'babelneighbor2hosts' || \
		echo "*/5 * * * *     /usr/sbin/babelneighbor2hosts.sh" >> /etc/crontabs/root
	SEED=$(get_seed)
	MIN1="$((SEED % 29))"
	MIN2="$((MIN1 + 30))"
	crontab -l | grep -q 'babelnode2hosts' || \
		echo "$MIN1,$MIN2 * * * *  /usr/sbin/babelnode2hosts.sh" >> /etc/crontabs/root
	crontab -l | grep -q 'babeldns64' || \
		echo "*/15 * * * *    /usr/sbin/babeldns64.sh" >> /etc/crontabs/root
	crontab -l | grep -q 'babel-dyn-addr' || \
		echo "*/8 * * * *    /usr/sbin/babel-dyn-addr.sh" >> /etc/crontabs/root

	if ! grep -q "/etc/init.d/babeld" /etc/rc.local ; then
		addrc '( sleep 60 ; /etc/init.d/babeld restart ) &'
	fi

else
	/sbin/uci revert babeld
	ubus call rc init '{"name":"babeld","action":"stop"}' 2>/dev/null || /etc/init.d/babeld stop
	ubus call rc init '{"name":"babeld","action":"disable"}' 2>/dev/null || /etc/init.d/babeld disable
	crontab -l | grep -q 'babelneighbor2hosts' && crontab -l | sed -e '/.*babelneighbor2hosts.*/d' | crontab -
	crontab -l | grep -q 'babelnode2hosts' && crontab -l | sed -e '/.*babelnode2hosts.*/d' | crontab -
	crontab -l | grep -q 'babeldns64' && crontab -l | sed -e '/.*babeldns64.*/d' | crontab -
	crontab -l | grep -q 'babel-dyn-addr' && crontab -l | sed -e '/.*babel-dyn-addr.*/d' | crontab -
	sed -e '/.*babeld restart.*/d' -i /etc/rc.local
fi
