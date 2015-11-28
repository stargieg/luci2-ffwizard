L.ui.view.extend({

	execute: function() {
		var self = this;

		var m = new L.cbi.Map('ffwizard', {
			caption:     L.tr('Freifunk Wizard')
		});

		var s = m.section(L.cbi.TypedSection, 'ffwizard', {
			caption:      L.tr('FF Wizard'),
			collabsible:  false
		});

		s.option(L.cbi.CheckboxValue, 'enabled', {
			caption:     L.tr('Enabled'),
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
			caption:     L.tr('VPN Noch nicht implementiert'),
			description: L.tr('Störerhaftung VPN'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		});

		s.option(L.cbi.CheckboxValue, 'bbvpn', {
			caption:     L.tr('MESH VPN Noch nicht implementiert'),
			description: L.tr('MESH VPN für Städte und Dörfer'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		});

		s.option(L.cbi.CheckboxValue, 'br', {
			caption:     L.tr('Freifunk Netzwerkbrücke'),
			description: L.tr('Netzwerkbrücke für AP-DHCP und Batman'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		});

		s.option(L.cbi.InputValue, 'dhcp_ip', {
			caption:     L.tr('DHCP IPv4 Netz'),
			description: L.tr('IP Netz DHCP Netz Batman Gateway mode und olsr Hna4'),
			datatype:    'cidr4',
			optional:    true
		}).depends('br');


		var ether_sec = m.section(L.cbi.TypedSection, 'ether', {
			caption:      L.tr('Ether Interface'),
			collabsible:  true,
			addremove: false,
			teasers:      [ 'device', 'olsr_mesh', 'bat_mesh' ]
		});

		ether_sec.option(L.cbi.CheckboxValue, 'enabled', {
			caption:     L.tr('Enabled'),
			enabled:     '1',
			disabled:    '0',
			optional:    false
		});

		ether_sec.option(L.cbi.InputValue, 'device', {
			caption:     L.tr('Device'),
			description: L.tr('Device Name'),
			optional:    false
		});

		ether_sec.option(L.cbi.CheckboxValue, 'dhcp_br', {
			caption:     L.tr('Freifunk Netzwerkbrücke'),
			description: L.tr('Netzwerkbrücke für DHCP und Batman'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		}).depends({enabled: 1});

		ether_sec.option(L.cbi.CheckboxValue, 'olsr_mesh', {
			caption:     L.tr('Olsr Mesh'),
			description: L.tr('OLSR Mesh Protokol'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		}).depends({enabled: 1, dhcp_br: 0});

		ether_sec.option(L.cbi.CheckboxValue, 'bat_mesh', {
			caption:     L.tr('Batman Mesh'),
			description: L.tr('Batman Mesh Protokol'),
			enabled:     '1',
			disabled:    '0',
			optional:    true
		}).depends({enabled: 1, dhcp_br: 0, olsr_mesh: 0});

		ether_sec.option(L.cbi.InputValue, 'mesh_ip', {
			caption:     L.tr('Mesh IPv4 Adresse'),
			datatype:    'cidr4',
			optional:    true
		}).depends({enabled: 1, dhcp_br: 0, olsr_mesh: 1});

		ether_sec.option(L.cbi.InputValue, 'dhcp_ip', {
			caption:     L.tr('DHCP Label IPv4 Netz'),
			datatype:    'cidr4',
			optional:    true
		}).depends({enabled: 1, dhcp_br: 0, olsr_mesh: 1});

		var wifi_sec = m.section(L.cbi.TypedSection, 'wifi', {
			caption:      L.tr('Wifi Interface'),
			collabsible:  true,
			addremove: false,
			teasers:      [ 'phy_idx', 'channel', 'olsr_mesh', 'bat_mesh' ]
		});

		wifi_sec.option(L.cbi.CheckboxValue, 'enabled', {
			caption:     L.tr('Enabled'),
			enabled:     '1',
			disabled:    '0',
			optional:    false
		});

		wifi_sec.option(L.cbi.InputValue, 'phy_idx', {
			caption:     L.tr('wifi'),
			description: L.tr('Wifi Physical Index'),
			datatype:    'range(0,255)',
			placeholder: 0,
			optional:    false
		}).depends({enabled: 1});

		wifi_sec.option(L.cbi.InputValue, 'channel', {
			caption:     L.tr('Funk Kanal'),
			description: L.tr('Der Funkkanal oder die Funk Kanalliste sind abhängieg von dem Gerät'),
			placeholder: 100,
			optional:    true
		}).depends({enabled: 1});

		wifi_sec.option(L.cbi.CheckboxValue, 'olsr_mesh', {
			caption:     L.tr('Olsr Mesh'),
			description: L.tr('OLSR Mesh Protokol'),
			enabled:     '1',
			disabled:    '0',
			optional:    false
		}).depends({enabled: 1});

		wifi_sec.option(L.cbi.CheckboxValue, 'bat_mesh', {
			caption:     L.tr('Batman Mesh'),
			description: L.tr('Batman Mesh Protokol'),
			enabled:     '1',
			disabled:    '0',
			optional:    false
		}).depends({enabled: 1, olsr_mesh: 0});

		wifi_sec.option(L.cbi.InputValue, 'mesh_ip', {
			caption:     L.tr('Mesh IPv4 Adresse'),
			datatype:    'cidr4',
			optional:    true
		}).depends({enabled: 1, olsr_mesh: 1});

		wifi_sec.option(L.cbi.CheckboxValue, 'vap', {
			caption:     L.tr('AP für Mobilgeräte'),
			description: L.tr('Acces Point für Mobil Geräte'),
			enabled:     '1',
			disabled:    '0',
			optional:    false
		}).depends({enabled: 1});

		wifi_sec.option(L.cbi.InputValue, 'dhcp_ip', {
			caption:     L.tr('VAP DHCP IPv4 Netz'),
			datatype:    'cidr4',
			optional:    true
		}).depends({enabled: 1, olsr_mesh: 1, vap: 1});

		$('#run').click(function() {
			L.ui.saveScrollTop();
			L.ui.loading(true);

			return m.apply().then(function() {
				return L.system.initRestart('ffwizard');
			}).then(function() {
				L.ui.loading(false);
				L.ui.restoreScrollTop();
			});
		})

		return m.insertInto('#map');
	}
});
