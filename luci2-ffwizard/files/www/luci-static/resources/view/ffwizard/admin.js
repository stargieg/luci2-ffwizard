'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('ffwizard', 'Freifunk Wizard');

		s = m.section(form.TypedSection, 'ffwizard', _('The Freifunk Wizard'));
		s.anonymous = false;
		s.addremove = false;
		o = s.option(form.Flag, "enabled", _("freigegeben Dieser hacken wird entfernt wenn der Wizard seine Arbeit getan hat."), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Value, "hostname", _("Router Name"), "");
		o.datatype = "host";
		o.placeholder = "OpenWrt";
		o = s.option(form.Value, "domain", _("Router Domain"), "");
		o.datatype = "hostname";
		o.placeholder = "olsr";
		o = s.option(form.Flag, "br", _("Netzwerkbrücke für AP-DHCP und Batman"), "");
		o.datatype = "bool";
		o.rmempty = false;
		o = s.option(form.Value, "dhcp_ip", _("IPv4 DHCP Netz für Batman Gateway mode und olsr Hna4"), "");
		o.datatype = "cidr4";
		o.placeholder = "192.168.111.0/28";
		o.optional = true;
		o = s.option(form.Value, "ip6prefix", _("Öffentliches IPv6 Prefix. Sinvolle Netzgrössen sind /62 (4x/64) - /48 (65535x/64)"), "");
		o.datatype = "cidr6";
		o.placeholder = "2a00:c1a0:488f:8404::/62";
		o.optional = true;

		return m.render();
	}
});
