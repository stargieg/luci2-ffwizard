#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -s -t olsrv2-dyn-addr $@
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

cfg_ip6prefix="loopback"
srcip6prefix="$(uci_get network $cfg_ip6prefix srcip6prefix)"
cfgip6prefix="$(uci_get network $cfg_ip6prefix ip6prefix)"
ip6prefix="$(echo $cfgip6prefix | cut -d '/' -f 1)"
ip6prefix_mask="$(echo $cfgip6prefix | cut -d '/' -f 2)"
ip6prefix_new=$ip6prefix
ip6prefix_mask_new=$ip6prefix_mask

json_init
json_load "$(echo '/olsrv2info json attached_network /quit' | nc ::1 2009)"
if ! json_select attached_network ; then
	log "Exit no lan entry"
	return 1
fi

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
		log "gateway $gateway net $attached_net_src"
		destination="$(echo $attached_net_src | cut -d '/' -f 1)"
		log "new $destination old $srcip6prefix"
		if [ ! "$destination" == "$srcip6prefix" ] ; then
			if [ $genmask == 48 ] || [ $genmask -eq 42 ] || [ $genmask -eq 56 ] || [ $genmask -eq 60 ]; then
				ula="$(echo $destination | cut -b -2)"
				json_get_var mtr domain_metric_out_raw
				json_get_var dis domain_distance
				if [ $ula != fd -a $ula != fe -a $mtr -lt $metric -a $dis -lt $distance ] ; then
					metric=$mtr
					distance=$dis
					log "attached_net_src $attached_net_src"
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
					log "new address $ip6prefix_new/$ip6prefix_mask_new"
				fi
			fi
		fi
	fi
	json_select ..
	i=$(( i + 1 ))
done


validate="1"
for j in $pre_list ; do
	if [ $ip6prefix_new == $j ] ; then
		validate="0"
		log "Not Validate"
	fi
done
#validate="0"
if [ "$validate" == "0" ] ; then
	log "Del Not Validate"
	log "ip6pre: $ip6prefix_new/$ip6prefix_mask_new"
else
	log "Validate"
	log "ip6pre: $ip6prefix_new/$ip6prefix_mask_new"

	if [ "$ip6prefix_new" != "$ip6prefix" ] ; then
		log "Update network $cfg_ip6prefix ip6prefix"
		log "ip6prefix:        $ip6prefix"
		log "ip6prefix_new:    $ip6prefix_new/$ip6prefix_mask_new"
		uci_remove network $cfg_ip6prefix ip6prefix 2>/dev/null
		uci_remove network $cfg_ip6prefix ip6addr 2>/dev/null
		uci_add_list network $cfg_ip6prefix ip6prefix "$ip6prefix_new/$ip6prefix_mask_new"
		uci_set network $cfg_ip6prefix srcip6prefix "$srcip6prefix_new"
		uci_add_list network $cfg_ip6prefix ip6addr "::1/128"
		uci_add_list network $cfg_ip6prefix ip6addr "$ip6prefix_new""2/128"
		#use unbound and jool on the gateway
		uci_remove network lan dns 2>/dev/null
		uci_remove dhcp @dnsmasq[-1] server 2>/dev/null
		uci_add_list dhcp @dnsmasq[-1] server "$srcip6prefix_new""1"
		uci_set dhcp @dnsmasq[-1] filter_a '1'
		uci_commit network
		uci_commit dhcp

		#ubus call uci "reload_config"
		/etc/init.d/network reload
		#netconfig is a reload triger for olsrv2
		sleep 5
		/etc/init.d/dnsmasq restart
	fi

	addr="$(printf '/config get olsrv2_lan[dynaddr].prefix' | nc ::1 2009 | tail -1)"
	ip6prefix_new="$ip6prefix_new/$ip6prefix_mask_new"
	if [ "$addr" == "$ip6prefix_new" ] ; then
		log "no change prefix olsrv2_lan dynaddr $addr $ip6prefix_new"
	else
		log "change prefix olsrv2_lan dynaddr $addr $ip6prefix_new"
		mask="$(echo $newaddr | cut -d '/' -f 2)"
		#if [ ! "$mask" == "64" ] ; then
		#	set_iface_prefix "$newaddr"
		#fi
		( printf "config set olsrv2_lan[dynaddr].prefix=$ip6prefix_new\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
		( printf "config commit\n" ; sleep 1 ; printf "quit\n" ) | nc ::1 2009 2>&1 >/dev/null
	fi
fi

