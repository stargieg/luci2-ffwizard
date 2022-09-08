#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

format6() {
	echo $1 | tr 'A-F' 'a-f'
}

log() {
	logger -s -t olsrv2-dyn-addr $@
}

uci_revert() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} revert "$PACKAGE${CONFIG:+.$CONFIG}${OPTION:+.$OPTION}"
}

uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}


ffip6prefix=$(uci_get ffwizard ffwizard ip6prefix)
if [ -n "$ffip6prefix" ] ; then
	log "Exit disable by ffwizard ip6prefix"
	return 1
fi

cfg_ip6prefix="loopback"
srcip6prefix="$(uci_get network $cfg_ip6prefix srcip6prefix)"
ip6prefix="$(uci_get network $cfg_ip6prefix ip6prefix)"
ip6prefix="$(echo $ip6prefix | cut -d '/' -f 1)"
ip6prefix_new=$ip6prefix

json_init
json_load "$(echo '/olsrv2info json attached_network /quit' | nc ::1 2009)"
if ! json_select attached_network ; then
	log "Exit no lan entry"
	return 1
fi

pre_list=""
metric="99"
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
		echo $gateway $attached_net_src $genmaskpre
		destination="$(echo $attached_net_src | cut -d '/' -f 1)"
		echo "new $destination old $srcip6prefix"
		if [ ! "$destination" == "$srcip6prefix" ] ; then
			if [ $genmask == 48 ] || [ $genmask -eq 42 ] || [ $genmask -eq 56 ] ; then
				ula="$(echo $destination | cut -b -2)"
				json_get_var mtr domain_metric_out_raw
				json_get_var dis domain_distance
				if [ $ula != fd -a $ula != fe -a $mtr -lt $metric -a $dis -lt $distance ] ; then
					metric=$mtr
					distance=$dis
					case $genmask in
						56) ip6pre="$(echo $attached_net_src | sed -e 's/[0-9a-fA-F]\{1,2\}::\/62/00::/')" ;;
						52) ip6pre="$(echo $attached_net_src | sed -e 's/[0-9a-fA-F]\{1,3\}::\/62/000::/')" ;;
						48) ip6pre="$(echo $attached_net_src | sed -e 's/:[0-9a-fA-F]\{1,4\}::\/62/::/')" ;;
						*) ip6pre="" ;;
					esac
					echo ip6pre $ip6pre
					#die letzten stellen eines 62 netzes können nur 0,4,8,c sein.
					rand2="" ; while [ "$rand2" != "0" ] && [ "$rand2" != "4" ] && [ "$rand2" != "8" ] && [ "$rand2" != "c" ] ; do
						rand2="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
					done
					case $genmask in
					56)
						#calc mask F[0 4 8 c] expect input f:f:f:f00::
						rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1)"
						netaddr="$(echo $destination | sed -e 's/00::/'$rand1$rand2'::/')"
						;;
					52)
						#calc mask FFF expect input f:f:f:f000::
						rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-2)"
						netaddr="$(echo $destination | sed -e 's/000::/'$rand1$rand2'::/')"
						;;
					48)
						#calc mask FFF expect input f:f:f::
						rand1="$(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-3)"
						netaddr="$(echo $destination | sed -e 's/::/:'$rand1$rand2'::/')"
						;;
					esac
					srcip6prefix_new="$destination"
					ip6prefix_new="$netaddr"
					echo address $ip6prefix_new
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
	fi
done

if [ "$validate" == "0" ] ; then
	log "Del Not Validate"
	log "ip6pre:           $ip6prefix_new"
else
	log "Validate"
	log "ip6pre:           $ip6prefix_new"

	if [ "$ip6prefix_new" != "$ip6prefix" ] ; then
		log "Update network $cfg_ip6prefix ip6prefix"
		log "ip6prefix:        $ip6prefix"
		log "ip6prefix_new:    $ip6prefix_new"
		if [ -n "$(uci_get network $cfg_ip6prefix ip6prefix)" ] ; then
			uci_remove network $cfg_ip6prefix ip6prefix
		fi
		uci_add_list network $cfg_ip6prefix ip6prefix "$ip6prefix_new/64"
		uci_set network $cfg_ip6prefix srcip6prefix "$srcip6prefix_new"
		uci_commit network

		ubus call uci "reload_config"
		#netconfig is a reload triger for olsrv2
		sleep 5
		/etc/init.d/dnsmasq restart
	fi

	addr="$(printf '/config get olsrv2_lan[dynaddr].prefix' | nc ::1 2009 | tail -1)"
	ip6prefix_new="$ip6prefix_new/64"
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
