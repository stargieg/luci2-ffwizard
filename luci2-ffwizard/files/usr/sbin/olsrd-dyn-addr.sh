#!/bin/sh

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

format6() {
	echo $1 | tr 'A-F' 'a-f'
}

log() {
	logger -s -t olsrd-dyn-addr $@
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

update_hna6() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	local hna6gw="$4"
	local prefix="$5"
	config_get cfg_netaddr $cfg netaddr
	ula="$(echo $cfg_netaddr | cut -b -2)"
	if [ "$ula" != "fd" ] && [ "$ula" != "fe" ] ; then
		config_get gw $cfg _gw
		config_get idx $cfg _idx
		if [ "$hna6gw" == "$gw" -a "$prefix" == "$idx" ] ; then
			if [ "$cfg_netaddr" != "$address" ] ; then
				log "Set New netaddr $address for gw $gw"
				log "    Old netaddr $cfg_netaddr for gw $gw"
				uci_set olsrd6 "$cfg" prefix "$mask"
				uci_set olsrd6 "$cfg" netaddr "$address"
				#uci_commit olsrd6
				local reload=1
			fi
		else
			log "UCI Hna6 $cfg_netaddr Not Managed from gateway $hna6gw_tmp"
			#echo "uci set olsrd6.Hna6[]._gw=$hna6gw"
			#echo "uci set olsrd6.Hna6[]._idx=$prefix"
		fi
	fi
}

clean_hna6() {
	local cfg="$1"
	local hna6gw="$2"
	local prefix="$3"
	config_get cfg_netaddr $cfg netaddr
	ula="$(echo $cfg_netaddr | cut -b -2)"
	if [ $ula != fd -a $ula != fe ] ; then
		config_get gw $cfg _gw
		config_get idx $cfg _idx 0
		if [ "$hna6gw" == "$gw" -a "$prefix" -lt "$idx" ] ; then
			log "Remove UCI Hna6 $cfg_netaddr Managed from gateway $hna6gw index $idx"
			uci_remove olsrd6 "$cfg"
			#uci_commit olsrd6
			reload=1
		fi
	fi
}

clean_hna6_ip6pre() {
	local cfg="$1"
	local address="$2"
	config_get cfg_netaddr $cfg netaddr
	if [ "$cfg_netaddr" == "$address" ] ; then
		log "Remove UCI Hna6 $cfg_netaddr"
		uci_remove olsrd6 "$cfg"
		#uci_commit olsrd6
		local reload=1
	fi
}

list_hosts() {
	local val=$1
	local cfg=$2
	local hostname=$3
	local address=$4
	local mask="$5"
	local hna6gw="$6"
	local prefix="$7"
	log "val: $val cfg: $cfg address: $address mask: $mask hna6gw: $hna6gw prefix: $prefix"
	hostname="$(cat /proc/sys/kernel/hostname)"
	case $val in
		*prefix-$prefix-hna6*)
			uci_add_list olsrd6 $cfg hosts "$address""1 prefix-$prefix-hna6.$hostname"
		;;
		*)
			uci_add_list olsrd6 $cfg hosts "$val"
		;;
	esac
}

update_hosts() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	local hna6gw="$4"
	local prefix="$5"
	config_get library $cfg library
	case $library in
		olsrd_nameservice*)
			hostname="$(cat /proc/sys/kernel/hostname)"
			if [ -n "$(uci_get olsrd6 $cfg hosts)" ] ; then
				log "update hosts $address""1 prefix-$prefix-hna6.$hostname"
				config_get hosts $cfg hosts
				uci_remove olsrd6 $cfg hosts
				config_list_foreach $cfg hosts list_hosts $cfg $hostname $address $mask $hna6gw $prefix
			else
				log "add hosts $address""1 prefix-$prefix-hna6.$hostname"
				uci_add_list olsrd6 $cfg hosts "$address""1 prefix-$prefix-hna6.$hostname"
			fi
		;;
	esac
}

add_hosts() {
	local cfg="$1"
	local address="$2"
	local mask="$3"
	local hna6gw="$4"
	local prefix="$5"
	config_get library $cfg library
	case $library in
		olsrd_nameservice*)
			hostname="$(cat /proc/sys/kernel/hostname)"
			log "add hosts $address""1 prefix-$prefix-hna6.$hostname"
			uci_add_list olsrd6 $cfg hosts "$address""1 prefix-$prefix-hna6.$hostname"
		;;
	esac
}

del_hosts() {
	local val=$1
	local cfg=$2
	local hna6gw="$3"
	local prefix="$4"
	log "val: $val cfg: $cfg hna6gw: $hna6gw prefix: $prefix"
	case $val in
		*prefix-*-hna6*)
			cfg_prefix="$(echo $val | cut -d '-' -f 2)"
			if [ "$prefix" -ge "$cfg_prefix" ] ; then
				uci_add_list olsrd6 $cfg hosts "$val"
			fi
		;;
		*)
			uci_add_list olsrd6 $cfg hosts "$val"
		;;
	esac
}

clean_hosts() {
	local cfg="$1"
	local hna6gw="$2"
	local prefix="$3"
	config_get library $cfg library
	case $library in
		olsrd_nameservice*)
			if [ -n "$(uci_get olsrd6 $cfg hosts)" ] ; then
				log "clean hosts gt pre$prefix"
				config_get hosts $cfg hosts
				uci_remove olsrd6 $cfg hosts
				config_list_foreach $cfg hosts del_hosts $cfg $hna6gw $prefix
			fi
		;;
	esac
}

del_hosts_ip6pre() {
	local val=$1
	local cfg=$2
	local address="$3"
	log "val: $val cfg: $cfg address: $address"
	case $val in
		*prefix-*-hna6*)
			cfg_prefix="$(echo $val | cut -d '-' -f 2)"
			if ! echo $val | grep -q $address ; then
				uci_add_list olsrd6 $cfg hosts "$val"
			fi
		;;
		*)
			uci_add_list olsrd6 $cfg hosts "$val"
		;;
	esac
}

clean_hosts_ip6pre() {
	local cfg="$1"
	local address="$2"
	config_get library $cfg library
	case $library in
		olsrd_nameservice*)
			if [ -n "$(uci_get olsrd6 $cfg hosts)" ] ; then
				log "clean hosts gt pre$prefix"
				config_get hosts $cfg hosts
				uci_remove olsrd6 $cfg hosts
				config_list_foreach $cfg hosts del_hosts_ip6pre $cfg $address
			fi
		;;
	esac
}

local ip6prefix
local ip6prefix_new


if [ "$(uci_get network lan)" == "interface" ] ; then
	cfg_ip6prefix="lan"
elif [ "$(uci_get network ffdhcp)" == "interface" ] ; then
	cfg_ip6prefix="ffdhcp"
else
	log "Exit no cfg ip6prefix source"
	return 1
fi

ip6prefix="$(uci_get network $cfg_ip6prefix ip6prefix)"
ip6prefix_new=$ip6prefix

json_init
json_load "$(echo /hna|nc ::1 9090)"
if ! json_select hna ; then
	log "Exit no olsrd6 on port 9090"
	return 1
fi

local hna0gw=""
local hna56gw=""
local hna52gw=""
local hna48gw=""
i=1;while json_is_a ${i} object;do
	json_select ${i}
	json_get_var destination destination
	json_get_var genmask genmask
	json_get_var gateway gateway
	case $genmask in
		0) hna0gw="$gateway $hna0gw" ;;
		62) hna62destination="$destination $hna62destination" ;;
		56) hna56destination="$destination $hna56destination" ;;
		52) hna52destination="$destination $hna52destination" ;;
		48) hna48destination="$destination $hna48destination" ;;
	esac
	json_select ..
	i=$(( i + 1 ))
done

local reload=0
for j in $hna0gw ; do
	local pre="1"
	i=1;while json_is_a ${i} object;do
		json_select ${i}
		json_get_var destination destination
		json_get_var genmask genmask
		json_get_var gateway gateway
		#Nutzbare Prefixe für das Gateway $j müssen eine Netzmaske 48 52 oder 56 haben
		if [ $gateway == $j ] && [ $genmask == 48 ] || [ $genmask -eq 42 ] || [ $genmask -eq 56 ] ; then
			ula="$(echo $destination | cut -b -2)"
			if [ $ula != fd -a $ula != fe ] ; then
				local netaddr="0"
				for k in $ip6prefix ; do
					case $genmask in
						56) ip6pre="$(echo $k | sed -e 's/[0-9a-fA-F]\{1,2\}::\/62/00::/')" ;;
						52) ip6pre="$(echo $k | sed -e 's/[0-9a-fA-F]\{1,3\}::\/62/000::/')" ;;
						48) ip6pre="$(echo $k | sed -e 's/:[0-9a-fA-F]\{1,4\}::\/62/::/')" ;;
						*) ip6pre="" ;;
					esac
					if [ "$destination" == "$ip6pre" ] ; then
						netaddr="$(echo $k | cut -d '/' -f 1)"
					fi
				done
				local hna6update=0
				if [ "$netaddr" != "0" ] ; then
					config_load olsrd6
					config_foreach update_hna6 Hna6 $netaddr $genmask $gateway $pre
					log "destination: $destination netaddr: $netaddr genmask: $genmask"
					config_foreach update_hosts LoadPlugin $netaddr $genmask $gateway $pre
				else
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
					address="$netaddr/62"
					log "Add Hna6 address=$address _gw=$gateway _idx=$pre"
					#add Hna6 for Host Interfaces
					uci_add olsrd6 Hna6 ; hna_sec="$CONFIG_SECTION"
					uci_set olsrd6 "$hna_sec" prefix "62"
					uci_set olsrd6 "$hna_sec" netaddr "$netaddr"
					uci_set olsrd6 "$hna_sec" _gw "$gateway"
					uci_set olsrd6 "$hna_sec" _idx "$pre"
					config_load olsrd6
					config_foreach add_hosts LoadPlugin $netaddr $genmask $gateway $pre
					ip6prefix_new="$address $ip6prefix_new"
				fi
				pre=$(( pre + 1 ))
			fi
		fi
		json_select ..
		i=$(( i + 1 ))
	done
	config_load olsrd6
	config_foreach clean_hna6 Hna6 $j $pre
	#config_foreach clean_hosts LoadPlugin $j $pre
done

for k in $ip6prefix ; do
	local validate="0"
	for j in $hna0gw ; do
		for i in $hna56destination ; do
			ip6pre=$(echo $k | sed -e 's/[0-9a-fA-F]\{1,2\}::\/62/00::/')
			if [ $i == $ip6pre ] ; then
				validate="1"
			fi
		done
		for i in $hna52destination ; do
			ip6pre=$(echo $k | sed -e 's/[0-9a-fA-F]\{1,3\}::\/62/000::/')
			if [ $i == $ip6pre ] ; then
				validate="1"
			fi
		done
		for i in $hna48destination ; do
			ip6pre=$(echo $k | sed -e 's/:[0-9a-fA-F]\{1,4\}::\/62/::/')
			if [ $i == $ip6pre ] ; then
				validate="1"
			fi
		done
		for i in $hna62destination ; do
			ip6pre=$(echo $k | sed -e 's/\/62//')
			if [ $i == $ip6pre ] ; then
				log "Del Dup"
				log "hna0gw:           $j"
				log "hna62destination: $i"
				log "ip6pre:           $ip6pre"
				log "ip6prefix:        $k"
				validate="0"
			fi
		done
	done
	if [ $validate == 0 ] ; then
		ip6pre=$(echo $k | sed -e 's/\/62//')
		log "Del Not Validate"
		log "ip6pre:           $ip6pre"
		config_load olsrd6
		config_foreach clean_hna6_ip6pre Hna6 $ip6pre
		config_foreach clean_hosts_ip6pre LoadPlugin $ip6pre
		ip6prefix_tmp=""
		for l in $ip6prefix_new ; do
			if [ $l != $k ] ; then
				ip6prefix_tmp="$l $ip6prefix_tmp"
			fi
		done
		ip6prefix_new=$ip6prefix_tmp
	else
		log "Validate"
		log "ip6pre:           $ip6pre"
		log "ip6prefix:        $k"
	fi
done

if [ "$ip6prefix_new" != "$ip6prefix" ] ; then
	log "Update network $cfg_ip6prefix ip6prefix"
	log "ip6prefix:        $ip6prefix"
	log "ip6prefix_new:    $ip6prefix_new"
	if [ -n "$(uci_get network $cfg_ip6prefix ip6prefix)" ] ; then
		uci_remove network $cfg_ip6prefix ip6prefix
	fi
	for i in $ip6prefix_new ; do
		uci_add_list network $cfg_ip6prefix ip6prefix $i
	done
	uci_commit network
	uci_commit olsrd6

	ubus call uci "reload_config"

else
	log "Revert changes on olsrd6"
	uci_revert olsrd6
	log "Revert changes on network $cfg_ip6prefix ip6prefix"
	uci_revert network $cfg_ip6prefix ip6prefix
fi
