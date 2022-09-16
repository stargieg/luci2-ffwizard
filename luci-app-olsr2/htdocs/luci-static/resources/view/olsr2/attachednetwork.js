'use strict';
'require view';
'require ui';
'require rpc';

var callgetAttached_network = rpc.declare({
	object: 'status.olsrd2',
	method: 'getAttached_network'
});

return view.extend({
	title: _('OLSR2 networks'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callgetAttached_network(), {})
		]);
	},

	render: function(data) {

		var tr = E('div', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			E('div', { 'class': 'td left' }, [ 'IP address' ]),
			E('div', { 'class': 'td left' }, [ 'Network' ]),
			E('div', { 'class': 'td left' }, [ 'Source' ]),
			E('div', { 'class': 'td left' }, [ 'Metric' ])
		]));

		if ( data && data[0] && data[0].attached_network ) {
			for (var idx = 0; idx < data[0].attached_network.length; idx++) {
				tr.appendChild(E('div', { 'class': 'tr' }, [
					E('div', { 'class': 'td left' }, [ E('a',{ 'href': 'https://[' + data[0].attached_network[idx].node + ']/'},data[0].attached_network[idx].node) ]),
					E('div', { 'class': 'td left' }, [ data[0].attached_network[idx].attached_net ]),
					E('div', { 'class': 'td left' }, [ data[0].attached_network[idx].attached_net_src ]),
					E('div', { 'class': 'td left' }, [ data[0].attached_network[idx].domain_metric_out ])
				]));
			}
		}

		return tr;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
