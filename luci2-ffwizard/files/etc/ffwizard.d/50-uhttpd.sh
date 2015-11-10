
#remove https certs
#set new common name
#generate new certs with uhttpd restart


get_hostname() {
	local cfg="$1"
	config_get sys_hostname $cfg hostname "$sys_hostname"
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
	uci_set uhttpd px5g commonname "$hostname"
	uci_commit uhttpd
fi

#set ports for listen on ipv6
uci_remove uhttpd main listen_http 2>/dev/null
uci_set uhttpd main listen_https "443"

#TODO disable http if the browser standard is https
if ! uci_get uhttpd redirect >/dev/null ; then
	uci_add uhttpd uhttpd redirect
fi
#TODO write redirect cgi script uri http --> https
#mkdir -p /www/redirect
#uci_set uhttpd redirect home "/www/redirect"
uci_set uhttpd redirect home "/www"
uci_set uhttpd redirect max_requests "3"
uci_set uhttpd redirect max_connections "100"
uci_set uhttpd redirect network_timeout "30"
uci_set uhttpd redirect http_keepalive "20"
uci_set uhttpd redirect tcp_keepalive "1"
uci_set uhttpd redirect ubus_prefix "/ubus"
uci_set uhttpd redirect rfc1918_filter "0"
uci_set uhttpd redirect listen_http "80"
uci_commit uhttpd

#
[ -s /www/index.html ] || ln -s /www/luci2.html /www/index.html

#restart
/etc/init.d/uhttpd restart
