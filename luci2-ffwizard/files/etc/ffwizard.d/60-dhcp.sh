
log_dhcp() {
	logger -s -t ffwizard_dhcp $@
}

setup_dhcp() {
		local cfg_dhcp="$1"
		local ipaddr="$2"
		if uci_get dhcp $cfg_dhcp >/dev/null ; then
			uci_remove dhcp $cfg_dhcp
		fi
		uci_add dhcp dhcp $cfg_dhcp
		uci_set dhcp $cfg_dhcp interface "$cfg_dhcp"
		if [ -n "$ipaddr" ] ; then
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 2))"
			ipaddr="$OCTET_1_3.$OCTET_4"
			uci_set dhcp $cfg_dhcp start "$ipaddr"
			limit=$(($((2**$((32-$PREFIX))))-2))
			uci_set dhcp $cfg_dhcp limit "$limit"
		fi
		uci_set dhcp $cfg_dhcp leasetime "15m"
		#uci_set dhcp $cfg_dhcp list dhcp_option "119,olsr"
		/sbin/uci add_list dhcp.$cfg_dhcp.dhcp_option="119,olsr"
		/sbin/uci add_list dhcp.$cfg_dhcp.dhcp_option="119,lan"
		uci_set dhcp $cfg_dhcp dhcpv6 "server"
		uci_set dhcp $cfg_dhcp ra "server"
		uci_set dhcp $cfg_dhcp ra_preference "low"
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_ip $cfg dhcp_ip "0"
	if [ "$dhcp_ip" != "0" ] ; then
		logger -t "ffwizard_dhcp_ether" "Setup $cfg"
		cfg_dhcp=$cfg"_dhcp"
		setup_dhcp $cfg_dhcp "$ipaddr"
	fi
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get dhcp_ip $cfg dhcp_ip "0"
	if [ "$dhcp_ip" != "0" ] ; then
		logger -t "ffwizard_dhcp_wifi" "Setup $cfg"
		cfg_dhcp=$cfg"_vap"
		setup_dhcp $cfg_dhcp "$dhcp_ip"
	fi
}

setup_dhcpbase() {
	local cfg="$1"
	uci_set dhcp $cfg local "/olsr/"
	uci_set dhcp $cfg domain "olsr"
}

setup_odhcpbase() {
	local cfg="$1"
	uci_set dhcp $cfg maindhcp "1"
}

local br_name="fflandhcp"
#Load dhcp config
config_load dhcp
#Setup dnsmasq
config_foreach setup_dhcpbase dnsmasq

#Setup odhcpd
config_foreach setup_odhcpbase odhcpd

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi $br_name

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	log_dhcp "Setup iface $br_name"
	config_get ipaddr ffwizard dhcp_ip
	setup_dhcp $br_name $ipaddr
fi

uci_commit dhcp
