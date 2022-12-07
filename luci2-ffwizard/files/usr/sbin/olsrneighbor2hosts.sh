#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -s -t olsrneighbor2hosts $@
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
domain="$(uci_get luci_olsr2 general domain olsr)"
i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var neighborip neighbor_originator
	neighborname=$(nslookup $neighborip $neighborip | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
	neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
	for j in $neighborips ; do
		echo "$j $neighborname $neighborname.$domain"
	done
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup
