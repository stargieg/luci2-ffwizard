
#remove https certs
#set new common name
#generate new certs with uhttpd restart


get_hostname() {
	local cfg="$1"
	config_get sys_hostname $cfg hostname "$sys_hostname"
}


sys_hostname=""

#Load system config
config_load system
#Setup dnsmasq
config_foreach get_hostname system

#Load uhttpd config
config_load uhttpd
config_get commonname defaults commonname
sys_fqdn="$sys_hostname"".olsr"
if [ "$commonname" != "$sys_fqdn" ] ; then
	config_get crtfile main cert
	config_get keyfile main key
	[ -f "$crtfile" ] && rm -f "$crtfile"
	[ -f "$keyfile" ] && rm -f "$keyfile"
	uci_set uhttpd defaults commonname "$sys_fqdn"
	uci_commit uhttpd
fi

[ -s /www/index.html ] || ln -s /www/luci-ng.html /www/index.html
