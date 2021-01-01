-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.olsr_public", package.seeall)

function index()
	local page

	page          = node("public")
	page.title    = _("Public")
	page.target   = alias("public", "status")
	page.order    = 5
	page.setuser  = "nobody"
	page.setgroup = "nogroup"
	page.i18n     = "public"
	page.index    = true
	page          = node("public","status")
	page.title    = _("Status")
	page.target   = alias("public","status","olsr")
	page.order    = 5
	page.setuser  = "nobody"
	page.setgroup = "nogroup"
	page.i18n     = "Status"
	page.index    = true
	assign({"public","status","olsr"}, {"admin", "status", "olsr"}, _("Olsr"), 40)
end
