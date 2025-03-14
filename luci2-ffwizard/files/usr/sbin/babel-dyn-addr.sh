#!/bin/sh

. /lib/functions.sh

log() {
	logger -t babel-dyn-addr $@
}

uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

uci_add_list_state() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} -P /var/state add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

chk_red() {
	local cfg=$1
	config_get ip $cfg ip
	[ "$ip" == "64:ff9b::/96" ] && exit 1
	[ "$ip" == "::/0" ] && exit 1
}

chk_dublicated() {
	local ip6prefix="$1"
	local prefix="$2"
	local is_valid="1"
	[ -z "$ip6prefix" ] && return
	#log "chk_dublicated $ip6prefix"
	ubus call babeld get_routes | \
	jsonfilter -e '@.IPv6[@.src_prefix="::/0"]' > /tmp/babel-dyn-addr.json
	while read line; do
		eval $(jsonfilter -s "$line" \
			-e 'installed=@.installed' \
			-e 'route_metric=@.route_metric' \
			-e 'address=@.address' )
		# [ "$installed" == "0" ] && continue
		[ "$route_metric" -ge "16383" ] && continue
		[ "$address" == "$prefix" ] && continue
		local invalid
		invalid=$(owipcalc $address contains $ip6prefix)
		if [ "$invalid" == "1" ] ; then
			#log "###dublicated mesh prefix $address contains new prefix $ip6prefix ###"
			is_valid="0"
		fi
		invalid=$(owipcalc $ip6prefix contains $address)
		if [ "$invalid" == "1" ] ; then
			#log "###dublicated new prefix $ip6prefix contains mesh prefix $address ###"
			is_valid="0"
		fi
	done < /tmp/babel-dyn-addr.json
	rm /tmp/babel-dyn-addr.json
	if [ "$is_valid" == "1" ] ; then
		echo "$ip6prefix"
	else
		echo ""
	fi
}

get_rand_addr() {
	local src_prefix="$1"
	local mask="$2"
	local destination="$(echo $src_prefix | cut -d '/' -f 1)"
	local src_mask="$(echo $src_prefix | cut -d '/' -f 2)"
	if [ $mask -lt $src_mask ] ; then
		return
	fi
	if [ $mask -eq $src_mask ] ; then
		echo "$src_prefix"
		return
	fi
	min_mask=$((mask-4))
	while [ $src_mask -lt $min_mask ] ; do
		src_mask=$((src_mask+3))
		#compat openwrt 19 doesn't support $RANDOM
		#rand_offset=$(awk -v seed=$RANDOM 'BEGIN {srand(seed) ; print int(rand() * 9)}')
		#fail
		#rand_offset=$(awk 'BEGIN {srand() ; print int(rand() * 9)}')
		rand_offset=$(head -n 1 /dev/urandom 2>/dev/null | md5sum | grep -o -e '[0-9]' | head -1)
		#log "rand_offset: $rand_offset"
		while [ $rand_offset -gt 0 ] ; do
			src_prefix=$(owipcalc $src_prefix next $src_mask)
			rand_offset=$((rand_offset-1))
		done
		src_prefix=$(owipcalc $src_prefix prefix $src_mask)
	done
	if [ $mask -eq $src_mask ] ; then
		echo "$src_prefix"
		return
	fi
	#log "owipcalc $src_prefix howmany ::/$mask"
	src_mask_count=$(owipcalc $src_prefix howmany ::/$mask)
	#log "src_mask_count: $src_mask_count"
	#rand_offset=$(awk -v seed=$RANDOM 'BEGIN {srand(seed) ; print int(rand() * '$src_mask_count')}')
	#rand_offset=$(awk 'BEGIN {srand() ; print int(rand() * '$src_mask_count')}')
	rand_offset=$(head -n 1 /dev/urandom 2>/dev/null | md5sum | grep -o -e '[0-'$src_mask_count']' | head -1)
	#log "rand_offset: $rand_offset"
	while [ $rand_offset -gt 0 ] ; do
		src_prefix=$(owipcalc $src_prefix next $mask)
		rand_offset=$((rand_offset-1))
	done
	src_prefix=$(owipcalc $src_prefix prefix $mask)
	echo "$src_prefix"
}

set_new_prefix() {
	local prefix="$1"
	local ffprefix="$2"
	log "reload network with new $prefix from $ffprefix"
	uci_set network fflandhcp ip6prefix "$prefix"
	uci_set network fflandhcp ffprefix "$ffprefix"
	uci_commit network
	ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
	sleep 3
	ubus call rc init '{"name":"odhcpd","action":"restart"}' 2>/dev/null || /etc/init.d/odhcpd restart
	ubus call rc init '{"name":"dnsmasq","action":"restart"}' 2>/dev/null || /etc/init.d/dnsmasq restart
}

remove_prefix() {
	local prefix="$1"
	log "remove uci prefix $prefix"
	uci_remove network fflandhcp ip6prefix 2>/dev/null
	uci_remove network fflandhcp ffprefix 2>/dev/null
	uci_commit network
	ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
	sleep 3
	ubus call rc init '{"name":"odhcpd","action":"restart"}' 2>/dev/null || /etc/init.d/odhcpd restart
	ubus call rc init '{"name":"dnsmasq","action":"restart"}' 2>/dev/null || /etc/init.d/dnsmasq restart
}

config_load babeld
config_foreach chk_red filter

if uci_get ffwizard ffwizard ip6prefix > /dev/null; then
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
prefixs=""
metric=65535
genmask=128
uci_mask="$(uci_get ffwizard autoconf ip6mask 64)"
uci_prefix_pref=$(uci_get ffwizard autoconf prefix_pref)
uci_prefix_exclude=$(uci_get ffwizard autoconf prefix_exclude)
uci_ffprefix=$(uci_get network fflandhcp ffprefix)
uci_ip6prefix=$(uci_get network fflandhcp ip6prefix)
uci_ip6prefix_mask="$(echo $uci_ip6prefix | cut -d '/' -f 2)"
if [ "$uci_ip6prefix_mask" != "$uci_mask" ] ; then
	uci_ffprefix=""
fi

#howto uci.load /var/state
#https://openwrt.github.io/luci/jsapi/LuCI.uci.html#load
#uci_revert_state ffwizard autoconf prefix_available
uci_remove ffwizard autoconf prefix_available
ubus call babeld get_routes | \
jsonfilter -e '@.IPv6[@.address="::/0"]' > /tmp/babel-dyn-addr.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'src_prefix=@.src_prefix' \
		-e 'refmetric=@.refmetric' )
	[ "$installed" == "1" ] || continue
	#uci_add_list_state ffwizard autoconf prefix_available "$src_prefix"
	uci_add_list ffwizard autoconf prefix_available "$src_prefix"
	[ "$src_prefix" == "$uci_prefix_exclude" ] && continue
	if [ "$src_prefix" == "$uci_prefix_pref" ] ; then
		refmetric=0
	fi
	if [ $refmetric -le $metric ] ; then
		prefixs="$src_prefix $prefixs"
		metric=$refmetric
	else
		prefixs="$prefixs $src_prefix"
		metric=$refmetric
	fi
done < /tmp/babel-dyn-addr.json
rm /tmp/babel-dyn-addr.json
uci_commit ffwizard

for prefix in $prefixs ; do
	ffprefix_new=""
	ffprefix_change="0"
	if [ "$prefix" == "$uci_ffprefix" ] ; then
		#log "found uci ip6prefix $uci_ffprefix $uci_ip6prefix"
		ip6prefix_new=$(chk_dublicated $uci_ip6prefix $prefix)
		#retry 1
		if [ -z "$ip6prefix_new" ] ; then
			#log "retry 1 $prefix"
			ip6prefix_new=$(get_rand_addr $prefix $uci_mask)
			ip6prefix_new=$(chk_dublicated $ip6prefix_new $prefix)
			ffprefix_change="1"
		fi
		#retry 2
		if [ -z "$ip6prefix_new" ] ; then
			#log "retry 2 $prefix"
			ip6prefix_new=$(get_rand_addr $prefix $uci_mask)
			ip6prefix_new=$(chk_dublicated $ip6prefix_new $prefix)
		fi
		if [ -z "$ip6prefix_new" ] ; then
			#log "remove uci ip6prefix $uci_ffprefix $uci_ip6prefix"
			remove_prefix "$uci_ip6prefix"
		elif [ "$ffprefix_change" == "1" ] ; then
			set_new_prefix "$ip6prefix_new" "$prefix"
			exit
		else
			exit
		fi
	else
		#log "try prefix $prefix"
		ip6prefix_new=$(get_rand_addr $prefix $uci_mask)
		ip6prefix_new=$(chk_dublicated $ip6prefix_new $prefix)
		#retry 1
		if [ -z "$ip6prefix_new" ] ; then
			#log "retry 1 $prefix"
			ip6prefix_new=$(get_rand_addr $prefix $uci_mask)
			ip6prefix_new=$(chk_dublicated $ip6prefix_new $prefix)
		fi
		#retry 2
		if [ -z "$ip6prefix_new" ] ; then
			#log "retry 2 $prefix"
			ip6prefix_new=$(get_rand_addr $prefix $uci_mask)
			ip6prefix_new=$(chk_dublicated $ip6prefix_new $prefix)
		fi
		if [ -n "$ip6prefix_new" ] ; then
			set_new_prefix "$ip6prefix_new" "$prefix"
			exit
		fi
	fi

done

if [ -n "$uci_ip6prefix" ] ; then
	remove_prefix "$uci_ip6prefix"
fi
