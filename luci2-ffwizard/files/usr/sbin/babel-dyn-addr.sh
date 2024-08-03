#!/bin/sh

. /lib/functions.sh

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

chk_red() {
	local cfg=$1
	config_get ip $cfg ip
	[ "$ip" == "64:ff9b::/96" ] && exit 1
	[ "$ip" == "::/0" ] && exit 1
}

config_load babeld
config_foreach chk_red filter

if uci_get ffwizard ffwizard ip6prefix ; then
	log "prefix set by ffwizard"
	return 1
fi

if ! ubus list babeld >/dev/null ; then
	log "babeld ubus-mod not running"
	return 1
fi

if pidof babel-dyn-addr.sh | grep -q ' ' >/dev/null ; then
	log "killall babel-dyn-addr.sh"
	killall -9 babel-dyn-addr.sh
	return 1
fi

ip6prefix_new=""
prefix=""
metric=65535
genmask=128
#ubus call babeld get_routes | jsonfilter -e '@.IPv6.A' valid
#ubus call babeld get_routes | jsonfilter -e '@.IPv6.64' invalid
#label for object key is duplicated eg. "::/0" if more than one internet gateway
#BUG parser error
ubus call babeld get_routes | \
#sed -e 's/^\t\t\(".*"\): {/\t\t\{\n\t\t\t"prefix": \1,/' \
#-e 's/^\(\t".*": \){/\1[/' \
#-e 's/^\t}/\t]/' \
#-e 's/src-prefix/src_prefix/' | \
jsonfilter -e '@.IPv6[@.prefix="::\/0"]' > /tmp/babel-dyn-addr.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'src_prefix=@.src_prefix' \
		-e 'refmetric=@.refmetric' )
	if [ "$installed" == "1" ] ; then
		if [ $refmetric -le $metric ] ; then
			src_mask="$(echo $src_prefix | cut -d '/' -f 2)"
			if [ $src_mask -le $genmask ] ; then
				prefix="$src_prefix"
				metric=$refmetric
				genmask=$src_mask
			fi
		fi
	fi
done < /tmp/babel-dyn-addr.json
rm /tmp/babel-dyn-addr.json

if [ "$prefix" == "" ] ; then
	log "Exit no IPv6 neighbor entry"
	return 1
fi

uciprefix=$(uci_get network fflandhcp ffprefix)
if [ "$prefix" == "$uciprefix" ] ; then
	ip6prefix_new=$(uci_get network fflandhcp ip6prefix)
else
	destination="$(echo $prefix | cut -d '/' -f 1)"
	if [ $genmask == 48 ] || [ $genmask -eq 42 ] || [ $genmask -eq 56 ] || [ $genmask -eq 60 ]; then
		ula="$(echo $destination | cut -b -2)"
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
			log "wrong mask src $genmask"
			ip6prefix_new=""
		fi
	fi
fi

keys=$(ubus call babeld get_routes | \
#sed -e 's/^\t\t\(".*"\): {/\t\t\{\n\t\t\t"prefix": \1,/' \
#-e 's/^\(\t".*": \){/\1[/' \
#-e 's/^\t}/\t]/' \
#-e 's/src-prefix/src_prefix/' | \
jsonfilter -e '@.IPv6[@.src_prefix="::\/0"].prefix')

valid="1"
for key in $keys ; do
	if [ "$key" == "$ip6prefix_new" ] ; then
		log "##############dublicated $key ########################"
		valid="0"
	fi
done

if [ "$valid" == "0" -o "$ip6prefix_new" == "" ] ; then
	if [ ! "$uciprefix" == "" ] ; then
		uci_remove network fflandhcp ip6prefix 2>/dev/null
		uci_set network fflandhcp ip6class "local"
		uci_remove network fflandhcp ffprefix 2>/dev/null
		uci_set network fflandhcp ip6assign '64'
		uci_commit network
		log "reload network with no ip6prefix"
		ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
		sleep 3
		ubus call rc init '{"name":"odhcpd","action":"restart"}' 2>/dev/null || /etc/init.d/odhcpd restart
		ubus call rc init '{"name":"dnsmasq","action":"restart"}' 2>/dev/null || /etc/init.d/dnsmasq restart
	fi
elif [ ! "$prefix" == "$uciprefix" ] ; then
	ip6prefix="$ip6prefix_new"
	uci_set network fflandhcp ip6prefix "$ip6prefix"
	uci_set network fflandhcp ip6class "fflandhcp"
	uci_set network fflandhcp ffprefix "$prefix"
	uci_set network fflandhcp ip6assign '64'
	uci_commit network
	log "reload network with new $ip6prefix and old $uciprefix"
	ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
	sleep 3
	ubus call rc init '{"name":"odhcpd","action":"restart"}' 2>/dev/null || /etc/init.d/odhcpd restart
	ubus call rc init '{"name":"dnsmasq","action":"restart"}' 2>/dev/null || /etc/init.d/dnsmasq restart
fi
