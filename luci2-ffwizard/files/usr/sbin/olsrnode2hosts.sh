#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t olsrnode2hosts $@
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
			[ -z $ret ] || continue
			nodename=$(nslookup $node $j | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
			nodeips=$(nslookup $nodename $j | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
			for k in $nodeips ; do
				if [ $unbound == 1 ] ; then
					ptr=$(ipv6_ptr "$k")
					#TODO remove old
					#echo "$nodename.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas_remove >/dev/null
					echo "$nodename.olsr. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
					if echo $k | grep -q ^fd ; then
						#TODO remove old
						if [ ! -z "$ptr" ] ; then
							echo "$ptr. 300 IN PTR $nodename.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
						fi
					else
						#TODO remove old
						if [ ! -z "$ptr" ] ; then
							echo "$ptr. 300 IN PTR $nodename.$domain." | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
						fi
						echo "$nodename.$domain. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
						echo "$nodename.$domain. 300 IN CAA 0 issue letsencrypt.org" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
					fi
				else
					if echo $k | grep -q ^fd ; then
						echo "$k $nodename.olsr" >>/tmp/olsrnode2hosts.tmp
					else
						echo "$k $nodename.$domain $nodename.olsr" >>/tmp/olsrnode2hosts.tmp
					fi
				fi
				ret="1"
			done
		done
		if [ -z $ret ] ; then
			nodename=$(nslookup $node $node | grep 'name =' | cut -d ' ' -f 3 | cut -d '.' -f -1)
			nodeips=$(nslookup $nodename $node | grep 'Address.*: [1-9a-f][0-9a-f]\{0,3\}:' | cut -d ':' -f 2-)
			for k in $nodeips ; do
				if [ $unbound == 1 ] ; then
					ptr=$(ipv6_ptr "$k")
					#TODO remove old
					#echo "$nodename.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas_remove >/dev/null
					echo "$nodename.olsr. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
					if echo $k | grep -q ^fd ; then
						#TODO remove old
						if [ ! -z "$ptr" ] ; then
							echo "$ptr. 300 IN PTR $nodename.olsr." | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
						fi
					else
						#TODO remove old
						if [ ! -z "$ptr" ] ; then
							echo "$ptr. 300 IN PTR $nodename.$domain." | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
						fi
						echo "$nodename.$domain. 300 IN AAAA $k" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
						echo "$nodename.$domain. 300 IN CAA 0 issue letsencrypt.org" | unbound-control -c /var/lib/unbound/unbound.conf local_datas >/dev/null
					fi
				else
					if echo $k | grep -q ^fd ; then
						echo "$k $nodename.olsr" >>/tmp/olsrnode2hosts.tmp
					else
						echo "$k $nodename.$domain $nodename.olsr" >>/tmp/olsrnode2hosts.tmp
					fi
				fi
			done
		fi
	fi
	json_select ..
	i=$(( i + 1 ))
done
json_cleanup
if [ $unbound == 0 ] ; then
	if [ -f /tmp/olsrnode2hosts.tmp ] ; then
		if [ -f /tmp/hosts/olsrnode ] ; then
			cat /tmp/olsrnode2hosts.tmp | sort > /tmp/olsrnode
			rm /tmp/olsrnode2hosts.tmp
			new=$(md5sum /tmp/olsrnode | cut -d ' ' -f 1)
			old=$(md5sum /tmp/hosts/olsrnode | cut -d ' ' -f 1)
			if [ ! "$new" == "$old" ] ; then
				mv /tmp/olsrnode /tmp/hosts/olsrnode
				killall -HUP dnsmasq
			fi
		else
			cat /tmp/olsrnode2hosts.tmp | sort > /tmp/hosts/olsrnode
			rm /tmp/olsrnode2hosts.tmp
			killall -HUP dnsmasq
		fi
	fi
fi
