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
#ubus call babeld get_routes | jsonfilter -e '@.IPv6.A' valid
#ubus call babeld get_routes | jsonfilter -e '@.IPv6.64' invalid
#label for object key is duplicated eg. "::/0" if more than one internet gateway
#BUG parser error
ubus call babeld get_routes | \
sed -e 's/^\t\t\(".*"\): {/\t\t\{\n\t\t\t"prefix": \1,/' \
-e 's/^\(\t".*": \){/\1[/' \
-e 's/^\t}/\t]/' \
-e 's/src-prefix/src_prefix/' | \
jsonfilter -e '@.IPv6[@.prefix="64:ff9b::\/96"]' > /tmp/babeldns64.json
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
sed -e 's/^\t\t\(".*"\): {/\t\t\{\n\t\t\t"prefix": \1,/' \
-e 's/^\(\t".*": \){/\1[/' \
-e 's/^\t}/\t]/' \
-e 's/src-prefix/src_prefix/' | \
jsonfilter -e '@.IPv6[@.id="'$dns64nodeid'"]' > /tmp/babeldns64.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'prefix=@.prefix' \
		-e 'src_prefix=@.src_prefix' \
		-e 'refmetric=@.refmetric')
	if [ "$installed" == "1" ] ; then
		if [ "$src_prefix" == "::/0" ] ; then
			node="$prefix"
			node=${node%:*}
			node="$node"":1"
			dns=""
			if ping6 -c1 -W3 -q "$node" >/dev/null ; then
				nslookup "twitter.com" $node | grep -q '64:ff9b::' && dns="$node"
				nslookup "v4.ipv6-test.com" $node | grep -q '64:ff9b::' && dns="$node"
				nslookup "ipv4.lookup.test-ipv6.com" $node | grep -q '64:ff9b::' && dns="$node"
				if [ -z "$dns" ] ; then
					log "Node $node no service"
				else
					dns_server="$dns_server $dns"
				fi
			else
				log "Node $node unreachable"
			fi
		fi
	fi
done < /tmp/babeldns64.json

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
	nat64=$(uci_get dhcp @dnsmasq[-1] nat64)
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
		/etc/init.d/dnsmasq reload
	fi
fi
rm -f /tmp/babeldns64.json
