#!/bin/sh

. /lib/functions.sh

log() {
	logger -t babel-dyn-addr $@
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
prefixs=""
metric=65535
genmask=128
uci_mask="$(uci_get ffwizard ffwizard ip6mask 64)"
uci_ffprefix=$(uci_get network fflandhcp ffprefix)
uci_ip6prefix=$(uci_get network fflandhcp ip6prefix)

ubus call babeld get_routes | \
jsonfilter -e '@.IPv6[@.address="::/0"]' > /tmp/babel-dyn-addr.json
while read line; do
	eval $(jsonfilter -s "$line" \
		-e 'installed=@.installed' \
		-e 'src_prefix=@.src_prefix' \
		-e 'refmetric=@.refmetric' )
	[ "$installed" == "1" ] || continue
	if [ $refmetric -le $metric ] ; then
		prefixs="$src_prefix $prefixs"
		metric=$refmetric
	else
		prefixs="$prefixs $src_prefix"
		metric=$refmetric
	fi
done < /tmp/babel-dyn-addr.json
rm /tmp/babel-dyn-addr.json

for prefix in $prefixs ; do
	if [ "$prefix" == "$uci_ffprefix" ] ; then
		ip6prefix_new="$uci_ip6prefix"
	else
		destination="$(echo $prefix | cut -d '/' -f 1)"
		genmask="$(echo $prefix | cut -d '/' -f 2)"
		min_mask=$((uci_mask-4))
		while [ $genmask -lt $min_mask ] ; do
			genmask=$((genmask+3))
			rand_offset=$(awk 'BEGIN {srand() ; print int(1 + rand() * 8)}')
			while [ $rand_offset -gt 0 ] ; do
				prefix=$(owipcalc $prefix next $genmask)
				rand_offset=$((rand_offset-1))
			done
		done
		src_mask_count=$(owipcalc $prefix howmany ::/$uci_mask)
		rand_offset=$(awk 'BEGIN {srand() ; print int(1 + rand() * '$src_mask_count')}')
		while [ $rand_offset -gt 0 ] ; do
			prefix=$(owipcalc $prefix next $uci_mask)
			rand_offset=$((rand_offset-1))
		done
		ip6prefix_new="$prefix"
	fi

	valid="1"
	ubus call babeld get_routes | \
	jsonfilter -e '@.IPv6[@.src_prefix="::/0"]' > /tmp/babel-dyn-addr.json
	while read line; do
		eval $(jsonfilter -s "$line" \
			-e 'installed=@.installed' \
			-e 'address=@.address' )
		[ "$installed" == "1" ] || continue
		invalid="0"
		invalid=$(owipcalc $address contains $ip6prefix_new)
		if [ "$invalid" == "1" ] ; then
			log "###dublicated mesh prefix $address contains new prefix $ip6prefix_new ###"
			valid="0"
		fi
		invalid=$(owipcalc $ip6prefix_new contains $address)
		if [ "$invalid" == "1" ] ; then
			log "###dublicated new prefix $ip6prefix_new contains mesh prefix $address ###"
			valid="0"
		fi
	done < /tmp/babel-dyn-addr.json
	rm /tmp/babel-dyn-addr.json

	if [ $valid == 1 ] ; then
		log "##############valid $ip6prefix_new ##################################"
		break
	fi
done

if [ "$valid" == "0" -o "$ip6prefix_new" == "" ] ; then
	if [ ! "$uci_ffprefix" == "" ] ; then
		uci_remove network fflandhcp ip6prefix 2>/dev/null
		uci_remove network fflandhcp ffprefix 2>/dev/null
		uci_set network fflandhcp ip6assign '64'
		uci_commit network
		log "reload network with no ip6prefix"
		ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
		sleep 3
		ubus call rc init '{"name":"odhcpd","action":"restart"}' 2>/dev/null || /etc/init.d/odhcpd restart
		ubus call rc init '{"name":"dnsmasq","action":"restart"}' 2>/dev/null || /etc/init.d/dnsmasq restart
	else
		log "no ip6prefix found"
	fi
elif [ ! "$prefix" == "$uci_ffprefix" ] ; then
	ip6prefix="$ip6prefix_new"
	uci_set network fflandhcp ip6prefix "$ip6prefix"
	uci_set network fflandhcp ffprefix "$prefix"
	uci_set network fflandhcp ip6assign '64'
	uci_commit network
	log "reload network with new $ip6prefix and old $uci_ffprefix"
	ubus call rc init '{"name":"network","action":"reload"}' 2>/dev/null || /etc/init.d/network reload
	sleep 3
	ubus call rc init '{"name":"odhcpd","action":"restart"}' 2>/dev/null || /etc/init.d/odhcpd restart
	ubus call rc init '{"name":"dnsmasq","action":"restart"}' 2>/dev/null || /etc/init.d/dnsmasq restart
fi
