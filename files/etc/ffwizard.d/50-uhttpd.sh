
#remove https certs
#set new common name
#generate new certs with uhttpd restart


get_hostname() {
	local cfg=$1
	config_get sys_hostname $cfg hostname $sys_hostname
}


local sys_hostname

#Load dhcp config
config_load system
#Setup dnsmasq
config_foreach get_hostname system

config_load uhttpd
config_get crtfile main cert
config_get keyfile main key
config_get cn_hostname px5g commonname
if [ "$cn_hostname" != "$sys_hostname" ] ; then
	rm -f $crtfile
	rm -f $keyfile
	uci_set uhttpd px5g commonname $hostname
	uci_commit uhttpd
fi

#set ports for list on ipv6
uci_set uhttpd main listen_http 80
uci_set uhttpd main listen_https 443
uci_commit

#
[ -s /www/index.html ] || ln -s /www/luci2.html /www/index.html

#restart
/etc/init.d/uhttpd restart
