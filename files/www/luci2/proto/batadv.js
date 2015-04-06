L.network.Protocol.extend({
	protocol:    'batadv',
	description: L.tr('bataman-adv'),
	tunnel:      false,
	virtual:     false,

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
			optional: false
		});

		section.taboption('general', L.cbi.InputValue, 'mtu', {
			caption:  L.tr('Mesh Interface'),
			optional: false
		});
	}
});
