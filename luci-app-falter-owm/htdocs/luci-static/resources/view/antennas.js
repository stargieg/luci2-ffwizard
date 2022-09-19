'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('antennas', 'Antennas settings');

		s = m.section(form.TypedSection, 'wifi-device', _('Antennas settings'));
		s.anonymous = false;
		s.addremove = true;

		o = s.option(form.Flag, "builtin", _("Built in"), "");
		o.optional = true;
		o.datatype = "bool";
		o = s.option(form.ListValue, "manufacturer", _("Manufacturer"), "");
		o.value("Huber & Suhner");
		o.value("Mars");
		o.value("Wimo");
		o.value("Rappl");
		o.optional = true;
		o = s.option(form.Value, "model", _("Model"), "");
		o.datatype = "string";
		o.optional = true;
		o = s.option(form.ListValue, "polarization", _("Polarization"), "");
		o.value("vertical");
		o.value("horizontal");
		o.value("horizontal/vertical");
		o.optional = true;
		o = s.option(form.Value, "gain", _("Gain"), "dBi");
		o.placeholder = "0";
		o.datatype = "range(0,100)";
		o = s.option(form.ListValue, "type", _("Type"), "");
		o.value("omni");
		o.value("directed");
		o.optional = true;
		o = s.option(form.Value, "horizontalDirection", _("Horizontal Direction"), "0º - 360º");
		o.placeholder = "0";
		o.datatype = "range(0,360)";
		o.optional = true;
		o = s.option(form.Value, "horizontalBeamwidth", _("Horizontal Beamwidth"), "0º - 360º");
		o.placeholder = "0";
		o.datatype = "range(0,360)";
		o.optional = true;
		o = s.option(form.Value, "verticalDirection", _("Vertical Direction"), "-90º - 90º");
		o.placeholder = "0";
		o.datatype = "range(-90,90)";
		o.optional = true;
		o = s.option(form.Value, "verticalBeamwidth", _("Vertical Beamwidth"), "-90º - 90º");
		o.placeholder = "0";
		o.datatype = "range(-90,90)";
		o.optional = true;

		return m.render();
	}
});
