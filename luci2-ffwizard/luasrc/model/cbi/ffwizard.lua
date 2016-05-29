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

s = m:section(NamedSection, "ffwizard", "Freifunk Wizard")
s:option(DummyValue, "dv1", nil,"Supported Hardware:")

svc = s:option(Flag, "enabled", "freigegeben","Dieser hacken wird entfernt wenn der Wizard seine Arbeit getan hat.")
svc.optional = true

svc = s:option(Flag, "br", "Netzwerkbrücke","Netzwerkbrücke für AP-DHCP und Batman")
svc.optional = true

svc = s:option(Value, "dhcp_ip", "DHCP IPv4 Netz", "IP Netz DHCP Netz Batman Gateway mode und olsr Hna4")
svc.optional = true
svc.placeholder = "192.168.111.0/28"
svc.datatype = "ip4addr"
svc:depends("br",1)

s = m:section(NamedSection, "ether", "Drahtgebundene Schnittstellen")

svc = s:option(Flag, "enabled", "freigegeben")
svc.optional = true

svc = s:option(Value, "device", "Device", "Device Name")
svc.optional = true
svc.placeholder = "lan"
svc.datatype = "string"

svc = s:option(Flag, "dhcp_br", "Netzwerkbrücke","Freifunk Netzwerkbrücke")
svc.optional = true

svc = s:option(Flag, "olsr_mesh", "OLSR Mesh","OLSR Meshprotokoll")
svc.optional = true
svc:depends("olsr_mesh",0)

svc = s:option(Flag, "bat_mesh", "B.A.T.M.A.N Mesh","B.A.T.M.A.N Meshprotokoll")
svc.optional = true

svc = s:option(Value, "mesh_ip", "Mesh IPv4 Addresse", "IP Netz")
svc.optional = true
svc.placeholder = "104.1.1.1/8"
svc.datatype = "ip4addr"
svc:depends("olsr_mesh",1)

svc = s:option(Value, "dhcp_ip", "DHCP Label IPv4 Netz", "IP Netz DHCP Netz Batman Gateway mode und olsr Hna4")
svc.optional = true
svc.placeholder = "192.168.112.0/28"
svc.datatype = "ip4addr"
svc:depends("olsr_mesh",1)

s = m:section(NamedSection, "wifi", "Drahtlose Schnittstellen")

svc = s:option(Flag, "enabled", "freigegeben")
svc.optional = true

svc = s:option(Value, "phy_idx", "wifi", "Wifi Physical Index")
svc.optional = true
svc.placeholder = "0"
svc.datatype = "port"

svc = s:option(Value, "channel", "Funk Kanal", "Der Funkkanal oder die Funk Kanalliste sind abhängieg von dem Gerät")
svc.optional = true
svc.placeholder = "0"
svc.datatype = "range(0,300)"

svc = s:option(Flag, "olsr_mesh", "OLSR Mesh","OLSR Meshprotokoll")
svc.optional = true

svc = s:option(Flag, "bat_mesh", "B.A.T.M.A.N Mesh","B.A.T.M.A.N Meshprotokoll")
svc.optional = true
svc:depends("olsr_mesh",0)

svc = s:option(Value, "mesh_ip", "Mesh IPv4 Addresse", "IP Netz")
svc.optional = true
svc.placeholder = "104.1.1.1/8"
svc.datatype = "ip4addr"
svc:depends("olsr_mesh",1)

svc = s:option(Flag, "vap", "AP für Mobilgeräte")
svc.optional = true

svc = s:option(Value, "dhcp_ip", "DHCP Label IPv4 Netz", "IP Netz DHCP Netz Batman Gateway mode und olsr Hna4")
svc.optional = true
svc.placeholder = "192.168.112.0/28"
svc.datatype = "ip4addr"
svc.depends = "vap"

return m
