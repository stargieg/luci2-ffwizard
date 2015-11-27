
log_net() {
	logger -s -t ffwizard_net $@
}

log_wifi() {
	logger -s -t ffwizard_wifi $@
}

setup_ip() {
	local cfg="$1"
	local ipaddr="$2"
	if ! uci_get network $cfg >/dev/null ; then
		uci_add network interface "$cfg"
	fi
	if [ -n "$ipaddr" ] ; then
		eval "$(ipcalc.sh $ipaddr)"
		uci_set network $cfg ipaddr "$IP"
		uci_set network $cfg netmask "$NETMASK"
	else
		uci_remove network $cfg ipaddr 2>/dev/null
		uci_remove network $cfg netmask 2>/dev/null
	fi
	uci_set network $cfg proto "static"
	uci_set network $cfg ip6assign "64"
}

setup_bridge() {
	local cfg="$1"
	local ipaddr="$2"
	local ifc="$3"
	setup_ip $cfg "$ipaddr"
	#for batman
	uci_set network $cfg mtu "1532"
	uci_set network $cfg force_link "1"
	#TODO
	#uci_set network $cfg macaddr "$random"?
	uci_set network $cfg type "bridge"
	uci_set network $cfg ifname "$ifc"
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_br $cfg dhcp_br "0"
	if [ "$dhcp_br" == "1" ] ; then
		log_net "Setup $cfg as DHCP Bridge member"
		if uci_get network $cfg >/dev/null ; then
			ifname="$(uci_get network $cfg ifname)"
			if [ -n "$ifname" ] ; then
				br_ifaces="$br_ifaces $ifname"
			fi
			uci_set network $cfg proto "none"
			uci_remove network $cfg type
		fi
	else
		log_net "Setup $cfg IP"
		config_get mesh_ip $cfg mesh_ip
		setup_ip "$cfg" "$mesh_ip"
		config_get dhcp_ip $cfg dhcp_ip "0"
		if [ "$dhcp_ip" != "0" ] ; then
			cfg_dhcp=$cfg"_dhcp"
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 1))"
			ipaddr="$OCTET_1_3.$OCTET_4"
			setup_ip "$cfg_dhcp" "$ipaddr/$PREFIX"
			uci_set network $cfg_dhcp ifname "@$cfg"
		fi
	fi
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
	info_data=$(ubus call iwinfo info '{ "device": "wlan'$idx'" }' 2>/dev/null)
	[ -z $info_data ] && {
		log_wifi "ERR No iwinfo hwmodes for wlan$idx"
		return 1
	}
	json_load "$info_data"
	json_select hwmodes
	json_get_values hw_res
	[ -z "$hw_res" ] && return
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
	chan_data=$(ubus call iwinfo freqlist '{ "device": "wlan'$idx'" }' 2>/dev/null)
	[ -z $chan_data ] && {
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
	[ $hw_n == 1 ] && uci_set wireless $device htmode "HT40"
	uci_set wireless $device country "00"
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
	if [ "$olsr_mesh" == "1" -o "$bat_mesh" == "1" ] ; then
		local bssid
		log_wifi "mesh"
		cfg_mesh=$cfg"_mesh"
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
		uci_set wireless $sec device "$device"
		uci_set wireless $sec mode "adhoc"
		uci_set wireless $sec encryption "none"
		uci_set wireless $sec ssid "intern-ch"$valid_channel".freifunk.net"
		if [ $valid_channel -gt 0 -a $valid_channel -lt 10 ] ; then
			bssid=$valid_channel"2:CA:FF:EE:BA:BE"
		elif [ $valid_channel -eq 10 ] ; then
			bssid="02:CA:FF:EE:BA:BE"
		elif [ $valid_channel -gt 10 -a $valid_channel -lt 15 ] ; then
			bssid=$(printf "%X" "$valid_channel")"2:CA:FF:EE:BA:BE"
		elif [ $valid_channel -gt 35 -a $valid_channel -lt 100 ] ; then
			bssid="02:"$valid_channel":CA:FF:EE:EE"
		elif [ $valid_channel -gt 99 -a $valid_channel -lt 199 ] ; then
			bssid="12:"$(printf "%02d" "$(expr $valid_channel - 100)")":CA:FF:EE:EE"
		fi
		uci_set wireless $sec bssid "$bssid"
		#uci_set wireless $sec "doth"
		uci_set wireless $sec network "$cfg_mesh"
		uci_set wireless $sec mcast_rate "18000"
		config_get ipaddr $cfg mesh_ip
		setup_ip "$cfg_mesh" "$ipaddr"
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
		uci_add wireless wifi-iface ; sec="$CONFIG_SECTION"
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
	uci_set wireless "$cfg" country "00"
	uci_set wireless "$cfg" disabled "0"
}

remove_wifi() {
	local cfg="$1"
	uci_remove wireless "$cfg"
}

local br_ifaces
local br_name="fflandhcp"

#Remove wireless config
rm /etc/config/wireless
/sbin/wifi detect > /etc/config/wireless

#Set regdomain
config_load wireless
config_foreach regdomain wifi-device
uci_commit wireless
/sbin/wifi reload
sleep 5

#Remove wifi ifaces
config_foreach remove_wifi wifi-iface
uci_commit wireless


#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi "$br_name"

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
	setup_bridge "$br_name" "$ipaddr" "$br_ifaces"
else
	uci_remove network "$br_name" >/dev/null
fi

uci_commit network
uci_commit wireless
