
config_load ffwizard
config_get hostname ffwizard hostname
config_get location ffwizard location
config_get latitude ffwizard latitude
config_get longitude ffwizard longitude

# Set Hostname
if [ -z $hostname ] ; then
	rand=$(echo -n $(head -n 1 /dev/urandom 2>/dev/null | md5sum | cut -b 1-4))
	hostname="OpenWrt-$rand"
fi

uci set system.@system[0].hostname="$hostname"
echo $hostname > /proc/sys/kernel/hostname

# Set Timezone
uci set system.@system[0].zonename="Europe/Berlin"
uci set system.@system[0].timezone="CET-1CEST,M3.5.0,M10.5.0/3"

# Set Location
if [ -n $location ] ; then
	uci set system.@system[0].location=$location
fi
# Set Geo Location
if [ -n $latitude ] ; then
	uci set system.@system[0].latitude=$latitude
fi
if [ -n $longitude ] ; then
	uci set system.@system[0].longitude=$longitude
fi

uci commit
