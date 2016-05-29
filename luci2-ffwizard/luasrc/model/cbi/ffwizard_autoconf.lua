--[[
LuCI - Lua Configuration Interface

Copyright 2012 Patrick Grimm <patrick@lunatiki.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--


m = Map("ffwizard", "Freifunk Wizard", "Autokonfiguration")
m.on_after_commit = function() luci.sys.call("ubus call uci reload_config") end

s = m:section(NamedSection, "autoconf", "Autokonfiguration")

svc = s:option(Flag, "enabled", "freigegeben","Dieser 
	hacken wird entfernt wenn die Autokonfiguration gestartet wurde.
	Die Netzwerk- und WLAN-Einstellungen werden zurückgesetzt.
	Der Neustart des WLAN dauert 20 sek. Anschliessend wird im verfügbaren
	Kanalbereich nach Freifunk Mesh Netzen gesucht. Der Kanal auf dem ein solches
	Netz gefunden wurde wird in die FF Wizard konfiguration eingetragen und
	anschliesend ausgeführt. Sollte keine Freifunk Mesh Netz gefunden werden
	benutzt der FF Wizard einen verfügbaren Standartkanal (13 oder 36).")

return m
