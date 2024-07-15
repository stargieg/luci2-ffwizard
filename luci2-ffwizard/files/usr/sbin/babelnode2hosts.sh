#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t babelnode2hosts $@
}

if ! ubus list babeld >/dev/null ; then
	log "babeld ubus-mod not running"
	return 1
fi

if pidof babelnode2hosts.sh | grep -q ' ' >/dev/null ; then
	log "killall babelnode2hosts.sh"
	killall -9 babelnode2hosts.sh
	return 1
fi

json_init
json_load "$(ubus call babeld get_neighbours)"
if ! json_select "IPv6" ; then
	log "Exit no IPv6 neighbor entry"
	return 1
fi

llneighborips=""
llneighborip=""
json_get_keys keys
for key in $keys ; do
	llneighborip=""
	json_select ${key}
	json_get_var device dev
	#log "llneighborip ${key//_/:}%${device}"
	llneighborip="${key//_/:}%${device}"
	if ping6 -c1 -W3 -q "$llneighborip" >/dev/null ; then
		llneighborips="$llneighborips $llneighborip"
	fi
	json_select ..
done
json_cleanup

json_init
json_load "$(ubus call babeld get_routes)"
if ! json_select "IPv6" ; then
	log "Exit no IPv6 neighbor entry"
	return 1
fi
unbound=0
[ -x /usr/lib/unbound/babelv2node.sh ] && unbound=1
rm -f /tmp/babelnode2hosts.tmp
domain="$(uci_get system @system[-1] domain olsr)"
domain_custom=""
if [ ! "$domain" == "olsr" ] ; then
	domain_custom="$domain"
	domain="olsr"
fi
json_get_keys keys
for key in $keys ; do
	json_select ${key}
	node=${key//_/:}
	node=${node%:*}
	node=${node%::1}
	node=${node%::}
	node="$node""::1"
	ret=""
	for j in $llneighborips ; do
		[ -z $ret ] || continue
		nodename=$(nslookup $node $j | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
		nodeips=$(nslookup $nodename $j | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
		for k in $nodeips ; do
			if echo $k | grep -q -v ^fe ; then
				if echo $k | grep -q ^fd ; then
					echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
				else
					if [ -z "$domain_custom" ] ; then
						echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
					else
						echo "$k $nodename.$domain_custom $nodename.$domain" >>/tmp/babelnode2hosts.tmp
					fi
				fi
				ret="1"
			fi
		done
	done
	if [ -z $ret ] ; then
		nodename=$(nslookup $node $node | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
		nodeips=$(nslookup $nodename $node | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
		for k in $nodeips ; do
			if echo $k | grep -q -v ^fe ; then
				if echo $k | grep -q ^fd ; then
					echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
				else
					if [ -z "$domain_custom" ] ; then
						echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
					else
						echo "$k $nodename.$domain_custom $nodename.$domain" >>/tmp/babelnode2hosts.tmp
					fi
				fi
			fi
		done
	fi
	json_select ..
done
json_cleanup
mkdir -p /tmp/hosts
touch /tmp/hosts/babelneighbor

if [ -f /tmp/babelnode2hosts.tmp ] ; then
	if [ -f /tmp/hosts/babelnode ] ; then
		cat /tmp/babelnode2hosts.tmp | sort | uniq > /tmp/babelnode
		rm /tmp/babelnode2hosts.tmp
		new=$(md5sum /tmp/babelnode | cut -d ' ' -f 1)
		old=$(md5sum /tmp/hosts/babelnode | cut -d ' ' -f 1)
		if [ ! "$new" == "$old" ] ; then
			mv /tmp/babelnode /tmp/hosts/babelnode
			if [ $unbound == 0 ] ; then
				killall -HUP dnsmasq
			fi
		fi
	else
		cat /tmp/babelnode2hosts.tmp | sort > /tmp/hosts/babelnode
		rm /tmp/babelnode2hosts.tmp
		if [ $unbound == 0 ] ; then
			killall -HUP dnsmasq
		fi
	fi
fi
if [ $unbound == 1 ] ; then
	/usr/lib/unbound/babelnode.sh
fi
