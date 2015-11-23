
setup_system() {
	local cfg=$1
	uci_set system $cfg hostname "$hostname"

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
config_load ffwizard

# Set Hostname
config_get hostname ffwizard hostname
if [ -z "$hostname" ] ; then
	rand="$(echo -n $(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-4))"
	rand="$(printf "%d" "0x$rand")"
	hostname="OpenWrt-$rand"
	uci_set ffwizard ffwizard hostname "$hostname"
fi

# Set lat lon
config_get location ffwizard location
config_get latitude ffwizard latitude
config_get longitude ffwizard longitude


#Load dhcp config
config_load system
#Setup system hostname,timezone,location,latlon
config_foreach setup_system system



uci_commit ffwizard
uci_commit system

#Reload, set Hostname and Timezone
/etc/init.d/system reload
