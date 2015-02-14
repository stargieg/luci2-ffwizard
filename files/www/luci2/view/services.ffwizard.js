L.ui.view.extend({
	execute: function() {
		var self = this;

		var m = new L.cbi.Map('ffwizard', {
			caption:     L.tr('Freifunk Wizard')
		});

		var s = m.section(L.cbi.TypedSection, 'ffwizard', {
			caption:      L.tr('FF Wizard'),
		});

		s.option(L.cbi.CheckboxValue, 'enabled', {
			caption:     L.tr('Enabled'),
			initial:     0,
			enabled:     '1',
			disabled:    '0',
			optional:    false
		});

		s.option(L.cbi.InputValue, 'hostname', {
			caption:     L.tr('Hostname'),
			datatype:    'hostname',
			optional:    false
		});

		s.option(L.cbi.CheckboxValue, 'vpn', {
			caption:     L.tr('VPN'),
			description: L.tr('Störerhaftung VPN'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		});

		s.option(L.cbi.CheckboxValue, 'bbvpn', {
			caption:     L.tr('MESH VPN'),
			description: L.tr('MESH VPN für Stäte und Dörfer'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		});


		var isec = m.section(L.cbi.TypedSection, 'ffinterface', {
			caption:      L.tr('Interface'),
			addremove:    true,
			add_caption:  L.tr('Add Interface …'),
		});

		isec.option(L.cbi.CheckboxValue, 'enabled', {
			caption:     L.tr('Enabled'),
			initial:     0,
			enabled:     '1',
			disabled:    '0',
			optional:    false
		});

		isec.option(L.cbi.InputValue, 'device', {
			caption:     L.tr('Device'),
			description: L.tr('Device Name'),
			optional:    false
		});

		isec.option(L.cbi.CheckboxValue, 'olsr_mesh', {
			caption:     L.tr('Olsr Mesh'),
			description: L.tr('OLSR Mesh Protokol'),
			initial:     1,
			enabled:     '1',
			disabled:    '0',
			optional:    false
		});

		isec.option(L.cbi.CheckboxValue, 'bat_mesh', {
			caption:     L.tr('Batman Mesh'),
			description: L.tr('Batman Mesh Protokol'),
			initial:     0,
			enabled:     '1',
			disabled:    '0',
			optional:    false
		});

		return m.insertInto('#map');
	}
});
