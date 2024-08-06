#!/bin/sh

. /lib/functions.sh

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

chk_red() {
	local cfg=$1
	config_get ip $cfg ip
	[ "$ip" == "64:ff9b::/96" ] && exit 1
	[ "$ip" == "::/0" ] && exit 1
}

if ! ubus list babeld >/dev/null ; then
	log "babeld ubus-mod not running"
	return 1
fi

config_load babeld
config_foreach chk_red filter

if pidof babeldns64.sh | grep -q ' ' >/dev/null ; then
	log "killall babeldns64.sh"
	killall -9 babeldns64.sh
	return 1
fi

dns64nodeid=""
metric=65535
ubus call babeld get_routes | \
jsonfilter -e '@.IPv6[@.address="64:ff9b::/96"]' > /tmp/babeldns64.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'id=@.id' \
		-e 'refmetric=@.refmetric')
	if [ "$installed" == "1" ] ; then
		if [ $refmetric -lt $metric ] ; then
			dns64nodeid="$id"
			metric=$refmetric
		fi
	fi
done < /tmp/babeldns64.json
rm /tmp/babeldns64.json

if [ "$dns64nodeid" == "" ] ; then
	log "Exit no IPv6 neighbor entry"
fi

dns_server=""
ubus call babeld get_routes | \
jsonfilter -e '@.IPv6[@.id="'$dns64nodeid'"]' > /tmp/babeldns64.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'address=@.address' \
		-e 'src_prefix=@.src_prefix' \
		-e 'refmetric=@.refmetric')
	if [ "$installed" == "1" -a "$address" != "::/0" -a "$address" != "64:ff9b::/96" ] ; then
		node="$address"
		node=${node%:*}
		node="$node"":1"
		dns=""
		if ping6 -c1 -W3 -q "$node" >/dev/null ; then
			nslookup "twitter.com" $node | grep -q '64:ff9b::' && dns="$node"
			nslookup "v4.ipv6-test.com" $node | grep -q '64:ff9b::' && dns="$node"
			nslookup "ipv4.lookup.test-ipv6.com" $node | grep -q '64:ff9b::' && dns="$node"
			nslookup "ipv4.google.com" $node | grep -q '64:ff9b::' && dns="$node"
			if [ -z "$dns" ] ; then
				log "Node $node no service"
			else
				dns=""
				ping6 -c1 -W3 -q "twitter.com" && dns="$node"
				ping6 -c1 -W3 -q "v4.ipv6-test.com" && dns="$node"
				ping6 -c1 -W3 -q "ipv4.lookup.test-ipv6.com" && dns="$node"
				ping6 -c1 -W3 -q "ipv4.google.com" && dns="$node"
				if [ -z "$dns" ] ; then
					log "Node $node no service"
				else
					dns_server="$dns_server $dns"
				fi
			fi
		else
			log "Node $node unreachable"
		fi
	fi
done < /tmp/babeldns64.json

nat64=$(uci_get dhcp @dnsmasq[-1] nat64)
if ! [ -z "$dns_server" ] ; then
	log "found nat64 on $dns_server"
	if [ "$nat64" == "1" ] ; then
		uciserver=" $(uci_get dhcp @dnsmasq[-1] server)"
	fi
	#Add more dns64 server for redundancy
	#https://developers.cloudflare.com/1.1.1.1/infrastructure/ipv6-networks/
	dns_server="$dns_server 2606:4700:4700::64 2606:4700:4700::6400"
	#https://developers.google.com/speed/public-dns/docs/dns64
	dns_server="$dns_server 2001:4860:4860::64 2001:4860:4860::6464"
	if ! [ "$dns_server" == "$uciserver" ] ; then
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
		/etc/init.d/dnsmasq restart
	fi
else
	log "not found"
	if [ "$nat64" == "1" ] ; then
		uci_remove dhcp @dnsmasq[-1] nat64
		uci_remove dhcp @dnsmasq[-1] server
		uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2c::1"
		uci_add_list dhcp @dnsmasq[-1] server "2a01:4f8:c2c:123f::1"
		uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2b::1"
		uci_commit dhcp
		config_load dhcp
		config_foreach setup_dhcp_ra_pref_default dhcp
		uci_commit dhcp
		/etc/init.d/dnsmasq restart
	fi
fi
rm -f /tmp/babeldns64.json
