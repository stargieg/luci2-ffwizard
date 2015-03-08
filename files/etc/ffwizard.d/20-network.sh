
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

setup_bridge() {
	local cfg=$1
	local ipaddr=$2
	setup_ip $cfg $ipaddr
	#for batman
	uci set network.fflandhcp.mtu=1532
	uci set network.fflandhcp.force_link=1
	#TODO
	#uci set network.fflandhcp.macaddr=$random?
	uci set network.fflandhcp.type=bridge
	uci commit
}

setup_iface() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
	config_get ipaddr $cfg mesh_ip
	setup_ip $cfg $ipaddr
	config_get ipaddr $cfg dhcp_ip "0"
	if [ "$ipaddr" != "0" ] ; then
		cfg_dhcp=$cfg"_dhcp"
		eval "$(ipcalc.sh $ipaddr)"
		OCTET_4="${NETWORK##*.}"
		OCTET_1_3="${NETWORK%.*}"
		OCTET_4="$((OCTET_4 + 1))"
		ipaddr="$OCTET_1_3.$OCTET_4"
		setup_ip $cfg_dhcp $ipaddr
		uci_set network $cfg_dhcp ifname "@"$cfg
	fi
}

setup_wifi() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get device $cfg device "0"
	[ "$device" == "0" ] && return
	logger -t "ffwizard_wifi" "Setup $cfg"
	#get valid hwmods
	local hw_a
	local hw_b
	local hw_g
	local hw_n
	info_data=$(ubus call iwinfo info '{ "device": "'$device'" }')
	json_load "$info_data"
	json_select hwmodes
	json_get_values hw_res
	for i in hw_res ; do
		case $i in
			a) hw_a=1 ;;
			b) hw_b=1 ;;
			g) hw_g=1 ;;
			n) hw_n=1 ;;
		esac
	done
	#get valid channel list
	local channels
	local valid_channel
	chan_data=$(ubus call iwinfo freqlist '{ "device": "'$device'" }')
	json_load "$chan_data"
	json_select results
	json_get_keys chan_res
	for i in $chan_res ; do
		json_select $i
		#check what channels are available
		json_get_var restricted restricted
		if [ $restricted == 0 ] ; then
				json_get_var channel channel
				channels="$channels $channel"
		fi
		json_select ".."
	do
	#get default channel depending on hw_mod
	[ $hw_a == 1 ] && def_channel=36
	[ $hw_b == 1 ] && def_channel=13
	[ $hw_g == 1 ] && def_channel=13
	config_get channel $cfg channel $def_channel
	local valid_channel
	for i in $channels ; do
		[ -z $valid_channel ] && valid_channel=$i
		if [ $channel == $i ] ; then
			valid_channel=$i
		fi
	done
	logger -t "ffwizard_wifi" "Channel $valid_channel"
	uci set wireless.$device.channel=$valid_channel
	uci set wireless.$device.disabled=0
	[ $hw_g == 1 ] && [ $hw_n == 1 ] && uci set wireless.$device.noscan=1
	[ $hw_n == 1 ] && uci set wireless.$device.htmode=HT40
	uci set wireless.wireless.$device.country=00
	[ $hw_a == 1 ] && wireless.$device.doth=0
	#read from Luci_ui
	uci set wireless.$device.distance=1000
	#Reduce the Broadcast distance and save Airtime
	[ $hw_n == 1 ] && uci set wireless.$device.basic_rate="5500 6000 9000 11000 12000 18000 24000 36000 48000 54000"
	#Set Man or Auto?
	#uci set wireless.$device.txpower=15
	#Save Airtime max 1000
	uci set wireless.$device.beacon_int=250
	#wifi-iface
	config_get olsr_mesh $cfg olsr_mesh "0"
	config_get mesh $cfg bat_mesh $olsr_mesh
	if [ mesh == 1 ] ; then
		local bssid
		logger -t "ffwizard_wifi" "mesch"
		cfg_mesh=$cfg"_mesh"
		uci set wireless.$cfg_mesh=wifi-iface
		uci set wireless.$cfg_mesh.device=$device
		uci set wireless.$cfg_mesh.mode=adhoc
		uci set wireless.$cfg_mesh.encryption=none
		uci set wireless.$cfg_mesh.ssid="intern-ch"$valid_channel".freifunk.net"
		if [ $valid_channel -gt 0 && $valid_channel -lt 10 ] ; then
			bssid=$valid_channel"2:CA:FF:EE:BA:BE"
		elif [ $valid_channel -eq 10 ] ; then
			bssid="02:CA:FF:EE:BA:BE"
		elif [ $valid_channel -gt 10 && $valid_channel -lt 15 ] ; then
			bssid=$(printf "%X" "$valid_channel")"2:CA:FF:EE:BA:BE"
		elif [ $valid_channel -gt 35 && $valid_channel -lt 100 ] ; then
			bssid="02:"$valid_channel":CA:FF:EE:EE"
		elif [ $valid_channel -gt 99 && $valid_channel -lt 199 ] ; then
			bssid="12:"$(printf "%02d" "$(expr $valid_channel - 100)")":CA:FF:EE:EE"
		fi
		uci set wireless.$cfg_mesh.bssid="$bssid"
		#uci set wireless.$cfg_mesh.doth
		uci set wireless.$cfg_mesh.network=$cfg_mesh
		uci set wireless.$cfg_mesh.mcast_rate=18000
		config_get ipaddr $cfg mesh_ip
		setup_ip $cfg_mesh $ipaddr
	fi
	config_get vap $cfg vap 0
	if [ $vap == 1 ] ; then
		logger -t "ffwizard_wifi" "Virtual AP"
		cfg_vap=$cfg"_vap"
		uci set wireless.$cfg_vap=wifi-iface
		uci set wireless.$cfg_vap.device=$device
		uci set wireless.$cfg_vap.mode=ap
		uci set wireless.$cfg_vap.mcast_rate=6000
		#uci set wireless.$cfg_vap.isolate=1
		uci set wireless.$cfg_vap.ssid=freifunk.net
		config_get vap_br $cfg vap_br 0
		if [ $vap_br == 1 ] ; then
			uci set wireless.$cfg_vap.network=fflandhcp
		else
			config_get ipaddr $cfg dhcp_ip
			uci set wireless.$cfg_vap.network=$cfg_vap
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 1))"
			ipaddr="$OCTET_1_3.$OCTET_4"
			setup_ip $cfg_vap $ipaddr
		fi
	fi
}

remove_wifi() {
	local cfg=$1
	uci_remove wireless $cfg
}

#Remove wifi ifaces
config_load wireless
config_foreach remove_wifi wifi-iface

#Setup ether and wifi
config_load ffwizard
config_foreach setup_iface ether
config_foreach setup_wifi wifi

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$enabled" == "1" ] ; then
	config_get ipaddr ffwizard dhcp_ip
	eval "$(ipcalc.sh $ipaddr)"
	OCTET_4="${NETWORK##*.}"
	OCTET_1_3="${NETWORK%.*}"
	OCTET_4="$((OCTET_4 + 1))"
	ipaddr="$OCTET_1_3.$OCTET_4"
	setup_bridge fflandhcp $ipaddr
fi
