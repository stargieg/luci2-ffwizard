
setup_dhcp() {
		local cfg_dhcp=$1
		local ipaddr=$2
		eval "$(ipcalc.sh $ipaddr)"
		OCTET_4="${NETWORK##*.}"
		OCTET_1_3="${NETWORK%.*}"
		OCTET_4="$((OCTET_4 + 2))"
		ipaddr="$OCTET_1_3.$OCTET_4"
		uci_add dhcp dhcp $cfg_dhcp
		uci_set dhcp $cfg_dhcp interface $cfg_dhcp
		uci_set dhcp $cfg_dhcp start $ipaddr
		limit=$(($((2**$((32-$PREFIX))))-2))
		uci_set dhcp $cfg_dhcp limit $limit
		uci_set dhcp $cfg_dhcp leasetime '15m'
		#uci_set dhcp $cfg_dhcp list dhcp_option '119,olsr'
		/sbin/uci add_list dhcp.$cfg_dhcp.dhcp_option="119,olsr"
		/sbin/uci add_list dhcp.$cfg_dhcp.dhcp_option="119,lan"
		uci_set dhcp $cfg_dhcp ra server
		uci_set dhcp $cfg_dhcp dhcpv6 server
}

setup_iface() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
	config_get dhcp_ip $cfg dhcp_ip "0"
	if [ "$dhcp_ip" != "0" ] ; then
		cfg_dhcp=$cfg"_dhcp"
		if uci_get dhcp $cfg_dhcp >/dev/null ; then
			uci_remove dhcp $cfg_dhcp
		fi
		setup_dhcp $cfg_dhcp $ipaddr
	fi
}

setup_wifi() {
	local cfg=$1
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	logger -t "ffwizard_iface" "Setup $cfg"
	config_get dhcp_ip $cfg dhcp_ip "0"
	if [ "$dhcp_ip" != "0" ] ; then
		cfg_dhcp=$cfg"_dhcp"
		if uci_get dhcp $cfg_dhcp >/dev/null ; then
			uci_remove dhcp $cfg_dhcp
		fi
		setup_dhcp $cfg_dhcp $ipaddr
	fi
}

setup_dhcpbase() {
	local cfg=$1
	uci_set dhcp $cfg local '/olsr/'
	uci_set dhcp $cfg domain 'olsr'
}


local br_name="fflandhcp"

#Setup ether and wifi
config_load ffwizard
config_foreach setup_iface ether
config_foreach setup_wifi wifi $br_name

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	config_get ipaddr ffwizard dhcp_ip
	if uci_get dhcp $br_name >/dev/null ; then
		uci_remove dhcp $br_name
	fi
	setup_dhcp $br_name $ipaddr
fi

uci_commit dhcp

/etc/init.d/dnsmasq restart
/etc/init.d/odhcpd restart
