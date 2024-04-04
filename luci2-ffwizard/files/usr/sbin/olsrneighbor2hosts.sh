#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t olsrneighbor2hosts $@
}

ipv6_ptr() {
	ipv6="$1"
################################
# AWK scripts                  #
################################
read -d '' scriptVariable << 'EOF'
{
	qpr = ipv6_ptr( $0 ) ;
    print ( qpr ) ;
}

function ipv6_ptr( ipv6, arpa, ary, end, i, j, new6, sz, start ) {
  # IPV6 colon flexibility is a challenge when creating [ptr].ip6.arpa.
  sz = split( ipv6, ary, ":" ) ; end = 9 - sz ;


  for( i=1; i<=sz; i++ ) {
    if( length(ary[i]) == 0 ) {
      for( j=1; j<=end; j++ ) { ary[i] = ( ary[i] "0000" ) ; }
    }

    else {
      ary[i] = substr( ( "0000" ary[i] ), length( ary[i] )+5-4 ) ;
    }
  }


  new6 = ary[1] ;
  for( i = 2; i <= sz; i++ ) { new6 = ( new6 ary[i] ) ; }
  start = length( new6 ) ;
  for( i=start; i>0; i-- ) { arpa = ( arpa substr( new6, i, 1 ) ) ; } ;
  gsub( /./, "&\.", arpa ) ; arpa = ( arpa "ip6.arpa" ) ;

  return arpa ;
}
EOF
################################
# End of AWK Scripts           #
################################
	echo "$ipv6" | awk "$scriptVariable"
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
			ptr=$(ipv6_ptr "$j")
			#TODO remove old
			#echo "$neighborname.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas_remove
			echo "$neighborname.olsr. 300 IN AAAA $j" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
			if echo $j | grep -q ^fd ; then
				#TODO remove old
				if [ ! -z "$ptr" ] ; then
					echo "$ptr. 300 IN PTR $neighborname.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
				fi
			else
				#TODO remove old
				if [ ! -z "$ptr" ] ; then
					echo "$ptr. 300 IN PTR $neighborname.$domain." | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
				fi
				echo "$neighborname.$domain. 300 IN AAAA $j" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
				echo "$neighborname.$domain. 300 IN CAA 0 issue letsencrypt.org" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
			fi
		else
			if echo $j | grep -q ^fd ; then
				echo "$j $neighborname.olsr" >>/tmp/olsrneighbor2hosts.tmp
			else
				echo "$j $neighborname.$domain $neighborname.olsr" >>/tmp/olsrneighbor2hosts.tmp
			fi
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
