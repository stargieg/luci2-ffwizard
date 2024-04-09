#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh
. /lib/functions/network.sh

log() {
	logger -t olsrneighbor2hosts $@
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

if pidof nc | grep -q ' ' >/dev/null ; then
	log "killall nc"
	killall -9 nc
	ubus call rc init '{"name":"olsrd2","action":"restart"}' || /etc/init.d/olsrd2 restart
	return 1
fi

if pidof olsrneighbor2hosts.sh | grep -q ' ' >/dev/null ; then
	log "killall olsrneighbor2hosts.sh"
	killall -9 olsrneighbor2hosts.sh
	return 1
fi

json_init
json_load "$(echo '/nhdpinfo json neighbor /quit' | nc ::1 2009)"
if ! json_select neighbor ; then
	log "Exit no neighbor entry"
	return 1
fi

unbound=0
[ -x /usr/lib/unbound/olsrv2neighbour.sh ] && unbound=1
rm -f /tmp/olsrneighbor2hosts.tmp
domain="$(uci_get luci_olsrd2 general domain olsr)"
domain_custom=""
if [ ! "$domain" == "olsr" ] ; then
	domain_custom="$domain"
	domain="olsr"
fi
i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var neighborip neighbor_originator
	neighborname=$(nslookup $neighborip $neighborip | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
	neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
	for j in $neighborips ; do
		if echo $j | grep -q -v ^fe ; then
			if echo $j | grep -q ^fd ; then
				echo "$j $neighborname.$domain" >>/tmp/olsrneighbor2hosts.tmp
			else
				if [ -z "$domain_custom" ] ; then
					echo "$j $neighborname.$domain" >>/tmp/olsrneighbor2hosts.tmp
				else
					echo "$j $neighborname.$domain_custom $neighborname.$domain" >>/tmp/olsrneighbor2hosts.tmp
				fi
			fi
		fi
	done
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup

#Add local hostname
hostname="$(cat /proc/sys/kernel/hostname)"
config_load network
config_foreach print_interface interface "$hostname" "/tmp/olsrneighbor2hosts.tmp"
mkdir -p /tmp/hosts
touch /tmp/hosts/olsrneighbor

if [ -f /tmp/olsrneighbor2hosts.tmp ] ; then
	if [ -f /tmp/hosts/olsrneighbor ] ; then
		cat /tmp/olsrneighbor2hosts.tmp | sort > /tmp/olsrneighbor
		rm /tmp/olsrneighbor2hosts.tmp
		new=$(md5sum /tmp/olsrneighbor | cut -d ' ' -f 1)
		old=$(md5sum /tmp/hosts/olsrneighbor | cut -d ' ' -f 1)
		if [ ! "$new" == "$old" ] ; then
			mv /tmp/olsrneighbor /tmp/hosts/olsrneighbor
			if [ $unbound == 0 ] ; then
				killall -HUP dnsmasq
			fi
		fi
	else
		cat /tmp/olsrneighbor2hosts.tmp | sort > /tmp/hosts/olsrneighbor
		rm /tmp/olsrneighbor2hosts.tmp
		if [ $unbound == 0 ] ; then
			killall -HUP dnsmasq
		fi
	fi
fi
if [ $unbound == 1 ] ; then
	/usr/lib/unbound/olsrv2neighbour.sh
fi
