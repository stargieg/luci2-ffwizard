

#remove https certs
#set new common name
#generate new certs with uhttpd restart
hostname=$(uci_get system.@system[0].hostname)
config_load uhttpd
config_get crtfile main cert
config_get keyfile main key
rm -f $crtfile
rm -f $keyfile
uci_set uhttpd px5g commonname $hostname
uci_commit uhttpd


#set ports for list on ipv6
uci_set uhttpd main listen_http 80
uci_set uhttpd main listen_https 443
uci_commit

#restart
/etc/init.d/uhttpd restart
