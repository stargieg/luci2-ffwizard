#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t olsrneighbor2hosts $@
}

if pidof nc | grep -q ' ' >/dev/null ; then
	log "killall nc"
	killall -9 nc
	ubus call rc init '{"name":"olsrd2","action":"restart"}' || /etc/init.d/olsrd2 restart
	return 1
fi
hostname="$(cat /proc/sys/kernel/hostname)"
if ! nslookup $hostname | grep -q 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' ; then
	log "restart dnsmasq nslookup $hostname fail"
	ubus call rc init '{"name":"dnsmasq","action":"restart"}' || /etc/init.d/dnsmasq restart
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
[ -f /var/lib/unbound/unbound.conf ] && unbound=1
[ $unbound == 0 ] && rm -f /tmp/olsrneighbor2hosts.tmp
domain="$(uci_get luci_olsrd2 general domain olsr)"
i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var neighborip neighbor_originator
	neighborname=$(nslookup $neighborip $neighborip | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
	neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
	for j in $neighborips ; do
		if [ $unbound == 1 ] ; then
			echo "$neighborname.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas_remove
			echo "$neighborname.olsr. 300 IN AAAA $j" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
			if ! echo $j | grep -q ^fd ; then
				echo "$neighborname.$domain." | unbound-control -c /var/lib/unbound/unbound.conf local_datas_remove
				echo "$neighborname.$domain. 300 IN AAAA $j" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
				echo "$neighborname.$domain. 300 IN CAA 0 issue letsencrypt.org" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
			fi
		else
			echo "$j $neighborname $neighborname.$domain" >>/tmp/olsrneighbor2hosts.tmp
		fi
	done
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup
if [ $unbound == 0 ] ; then
	if [ -f /tmp/olsrneighbor2hosts.tmp ] ; then
		if [ -f /tmp/hosts/olsrneighbor ] ; then
			cat /tmp/olsrneighbor2hosts.tmp | sort > /tmp/olsrneighbor
			rm /tmp/olsrneighbor2hosts.tmp
			new=$(md5sum /tmp/olsrneighbor | cut -d ' ' -f 1)
			old=$(md5sum /tmp/hosts/olsrneighbor | cut -d ' ' -f 1)
			if [ ! "$new" == "$old" ] ; then
				mv /tmp/olsrneighbor /tmp/hosts/olsrneighbor
				killall -HUP dnsmasq
			fi
		else
			cat /tmp/olsrneighbor2hosts.tmp | sort > /tmp/hosts/olsrneighbor
			rm /tmp/olsrneighbor2hosts.tmp
			killall -HUP dnsmasq
		fi
	fi
fi
