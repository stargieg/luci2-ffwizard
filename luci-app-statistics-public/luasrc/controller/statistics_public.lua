-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.statistics_public", package.seeall)

function index()
	local page

	page          = node("public","status")
	page.title    = _("Status")
	page.target   = alias("public","status","graph")
	page.order    = 5
	page.setuser  = "nobody"
	page.setgroup = "nogroup"
	page.i18n     = "Status"
	page.index    = true
	assign({"public","status","graph"}, {"admin", "statistics", "graph"}, _("Statistics"), 40)
end
