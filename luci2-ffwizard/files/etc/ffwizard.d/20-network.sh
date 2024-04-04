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
	if ! uci_get network $cfg 2>/dev/null 1>/dev/null ; then
		uci_add network interface "$cfg"
	fi
	if [ ! -z "$device" ] ; then
		uci_set network $cfg device "$device"
	fi
	if [ ! -z "$ipaddr" ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_set network $cfg ipaddr "$IP"
		uci_set network $cfg netmask "$NETMASK"
	else
		if [ "$cfg" == "lan" ] ; then
			#Magemant Access via lan ipv4
			uci_set network $cfg ipaddr "192.168.1.1"
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
	config_get type $cfg type 2>/dev/null
	if [ "$type" == "bridge" ] ; then
		config_get ports $cfg ports 2>/dev/null
		if [ -z "$ports" ] ; then
			config_get ports $cfg _ports 2>/dev/null
		else
			uci_remove network $cfg ports
			for port in $ports ; do
				uci_add_list network $cfg _ports $port
			done
		fi
	else
		ports="$name"
	fi
	for port in $ports ; do
		uci_add_list network br$br_name ports "$port"
	done
}

restore_portlist() {
	local cfg="$1"
	local gname="$2"
	config_get name $cfg name
	[ "$name" == "$gname" ] || return
	config_get ports $cfg _ports
	fports="$fports $ports"
	uci_remove network $cfg _ports 2>/dev/null
	for port in $ports ; do
		log_net "restore_portlist $cfg $gname $port"
		uci_add_list network $cfg ports $port
	done
}

setup_bridge() {
	local cfg="$1"
	local ipaddr="$2"
	if [ "$compat" == "1" ] ; then
		setup_ip $cfg "$ipaddr"
		#for batman
		uci_set network $cfg bridge_empty "1"
		uci_set network $cfg mtu "1532"
		#TODO
		#uci_set network $cfg macaddr "$random"?
		uci_set network $cfg type "bridge"
		uci_set network $cfg ifname "$ifc"
	else
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
		#r1=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null |hexdump -e '1/1 "%02x"')
		#r2=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null |hexdump -e '1/1 "%02x"')
		#r3=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null |hexdump -e '1/1 "%02x"')
		#r4=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null |hexdump -e '1/1 "%02x"')
		#r5=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null |hexdump -e '1/1 "%02x"')
		#r6=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null |hexdump -e '1/1 "%02x"')
		#uci_set network br$cfg macaddr "$r1:$r2:$r3:$r4:$r5:$r6"
	fi
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0" 2>/dev/null
	config_get dhcp_br $cfg dhcp_br "0" 2>/dev/null
	if [ "$dhcp_br" == "0" ] || [ "$enabled" == "0" ] ; then
		if [ "$compat" == "1" ] ; then
			device="$(uci_get network $cfg _ifname)"
		else
			device="$(uci_get network $cfg _device)"
		fi
		if [ ! -z "$device" ] ; then
			log_net "Setup $cfg with device $device"
			restore_ports="$restore_ports $device"
		fi
		[ "$enabled" == "0" ] && return
	fi
	cfg_dhcp=$cfg"_dhcp"
	uci_remove network $cfg_dhcp 2>/dev/null
	if [ "$dhcp_br" == "1" ] ; then
		log_net "Setup $cfg as DHCP Bridge member"
		if uci_get network $cfg 2>/dev/null 1>/dev/null ; then
			if [ "$compat" == "1" ] ; then
				device="$(uci_get network $cfg ifname)"
				if [ ! -z "$device" ] ; then
					uci_set network $cfg _ifname "$device"
					uci_remove network $cfg type 2>/dev/null
					uci_remove network $cfg ifname 2>/dev/null
				else
					device="$(uci_get network $cfg _ifname)"
				fi
			else
				device="$(uci_get network $cfg device)"
				if [ ! -z "$device" ] ; then
					uci_set network $cfg _device "$device"
					uci_remove network $cfg device 2>/dev/null
				else
					device="$(uci_get network $cfg _device)"
				fi
			fi
			if [ ! -z "$device" ] ; then
				br_ifaces="$br_ifaces $device"
			fi
			uci_set network $cfg proto "none"
			uci_set network "$cfg"6 proto "none"
			uci_remove network "$cfg"6 device 2>/dev/null
		fi
	else
		log_net "Setup $cfg IP"
		config_get ipaddr $cfg mesh_ip 2>/dev/null
		setup_ip "$cfg" "$ipaddr"
		config_get ipaddr $cfg dhcp_ip 2>/dev/null
		uci_remove network $cfg ip6class 2>/dev/null
		if [ ! -z "$ipaddr" ] ; then
			uci_remove network $cfg ip6assign 2>/dev/null
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 1))"
			ipaddr="$OCTET_1_3.$OCTET_4"
			setup_ip "$cfg_dhcp" "$ipaddr/$PREFIX"
			uci_set network $cfg_dhcp device "@$cfg"
		else
			uci_set network $cfg ip6assign "64"
			uci_add_list network $cfg ip6class "local"
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
	config_get enabled $cfg enabled "0" 2>/dev/null
	[ "$enabled" == "0" ] && return
	config_get idx $cfg phy_idx "-1" 2>/dev/null
	[ "$idx" == "-1" ] && return
	local device="radio$idx"
	log_wifi "Setup $cfg"
	#get valid hwmods
	local hw_a=0
	local hw_b=0
	local hw_g=0
	local hw_n=0
	local hw_ac=0
	local info_data
	info_data=$(ubus call iwinfo info '{ "device": "phy'$idx'" }' 2>/dev/null)
	[ -z "$info_data" ] && {
		log_wifi "ERR No iwinfo data for phy$idx"
		return 1
	}
	json_load "$info_data"
	json_select hwmodes
	# hwmodes list "n","ac"
	json_get_values hw_res
	[ -z "$hw_res" ] && {
		log_wifi "ERR No iwinfo hwmodes for phy$idx"
		return 1
	}
	for i in $hw_res ; do
		case $i in
			a) hw_a=1 ;;
			b) hw_b=1 ;;
			g) hw_g=1 ;;
			n) hw_n=1 ;;
			ac) hw_ac=1 ;;
		esac
	done
	json_select ".."
	#get valid htmods
	local ht_ht20=0
	local ht_ht40=0
	local ht_vht20=0
	local ht_vht40=0
	local ht_vht80=0
	local ht_vht160=0
	json_select htmodes
	# htmodes list "HT20","HT40","VHT20","VHT40","VHT80","VHT160"
	json_get_values ht_res
	for i in $ht_res ; do
		case $i in
			VHT20) ht_vht20=1 ;;
			VHT40) ht_vht40=1 ;;
			VHT80) ht_vht80=1 ;;
			VHT160) ht_vht160=1 ;;
			HT20) ht_ht20=1 ;;
			HT40) ht_ht40=1 ;;
		esac
	done
	#get valid channel list
	local channels
	local valid_channel
	local chan_data
	chan_data=$(ubus call iwinfo freqlist '{ "device": "phy'$idx'" }' 2>/dev/null)
	[ -z "$chan_data" ] && {
		log_wifi "ERR No iwinfo freqlist for phy$idx"
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
	[ "$hw_b" == 1 ] && def_channel=13
	[ "$hw_g" == 1 ] && def_channel=13
	[ "$hw_a" == 1 ] && def_channel=36
	[ "$hw_n" == 1 ] && def_channel=36
	[ "$hw_ac" == 1 ] && def_channel=36
	config_get channel $cfg channel "$def_channel"
	local valid_channel
	for i in $channels ; do
		[ -z "$valid_channel" ] && valid_channel="$i"
		if [ "$channel" == "$i" ] ; then
			valid_channel="$i"
		fi
	done
	local htmode
	if [ "$hw_n" == 1 ] ; then
		[ "$ht_ht20" == 1 ] && htmode="HT20"
		[ "$ht_ht40" == 1 ] && htmode="HT40"
	fi
	if [ "$hw_ac" == 1 ] ; then
		[ "$ht_vht20" == 1 ] && htmode="VHT20"
		[ "$ht_vht40" == 1 ] && htmode="VHT40"
		[ "$ht_vht80" == 1 ] && htmode="VHT80"
		[ "$ht_vht160" == 1 ] && htmode="VHT160"
	fi
	if [ ! -z "$htmode" ] ; then
		uci_set wireless $device htmode "$htmode"
	fi
	log_wifi "Channel $valid_channel htmode $htmode"
	uci_set wireless $device channel "$valid_channel"
	uci_set wireless $device disabled "0"
	uci_set wireless $device noscan "1"
	uci_set wireless $device country "DE"
	uci_set wireless $device legacy_rates "0"
	#read from Luci_ui
	uci_set wireless $device distance "500"
	if [ ! "$compat" = "1" ] ; then
		uci_set wireless $device cell_density '0'
	fi
	#Save Airtime max 1000
	uci_set wireless $device beacon_int "250"
	#wifi-iface
	config_get olsr_mesh $cfg olsr_mesh "0"
	config_get bat_mesh $cfg bat_mesh "0"
	#todo grep Device supports
	#iw phy phy0 info | grep IBSS
	#iw phy phy0 info | grep "mesh point"
	#iw phy phy0 info | grep "AP"
	config_get iface_mode $cfg iface_mode "mesh"
	if [ "$olsr_mesh" == "1" -o "$bat_mesh" == "1" ] ; then
		local bssid
		log_wifi "mesh"
		cfg_mesh=$cfg"_mesh"
		uci_add wireless wifi-iface "$device"mesh ; sec="$CONFIG_SECTION"
		uci_set wireless $sec device "$device"
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
			[ $hw_ac == 1 ] && uci_set wireless $device htmode "VHT20"
			uci_set wireless $sec mode "mesh"
			uci_set wireless $sec mesh_id 'freifunk'
			uci_set wireless $sec mesh_fwding '0'
			uci_set wireless $sec mesh_rssi_threshold '0'
		fi
		uci_set wireless $sec network "$cfg_mesh"
		uci_set wireless $sec mcast_rate "18000"
		uci_set wireless $sec encryption "none"
		config_get ipaddr $cfg mesh_ip
		setup_ip "$cfg_mesh" "$ipaddr"
		uci_remove network $cfg_mesh ip6class 2>/dev/null
		uci_add_list network $cfg_mesh ip6class "local"
	else
		if uci_get network $cfg 2>/dev/null 1>/dev/null ; then
			cfg_mesh=$cfg"_mesh"
			uci_remove network "$cfg_mesh" 2>/dev/null
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
		uci_set wireless $sec encryption "none"
		config_get vap_br $cfg vap_br "0"
		if [ $vap_br == 1 ] ; then
			uci_set wireless $sec network "$br_name"
		else
			config_get ipaddr $cfg dhcp_ip 2>/dev/null
			uci_set wireless $sec network "$cfg_vap"
			if [ ! -z "$ipaddr" ] ; then
				eval "$(ipcalc.sh $ipaddr)"
				OCTET_4="${NETWORK##*.}"
				OCTET_1_3="${NETWORK%.*}"
				OCTET_4="$((OCTET_4 + 1))"
				ipaddr="$OCTET_1_3.$OCTET_4"
				setup_ip "$cfg_vap" "$ipaddr/$PREFIX"
			else
				setup_ip "$cfg_vap"
			fi
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

. /etc/os-release
echo $VERSION | grep -q ^19* && compat=1

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
ula_uci=$(uci_get network globals ula_prefix)
ula_addr="$(echo $ula_uci | cut -d '/' -f 1)"
config_get ip6prefix ffwizard ip6prefix
if [ ! -z "$ip6prefix" ] ; then
	uci_set network loopback ip6prefix "$ip6prefix"
	ip6_addr="$(echo $ip6prefix | cut -d '/' -f 1)"
	uci_remove network globals srcip6prefix 2>/dev/null
	uci_remove network loopback ip6addr 2>/dev/null
	uci_add_list network loopback ip6addr "::1/128"
	uci_add_list network loopback ip6addr "$ula_addr""2/128"
	uci_add_list network loopback ip6addr "$ip6_addr""2/128"
#else
	#uci_remove network loopback ip6prefix 2>/dev/null
	#uci_remove network globals srcip6prefix 2>/dev/null
	#uci_remove network loopback ip6addr 2>/dev/null
	#uci_add_list network loopback ip6addr "::1/128"
	#uci_add_list network loopback ip6addr "$ula_addr""2/128"
fi

#Set lan defaults if not an freifunk interface
if [ ! -z "$lan_iface" ] ; then
	if [ "$compat" == "1" ] ; then
		uci_set network lan type "bridge"
	else
		uci_set network lan device "br-lan"
	fi
	uci_set network lan proto "static"
	uci_set network lan ipaddr "192.168.1.1"
	uci_set network lan netmask "255.255.255.0"
	uci_set network lan ip6assign '64'
	uci_remove network lan ip6class 2>/dev/null
	uci_add_list network lan ip6class "local"
fi

#Set wan defaults if not an freifunk interface
if [ ! -z "$wan_iface" ] ; then
	uci_remove network wan ipaddr 2>/dev/null
	uci_remove network wan netmask 2>/dev/null
	uci_remove network wan ip6assign 2>/dev/null
	uci_remove network wan ip6class 2>/dev/null
	uci_set network wan proto "dhcp"
	uci_set network wan6 proto "dhcpv6"
fi

if [ "$br" == "1" ] ; then
	if [ "$compat" == "1" ] ; then
		config_load network
		config_get ifname $br_name ifname
		uci_set network $br_name _ifname "$ifname"
	else
		uci_remove network br$br_name ports 2>/dev/null
		config_load network
		for device in $br_ifaces ; do
			config_foreach get_ports device "$device"
		done
	fi
fi

if [ ! -z "$restore_ports" ] ; then
	config_load network
	for device in $restore_ports ; do
		if [ "$compat" == "1" ] ; then
			config_get ifname $br_name _ifname
			uci_set network $br_name ifname "$ifname"
		else
			fports=""
			config_foreach restore_portlist device "$device"
		fi
	done
fi


uci_commit network
uci_commit dhcp
uci_commit wireless
