'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('olsrd2', 'OLSRD2 Daemon');

		s = m.section(form.TypedSection, 'olsrv2_lan', _('Prefix configuration section'));
		s.anonymous = true;
		s.addremove = true;
		o = s.option(form.Value, "name", _("Name"), "Text");
		o.datatype = "string";
		o = s.option(form.Value, "prefix", _("locally attached network prefix"), "");
		o.datatype = "cidr6";
		o = s.option(form.Value, "domain", _("domain for this LAN entry, -1 for all domains"), "-1-254");
		o.optional = true;
		o.placeholder = -1;
		o.datatype = "range(-1,254)";
		o = s.option(form.Value, "metric", _("metric value for this LAN entry"), "0-254");
		o.optional = true;
		o.placeholder = 2;
		o.datatype = "range(0,254)";
		o = s.option(form.Value, "source_prefix", _("source prefix for lan (source specific routing)"), "");
		o.optional = true;
		o.datatype = "cidr6";

		return m.render();
	}
});
