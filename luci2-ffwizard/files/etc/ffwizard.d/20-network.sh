uci_add_list() {
        local PACKAGE="$1"
        local CONFIG="$2"
        local OPTION="$3"
        local VALUE="$4"

        /sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_net() {
	logger -s -t ffwizard_net $@
}

log_wifi() {
	logger -s -t ffwizard_wifi $@
}

setup_ip() {
	local cfg="$1"
	local ipaddr="$2"
	local device="$3"
	if ! uci_get network $cfg >/dev/null ; then
		uci_add network interface "$cfg"
	fi
	if [ -n "$device" ] ; then
		uci_set network $cfg device "$device"
	fi
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_set network $cfg ipaddr "$IP"
		uci_set network $cfg netmask "$NETMASK"
	else
		if [ "$cfg" == "lan" ] ; then
			#Magemant Access via lan ipv4
			uci_set network $cfg ipaddr "192.168.42.1"
			uci_set network $cfg netmask "255.255.255.0"
		else
			#ipv6 only via ip6assign
			uci_remove network $cfg ipaddr 2>/dev/null
			uci_remove network $cfg netmask 2>/dev/null
		fi
	fi
	uci_set network $cfg proto "static"
	uci_set network $cfg ip6assign "64"
	if [ "$cfg" == "wan" ] ; then
		#Disable dhcpv6 if wan a freifunk interface
		uci_set network wan6 proto "none"
	fi
}

get_ports() {
	local cfg="$1"
	local gname="$2"
	config_get name $cfg name
	[ "$name" == "$gname" ] || return
	config_get ports $cfg ports
	log_net "get_ports $cfg $gname $ports"
	fports="$fports $ports"
	uci_remove network $cfg ports
	for port in $ports ; do
		uci_add_list network $cfg _ports $port
	done
}

restore_portlist() {
	local cfg="$1"
	local gname="$2"
	config_get name $cfg name
	[ "$name" == "$gname" ] || return
	config_get ports $cfg _ports
	fports="$fports $ports"
	uci_remove network $cfg _ports
	for port in $ports ; do
		log_net "restore_portlist $cfg $gname $port"
		uci_add_list network $cfg ports $port
	done
}

setup_bridge() {
	local cfg="$1"
	local ipaddr="$2"
	setup_ip $cfg "$ipaddr" "br-$cfg"
	if ! uci_get network br$cfg >/dev/null ; then
			uci_add network device "br$cfg"
	fi
	uci_set network br$cfg name "br-$cfg"
	uci_set network br$cfg type "bridge"
	#for batman
	uci_set network br$cfg bridge_empty "1"
	uci_set network br$cfg mtu "1532"
	#TODO
	#uci_set network br$cfg macaddr "$random"?
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	config_get dhcp_br $cfg dhcp_br "0"
	if [ "$dhcp_br" == "0" ] || [ "$enabled" == "0" ] ; then
		device="$(uci_get network $cfg device)"
		if [ -n "$device" ] ; then
			log_net "Setup $cfg with device $device"
			restore_ports="$restore_ports $device"
		fi
		[ "$enabled" == "0" ] && return
	fi
	cfg_dhcp=$cfg"_dhcp"
	uci_remove network $cfg_dhcp 2>/dev/null
	if [ "$dhcp_br" == "1" ] ; then
		log_net "Setup $cfg as DHCP Bridge member"
		if uci_get network $cfg >/dev/null ; then
			device="$(uci_get network $cfg device)"
			if [ -n "$device" ] ; then
				log_net "Setup $cfg with device $device"
				br_ifaces="$br_ifaces $device"
			fi
			uci_set network $cfg proto "none"
			uci_remove network $cfg ip6prefix 2>/dev/null
			uci_remove network $cfg type 2>/dev/null
		fi
	else
		log_net "Setup $cfg IP"
		config_get ipaddr $cfg mesh_ip
		setup_ip "$cfg" "$ipaddr"
		config_get ipaddr $cfg dhcp_ip "0"
		uci_remove network $cfg ip6class
		uci_add_list network $cfg ip6class "local"
		if [ "$ipaddr" != "0" ] ; then
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 1))"
			ipaddr="$OCTET_1_3.$OCTET_4"
			setup_ip "$cfg_dhcp" "$ipaddr/$PREFIX"
			uci_set network $cfg_dhcp device "@$cfg"
			uci_remove network $cfg_dhcp ip6prefix 2>/dev/null
		fi
	fi
	case $cfg in
		lan) lan_iface="";;
		wan) wan_iface="";;
	esac
}

setup_wifi() {
	local cfg="$1"
	local br_name="$2"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get idx $cfg phy_idx "-1"
	[ "$idx" == "-1" ] && return
	local device="radio$idx"
	log_wifi "Setup $cfg"
	#get valid hwmods
	local hw_a=0
	local hw_b=0
	local hw_g=0
	local hw_n=0
	local info_data
	info_data=$(ubus call iwinfo info '{ "device": "wlan'$idx'" }' 2>/dev/null)
	[ -z "$info_data" ] && {
		log_wifi "ERR No iwinfo data for wlan$idx"
		return 1
	}
	json_load "$info_data"
	json_select hwmodes
	json_get_values hw_res
	[ -z "$hw_res" ] && {
		log_wifi "ERR No iwinfo hwmodes for wlan$idx"
		return 1
	}
	for i in $hw_res ; do
		case $i in
			a) hw_a=1 ;;
			b) hw_b=1 ;;
			g) hw_g=1 ;;
			n) hw_n=1 ;;
		esac
	done
	[ "$hw_a" == 1 ] && log_wifi "HWmode a"
	[ "$hw_b" == 1 ] && log_wifi "HWmode b"
	[ "$hw_g" == 1 ] && log_wifi "HWmode g"
	[ "$hw_n" == 1 ] && log_wifi "HWmode n"
	#get valid channel list
	local channels
	local valid_channel
	local chan_data
	chan_data=$(ubus call iwinfo freqlist '{ "device": "wlan'$idx'" }' 2>/dev/null)
	[ -z "$chan_data" ] && {
		log_wifi "ERR No iwinfo freqlist for wlan$idx"
		return 1
	}
	json_load "$chan_data"
	json_select results
	json_get_keys chan_res
	for i in $chan_res ; do
		json_select "$i"
		#check what channels are available
		json_get_var restricted restricted
		if [ "$restricted" == 0 ] ; then
			json_get_var channel channel
			channels="$channels $channel"
		fi
		json_select ".."
	done
	#get default channel depending on hw_mod
	[ "$hw_a" == 1 ] && def_channel=36
	[ "$hw_b" == 1 ] && def_channel=13
	[ "$hw_g" == 1 ] && def_channel=13
	config_get channel $cfg channel "$def_channel"
	local valid_channel
	for i in $channels ; do
		[ -z "$valid_channel" ] && valid_channel="$i"
		if [ "$channel" == "$i" ] ; then
			valid_channel="$i"
		fi
	done
	log_wifi "Channel $valid_channel"
	uci_set wireless $device channel "$valid_channel"
	uci_set wireless $device disabled "0"
	[ $hw_g == 1 ] && [ $hw_n == 1 ] && uci_set wireless $device noscan "1"
	#[ $hw_n == 1 ] && [ $valid_channel -gt 165 ] && uci_set wireless $device htmode "HT40+"
	# Channel 165 HT40-
	#[ $hw_n == 1 ] && [ $valid_channel -le 165 ] && uci_set wireless $device htmode "HT40-"
	# Channel 153,157,161 HT40+
	#[ $hw_n == 1 ] && [ $valid_channel -le 161 ] && uci_set wireless $device htmode "HT40+"
	# Channel 104 - 140 HT40-
	#[ $hw_n == 1 ] && [ $valid_channel -le 140 ] && uci_set wireless $device htmode "HT40-"
	# Channel 100 HT40+
	#[ $hw_n == 1 ] && [ $valid_channel -le 100 ] && uci_set wireless $device htmode "HT40+"
	# Channel 40 - 64 HT40-
	#[ $hw_n == 1 ] && [ $valid_channel -le 64 ] && uci_set wireless $device htmode "HT40-"
	# Channel 36 HT40+
	#[ $hw_n == 1 ] && [ $valid_channel -le 36 ] && uci_set wireless $device htmode "HT40+"
	# Channel 10 - 14 HT40-
	#[ $hw_n == 1 ] && [ $valid_channel -le 14 ] && uci_set wireless $device htmode "HT40-"
	# Channel 5 - 9 HT40+/-
	#[ $hw_n == 1 ] && [ $valid_channel -le 7 ] && uci_set wireless $device htmode "HT40+"
	# Channel 1 - 4 HT40+
	#[ $hw_n == 1 ] && [ $valid_channel -le 4 ] && uci_set wireless $device htmode "HT40+"
	uci_set wireless $device country "DE"
	[ $hw_a == 1 ] && uci_set wireless $device doth "0"
	#read from Luci_ui
	uci_set wireless $device distance "1000"
	#Reduce the Broadcast distance and save Airtime
	#Not working on wdr4300 with AP and ad-hoc
	#[ $hw_n == 1 ] && uci_set wireless $device basic_rate "5500 6000 9000 11000 12000 18000 24000 36000 48000 54000"
	#Set Man or Auto?
	#uci_set wireless $device txpower 15
	#Save Airtime max 1000
	uci_set wireless $device beacon_int "250"
	#wifi-iface
	config_get olsr_mesh $cfg olsr_mesh "0"
	config_get bat_mesh $cfg bat_mesh "0"
	config_get iface_mode $cfg iface_mode "mesh"
	if [ "$olsr_mesh" == "1" -o "$bat_mesh" == "1" ] ; then
		local bssid
		log_wifi "mesh"
		cfg_mesh=$cfg"_mesh"
		uci_add wireless wifi-iface "$device"mesh ; sec="$CONFIG_SECTION"
		uci_set wireless $sec device "$device"
		uci_set wireless $sec encryption "none"
		# Depricated Ad-Hoc config
		if [ "$iface_mode" == "adhoc" ] ; then
			uci_set wireless $sec mode "adhoc"
			config_get ssid $cfg ssid "intern-ch"$valid_channel".freifunk.net"
			uci_set wireless $sec ssid "$ssid"
			if [ $valid_channel -gt 0 -a $valid_channel -lt 10 ] ; then
				bssid_ch=$valid_channel"2:CA:FF:EE:BA:BE"
			elif [ $valid_channel -eq 10 ] ; then
				bssid_ch="02:CA:FF:EE:BA:BE"
			elif [ $valid_channel -gt 10 -a $valid_channel -lt 15 ] ; then
				bssid_ch=$(printf "%X" "$valid_channel")"2:CA:FF:EE:BA:BE"
			elif [ $valid_channel -gt 35 -a $valid_channel -lt 100 ] ; then
				bssid_ch="02:"$valid_channel":CA:FF:EE:EE"
			elif [ $valid_channel -gt 99 -a $valid_channel -lt 199 ] ; then
				bssid_ch="12:"$(printf "%02d" "$(expr $valid_channel - 100)")":CA:FF:EE:EE"
			fi
			config_get bssid $cfg bssid "$bssid_ch"
			uci_set wireless $sec bssid "$bssid"
		else
			#TODO check valid htmode. adhoc works with HT40
			[ $hw_n == 1 ] && uci_set wireless $device htmode "HT20"
			uci_set wireless $sec mode "mesh"
			uci_set wireless $sec mesh_id 'freifunk'
			uci_set wireless $sec mesh_fwding '0'
		fi
		#uci_set wireless $sec "doth"
		uci_set wireless $sec network "$cfg_mesh"
		uci_set wireless $sec mcast_rate "18000"
		config_get ipaddr $cfg mesh_ip
		setup_ip "$cfg_mesh" "$ipaddr"
		uci_remove network $cfg_mesh ip6class
		uci_add_list network $cfg_mesh ip6class "local"
	else
		if uci_get network $cfg >/dev/null ; then
			cfg_mesh=$cfg"_mesh"
			uci_remove network "$cfg_mesh"
		fi
	fi
	config_get vap $cfg vap "0"
	#TODO check valid interface combinations
	#iw phy$idx info | grep -A6 "valid interface combinations"
	#iw phy$idx info | grep "interface combinations are not supported"
	if [ "$vap" == "1" ] && \
		[ -n "$(iw phy$idx info | grep 'interface combinations are not supported')" ]  ; then
		vap="0"
		log_wifi "Virtual AP Not Supported"
		#uci_set ffwizard $cfg vap "0"
	fi
	if [ "$vap" == "1" ] ; then
		log_wifi "Virtual AP"
		cfg_vap=$cfg"_vap"
		uci_add wireless wifi-iface "$device"vap ; sec="$CONFIG_SECTION"
		uci_set wireless $sec device "$device"
		uci_set wireless $sec mode "ap"
		uci_set wireless $sec mcast_rate "6000"
		#uci_set wireless $sec isolate 1
		uci_set wireless $sec ssid "freifunk.net"
		config_get vap_br $cfg vap_br "0"
		if [ $vap_br == 1 ] ; then
			uci_set wireless $sec network "$br_name"
		else
			config_get ipaddr $cfg dhcp_ip
			uci_set wireless $sec network "$cfg_vap"
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 1))"
			ipaddr="$OCTET_1_3.$OCTET_4"
			setup_ip "$cfg_vap" "$ipaddr/$PREFIX"
		fi
	fi
}

regdomain() {
	local cfg="$1"
	uci_set wireless "$cfg" country "DE"
	uci_set wireless "$cfg" disabled "0"
}

remove_wifi() {
	local cfg="$1"
	uci_remove wireless "$cfg" 2>/dev/null
}

restore_ports=""
br_ifaces=""
br_name="fflandhcp"
lan_iface="lan"
wan_iface="wan wan6"

#Remove wireless config
rm /etc/config/wireless
/sbin/wifi config

#Set regdomain
config_load wireless
config_foreach regdomain wifi-device
uci_commit wireless
/sbin/wifi reload
sleep 5

#Remove wifi ifaces
config_load wireless
config_foreach remove_wifi wifi-iface
uci_commit wireless

#Setup ether
config_load ffwizard
config_foreach setup_ether ether

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	config_get ipaddr ffwizard dhcp_ip
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		OCTET_4="${NETWORK##*.}"
		OCTET_1_3="${NETWORK%.*}"
		OCTET_4="$((OCTET_4 + 1))"
		ipaddr="$OCTET_1_3.$OCTET_4/$PREFIX"
	fi
	setup_bridge "$br_name" "$ipaddr"
else
	uci_remove network "$br_name" 2>/dev/null
	br_name="lan"
fi

#Setup wifi
config_foreach setup_wifi wifi "$br_name"


#Setup IP6 Prefix
config_get ip6prefix ffwizard ip6prefix
if [ -n "$ip6prefix" ] ; then
	uci_set network loopback ip6prefix "$ip6prefix"
	uci_remove network loopback srcip6prefix
else
	uci_remove network loopback ip6prefix
	uci_remove network loopback srcip6prefix
fi
r1=$(dd if=/dev/urandom bs=1 count=1 |hexdump -e '1/1 "%02x"')
r2=$(dd if=/dev/urandom bs=2 count=1 |hexdump -e '2/1 "%02x"')
r3=$(dd if=/dev/urandom bs=2 count=1 |hexdump -e '2/1 "%02x"')
uci_set network globals ula_prefix "fd$r1:$r2:$r3::/48"
uci_set dhcp frei_funk_ipv6 ip "fd$r1:$r2:$r3::1"

#Set lan defaults if not an freifunk interface
if [ -n "$lan_iface" ] ; then
	uci_set network lan device "br-lan"
	uci_set network lan proto "static"
	uci_set network lan ipaddr "192.168.42.1"
	uci_set network lan netmask "255.255.255.0"
	uci_set network lan ip6assign '64'
	uci_remove network lan ip6class
	uci_add_list network lan ip6class "local"
fi

#Set wan defaults if not an freifunk interface
if [ -n "$wan_iface" ] ; then
	uci_remove network wan ipaddr 2>/dev/null
	uci_remove network wan netmask 2>/dev/null
	uci_remove network wan ip6assign 2>/dev/null
	uci_remove network wan ip6class 2>/dev/null
	uci_set network wan proto "dhcp"
	uci_set network wan6 proto "dhcpv6"
fi

if [ "$br" == "1" ] ; then
	uci_remove network br$br_name ports
	config_load network
	for device in $br_ifaces ; do
		fports=""
		config_foreach get_ports device "$device"
		if [ -z "$fports" ] ; then
			uci_add_list network br$br_name ports "$device"
		else
			for port in $fports ; do
				uci_add_list network br$br_name ports "$port"
			done
		fi
	done
fi

if [ -n "$restore_ports" ] ; then
	config_load network
	for device in $restore_ports ; do
		fports=""
		config_foreach restore_portlist device "$device"
	done
fi


uci_commit network
uci_commit dhcp
uci_commit wireless
