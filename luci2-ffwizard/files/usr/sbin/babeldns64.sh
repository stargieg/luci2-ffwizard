#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t babeldns64 $@
}

setup_dhcp_ra_pref_add() {
	local cfg=$1
	local prefix="64:ff9b::/96"
	config_get ra $cfg ra
	if [ "$ra" == "server" ] ; then
		uci_set dhcp "$cfg" ra_pref64 "$prefix"
		#normaly 1500 uplink
		#uci_set dhcp "$cfg" ra_mtu "1492"
		#ppoe 1492 uplink
		uci_set dhcp "$cfg" ra_mtu "1473"
		uci_remove dhcp "$cfg" dhcp_option 2>/dev/null
		uci_add_list dhcp $cfg dhcp_option "108,0:0:7:8"
	fi
}

setup_dhcp_ra_pref_default() {
	local cfg=$1
	config_get ra $cfg ra
	if [ "$ra" == "server" ] ; then
		uci_remove dhcp "$cfg" ra_pref64 2>/dev/null
		uci_remove dhcp "$cfg" ra_mtu 2>/dev/null
		uci_remove dhcp "$cfg" dhcp_option 2>/dev/null
	fi
}

if ! ubus list babeld >/dev/null ; then
	log "babeld ubus-mod not running"
	return 1
fi

if pidof babeldns64.sh | grep -q ' ' >/dev/null ; then
	log "killall babeldns64.sh"
	killall -9 babeldns64.sh
	return 1
fi

json_init
json_load "$(ubus call babeld get_routes)"
if ! json_select "IPv6" ; then
	log "Exit no IPv6 neighbor entry"
	return 1
fi

dns64nodes=""
log "id route_metric route_smoothed_metric refmetric"
json_get_keys keys
for key in $keys ; do
	if [ "$key" == "64_ff9b___97" ] ; then
		json_select ${key}
		json_get_var route_metric route_metric
		json_get_var route_smoothed_metric route_smoothed_metric
		json_get_var refmetric refmetric
		json_get_var id id
		log "$id $route_metric $route_smoothed_metric $refmetric"
		dns64nodes="$dns64nodes $id"
		json_select ..
	fi
done

dns_server=""
for dns64node in $dns64nodes ; do
	for key in $keys ; do
		json_select ${key}
		json_get_var id id
		if [ "$id" == "$dns64node" ] ; then
			node=${key//_/:}
			node=${node%:*}
			node="$node""1"
			dns=""
			if ping6 -c1 -W3 -q "$node" >/dev/null ; then
				log "$id $node"
				nslookup "twitter.com" $node | grep -q '64:ff9b::' && dns="$node"
				nslookup "v4.ipv6-test.com" $node | grep -q '64:ff9b::' && dns="$node"
				nslookup "ipv4.lookup.test-ipv6.com" $node | grep -q '64:ff9b::' && dns="$node"
			else
				log "Node $node unreachable"
			fi
			if ! [ -z "$dns" ] ; then
				log "dns $dns"
				dns_server="$dns_server $dns"
			fi
		fi
		json_select ..
	done
done
json_cleanup

if ! [ -z "$dns_server" ] ; then
	log "found nat64 on $dns_server"
	uci_set dhcp @dnsmasq[-1] rebind_protection "0"
	uci_set dhcp @dnsmasq[-1] nat64 "1"
	uci_remove dhcp @dnsmasq[-1] server 2>/dev/null
	for server in $dns_server ; do
		uci_add_list dhcp @dnsmasq[-1] server "$server"
	done
	uci_commit dhcp
	config_load dhcp
	config_foreach setup_dhcp_ra_pref_add dhcp
	uci_commit dhcp
	/etc/init.d/dnsmasq reload
else
	log "not found"
	uci_remove dhcp @dnsmasq[-1] nat64
	uci_remove dhcp @dnsmasq[-1] server
	uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2c::1"
	uci_add_list dhcp @dnsmasq[-1] server "2a01:4f8:c2c:123f::1"
	uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2b::1"
	uci_commit dhcp
	config_load dhcp
	config_foreach setup_dhcp_ra_pref_default dhcp
	uci_commit dhcp
	/etc/init.d/dnsmasq reload
fi
