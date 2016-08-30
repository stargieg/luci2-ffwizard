--[[
LuCI - Lua Configuration Interface

Copyright 2012 Patrick Grimm <patrick@lunatiki.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local utl = require "luci.util"

m = Map("ffwizard", "Freifunk Wizard", "Freifunk Wizard")
m.on_after_commit = function() utl.ubus("uci", "reload_config") end

s = m:section(TypedSection, "ffwizard", "Freifunk Wizard")
s.addremove = false
s.anonymous = false
s:option(DummyValue, "dv1", nil,"Supported Hardware:")

svc = s:option(Flag, "enabled", "freigegeben","Dieser hacken wird entfernt wenn der Wizard seine Arbeit getan hat.")

svc = s:option(Value, "hostname", "Hostname", "Router Name")
svc.placeholder = "lede"
svc.datatype = "string"

svc = s:option(Flag, "br", "Netzwerkbrücke","Netzwerkbrücke für AP-DHCP und Batman")

svc = s:option(Value, "dhcp_ip", "DHCP IPv4 Netz", "IP Netz DHCP Netz Batman Gateway mode und olsr Hna4")
svc.placeholder = "192.168.111.0/28"
svc.datatype = "ip4addr"

svc = s:option(Value, "ip6prefix", "IPv6 Prefix", "Öffentliches IPv6 Prefix. Sinvolle Netzgrössen sind /62 (4x/64) - /48 (65535x/64)")
svc.placeholder = "2a00:c1a0:488f:8404::/62"
svc.datatype = "ip6addr"

s = m:section(TypedSection, "ether", "Drahtgebundene Schnittstellen")

svc = s:option(Flag, "enabled", "freigegeben")

svc = s:option(Value, "device", "Device", "Device Name")
svc.placeholder = "lan"
svc.datatype = "string"

svc = s:option(Flag, "dhcp_br", "Netzwerkbrücke","Freifunk Netzwerkbrücke")

svc = s:option(Flag, "olsr_mesh", "OLSR Mesh","OLSR Meshprotokoll")

svc = s:option(Flag, "bat_mesh", "B.A.T.M.A.N Mesh","B.A.T.M.A.N Meshprotokoll")

svc = s:option(Value, "mesh_ip", "Mesh IPv4 Addresse", "IP Netz")
svc.placeholder = "104.1.1.1/8"
svc.datatype = "ip4addr"

svc = s:option(Value, "dhcp_ip", "DHCP Label IPv4 Netz", "IP Netz DHCP Netz Batman Gateway mode und olsr Hna4")
svc.placeholder = "192.168.112.0/28"
svc.datatype = "ip4addr"

s = m:section(TypedSection, "wifi", "Drahtlose Schnittstellen")

svc = s:option(Flag, "enabled", "freigegeben")

svc = s:option(Value, "phy_idx", "wifi", "Wifi Physical Index")
svc.placeholder = "0"
svc.datatype = "port"

svc = s:option(Value, "channel", "Funk Kanal", "Der Funkkanal oder die Funk Kanalliste sind abhängieg von dem Gerät")
svc.placeholder = "0"
svc.datatype = "range(0,300)"

svc = s:option(Flag, "olsr_mesh", "OLSR Mesh","OLSR Meshprotokoll")

svc = s:option(Flag, "bat_mesh", "B.A.T.M.A.N Mesh","B.A.T.M.A.N Meshprotokoll")

svc = s:option(Value, "mesh_ip", "Mesh IPv4 Addresse", "IP Netz")
svc.placeholder = "104.1.1.1/8"
svc.datatype = "ip4addr"

svc = s:option(Flag, "vap", "AP für Mobilgeräte")

svc = s:option(Value, "dhcp_ip", "DHCP Label IPv4 Netz", "IP Netz DHCP Netz Batman Gateway mode und olsr Hna4")
svc.placeholder = "192.168.112.0/28"
svc.datatype = "ip4addr"

return m
