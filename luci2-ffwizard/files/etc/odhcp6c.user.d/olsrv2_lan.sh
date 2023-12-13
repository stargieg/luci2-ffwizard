
. /lib/functions.sh
. /usr/share/libubox/jshn.sh

set_iface_prefix() {
	addr="$1"
	net=`ubus call network.interface dump`
	json_load "$net"
	json_select interface
	json_get_keys net_res
	for i in $net_res ; do
		json_select $i
		json_get_keys pref ipv6-prefix
		if [ -n "$pref" ] ; then
			json_select ipv6-prefix
			json_get_keys pref_res
			for n in $pref_res ; do
				json_select $n
				json_get_var pref_n address
				if echo "$addr" | grep -q "$pref_n" >/dev/null ; then
					json_get_keys asg assigned
					if [ -n "$asg" ] ; then
						json_select assigned
						json_get_keys asg_res
						for m in $asg_res ; do
							json_select $m
							json_get_var asg_m address
							logger -t odhcp6c.user "change addr olsrv2_lan wan $m $asg_m/64"
							( printf "config set olsrv2_lan[$m].prefix=$asg_m/64\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
							logger -t odhcp6c.user "change addr olsrv2_lan wan2 $m $asg_m/64"
							json_select ".."
						done
						json_select ".."
					fi
				fi
				json_select ".."
			done
			json_select ".."
		fi
		json_select ".."
	done
	json_select ".."
}


case "$2" in
	ra-updated)
		if pidof nc | grep -q ' ' >/dev/null ; then
			log "killall nc"
			killall -9 nc
			ubus call rc init '{"name":"olsrd2","action":"restart"}'
			return
		fi
		if ! [ -z "$RA_ADDRESSES" ] ; then
			for ra in $RA_ADDRESSES ; do
				newlan=1
				newaddr="$(echo "$ra" | cut -d ',' -f1 | cut -d '/' -f1)"
				addr="$(printf '/config get olsrv2_lan[wanip].prefix' | nc ::1 2009 | tail -1)"
				if [ "$addr" == "$newaddr/128" ] ; then
					logger -t odhcp6c.user "no change addr olsrv2_lan wanip $1 $newaddr/128"
				else
					logger -t odhcp6c.user "change addr olsrv2_lan wanip $1 $newaddr/128"
					( printf "config set olsrv2_lan[wanip].prefix=$newaddr/128\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
					sleep 1
					( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
					( sleep 5 ; /etc/init.d/dnsmasq restart ) &
				fi
			done
		fi
		if ! [ -z "$PREFIXES" ] ; then
			for pre in $PREFIXES ; do
				newaddr="$(echo "$pre" | cut -d ',' -f1 )"
				case $newaddr in
					fd*)
						addr="$(printf '/config get olsrv2_lan[wanfd].prefix' | nc ::1 2009 | tail -1)"
						if [ "$addr" == "$newaddr" ] ; then
							logger -t odhcp6c.user "no change prefix olsrv2_lan wanfd $1 $addr $newaddr"
						else
							logger -t odhcp6c.user "change prefix olsrv2_lan wanfd $1 $addr $newaddr"
							( printf "config set olsrv2_lan[wanfd].prefix=$newaddr\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
							( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
						fi
						;;
					*)
						addr="$(printf '/config get olsrv2_lan[wangw].source_prefix' | nc ::1 2009 | tail -1)"
						if [ "$addr" == "$newaddr" ] ; then
							logger -t odhcp6c.user "no change prefix olsrv2_lan wangw $1 $addr $newaddr"
						else
							logger -t odhcp6c.user "change prefix olsrv2_lan wangw $1 $addr $newaddr"
							set_iface_prefix "$newaddr"
							( printf "config set olsrv2_lan[wangw].prefix=::/0\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null 
							( printf "config set olsrv2_lan[wangw].source_prefix=$newaddr\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
							( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
						fi
						#Public Domain
						if dnsmasq -v 2>/dev/null | grep -q auth && grep -q auth-zone /etc/dnsmasq.conf ; then
							#optional set domain from config
							domain=$(uci get luci_olsr2.general.domain)
							#if ! [ -z "$domain" ] ; then
								if ! grep -q "$newaddr" /etc/dnsmasq.conf ; then
									logger -t odhcp6c.user "change prefix dnsmasq for domain $domain"
									sed -i /etc/dnsmasq.conf -e "s|\(auth-zone=[a-zA-Z0-9.]*,\).*|\1$newaddr|"
									#optional set domain from config
									#sed -i /etc/dnsmasq.conf -e "s|auth-zone=.*|auth-zone=$domain,$newaddr|"
									#/etc/dnsmasq.conf
									#auth-ttl=60
									#auth-zone=ff.example.com,2003:ea:2222:1f00::/56
									#auth-zone=ff.example.com,br-lan/6,exclude:f000::/4
									#auth-server=inetrouter.example.com,pppoe-wan
									logger -t odhcp6c.user "restart dnsmasq"
									( sleep 5 ; /etc/init.d/dnsmasq restart ) &
								fi
							#fi
						fi
						;;
				esac
			done
		fi
	;;
esac
