#!/bin/sh

. /lib/functions.sh
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
				if echo $i | grep -q ^fd ; then
					echo "$i $hostname.$domain $hostname" >> "$out"
				else
					if [ -z "$domain_custom" ] ; then
						echo "$i $hostname.$domain $hostname" >> "$out"
					else
						echo "$i $hostname.$domain_custom $hostname.$domain $hostname" >> "$out"
					fi
				fi
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

unbound=0
[ -x /usr/lib/unbound/babelneighbour.sh ] && unbound=1
rm -f /tmp/babelneighbor2hosts.tmp
domain="$(uci_get system @system[-1] domain olsr)"
domain_custom=""
if [ ! "$domain" == "olsr" ] ; then
	domain_custom="$domain"
	domain="olsr"
fi
ubus call babeld get_routes | \
sed -e 's/^\t\t\(".*"\): {/\t\t\{\n\t\t\t"prefix": \1,/' \
-e 's/^\(\t".*": \){/\1[/' \
-e 's/^\t}/\t]/' \
-e 's/src-prefix/src_prefix/' | \
jsonfilter -e '@.IPv6[@.refmetric=0]' > /tmp/babelneighbor2hosts.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'prefix=@.prefix' \
		-e 'src_prefix=@.src_prefix' \
		-e 'refmetric=@.refmetric' \
		-e 'id=@.id' \
		-e 'via=@.via')
	if [ "$installed" == "1" ] ; then
		if [ "$src_prefix" == "::/0" ] ; then
			mask="$(echo $prefix | cut -d '/' -f 2)"
			neighborip=${prefix%/*}
			if [ $mask -lt 128 ] ; then
				neighborip="$neighborip""1"
			fi
			echo $neighborip | grep -q -v ^64 || continue
			echo $neighborip | grep -q -v ^fe || continue
			if ! ping6 -c1 -W3 -q "$neighborip" >/dev/null ; then
				log "neighborip ping fail $neighborip via $via id $id"
				continue
			fi
			#log "neighborip $neighborip $llneighborip"
			neighborname=$(nslookup $neighborip $llneighborip 2>/dev/null | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
			if [ -z $neighborname ] ; then
				neighborname=$(wget -q -T 2 -O - --no-check-certificate https://[$neighborip]/cgi-bin/luci/ 2>/dev/null | \
				grep 'href="/"' | \
				sed -e 's/.*>\([0-9a-zA-Z-]*\)<.*/\1/')
				if [ -z $neighborname ] ; then
					neighborname=$(wget -q -T 2 -O - http://[$neighborip]/cgi-bin/luci/ 2>/dev/null | \
					grep 'href="/"' | \
					sed -e 's/.*>\([0-9a-zA-Z-]*\)<.*/\1/')
				fi
				if [ -z $neighborname ] ; then
					log "neighbor $neighborip no dns,https,http service"
				else
					if [ -z "$domain_custom" ] ; then
						#log "https $neighborip $neighborname.$domain"
						echo "$neighborip $neighborname.$domain" >>/tmp/babelneighbor2hosts.tmp
					else
						#log "https $neighborip $neighborname.$domain_custom $neighborname.$domain"
						echo "$neighborip $neighborname.$domain_custom $neighborname.$domain" >>/tmp/babelneighbor2hosts.tmp
					fi
				fi
			else
				neighborips=$(nslookup $neighborname $neighborip | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
				if [ -z "$neighborips" ] ; then
					neighborips=$neighborip
				fi
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
	fi
done < /tmp/babelneighbor2hosts.json
rm /tmp/babelneighbor2hosts.json

#Add local hostname
hostname="$(cat /proc/sys/kernel/hostname)"
config_load network
config_foreach print_interface interface "$hostname" "/tmp/babelneighbor2hosts.tmp"
mkdir -p /tmp/hosts
touch /tmp/hosts/babelneighbor

if [ -f /tmp/babelneighbor2hosts.tmp ] ; then
	if [ -f /tmp/hosts/babelneighbor ] ; then
		cat /tmp/babelneighbor2hosts.tmp | sort | uniq > /tmp/babelneighbor
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
		cat /tmp/babelneighbor2hosts.tmp | sort  | uniq > /tmp/hosts/babelneighbor
		rm /tmp/babelneighbor2hosts.tmp
		if [ $unbound == 0 ] ; then
			killall -HUP dnsmasq
		fi
	fi
fi
if [ $unbound == 1 ] ; then
	/usr/lib/unbound/babelneighbour.sh
fi
