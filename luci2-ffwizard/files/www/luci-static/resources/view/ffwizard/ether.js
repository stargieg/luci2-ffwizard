'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('ffwizard', 'Kabel');

		s = m.section(form.TypedSection, 'ether', _('Drahtgebundene Schnittstellen'));
		s.anonymous = false;
		s.addremove = true;
		o = s.option(form.Flag, "enabled", _("freigegeben"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Value, "device", _("Device Name"), "");
		o.placeholder = "lan";
		o.datatype = "uciname";
		o = s.option(form.Flag, "dhcp_br", _("Freifunk Netzwerkbrücke"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Flag, "olsr_mesh", _("OLSR Meshprotokoll"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Flag, "bat_mesh", _("B.A.T.M.A.N Meshprotokoll"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Value, "mesh_ip", _("Mesh IPv4 Addresse"), "");
		o.placeholder = "104.1.1.1/32";
		o.datatype = "cidr4";
		o.optional = true;
		o = s.option(form.Value, "dhcp_ip", _("IP Netz DHCP Netz Batman Gateway mode und olsr Hna4"), "");
		o.placeholder = "192.168.112.0/28";
		o.datatype = "cidr4";
		o.optional = true;

		return m.render();
	}
});
