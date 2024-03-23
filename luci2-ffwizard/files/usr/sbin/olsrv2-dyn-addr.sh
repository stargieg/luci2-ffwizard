#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t olsrv2-dyn-addr $@
}

uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

calc_from_60() {
	addr=$1
	OIFS=$IFS
	IFS=:
	set $addr
	IFS=$OIFS
	echo -n $1:
	if [ -z $2 ] ; then
		echo -n 0: 
	else
		echo -n $2:
	fi
	if [ -z $3 ] ; then
		echo -n 0:
	else
		echo -n $3:
	fi
	#mask=64
	rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	if [ -z $4 ] ; then
		[ "$rand1" == "0" ] && rand1=""
		echo -n $rand1:
	else
		echo -n $(echo $4 | sed -e "s/0$/$rand1/"):
	fi
	echo :
}

calc_from_56() {
	addr=$1
	mask=$2
	OIFS=$IFS
	IFS=:
	set $addr
	IFS=$OIFS
	echo -n $1:
	if [ -z $2 ] ; then
		echo -n 0:
	else
		echo -n $2:
	fi
	if [ -z $3 ] ; then
		echo -n 0:
	else
		echo -n $3:
	fi
	rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	rand2=""
	#die letzten stellen eines 62 netzes können nur 0,4,8,c sein.
	if [ "$mask" == "62" ] ; then
		while [ "$rand2" != "0" ] && [ "$rand2" != "4" ] && [ "$rand2" != "8" ] && [ "$rand2" != "c" ] ; do
			rand2="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
		done
	else #mask=64
		rand2="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	fi

	if [ -z $4 ] ; then
		[ "$rand1" == "0" ] && rand1=""
		[ -z "$rand1" ] && [ "$rand2" == "0" ] && rand2=""
		echo -n $rand1$rand2:
	else
		echo -n $(echo $4 | sed -e "s/00$/$rand1$rand2/"):
	fi
	echo :
}

calc_from_52() {                                                 
	addr=$1
	mask=$2
	OIFS=$IFS
	IFS=:
	set $addr
	IFS=$OIFS
	echo -n $1:
	if [ -z $2 ] ; then
		echo -n 0:
	else
		echo -n $2:
	fi
	if [ -z $3 ] ; then
		echo -n 0:
	else
		echo -n $3:
	fi
	rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	rand2="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	rand3=""
	if [ "$mask" == "62" ] ; then
		while [ "$rand3" != "0" ] && [ "$rand3" != "4" ] && [ "$rand3" != "8" ] && [ "$rand3" != "c" ] ; do
			rand3="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
		done
	else #mask=64
		rand3="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	fi

	if [ -z $4 ] ; then
		[ "$rand1" == "0" ] && rand1=""
		[ -z "$rand1" ] && [ "$rand2" == "0" ] && rand2=""
		[ -z "$rand2" ] && [ "$rand3" == "0" ] && rand3=""
		echo -n $rand1$rand2$rand3:
	else
		echo -n $(echo $4 | sed -e "s/000$/$rand1$rand2$rand3/"):
	fi
	echo :
}

calc_from_48() {
	addr=$1
	mask=$2
	OIFS=$IFS
	IFS=:
	set $addr
	IFS=$OIFS
	echo -n $1:
	if [ -z $2 ] ; then
		echo -n 0:
	else
		echo -n $2:
	fi
	rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	rand2="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	rand3="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	rand4=""
	if [ "$mask" == "62" ] ; then
		while [ "$rand4" != "0" ] && [ "$rand4" != "4" ] && [ "$rand4" != "8" ] && [ "$rand4" != "c" ] ; do
			rand4="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
		done
	else #mask=64
		rand4="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
	fi
	[ "$rand1" == "0" ] && rand1=""
	[ -z "$rand1" ] && [ "$rand2" == "0" ] && rand2=""
	[ -z "$rand2" ] && [ "$rand3" == "0" ] && rand3=""
	[ -z "$rand3" ] && [ "$rand4" == "0" ] && rand4=""
	if [ -z $3 ] ; then
		if [ -z $rand4 ] ; then
			echo -n :
		else
			echo -n 0:$rand1$rand2$rand3$rand4:
		fi
	else
		if [ -z $rand4 ] ; then
			echo -n $3:
		else
			echo -n $3:$rand1$rand2$rand3$rand4:
		fi
	fi
	echo :
}

setup_lan() {
	local cfg=$1
	local prefix="$2"
	config_get name $cfg name
	if [ "$name" == "dynaddr" ] ; then
		olsrv2_lan_update=1
		uci_set olsrd2 "$cfg" prefix "$prefix"
	fi
}

remove_lan() {
	local cfg=$1
	config_get name $cfg name
	if [ "$name" == "dynaddr" ] ; then
		uci_remove olsrd2 "$cfg"
	fi
}

setup_dhcp_ra_pref() {
	local cfg=$1
	local prefix="64:ff9b::/96"
	config_get ra $cfg ra
	if [ "$ra" == "server" ] ; then
		uci_set dhcp "$cfg" ra_pref64 "$prefix"
		uci_set dhcp "$cfg" ra_mtu "1492"
		uci_remove dhcp "$cfg" dhcp_option 2>/dev/null
		uci_add_list dhcp $cfg dhcp_option "108,0:0:7:8"
	fi
}

remove_dhcp_ra_pref() {
	local cfg=$1
	config_get ra $cfg ra
	if [ "$ra" == "server" ] ; then
		uci_remove dhcp "$cfg" ra_pref64
		uci_remove dhcp "$cfg" ra_mtu
		uci_remove dhcp "$cfg" dhcp_option
	fi
}

if pidof nc | grep -q ' ' >/dev/null ; then
	log "killall nc"
	killall -9 nc
	ubus call rc init '{"name":"olsrd2","action":"restart"}' || /etc/init.d/olsrd2 restart
	return 1
fi

if pidof olsrv2-dyn-addr.sh | grep -q ' ' >/dev/null ; then
	log "killall olsrv2-dyn-addr.sh"
	killall -9 olsrv2-dyn-addr.sh
	return 1
fi

if [ -z $(pidof olsrd2) ] ; then
	log "restart olsrd"
	ubus call rc init '{"name":"olsrd2","action":"restart"}' || /etc/init.d/olsrd2 restart
	return 1
fi

ffip6prefix=$(uci_get ffwizard ffwizard ip6prefix)
if [ -n "$ffip6prefix" ] ; then
	log "Exit disable by ffwizard ip6prefix"
	return 1
fi

ula_uci=$(uci get network.globals.ula_prefix)
ula_cfg="$(printf '/config get olsrv2_lan[ula].prefix' | nc ::1 2009 | tail -1)"
if [ ! "$ula_uci" == "$ula_cfg" ] ; then
	log "change prefix olsrv2_lan ula $ula_uci"
	( printf "config set olsrv2_lan[ula].prefix=$ula_uci\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
	( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
fi

srcip6prefix="$(uci_get network globals srcip6prefix)"
cfgip6prefix="$(uci_get network loopback ip6prefix)"
ip6prefix="$(echo $cfgip6prefix | cut -d '/' -f 1)"
ip6prefix_mask="$(echo $cfgip6prefix | cut -d '/' -f 2)"
ip6prefix_new=""
ip6prefix_mask_new="" 

json_init
json_load "$(echo '/olsrv2info json attached_network /quit' | nc ::1 2009)"
if ! json_select attached_network ; then
	log "Exit no lan entry"
	return 1
fi

#Prefix list for conflict detection
pre_list=""
#MAX Metric
metric="99"
#MAX Distance
distance="99"
i=1;while json_is_a ${i} object;do
	destination=""
	genmask=""
	gateway=""
	json_select ${i}
	json_get_var destination attached_net
	genmask="$(echo $destination | cut -d '/' -f 2)"
	pre="$(echo $destination | cut -d '/' -f 1)"
	pre_list="$pre_list $pre"
	if [ "$genmask" == "0" ] ; then
		json_get_var attached_net_src attached_net_src
		genmask="$(echo $attached_net_src | cut -d '/' -f 2)"
		json_get_var gateway node
		destination="$(echo $attached_net_src | cut -d '/' -f 1)"
		if [ $genmask == 48 ] || [ $genmask -eq 42 ] || [ $genmask -eq 56 ] || [ $genmask -eq 60 ]; then
			ula="$(echo $destination | cut -b -2)"
			json_get_var mtr domain_metric_out_raw
			json_get_var dis domain_distance
			if [ $ula != fd -a $ula != fe -a $mtr -lt $metric -a $dis -lt $distance ] ; then
				metric=$mtr
				distance=$dis
				if [ ! "$destination" == "$srcip6prefix" ] ; then
					log "new attached_net_src $attached_net_src"
					case $genmask in
					60)
						srcip6prefix_new="$destination"
						ip6prefix_new=$(calc_from_60 $destination)
						ip6prefix_mask_new="64"
						;;
					56)
						srcip6prefix_new="$destination"
						ip6prefix_new=$(calc_from_56 $destination 64)
						ip6prefix_mask_new="64"
						#ip6prefix_new=$(calc_from_56 $destination 62)
						#ip6prefix_mask_new="62"
						;;
					52)
						srcip6prefix_new="$destination"
						ip6prefix_new=$(calc_from_52 $destination 64)
						ip6prefix_mask_new="64"
						#ip6prefix_new=$(calc_from_56 $destination 62)
						#ip6prefix_mask_new="62"
						;;
					48)
						srcip6prefix_new="$destination"
						ip6prefix_new=$(calc_from_48 $destination 64)
						ip6prefix_mask_new="64"
						#ip6prefix_new=$(calc_from_56 $destination 62)
						#ip6prefix_mask_new="62"
						;;
					*)
						log "wrong mask src $genmask"
						;;
					esac
				else
					ip6prefix_new="$ip6prefix"
					ip6prefix_mask_new="$ip6prefix_mask"
				fi
			fi
		fi
	elif [ "$pre" == "64:ff9b::" ] ; then
		json_get_var node node
		nat64_server="$node"
	fi
	json_select ..
	i=$(( i + 1 ))
done

for j in $pre_list ; do
	if [ "$ip6prefix_new" == "$j" ] ; then
		log "Conflict found for $ip6prefix_new"
		ip6prefix_new=""
	fi
done

#use unbound and jool on the gateway
if [ ! -z "$nat64_server" ] ; then
	nat64_uci_server=$(uci_get dhcp @dnsmasq[-1] server)
	if [ "$nat64_server" != "$nat64_uci_server" ] ; then
		log "found nat64 on $nat64_server"
		uci_set dhcp @dnsmasq[-1] nat64 "1"
		uci_remove dhcp @dnsmasq[-1] server 2>/dev/null
		uci_add_list dhcp @dnsmasq[-1] server "$nat64_server"
		config_load dhcp
		config_foreach setup_dhcp_ra_pref dhcp
		uci_commit dhcp
		/etc/init.d/dnsmasq restart
	fi
else
	nat64_uci=$(uci_get dhcp @dnsmasq[-1] nat64)
	if [ -z "$nat64_server" ] && [ "$nat64_uci" == "1" ] ; then
		log "remove local nat64 server $nat64_uci and add https://nat64.net/ server"
		# https://nat64.net/
		uci_remove dhcp @dnsmasq[-1] nat64
		uci_remove dhcp @dnsmasq[-1] server
		uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2c::1"
		uci_add_list dhcp @dnsmasq[-1] server "2a01:4f8:c2c:123f::1"
		uci_add_list dhcp @dnsmasq[-1] server "2a00:1098:2b::1"
		config_load dhcp
		config_foreach remove_dhcp_ra_pref dhcp
		uci_commit dhcp
		/etc/init.d/dnsmasq restart
	fi
fi

if [ -z "$ip6prefix_new" ] ; then
	if [ ! -z "$srcip6prefix" ] ; then
		log "No valid prefix found. remove $ip6prefix/$ip6prefix_mask"
		uci_remove network globals srcip6prefix 2>/dev/null
		uci_remove network loopback ip6prefix 2>/dev/null
		uci_remove network loopback ip6addr 2>/dev/null
		ula_addr="$(echo $ula_uci | cut -d '/' -f 1)"
		uci_add_list network loopback ip6addr "::1/128"
		uci_add_list network loopback ip6addr "$ula_addr""2/128"
		uci_commit network
		# remove prefix from olsrd2 prozess
		( printf "config remove olsrv2_lan[dynaddr]\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
		( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
		#optional remove prefix from olsrd2 config
		#faster reconect after reboot
		config_load olsrd2
		config_foreach remove_lan olsrv2_lan
		uci_commit olsrd2
		#ubus call uci "reload_config"
		/etc/init.d/network reload
		#netconfig is a reload triger for olsrv2
		sleep 5
		/etc/init.d/dnsmasq restart
	fi
else
	if [ "$ip6prefix_new" != "$ip6prefix" ] ; then
		log "Write new config for $ip6prefix_new/$ip6prefix_mask_new"
		uci_remove network loopback ip6prefix 2>/dev/null
		uci_remove network loopback ip6addr 2>/dev/null
		uci_add_list network loopback ip6prefix "$ip6prefix_new/$ip6prefix_mask_new"
		uci_set network globals srcip6prefix "$srcip6prefix_new"
		ula_addr="$(echo $ula_uci | cut -d '/' -f 1)"
		uci_add_list network loopback ip6addr "::1/128"
		uci_add_list network loopback ip6addr "$ula_addr""2/128"
		uci_add_list network loopback ip6addr "$ip6prefix_new""2/128"
		uci_commit network

		#optional add prefix to olsrd2 config
		#faster reconect after reboot
		config_load olsrd2
		olsrv2_lan_update=0
		config_foreach setup_lan olsrv2_lan "$ip6prefix_new/$ip6prefix_mask_new"
		if [ $olsrv2_lan_update == 0 ] ; then
			uci_add olsrd2 olsrv2_lan ; cfg="$CONFIG_SECTION"
			uci_set olsrd2 "$cfg" name "dynaddr"
			uci_set olsrd2 "$cfg" prefix "$ip6prefix_new/$ip6prefix_mask_new"
		fi
		uci_commit olsrd2

		#ubus call uci "reload_config"
		/etc/init.d/network reload
		#netconfig is a reload triger for olsrv2
		sleep 5
		/etc/init.d/dnsmasq restart
	else
		#BUG check if default route is present
		if [ -z "$(ip -6 route show default)" ] ; then
			log "ip6pre: BUG no default route found for $ip6prefix_new/$ip6prefix_mask_new"
			/etc/init.d/olsrd2 restart
		elif ! ping6 -q -c 3 "2.pool.ntp.org" >/dev/null 2>&1 && ! ping6 -q -c 3 "openwrt.org" >/dev/null 2>&1 ; then 
			log "ip6pre: BUG ipv6.net ping6 timeout $ip6prefix_new/$ip6prefix_mask_new"
			/etc/init.d/olsrd2 restart
		fi
	fi

	# add prefix to olsrd2 prozess
	addr="$(printf '/config get olsrv2_lan[dynaddr].prefix' | nc ::1 2009 | tail -1)"
	ip6prefix_new="$ip6prefix_new/$ip6prefix_mask_new"
	if [ ! "$addr" == "$ip6prefix_new" ] ; then
		log "change prefix olsrv2_lan dynaddr $addr $ip6prefix_new"
		mask="$(echo $newaddr | cut -d '/' -f 2)"
		( printf "config set olsrv2_lan[dynaddr].prefix=$ip6prefix_new\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
		( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
	fi
fi

