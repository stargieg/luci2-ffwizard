#!/bin/sh
# Copyright (C) 2016 OpenWrt.org

. /lib/functions.sh
. /usr/share/libubox/jshn.sh

log_system() {
	logger -s -t ffwizard_system $@
}

setup_system() {
	local cfg=$1
	
	if [ -z "$hostname" ] || [ "$hostname" == "OpenWrt" ] ; then
		config_get hostname $cfg hostname "$hostname"
		log_system "No custom Hostname! Get sys Hostname $hostname"
	fi
	if [ -z "$hostname" ] || [ "$hostname" == "OpenWrt" ] ; then
		rand="$(echo -n $(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-4))"
		rand="$(printf "%d" "0x$rand")"
		hostname="$hostname-$rand"
		log_system "No valid Hostname! Set rand Hostname $hostname"
		uci_set system $cfg hostname "$hostname"
	else
		log_system "Set Hostname $hostname"
		uci_set system $cfg hostname "$hostname"
	fi

	# Set Timezone
	uci_set system $cfg zonename "Europe/Berlin"
	uci_set system $cfg timezone "CET-1CEST,M3.5.0,M10.5.0/3"

	# Set Location
	if [ -n "$location" ] ; then
		uci_set system $cfg location "$location"
	fi
	# Set Geo Location
	if [ -n "$latitude" ] ; then
		uci_set system $cfg latitude "$latitude"
	fi
	if [ -n "$longitude" ] ; then
		uci_set system $cfg longitude "$longitude"
	fi
}

#Load ffwizard config
json_init
json_load "$(cat /tmp/config.json)"
if ! json_select router ; then
	log_system "Exit no valid json"
	return 1
fi
# Set Hostname
json_get_var hostname name "OpenWrt"

json_select sshkeys
json_select keys
i=1;while json_is_a ${i} string;do
	json_get_var key ${i}
	echo $key >> /etc/dropbear/authorized_keys
	i=$(( i + 1 ))
done

json_select ..
json_select ..
json_select ..
json_select location
json_get_var latitude lat
json_get_var longitude lng
json_get_var street street
json_get_var postalCode postalCode
json_get_var city city

local location="$street $postalCode $city"

#Load dhcp config
config_load system
#Setup system hostname,timezone,location,latlon
config_foreach setup_system system

#Save
uci_commit system
