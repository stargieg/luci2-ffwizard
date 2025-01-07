'use strict';
'require uci';
'require view';
'require form';

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('ffwizard'),
			uci.load('network')
		]);
	},
	render: function() {
		var m, s, o;
		var prefix_available = uci.get('ffwizard', 'autoconf', 'prefix_available') || {};
		var prefix_selected = uci.get('network', 'fflandhcp', 'ffprefix') || '';
		var prefix_rand = uci.get('network', 'fflandhcp', 'ip6prefix') || '';

		m = new form.Map('ffwizard', 'Autokonfiguration');

		s = m.section(form.TypedSection, 'autoconf', _('Autokonfiguration'));
		s.anonymous = false;
		s.addremove = false;

		o = s.option(form.Flag, "firstboot", _("Start der autokonfiguration"), "");
		o.datatype = "bool";
		o.rmempty = false;

		o = s.option(form.Value, "prefix_pref", _("Bevorzugtes IPv6 Prefix."), "2001:bf7::/32");
		o.datatype = "cidr6";
		o.optional = true;
		for (var i = 0; i < prefix_available.length; i++) 
		{
			o.value(prefix_available[i]);
		}

		o = s.option(form.Value, "ip6mask", _("IPv6 Netzgröße"), "1-64");
		o.placeholder = "64";
		o.datatype = "range(0,128)";

		o = s.option(form.Value, "prefix_exclude", _("Ausgeschlossenes IPv6 Prefix."), "2001:bf7::/32");
		o.datatype = "cidr6";
		o.optional = true;
		for (var i = 0; i < prefix_available.length; i++) 
		{
			o.value(prefix_available[i]);
		}
		o = s.option(form.DummyValue, "", _("Ausgewähltes IPv6 Prefix."));
		o.cfgvalue = function () {return prefix_selected};
		o = s.option(form.DummyValue, "", _("Gewürfeltes IPv6 Prefix."));
		o.cfgvalue = function () {return prefix_rand};

		return m.render();
	}
});
