
iface=""

uci_add_list() {
	local PACKAGE="$1"
	local CONFIG="$2"
	local OPTION="$3"
	local VALUE="$4"

	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$PACKAGE.$CONFIG.$OPTION=$VALUE"
}

log_kadnode() {
	logger -s -t ffwizard_kadnode $@
}

setup_ether() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	if [ "$olsr_mesh" == "1" ] ; then
		iface=$cfg
	fi
}

setup_wifi() {
	local cfg="$1"
	config_get enabled $cfg enabled "0"
	[ "$enabled" == "0" ] && return
	config_get olsr_mesh $cfg olsr_mesh "0"
	if [ "$olsr_mesh" == "1" ] ; then
		iface=$cfg"_mesh"
	fi
}

setup_kadnode() {
	local cfg="$1"
	local hostname="$2"
	local iface="$3"
	uci_set kadnode $cfg enabled "1"
	uci_set kadnode $cfg ipv6 "1"
	uci_set kadnode $cfg ipv4 "0"
	uci_set kadnode $cfg verbosity "quiet"
	uci_set kadnode $cfg port "5881"
	uci_remove kadnode $cfg peer 2>/dev/null
	uci_set kadnode $cfg peerfile '/etc/kadnode_peers.txt'
	#TODO https://github.com/mwarning/KadNode/issues/44
	#uci_set kadnode $cfg ifname "$iface"
	uci_remove kadnode $cfg bob_load_key 2>/dev/null
	uci_add_list kadnode $cfg bob_load_key '/etc/kadnode_secret.pem'
	uci_remove kadnode $cfg tls_server_cert 2>/dev/null
	uci_add_list kadnode $cfg tls_server_cert '/etc/uhttpd.crt,/etc/uhttpd.key'
	uci_remove kadnode $cfg tls_client_cert 2>/dev/null
	uci_add_list kadnode $cfg tls_client_cert '/etc/ssl/cert.pem'
	uci_remove kadnode $cfg announce 2>/dev/null
	uci_add_list kadnode $cfg announce "$hostname"".olsr"
	local hostid="$(rm /etc/kadnode_secret.pem;kadnode --bob-create-key /etc/kadnode_secret.pem | grep 'Public key' | cut -d ' ' -f 3)"
	uci_add_list kadnode $cfg announce "$hostid"
}

#Load ffwizard config
config_load ffwizard

# Set Hostname
config_get hostname ffwizard hostname "OpenWrt"

#Setup ether and wifi
config_foreach setup_ether ether
config_foreach setup_wifi wifi

#Load kadnode config
config_load kadnode
#Setup kadnode
config_foreach setup_kadnode kadnode "$hostname" "$iface"

uci_commit kadnode
mkdir -p /tmp/ff
touch /tmp/ff/kadnode
