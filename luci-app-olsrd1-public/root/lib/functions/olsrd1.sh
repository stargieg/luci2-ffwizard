# 1: destination variable
# 2: interface
# 3: path
# 4: separator
# 5: limit
__network_ifstatus() {
	local __tmp

	[ -z "$__NETWORK_CACHE" ] && {
		__tmp="$(ubus call network.interface dump 2>&1)"
		case "$?" in
			4) : ;;
			0) export __NETWORK_CACHE="$__tmp" ;;
			*) echo "$__tmp" >&2 ;;
		esac
	}

	__tmp="$(jsonfilter ${4:+-F "$4"} ${5:+-l "$5"} -s "${__NETWORK_CACHE:-{}}" -e "$1=@.interface${2:+[@.interface='$2']}$3")"

	[ -z "$__tmp" ] && \
		unset "$1" && \
		return 1

	eval "$__tmp"
}

# 1: addr
# 2: export var neighbour dev lladdr
network_get_neighbour_by_ip()
{
	local __tmp
	neighbour=''
	dev=''
	lladdr=''
	local ipaddr="$1"
	hostname=$(nslookup "$ipaddr" | grep name | cut -d " " -f 3 | sed -e 's/mid[0-9]*\./\1/' -e 's/\(.*\)\..*$/\1/')
	[ -z "$__NEIGH_CACHE" ] && {
		__tmp="$(ip -6 neigh)"
		export __NEIGH_CACHE="$__tmp"
	}
	[ -z "$__ROUTE_CACHE" ] && {
		__tmp="$(ip -6 route)"
		export __ROUTE_CACHE="$__tmp"
	}
	local gwaddr=$(echo "$__ROUTE_CACHE" | grep "^$ipaddr" | cut -d ' ' -f 3)
	[ -z "$gwaddr" ] && return
	ping -c 1 -I $gwaddr $ipaddr >/dev/null 2>/dev/null
	local neigh=$(echo "$__NEIGH_CACHE" | grep "$gwaddr")
	[ -z "$neigh" ] && return
	set -- $neigh
	eval "neighbour=$1;dev=$3;lladdr=$5"
}

# 1: addr
# 2: export var neighbour dev lladdr
network_get_neighbour_by_ip4()
{
	local __tmp
	neighbour=''
	dev=''
	lladdr=''
	local ipaddr="$1"
	hostname=$(nslookup "$ipaddr" | grep name | cut -d " " -f 3 | sed -e 's/mid[0-9]*\./\1/' -e 's/\(.*\)\..*$/\1/')
	[ -z "$__ROUTE_CACHE" ] && {
		__tmp="$(ip -4 route)"
		export __ROUTE_CACHE="$__tmp"
	}
	local gwdev=$(echo "$__ROUTE_CACHE" | grep "^$ipaddr" | cut -d ' ' -f 5)
	[ -z "$gwdev" ] && return
	ping -c 1 -I $gwdev $ipaddr >/dev/null 2>/dev/null
	local neigh=$(ip -4 neigh | grep "$ipaddr")
	[ -z "$neigh" ] && return
	set -- $neigh
	eval "neighbour=$1;dev=$3;lladdr=$5"
}

# 1: destination variable
# 2: addr
network_get_name_by_device()
{
	__network_ifstatus "$1" "" \
		"[@.device='$2' && !@.table].interface" "" 1 && \
			return 0
}

