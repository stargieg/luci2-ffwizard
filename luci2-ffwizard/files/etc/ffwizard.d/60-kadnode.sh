
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

setup_kadnode() {
	local cfg="$1"
	local hostname="$2"
	uci_remove kadnode $cfg value_id
	uci_add_list kadnode $cfg value_id "$hostname"
}

#Load ffwizard config
config_load ffwizard

# Set Hostname
config_get hostname ffwizard hostname "OpenWrt"

#Load kadnode config
config_load kadnode
#Setup kadnode
config_foreach setup_kadnode kadnode "$hostname"

uci_commit kadnode
