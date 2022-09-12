'use strict';
'require view';
'require form';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('ffwizard', 'Autokonfiguration');

		s = m.section(form.TypedSection, 'autoconf', _('Autokonfiguration'));
		s.anonymous = true;
		s.addremove = false;
		o = s.option(form.Flag, "firstboot", _("Start der autokonfiguration"), "");
		o.datatype = "bool";

		return m.render();
	}
});
