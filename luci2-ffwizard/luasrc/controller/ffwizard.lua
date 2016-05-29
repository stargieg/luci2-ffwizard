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
	page = entry({"admin", "services", "ffwizard"}, cbi("ffwizard"))
	page.dependent = true
	page.title  = _("ffwizard")
	page.order = 10

	page = node("admin", "services", "ffwizard_diag")
	page.target = template("ffwizard_diag")
	page.title  = _("ffwizard Diagnostics")
	page.order  = 11

	page = entry({"admin", "services", "autoconf"}, call("ffwizard_autoconf"), nil)
	page.leaf = true

	page = entry({"admin", "services", "ffwizard"}, call("ffwizard"), nil)
	page.leaf = true

end
