
uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

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
		uci_set dhcp $cfg_dhcp ignore "0"
		if [ -n "$ipaddr" ] ; then
			uci_set dhcp $cfg_dhcp ignore "0"
			eval "$(ipcalc.sh $ipaddr)"
			OCTET_4="${NETWORK##*.}"
			OCTET_1_3="${NETWORK%.*}"
			OCTET_4="$((OCTET_4 + 2))"
			start_ipaddr="$OCTET_4"
			uci_set dhcp $cfg_dhcp start "$start_ipaddr"
			limit=$(($((2**$((32-$PREFIX))))-2))
			uci_set dhcp $cfg_dhcp limit "$limit"
		else
			#ignore was over writen by dhcpv6 "server"
			uci_set dhcp $cfg_dhcp ignore "1"
			uci_set dhcp $cfg_dhcp dhcpv4 "disabled"
		fi
		uci_set dhcp $cfg_dhcp leasetime "2m"
		uci_add_list dhcp $cfg_dhcp dhcp_option "119,olsr"
		uci_add_list dhcp $cfg_dhcp domain "olsr"
		uci_set dhcp $cfg_dhcp dhcpv6 "server"
		uci_set dhcp $cfg_dhcp ra "server"
		uci_set dhcp $cfg_dhcp ra_preference "low"
		uci_set dhcp $cfg_dhcp ra_default "2"
		uci_set dhcp $cfg_dhcp ra_useleasetime "1"
		uci_set dhcp $cfg_dhcp preferred_lifetime "2m"
		uci_add_list dhcp $cfg_dhcp ra_flags "managed-config"
		uci_add_list dhcp $cfg_dhcp ra_flags "other-config"
		uci_set dhcp $cfg_dhcp ffwizard "1"
}

setup_dhcp_ignore() {
		local cfg_dhcp="$1"
		uci_remove dhcp $cfg_dhcp >/dev/null 2>/dev/null
		uci_add dhcp dhcp $cfg_dhcp
		uci_set dhcp $cfg_dhcp interface "$cfg_dhcp"
		uci_set dhcp $cfg_dhcp ignore "1"
		uci_set dhcp $cfg_dhcp ffwizard "1"
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	if [ "$enabled" == "0" ] ; then
		ff_restore=$(uci_get dhcp $cfg ffwizard "0")
		if [ "$ff_restore" == "1" ] ; then
			uci_remove dhcp $cfg_dhcp 2>/dev/null
			if [ "$cfg" == "lan" ] ; then
				uci_add dhcp dhcp $cfg
				uci_set dhcp $cfg interface "$cfg"
				uci_set dhcp $cfg ignore "0"
				uci_set dhcp $cfg start "100"
				uci_set dhcp $cfg limit "150"
				uci_set dhcp $cfg leasetime "2m"
				uci_add_list dhcp $cfg dhcp_option "119,olsr"
				uci_add_list dhcp $cfg domain "olsr"
				uci_set dhcp $cfg dhcpv6 "server"
				uci_set dhcp $cfg ra "server"
				uci_set dhcp $cfg ra_preference "low"
				uci_set dhcp $cfg ra_default "1"
				uci_set dhcp $cfg preferred_lifetime "2m"
				uci_add_list dhcp $cfg ra_flags "managed-config"
				uci_add_list dhcp $cfg ra_flags "other-config"
			else
				uci_add dhcp dhcp $cfg
				uci_set dhcp $cfg interface "$cfg"
				uci_set dhcp $cfg ignore "1"
			fi
		fi
		return
	fi
	config_get dhcp_ip $cfg dhcp_ip "0"
	cfg_dhcp=$cfg"_dhcp"
	uci_remove dhcp $cfg_dhcp 2>/dev/null
	uci_remove dhcp $cfg 2>/dev/null
	if [ "$dhcp_ip" != "0" ] ; then
		log_dhcp "Setup $cfg"
		setup_dhcp $cfg
		setup_dhcp $cfg_dhcp "$dhcp_ip"
	else
		config_get dhcp_br $cfg dhcp_br "0"
		config_get mesh_ip $cfg mesh_ip "0"
		if [ "$cfg" == "lan" ] && [ "$mesh_ip" == "0" ] && [ "$dhcp_br" == "0" ] ; then
			log_dhcp "Setup iface $cfg to default ip 192.168.1.1/24 ?"
			#setup_dhcp $cfg "192.168.1.1/24"
			setup_dhcp $cfg
		else
			log_dhcp "Setup iface $cfg ignore"
			setup_dhcp_ignore $cfg
		fi
	fi
	case $cfg in
		lan) lan_iface="";;
		wan) wan_iface="";;
	esac
}

setup_wifi() {
	local cfg="$1"
	local cfg_dhcp=$cfg"_vap"
	local cfg_mesh=$cfg"_mesh"
	uci_get dhcp $cfg ffwizard && \
	uci_remove dhcp $cfg
	uci_get dhcp $cfg_dhcp ffwizard && \
	uci_remove dhcp $cfg_dhcp
	uci_get dhcp $cfg_mesh ffwizard && \
	uci_remove dhcp $cfg_mesh
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	config_get babel_mesh $cfg babel_mesh "0"
	if [ "$olsr_mesh" == "1" -o "$babel_mesh" == "1" ] ; then
		log_dhcp "Setup "$cfg"_mesh with"
		setup_dhcp_ignore $cfg"_mesh"
	fi
	config_get vap $cfg vap "0"
	config_get vap_br $cfg vap_br "0"
	if [ "$vap_br" == "0" -a "$vap" == "1" ] ; then
		log_dhcp "Setup $cfg with $dhcp_ip"
		config_get dhcp_ip $cfg dhcp_ip
		setup_dhcp $cfg_dhcp "$dhcp_ip"
		uci_add_list dhcp $cfg_dhcp dns "fd53::1"
	fi
}

setup_dhcpbase() {
	local cfg="$1"
	uci_set dhcp $cfg local "/olsr/"
	uci_set dhcp $cfg domain "olsr"
	uci_set dhcp $cfg localservice "0"
	uci_set dhcp $cfg add_local_fqdn "1"
	uci_set dhcp $cfg add_wan_fqdn "1"
	uci_set dhcp $cfg rebind_protection "0"
	# https://nat64.net/
	uci_remove dhcp @dnsmasq[-1] nat64 2>/dev/null
	uci_remove dhcp @dnsmasq[-1] server 2>/dev/null
	uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2c::1"
	uci_add_list dhcp @dnsmasq[-1] server "2a01:4f8:c2c:123f::1"
	uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2b::1"
	uci_set dhcp @dnsmasq[-1] allservers "1"
}

setup_odhcpbase() {
	local cfg="$1"
	uci_set dhcp $cfg maindhcp "0"
}

restore_iface=""
br_name="fflandhcp"
lan_iface="lan"
wan_iface="wan"
#Load dhcp config
config_load dhcp
#Setup dnsmasq
config_foreach setup_dhcpbase dnsmasq

#Setup odhcpd
config_foreach setup_odhcpbase odhcpd

#Setup ether and wifi
config_load ffwizard
config_foreach setup_ether ether
config_foreach setup_wifi wifi

#Setup DHCP Batman Bridge
config_get br ffwizard br "0"
if [ "$br" == "1" ] ; then
	config_get dhcp_ip ffwizard dhcp_ip
	log_dhcp "Setup iface $br_name with ip $dhcp_ip"
	setup_dhcp $br_name $dhcp_ip
	uci_remove dhcp $br_name dns 2>/dev/null
	uci_add_list dhcp $br_name dns "fd53::1"
else
	if uci_get dhcp $br_name >/dev/null ; then
		log_dhcp "Setup $br_name remove"
		uci_remove dhcp $br_name 2>/dev/null
	fi
fi

#Enable dhcp on LAN
if [ -n "$lan_iface" ] ; then
	log_dhcp "Setup iface $lan_iface to default"
	setup_dhcp $lan_iface
fi

#Disable dhcp on WAN
if [ -n "$wan_iface" ] ; then
	log_dhcp "Setup iface $wan_iface to default"
	setup_dhcp_ignore $wan_iface
fi

uci_add dhcp domain openwrt 2>/dev/null
uci_set dhcp openwrt name "openwrt"
uci_set dhcp openwrt ip "fd53::1"
uci_add dhcp domain openwrt_lan 2>/dev/null
uci_set dhcp openwrt name "openwrt.lan"
uci_set dhcp openwrt ip "fd53::1"

uci_commit dhcp
# restart service dnsmasq and odhcpd
mkdir -p /tmp/ff
touch /tmp/ff/dnsmasq
touch /tmp/ff/odhcpd
