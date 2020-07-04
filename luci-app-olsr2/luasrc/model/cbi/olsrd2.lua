-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2010 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

require("luci.tools.webadmin")
local utl = require "luci.util"
local nwm = require "luci.model.network".init()
local net, iface, arg_if, arg_interface, arg_global, arg_log, arg_olsrv2
local arg_mesh, arg_lan_import
local networks = nwm:get_networks()

m = Map("olsrd2", translate("OLSR2 Daemon"),
	translate("olsrd2 implements the IETF <a href='http://tools.ietf.org/html/rfc6130'>RFC 6130: Neighborhood Discovery Protocol (NHDP)</a> and <a href='http://tools.ietf.org/html/rfc7181'>RFC 7181: Optimized Link State Routing Protocol v2.</a>"))

if arg[1] then
	if arg[1] == "global" then
		arg_global=true
	end
	if arg[1] == "log" then
		arg_log=true
	end
	if arg[1] == "olsrv2" then
		arg_olsrv2=true
	end
	if arg[1] == "domain" then
		arg_domain=true
	end
	if arg[1] == "mesh" then
		arg_mesh=true
	end
	if arg[1] == "lan_import" then
		arg_lan_import=true
	end
	if arg[1] == "interface" then
		arg_interface=true
		if arg[2] and m.uci:get("olsrd2", arg[2]) == "interface" then
			arg_if = arg[2]
		end
	end
end

if arg_global then
	s = m:section(TypedSection, "global", translate("It controls the basic behavior of the OONF core."))
	s.anonymous = true
	s.addremove = true
	local svc = s:option(Value, "failfast", translate("failfast is another boolean setting which can activate an error during startup if a requested plugin does not load or an unknown configuration variable is set."), "bool")
	svc.optional = true
	svc.rmempty = false
	svc.datatype = "bool"
	local svc = s:option(Value, "pidfile", translate("pidfile is used together with the fork option to store the pid of the background process in a file."),"Filename")
	svc.rmempty = false
	svc.optional = true
	svc.placeholder = "/var/run/olsrd2.pid"
	svc.datatype = "string"
	local svc = s:option(Value, "lockfile", translate("lockfile creates a file on disk and keeps a lock on it as long as the OONF application is running to prevent the application from running multiple times at once."),"Filename")
	svc.rmempty = false
	svc.optional = true
	svc.placeholder = "/var/lock/olsrd2"
	svc.datatype = "string"
end
if arg_log then
	s = m:section(TypedSection, "log", translate("OONF Logging"))
	s.anonymous = true
	s.addremove = true
	local svc = s:option(Value, "syslog", translate("syslog are boolean options that activate or deactivate the syslog Logging Target."), "bool")
	svc.optional = true
	svc.datatype = "bool"
	local svc = s:option(Value, "stderr", translate("stderr are boolean options that activate or deactivate the stderr Logging Target."), "bool")
	svc.optional = true
	svc.datatype = "bool"
	local svc = s:option(Value, "file", translate("file asks for a filename for logging output"),"Filename")
	svc.rmempty = false
	svc.optional = true
	svc.placeholder = "/tmp/olsrd2.log"
	svc.datatype = "string"
	local svc = s:option(Value, "debug", translate("debug ask for a list of Logging Sources that will be logged by the OONF Core Logging Targets."))
	svc.rmempty = false
	svc.optional = true
	svc.datatype = "string"
	local svc = s:option(Value, "info", translate("info ask for a list of Logging Sources that will be logged by the OONF Core Logging Targets."))
	svc.rmempty = false
	svc.optional = true
	svc.datatype = "string"
end
if arg_olsrv2 then
	s = m:section(TypedSection, "olsrv2", translate("the OLSRv2 implementation including the OLSRv2 API for other plugins."))
	s.anonymous = true
	s.addremove = true
	local svc = s:option(Value, "tc_interval", translate("defines the time between two TC messages."), "s")
	svc.optional = true
	svc.placeholder = 5.0
	svc.datatype = "ufloat"
	local svc = s:option(Value, "tc_validity", translate("tc_validity defines the validity time of the TC messages."), "s")
	svc.optional = true
	svc.placeholder = 300.0
	svc.datatype = "ufloat"
	local svc = s:option(Value, "forward_hold_time", translate("forward_hold_time defines the time until the router will forget an entry in its forwarding duplicate database."), "s")
	svc.optional = true
	svc.placeholder = 300.0
	svc.datatype = "ufloat"
	local svc = s:option(Value, "processing_hold_time", translate("processing_hold_time defines the time until the router will forget an entry in its processing duplicate database."), "s")
	svc.optional = true
	svc.placeholder = 300.0
	svc.datatype = "ufloat"
	local svc = s:option(DynamicList, "routable", translate("routable defines the ACL which declares an IP address routable. Other IP addresses will not be included in TC messages."), "ip6prefix, ip4prefix, default_accept, default_reject")
	svc.datatype = "string"
--TODO
--svc.datatype = "or(negm(ip6addr), negm(ip4addr), 'default_accept', 'default_reject')"
--modules/luci-base/htdocs/luci-static/resources/cbi.js:545
--			negm: function() {
--			return this.apply('or', this.value.replace(/^[ \t]*-[ \t]*/, ''), arguments);
--		},
	--modules/luci-base/luasrc/cbi/datatypes.lua:51
--function negm(v, ...)
--	return _M['or'](v:gsub("^%s*-%s*", ""), ...)
--end
	svc.optional = true
	local svc = s:option(DynamicList, "lan", translate("lan defines the locally attached network prefixes (similar to HNAs in OLSR v1). A LAN entry is a IP address/prefix, followed (optionally) by up to three key=value pairs defining the metric cost, hopcount distance and domain of the LAN ( <metric=...> <dist=...> <domain=...> )."), "ip6prefix, ip4prefix, src=ip6prefix")
	svc.datatype = "string"
	--svc.datatype = "or(ip6addr, ip4addr, 'src='"
	svc.optional = true
	local svc = s:option(DynamicList, "originator", translate("originator defines the ACL which declares a valid originator IP address for the router."), "ip6prefix, ip4prefix, default_accept, default_reject")
	svc.datatype = "string"
--TODO
--svc.datatype = "or(negm(ip6addr), negm(ip4addr), 'default_accept', 'default_reject')"
--modules/luci-base/htdocs/luci-static/resources/cbi.js:545
--			negm: function() {
--			return this.apply('or', this.value.replace(/^[ \t]*-[ \t]*/, ''), arguments);
--		},
	--modules/luci-base/luasrc/cbi/datatypes.lua:51
--function negm(v, ...)
--	return _M['or'](v:gsub("^%s*-%s*", ""), ...)
--end
	svc.optional = true
end
if arg_domain then
	s = m:section(TypedSection, "domain", translate("domain configuration section"))
	s.anonymous = true
	s.addremove = true
	local svc = s:option(Value, "table", translate("table defines the routing table for the local routing entries."), "0-254")
	svc.optional = true
	svc.placeholder = 254
	svc.datatype = "range(0,254)"
	local svc = s:option(Value, "protocol", translate("protocol defines the protocol number for the local routing entries."), "0-254")
	svc.optional = true
	svc.placeholder = 100
	svc.datatype = "range(0,254)"
	local svc = s:option(Value, "distance", translate("distance defines the 'metric' (hopcount) of the local routing entries."), "0-254")
	svc.optional = true
	svc.placeholder = 2
	svc.datatype = "range(0,254)"
	local svc = s:option(Value, "srcip_routes", translate("srcip_routes defines if the router sets the originator address as the source-ip entry into the local routing entries."), "bool")
	svc.optional = true
	svc.datatype = "bool"
end
if arg_mesh then
	s = m:section(TypedSection, "mesh", translate("mesh configuration section"))
	s.anonymous = true
	s.addremove = true
	local svc = s:option(Value, "port", translate("port defines the UDP port number of the RFC5444 socket."), "1-65535")
	svc.optional = true
	svc.placeholder = 269
	svc.datatype = "range(1,65535)"
	local svc = s:option(Value, "ip_proto", translate("ip_proto defines the IP protocol number that can be used for RFC5444 communication."), "1-255")
	svc.optional = true
	svc.placeholder = 138
	svc.datatype = "range(1,255)"
	local svc = s:option(Value, "aggregation_interval", translate("aggregation_interval defines the time the local RFC5444 implementation will keep messages to aggregate them before creating a new RFC5444 packet to forward them."), ">0.1 s")
	svc.optional = true
	svc.placeholder = 1.0
	svc.datatype = "and(min(0.1), ufloat)"
end
if arg_lan_import then
	s = m:section(TypedSection, "lan_import", translate("Automatic import of routing tables as locally attached networks."))
	s.anonymous = true
	s.addremove = true
	local svc = s:option(Value, "name", translate("Name"), "Text")
	svc.datatype = "string"
	local svc = s:option(Value, "interface", translate("Interface"), "Name Interface")
	svc.datatype = "string"
	local svc = s:option(Value, "table", translate("IP Table"), "1-255")
	svc.datatype = "range(1,255)"
	local svc = s:option(Value, "protocol", translate("IP protocol"), "1-255")
	svc.datatype = "range(1,255)"
end

if not arg_if and arg_interface then
	ifs = m:section(TypedSection, "interface", translate("interface configuration section"))
	ifs.anonymous = true
	ifs.addremove = true
	ifs.extedit = luci.dispatcher.build_url("admin/services/olsrd2/interface/%s")
	ifs.template = "cbi/tblsection"
	ifs:tab("general", translate("General Settings"))
end
if arg_if and arg_interface then
	ifs = m:section(NamedSection, arg_if, "interface", translate(" interface configuration section"))
	ifs.anonymous = true
	ifs.addremove = true
	ifs:tab("general", translate("General Settings"))
	ifs:tab("oonf", translate("OONF RFC5444 Plugin"))
	ifs:tab("nhdp", translate("NHDP Plugin"))
	ifs:tab("link", translate("Link Config Plugin"))
end

if arg_interface then
	local ign = ifs:taboption("general",Flag, "ignore", translate("Enable"))
	ign.enabled = "0"
	ign.disabled = "1"
	ign.rmempty = false
	function ign.cfgvalue(self, section)
		return Flag.cfgvalue(self, section) or "0"
	end
	local svc = ifs:taboption("general", Value, "ifname", translate("Network"),
	translate("The interface OLSR2 should serve."))
	for _, net in ipairs(networks) do
		if (not net:is_virtual()) then
			svc:value(net:name())
		end
	end
	svc.widget = "select"
	svc.nocreate = true
end

if arg_interface and arg_if then
	local svc = ifs:taboption("oonf", DynamicList, "acl", translate("acl defines the IP addresses that are allowed to use the RFC5444 socket."), "ip6prefix, ip4prefix, default_accept, default_reject")
	svc.datatype = "string"
--TODO
--svc.datatype = "or(negm(ip6addr), negm(ip4addr), 'default_accept', 'default_reject')"
--modules/luci-base/htdocs/luci-static/resources/cbi.js:545
--			negm: function() {
--			return this.apply('or', this.value.replace(/^[ \t]*-[ \t]*/, ''), arguments);
--		},
	--modules/luci-base/luasrc/cbi/datatypes.lua:51
--function negm(v, ...)
--	return _M['or'](v:gsub("^%s*-%s*", ""), ...)
--end
	svc.optional = true
	local svc = ifs:taboption("oonf", DynamicList, "bindto", translate("bindto defines the IP addresses which the RFC5444 socket will be bound to."), "ip6prefix, ip4prefix, default_accept, default_reject")
	svc.datatype = "string"
--TODO
--svc.datatype = "or(negm(ip6addr), negm(ip4addr), 'default_accept', 'default_reject')"
--modules/luci-base/htdocs/luci-static/resources/cbi.js:545
--			negm: function() {
--			return this.apply('or', this.value.replace(/^[ \t]*-[ \t]*/, ''), arguments);
--		},
	--modules/luci-base/luasrc/cbi/datatypes.lua:51
--function negm(v, ...)
--	return _M['or'](v:gsub("^%s*-%s*", ""), ...)
--end
	svc.optional = true
	local svc = ifs:taboption("oonf", Value, "multicast_v4", translate("multicast_v4 defines the IPv4 multicast address used for RFC5444 packets."), "ip4addr")
	svc.datatype = "ip4addr"
	svc.placeholder = "224.0.0.109"
	svc.optional = true
	local svc = ifs:taboption("oonf", Value, "multicast_v6", translate("multicast_v6 defines the IPv6 multicast address used for RFC5444 packets."), "ip6addr")
	svc.datatype = "ip6addr"
	svc.placeholder = "ff02::6d"
	svc.optional = true
	local svc = ifs:taboption("oonf", Value, "dscp", translate("dscp defines the DSCP value set for each outgoing RFC5444 packet. The value must be between 0 and 252 without fractional digits. The value should be a multiple of 4."), "0-255")
	svc.optional = true
	svc.placeholder = 192
	svc.datatype = "range(0,255)"
	local svc = ifs:taboption("oonf", Value, "rawip", translate("rawip defines if the interface should put RFC5444 packets directly into IP headers (skipping the UDP header)."), "bool")
	svc.optional = true
	svc.rmempty = true
	svc.datatype = "bool"
	local svc = ifs:taboption("nhdp", DynamicList, "ifaddr_filter", translate("ifaddr_filter defines the IP addresses that are allowed to NHDP interface addresses."), "ip6prefix, ip4prefix, default_accept, default_reject")
	svc.datatype = "string"
--TODO
--svc.datatype = "or(negm(ip6addr), negm(ip4addr), 'default_accept', 'default_reject')"
--modules/luci-base/htdocs/luci-static/resources/cbi.js:545
--			negm: function() {
--			return this.apply('or', this.value.replace(/^[ \t]*-[ \t]*/, ''), arguments);
--		},
	--modules/luci-base/luasrc/cbi/datatypes.lua:51
--function negm(v, ...)
--	return _M['or'](v:gsub("^%s*-%s*", ""), ...)
--end
	svc.optional = true
	local svc = ifs:taboption("nhdp", Value, "hello_validity", translate("hello_validity defines the time the local HELLO messages will be valid for the neighbors."), ">0.1 s")
	svc.optional = true
	svc.placeholder = 20.0
	svc.datatype = "and(min(0.1), ufloat)"
	local svc = ifs:taboption("nhdp", Value, "hello_interval", translate("hello_interval defines the time between two HELLO messages on the interface."), ">0.1 s")
	svc.optional = true
	svc.placeholder = 2.0
	svc.datatype = "and(min(0.1), ufloat)"
	local svc = ifs:taboption("link", Value, "rx_bitrate", translate("rx_bitrate"))
	svc.optional = true
	svc.rmempty = false
	svc.placeholder = "1G"
	svc.datatype = "string"
	local svc = ifs:taboption("link", Value, "tx_bitrate", translate("tx_bitrate"))
	svc.optional = true
	svc.rmempty = false
	svc.placeholder = "1G"
	svc.datatype = "string"
	local svc = ifs:taboption("link", Value, "rx_max_bitrate", translate("rx_max_bitrate"))
	svc.optional = true
	svc.rmempty = false
	svc.placeholder = "1G"
	svc.datatype = "string"
	local svc = ifs:taboption("link", Value, "tx_max_bitrate", translate("tx_max_bitrate"))
	svc.optional = true
	svc.rmempty = false
	svc.placeholder = "1G"
	svc.datatype = "string"
	local svc = ifs:taboption("link", Value, "rx_signal", translate("rx_signal"))
	svc.optional = true
	svc.rmempty = false
	svc.placeholder = "1G"
	svc.datatype = "string"
end
return m
