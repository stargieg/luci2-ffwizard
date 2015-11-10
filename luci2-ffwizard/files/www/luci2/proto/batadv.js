L.network.Protocol.extend({
	protocol:    'batadv',
	description: L.tr('B.A.T.M.A.N. Advanced'),
	tunnel:      false,
	virtual:     true,

	populateForm: function(section, iface)
	{
		var device = L.network.getDeviceByInterface(iface);

		section.taboption('general', L.cbi.InputValue, 'ifname', {
			caption:  L.tr('Interface'),
			datatype: 'string',
			optional: true
		});

		section.taboption('general', L.cbi.InputValue, 'mesh', {
			caption:  L.tr('Mesh Interface'),
			datatype: 'string',
			placeholder: 'bat0',
			optional: false
		});

		section.taboption('general', L.cbi.InputValue, 'mtu', {
			caption:  L.tr('MTU'),
			datatype: 'range(64,9000)',
			placeholder: 1532,
			optional: true
		});
	}
});
