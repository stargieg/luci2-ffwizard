'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('ffwizard', 'Drahtlos');

		s = m.section(form.TypedSection, 'wifi', _('Drahtlose Schnittstellen'));
		s.anonymous = false;
		s.addremove = true;
		o = s.option(form.Flag, "enabled", _("freigegeben"), "");
		o.datatype = "bool";
		o = s.option(form.Value, "phy_idx", _("Wifi Physical Index"), "0-254");
		o.placeholder = "0";
		o.datatype = "range(0,254)";
		o = s.option(form.Value, "channel", _("Der Funkkanal oder die Funk Kanalliste sind abhängieg von dem Gerät"), "0-300");
		o.placeholder = "0";
		o.datatype = "range(0,300)";
		o = s.option(form.ListValue, "iface_mode", _("Interface Modus"), "");
		o.value("adhoc","IBSS/Ad-Hoc");
		o.value("mesh","802.11s-Mesh");
		o.value("sta","802.11 Client");
		o.value("ap","802.11 AP");
		o = s.option(form.Value, "ssid", _("SSID Wlan Name"), "optional");
		o.optional = true;
		o.datatype = "string";
		o.placeholder = "freifunk";
		o = s.option(form.Value, "bssid", _("BSSID Wlan Nummer"), "optional");
		o.optional = true;
		o.datatype = "macaddr";
		o.placeholder = "02:ca:fe:ba:be";
		o = s.option(form.Flag, "olsr_mesh", _("OLSR Meshprotokoll"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Flag, "bat_mesh", _("B.A.T.M.A.N Meshprotokoll"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Flag, "babel_mesh", _("Babel Meshprotokoll"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Value, "mesh_ip", _("Mesh IPv4 Addresse"), "");
		o.placeholder = "104.1.1.1/32";
		o.datatype = "cidr4";
		o.optional = true;
		o = s.option(form.Flag, "vap", _("AP für Mobilgeräte"), "");
		o.datatype = "bool";
		o.optional = true;
		o.rmempty = false;
		o = s.option(form.Flag, "vap_br", _("AP für Mobilgeräte brücken"), "");
		o.datatype = "bool";
		o.optional = true;
		o.rmempty = false;
		o = s.option(form.Value, "dhcp_ip", _("IP Netz DHCP Netz Batman Gateway mode und olsr Hna4"), "");
		o.placeholder = "192.168.112.0/28";
		o.datatype = "cidr4";
		o.optional = true;

		return m.render();
	}
});
