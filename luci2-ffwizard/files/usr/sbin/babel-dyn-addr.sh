#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log() {
	logger -t babel-dyn-addr $@
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

if uci_get ffwizard ffwizard ip6prefix ; then
	log "prefix set by ffwizard"
	return 1
fi

if ! ubus list babeld >/dev/null ; then
	log "babeld ubus-mod not running"
	return 1
fi

if pidof babeldns64.sh | grep -q ' ' >/dev/null ; then
	log "killall babeldns64.sh"
	killall -9 babeldns64.sh
	return 1
fi

json_init
json_load "$(ubus call babeld get_routes)"
if ! json_select "IPv6" ; then
	log "Exit no IPv6 neighbor entry"
	return 1
fi

uciprefix=$(uci_get network fflandhcp ffprefix)
prefix=""
json_get_keys keys
for key in $keys ; do
	if [ "$key" == "___0" ] ; then
		json_select ${key}
		#json_get_var route_metric route_metric
		json_get_var src_prefix src-prefix
		#json_get_var route_smoothed_metric route_smoothed_metric
		#json_get_var refmetric refmetric
		#json_get_var id id
		#log "$id $route_metric $route_smoothed_metric $refmetric $src_prefix"
		prefix="$src_prefix"
		json_select ..
	fi
done

if [ "$prefix" == "$uciprefix" ] ; then
	ip6prefix_new=$(uci_get network fflandhcp ffprefix)
else
	genmask="$(echo $prefix | cut -d '/' -f 2)"
	destination="$(echo $prefix | cut -d '/' -f 1)"
	if [ $genmask == 48 ] || [ $genmask -eq 42 ] || [ $genmask -eq 56 ] || [ $genmask -eq 60 ]; then
		ula="$(echo $destination | cut -b -2)"
		#json_get_var mtr domain_metric_out_raw
		#json_get_var dis domain_distance
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
					ip6prefix_new="$ip6prefix_new/$ip6prefix_mask_new"
					;;
				56)
					srcip6prefix_new="$destination"
					ip6prefix_new=$(calc_from_56 $destination 64)
					ip6prefix_mask_new="64"
					#ip6prefix_new=$(calc_from_56 $destination 62)
					#ip6prefix_mask_new="62"
					ip6prefix_new="$ip6prefix_new/$ip6prefix_mask_new"
					;;
				52)
					srcip6prefix_new="$destination"
					ip6prefix_new=$(calc_from_52 $destination 64)
					ip6prefix_mask_new="64"
					#ip6prefix_new=$(calc_from_56 $destination 62)
					#ip6prefix_mask_new="62"
					ip6prefix_new="$ip6prefix_new/$ip6prefix_mask_new"
					;;
				48)
					srcip6prefix_new="$destination"
					ip6prefix_new=$(calc_from_48 $destination 64)
					ip6prefix_mask_new="64"
					#ip6prefix_new=$(calc_from_56 $destination 62)
					#ip6prefix_mask_new="62"
					ip6prefix_new="$ip6prefix_new/$ip6prefix_mask_new"
					;;
				*)
					log "wrong mask src $genmask"
					;;
				esac
			else
				ip6prefix_new="$ip6prefix/$ip6prefix_mask"
			fi
		fi
	fi
fi

newkey="${ip6prefix_new//:/_}"
newkey="${newkey////_}"
valid="1"
for key in $keys ; do
	if [ "$key" == "$newkey" ] ; then
		log "##############dublicated $key ########################"
		valid="0"
	fi
done

if [ "$valid" == "1" -a ! "$ip6prefix_new" == "$uciprefix" ] ; then
	ip6prefix="$ip6prefix_new"
	uci_set network fflandhcp ip6prefix "$ip6prefix"
	uci_set network fflandhcp ip6class "fflandhcp"
	uci_set network fflandhcp ffprefix "$prefix"
	uci_set network fflandhcp ip6assign '64'
	uci_commit network
	log "reload network with $ip6prefix"
	ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
fi
