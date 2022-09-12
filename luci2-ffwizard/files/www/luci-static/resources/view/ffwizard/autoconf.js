'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('ffwizard', 'Autokonfiguration');

		s = m.section(form.TypedSection, 'autoconf', _('Autokonfiguration'));
		s.anonymous = true;
		s.addremove = true;
		o = s.option(form.Value, "firstboot", _("Start der autokonfiguration"), "bool");
		o.datatype = "bool";

		return m.render();
	}
});
