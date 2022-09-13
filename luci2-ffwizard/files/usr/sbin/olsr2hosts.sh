#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -s -t olsr2hosts $@
}

if pidof nc | grep -q ' ' >/dev/null ; then
    log "killall nc"
	killall -9 nc
	ubus call rc init '{"name":"olsrd2","action":"restart"}'
    return 1
fi
hostname="$(cat /proc/sys/kernel/hostname)"
if ! nslookup $hostname | grep -q 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' ; then
        log "restart dnsmasq nslookup $hostname fail"
        ubus call rc init '{"name":"dnsmasq","action":"restart"}'
        return 1
fi
if pidof olsr2hosts.sh | grep -q ' ' >/dev/null ; then
    log "killall olsr2hosts.sh"
	killall -9 olsr2hosts.sh
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
	neighborname=$(nslookup $neighborip $neighborip | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
	neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ' ' -f 2)
	for j in $neighborips ; do
		echo "$j $neighborname $neighborname.olsr"
	done
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
			nodeips=$(nslookup $nodename $j | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ' ' -f 2)
			for k in $nodeips ; do
				echo "$k $nodename $nodename.olsr"
				ret="1"
			done
		done
		if [ -z $ret ] ; then                                                                                  
			nodename=$(nslookup $node $node | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)          
			nodeips=$(nslookup $nodename $node | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ' ' -f 2)
			for k in $nodeips ; do                                                                         
				echo "$k $nodename $nodename.olsr"                                                     
				ret="1"                                                                                
			done                                                                                           
		fi
	fi
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup
