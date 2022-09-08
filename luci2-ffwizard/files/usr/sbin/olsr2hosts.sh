#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -s -t olsr2hosts $@
}

json_init
json_load "$(echo '/nhdpinfo json neighbor /quit' | nc ::1 2009)"
if ! json_select neighbor ; then
	log "Exit no lan entry"
	return 1
fi

i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var neighborip neighbor_originator
	neighborname=$(nslookup $neighborip $neighborip | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
	neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ' ' -f 2)
	for j in $neighborips ; do
		echo "$j $neighborname"
	done
	json_select ..
	i=$(( i + 1 ))
done
