
log_system() {
	logger -s -t ffwizard_system $@
}

setup_system() {
	local cfg=$1
	if [ "$hostname" == "OpenWrt" ] ; then
		config_get hostname $cfg hostname "$hostname"
		uci_set ffwizard ffwizard hostname "$hostname"
		log_system "No custom Hostname! Get sys Hostname $hostname"
	fi
	if [ "$hostname" == "OpenWrt" ] ; then
		rand="$(echo -n $(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-4))"
		rand="$(printf "%d" "0x$rand")"
		hostname="$hostname-$rand"
		log_system "No valid Hostname! Set rand Hostname $hostname"
		uci_set system $cfg hostname "$hostname"
		uci_set ffwizard ffwizard hostname "$hostname"
	else
		log_system "Set Hostname $hostname"
		uci_set system $cfg hostname "$hostname"
	fi

	if uci_get snmpd ; then
		uci_set snmpd @system[-1] sysName "$hostname"
		# Set Contact mail address
		if [ ! -z "$mail" ] ; then
			uci_set snmpd @system[-1] sysContact "$mail"
		fi
		# Set nickname
		if [ ! -z "$nickname" ] ; then
			uci_set snmpd @system[-1] sysDescr "$nickname"
		fi
		# Set Location
		if [ ! -z "$location" ] ; then
			uci_set snmpd @system[-1] sysLocation "$location"
		fi
	fi

	if uci_get freifunk ; then
		# Set Contact mail address
		if [ ! -z "$mail" ] ; then
			uci_set freifunk contact "$mail"
		fi
		# Set nickname
		if [ ! -z "$nickname" ] ; then
			uci_set freifunk nickname "$nickname"
		fi
	fi

	if ! [ "$domain" == "olsr" ] ; then
		uci_set system $cfg domain "$domain"
	fi

	# Set Timezone
	uci_set system $cfg zonename "Europe/Berlin"
	uci_set system $cfg timezone "CET-1CEST,M3.5.0,M10.5.0/3"

	# Set Location
	if [ ! -z "$location" ] ; then
		uci_set system $cfg location "$location"
	fi
	# Set Geo Location
	if [ ! -z "$latitude" ] ; then
		uci_set system $cfg latitude "$latitude"
	fi
	if [ ! -z "$longitude" ] ; then
		uci_set system $cfg longitude "$longitude"
	fi
}

#Load ffwizard config
config_load ffwizard

# Set Hostname
config_get hostname ffwizard hostname "OpenWrt"

# Set Domain
config_get domain ffwizard domain "olsr"

# Set loc lat lon
config_get location ffwizard location
config_get latitude ffwizard latitude
config_get longitude ffwizard longitude

config_get mail ffwizard mail
config_get nickname ffwizard nickname

#Load dhcp config
config_load system
#Setup system hostname,timezone,location,latlon
config_foreach setup_system system

#Save
uci_commit system
uci_commit ffwizard
uci_get snmpd && uci_commit snmpd
uci_get freifunk && uci_commit freifunk
