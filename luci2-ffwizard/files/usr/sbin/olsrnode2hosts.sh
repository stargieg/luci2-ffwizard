#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -s -t olsrnode2hosts $@
}

if pidof olsrnode2hosts.sh | grep -q ' ' >/dev/null ; then
	log "killall olsrnode2hosts.sh"
	killall -9 olsrnode2hosts.sh
	return 1
fi
json_init
json_load "$(echo '/nhdpinfo json neighbor /quit' | nc ::1 2009)"
if ! json_select neighbor ; then
	log "Exit no neighbor entry"
	return 1
fi
neighborips=""
i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var neighborip neighbor_originator
	neighborips="$neighborips $neighborip"
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup

json_init
json_load "$(echo '/olsrv2info json node /quit' | nc ::1 2009)"
if ! json_select node ; then
	log "Exit no node entry"
	return 1
fi
unbound=0
[ -f /var/lib/unbound/unbound.conf ] && unbound=1
[ $unbound == 0 ] && rm -f /tmp/olsrnode2hosts.tmp
domain="$(uci_get luci_olsrd2 general domain olsr)"
i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var neighbor node_neighbor
	json_get_var virtual node_virtual
	if [ "$neighbor" == "false" ] && [ "$virtual" == "false" ] ; then
		json_get_var node node
		ret=""
		for j in $neighborips ; do
			[ -z $ret ] || return
			nodename=$(nslookup $node $j | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
			nodeips=$(nslookup $nodename $j | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
			for k in $nodeips ; do
				if [ $unbound == 1 ] ; then
					echo "$nodename.olsr. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
					if ! echo $k | grep -q ^fd ; then
						echo "$nodename.$domain. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
						echo "$nodename.$domain. 300 IN CAA 0 issue letsencrypt.org" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
					fi
				else
					echo "$k $nodename $nodename.$domain" >> /tmp/olsrnode2hosts.tmp
				fi
				ret="1"
			done
		done
		if [ -z $ret ] ; then
			nodename=$(nslookup $node $node | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
			nodeips=$(nslookup $nodename $node | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
			for k in $nodeips ; do
				if [ $unbound == 1 ] ; then
					echo "$nodename.olsr. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
					if ! echo $k | grep -q ^fd ; then
						echo "$nodename.$domain. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
						echo "$nodename.$domain. 300 IN CAA 0 issue letsencrypt.org" | unbound-control -c /var/lib/unbound/unbound.conf local_datas
					fi
				else
					echo "$k $nodename $nodename.$domain" >> /tmp/olsrnode2hosts.tmp
				fi
				ret="1"
			done
		fi
	fi
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup
if [ $unbound == 0 ] ; then
	if [ -f /tmp/olsrneighbor2hosts.tmp ] ; then
		if [ -f /tmp/hosts/olsrneighbor ] ; then
			new=$(md5sum /tmp/olsrneighbor2hosts.tmp | cut -d ' ' -f 1)
			old=$(md5sum /tmp/hosts/olsrneighbor | cut -d ' ' -f 1)
			if [ ! "$new" == "$old" ] ; then
				mv /tmp/olsrneighbor2hosts.tmp /tmp/hosts/olsrneighbor
				killall -HUP dnsmasq
			fi
		else
			mv /tmp/olsrneighbor2hosts.tmp /tmp/hosts/olsrneighbor
			killall -HUP dnsmasq
		fi
	fi
fi
