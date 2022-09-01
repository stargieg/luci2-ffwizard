--[[
LuCI - Lua Configuration Interface

Copyright 2012 Patrick Grimm <patrick@lunatiki.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.ffwizard", package.seeall)


function index()
	if not fs.access("/etc/config/ffwizard") then
		return
	end

	local page
	page = entry({"admin", "services", "ffwizard_autoconf"}, cbi("ffwizard_autoconf"))
	page.title  = _("ffwizard autoconf")
	page.order = 10

	page = entry({"admin", "services", "ffwizard_conf"}, cbi("ffwizard"))
	page.title  = _("ffwizard conf")
	page.order  = 11
end
