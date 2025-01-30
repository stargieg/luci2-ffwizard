#!/bin/sh

. /lib/functions.sh

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

neighborips=""
ubus call babeld get_routes | \
jsonfilter -e '@.IPv6[@.refmetric=0]' > /tmp/babelnode2hosts.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'address=@.address' \
		-e 'src_prefix=@.src_prefix')
	if [ "$installed" == "1" -a "$address" != "::/0" -a "$address" != "64:ff9b::/96" ] ; then
		if [ "$src_prefix" == "::/0" ] ; then
			mask="$(echo $address | cut -d '/' -f 2)"
			neighborip=${address%/*}
			if [ $mask -lt 128 ] ; then
				neighborip="$neighborip""1"
			fi
			if ping6 -c1 -W3 -q "$neighborip" >/dev/null 2>&1 ; then
				if nslookup "$neighborip" "$neighborip" >/dev/null 2>&1 ;then
					neighborips="$neighborips $neighborip"
				fi
			fi
		fi
	fi
done < /tmp/babelnode2hosts.json
rm /tmp/babelnode2hosts.json
neighborips=$(for i in $neighborips;do echo $i;done | uniq)
#log "$neighborips"

unbound=0
[ -x /usr/lib/unbound/babelnode.sh ] && unbound=1
rm -f /tmp/babelnode2hosts.tmp
domain="$(uci_get system @system[0] domain olsr)"
domain_custom=""
if [ ! "$domain" == "olsr" ] ; then
	domain_custom="$domain"
	domain="olsr"
fi
ubus call babeld get_routes | \
jsonfilter -e '@.IPv6[@.refmetric>0]' > /tmp/babelnode2hosts.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'address=@.address' \
		-e 'src_prefix=@.src_prefix')
	if [ "$installed" == "1" -a "$address" != "::/0" -a "$address" != "64:ff9b::/96" ] ; then
		if [ "$src_prefix" == "::/0" ] ; then
			mask="$(echo $address | cut -d '/' -f 2)"
			node=${address%/*}
			if [ $mask -lt 128 ] ; then
				node="$node""1"
			fi
			echo $node | grep -q -v ::$ || continue
			echo $node | grep -q -v ^64 || continue
			echo $node | grep -q -v ^fe || continue
			ret=""
			for j in $neighborips ; do
				[ -z $ret ] || continue
				nodenames=$(nslookup $node $j 2>/dev/null | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
				if ! [ -z "$nodenames" ] ; then
					for nodename in $nodenames ; do
						nodeips=$(nslookup $nodename $j 2>/dev/null | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
						if [ -z "$nodeips" ] ; then
							nodeips=$node
						fi
						for k in $nodeips ; do
							echo $k | grep -q -v ::$ || continue
							echo $k | grep -q -v ^64 || continue
							echo $k | grep -q -v ^fe || continue
							if echo $k | grep -q ^fd ; then
								#log "ret from neighb $j for ip $k : $nodename.$domain"
								echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
							else
								if [ -z "$domain_custom" ] ; then
									#log "ret from neighb $j for ip $k : $nodename.$domain"
									echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
								else
									#log "ret from neighb $j for ip $k : $nodename.$domain_custom $nodename.$domain"
									echo "$k $nodename.$domain_custom $nodename.$domain" >>/tmp/babelnode2hosts.tmp
								fi
							fi
							ret="1"
						done
					done
				fi
			done
			if [ -z $ret ] ; then
				nodename=""
				nodenames=$(nslookup $node $node 2>/dev/null | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
				if [ -z "$nodenames" ] ; then
					if ping6 -c1 -W3 -q "$node" >/dev/null 2>&1 ; then
						nodename=$(wget -q -T 2 -O - --no-check-certificate https://[$node]/cgi-bin/luci/ 2>/dev/null | \
						grep 'href="/"' | \
						sed -e 's/.*>\([0-9a-zA-Z-]*\)<.*/\1/')
					fi
					if [ -z $nodename ] ; then
						if ping6 -c1 -W3 -q "$node" >/dev/null 2>&1 ; then
							nodename=$(wget -q -T 2 -O - http://[$node]/cgi-bin/luci/ 2>/dev/null | \
							grep 'href="/"' | \
							sed -e 's/.*>\([0-9a-zA-Z-]*\)<.*/\1/')
						fi
					fi
					if [ -z $nodename ] ; then
							log "node $node no dns,https,http service"
					else
						if [ -z "$domain_custom" ] ; then
							#log "https $node $nodename.$domain"
							echo "$node $nodename.$domain" >>/tmp/babelnode2hosts.tmp
						else
							#log "https $node $nodename.$domain_custom $nodename.$domain"
							echo "$node $nodename.$domain_custom $nodename.$domain" >>/tmp/babelnode2hosts.tmp
						fi
					fi
				else
						#log "nslookup on $node for hostnames: $nodenames"
						for nodename in $nodenames ; do
						nodeips=$(nslookup $nodename $node | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
						if [ -z "$nodeips" ] ; then
							nodeips=$node
						fi
						for k in $nodeips ; do
							echo $k | grep -q -v ::$ || continue
							echo $k | grep -q -v ^64 || continue
							echo $k | grep -q -v ^fe || continue
							if echo $k | grep -q ^fd ; then
								#log "ns $k $nodename.$domain"
								echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
							else
								if [ -z "$domain_custom" ] ; then
									#log "ns $k $nodename.$domain"
									echo "$k $nodename.$domain" >>/tmp/babelnode2hosts.tmp
								else
									#log "ns $k $nodename.$domain_custom $nodename.$domain"
									echo "$k $nodename.$domain_custom $nodename.$domain" >>/tmp/babelnode2hosts.tmp
								fi
							fi
						done
					done
				fi
			fi
		fi
	fi
done < /tmp/babelnode2hosts.json
rm /tmp/babelnode2hosts.json
mkdir -p /tmp/hosts

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
		cat /tmp/babelnode2hosts.tmp | sort | uniq > /tmp/hosts/babelnode
		rm /tmp/babelnode2hosts.tmp
		if [ $unbound == 0 ] ; then
			killall -HUP dnsmasq
		fi
	fi
else
	log "no nodes"
	if [ -f /tmp/hosts/babelnode ] ; then
		rm /tmp/hosts/babelnode
		if [ $unbound == 0 ] ; then
			killall -HUP dnsmasq
		fi
	fi
fi
if [ $unbound == 1 ] ; then
	/usr/lib/unbound/babelnode.sh
fi
