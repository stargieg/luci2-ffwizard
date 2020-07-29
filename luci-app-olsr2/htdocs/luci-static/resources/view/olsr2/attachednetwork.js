'use strict';
'require view';
'require ui';
'require rpc';

var callgetAttached_network = rpc.declare({
	object: 'status.olsrd2',
	method: 'getAttached_network'
});

return view.extend({
	title: _('OLSR2 mesh nodes'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callgetAttached_network(), {})
		]);
	},

	render: function(data) {
		var attached_network = data[0];

		var fields = [];
		for (var idx = 0; idx < attached_network.attached_network.length; idx++) {
			fields.push(attached_network.attached_network[idx].node,
				attached_network.attached_network[idx].attached_net,
				attached_network.attached_network[idx].attached_net_src,
				attached_network.attached_network[idx].domain_metric_out
				);
		}
			
		var table = E('div', { 'class': 'table' });

		for (var i = 0; i < fields.length; i += 4) {
			table.appendChild(E('div', { 'class': 'tr' }, [
				E('div', { 'class': 'td left', 'width': '33%' }, [ fields[i] ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 1] != null) ? fields[i + 1] : '?' ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 2] != null) ? fields[i + 2] : '?' ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 3] != null) ? fields[i + 3] : '?' ])
			]));
		}

		return table;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
