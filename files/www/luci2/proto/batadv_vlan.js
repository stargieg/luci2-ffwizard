L.network.Protocol.extend({
	protocol:    'batadv_vlan',
	description: L.tr('bataman-adv vlan'),
	tunnel:      false,
	virtual:     false,

	populateForm: function(section, iface)
	{
		var device = L.network.getDeviceByInterface(iface);

		section.taboption('general', L.cbi.InputValue, 'ifname', {
			caption:  L.tr('Interface'),
			datatype: 'string',
			optional: true,
			placeholder: 'eth0.1'
		});

		section.taboption('general', L.cbi.InputValue, 'ap_isolation', {
			caption:  L.tr('Mesh AP isolated Interface'),
			optional: false
		});
	}
});
