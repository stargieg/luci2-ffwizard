#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh
. /lib/functions/network.sh

log() {
	logger -t babelneighbor2hosts $@
}

print_interface() {
	local cfg=$1
	local hostname=$2
	local out=$3
	network_get_ipaddrs6 lanaddrs6 "$cfg"
	for i in $lanaddrs6 ; do
		if [ ! "$i" = "::1" ] ; then
			if echo "$i" | grep -q -v ^fe ; then
				echo "$i" "$hostname" >> "$out"
			fi
		fi
	done
}

if ! ubus list babeld >/dev/null ; then
	log "babeld ubus-mod not running"
	return 1
fi

if pidof babelneighbor2hosts.sh | grep -q ' ' >/dev/null ; then
	log "killall babelneighbor2hosts.sh"
	killall -9 babelneighbor2hosts.sh
	return 1
fi

json_init
json_load "$(ubus call babeld get_neighbours)"
if ! json_select "IPv6" ; then
	log "Exit no IPv6 neighbor entry"
	return 1
fi

unbound=0
[ -x /usr/lib/unbound/babelneighbour.sh ] && unbound=1
rm -f /tmp/babelneighbor2hosts.tmp
domain="$(uci_get system @system[-1] domain olsr)"
domain_custom=""
if [ ! "$domain" == "olsr" ] ; then
	domain_custom="$domain"
	domain="olsr"
fi
#log "domain $domain $domain_custom"
llneighborips=""
json_get_keys keys
for key in $keys ; do
	llneighborip=""
	json_select ${key}
	json_get_var device dev
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
for llneighborip in $llneighborips ; do
	json_get_keys keys
	for key in $keys ; do
		json_select ${key}
		neighborip=${key//_/:}
		neighborip=${neighborip%:*}
		neighborip=${neighborip%::1}
		neighborip=${neighborip%::}
		neighborip="$neighborip""::1"
		refmetric=""
		json_get_var refmetric refmetric
		if [ "$refmetric" = "0" ] ; then
			json_get_var via via
			llvia=$(echo $llneighborip | cut -d '%' -f 1)
			if [ "$via" = "$llvia" ] ; then
				if ! ping6 -c1 -W3 -q "$neighborip" >/dev/null ; then
					log "neighborip ping fail $neighborip $llneighborip"
					json_select ..
					continue
				fi
				#log "neighborip $neighborip $llneighborip"
				neighborname=$(nslookup $neighborip $llneighborip | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
				neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
				for j in $neighborips ; do
					if echo $j | grep -q -v ^fe ; then
						if echo $j | grep -q ^fd ; then
							echo "$j $neighborname.$domain" >>/tmp/babelneighbor2hosts.tmp
						else
							if [ -z "$domain_custom" ] ; then
								echo "$j $neighborname.$domain" >>/tmp/babelneighbor2hosts.tmp
							else
								echo "$j $neighborname.$domain_custom $neighborname.$domain" >>/tmp/babelneighbor2hosts.tmp
							fi
						fi
					fi
				done
			fi
		fi
		json_select ..
	done
done

#Add local hostname
hostname="$(cat /proc/sys/kernel/hostname)"
config_load network
config_foreach print_interface interface "$hostname" "/tmp/babelneighbor2hosts.tmp"
mkdir -p /tmp/hosts
touch /tmp/hosts/babelneighbor

if [ -f /tmp/babelneighbor2hosts.tmp ] ; then
	if [ -f /tmp/hosts/babelneighbor ] ; then
		cat /tmp/babelneighbor2hosts.tmp | sort > /tmp/babelneighbor
		rm /tmp/babelneighbor2hosts.tmp
		new=$(md5sum /tmp/babelneighbor | cut -d ' ' -f 1)
		old=$(md5sum /tmp/hosts/babelneighbor | cut -d ' ' -f 1)
		if [ ! "$new" == "$old" ] ; then
			mv /tmp/babelneighbor /tmp/hosts/babelneighbor
			if [ $unbound == 0 ] ; then
				killall -HUP dnsmasq
			fi
		fi
	else
		cat /tmp/babelneighbor2hosts.tmp | sort > /tmp/hosts/babelneighbor
		rm /tmp/babelneighbor2hosts.tmp
		if [ $unbound == 0 ] ; then
			killall -HUP dnsmasq
		fi
	fi
fi
if [ $unbound == 1 ] ; then
	/usr/lib/unbound/babelneighbour.sh
fi
