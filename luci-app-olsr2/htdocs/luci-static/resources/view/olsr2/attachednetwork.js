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

		var menu = E('ul',{ 'class': 'tabs'});
		menu.appendChild(E('li', { 'class': 'tabmenu-item-admin' }, [ E('a',{ 'href': '/cgi-bin/luci/admin'}, _('Admin')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-overview' }, [ E('a',{ 'href': '../olsr2'}, _('Overview')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-node' }, [ E('a',{ 'href': '../olsr2/node'}, _('Node')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-attachednetwork active' }, [ E('a',{ 'href': '../olsr2/attachednetwork'}, _('Attachednetwork')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-neighbors' }, [ E('a',{ 'href': '../olsr2/neighbors'}, _('Neighbors')) ]));

		var tr = E('div', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			E('div', { 'class': 'td left', 'width': '33%' }, [ 'IP address' ]),
			E('div', { 'class': 'td left' }, [ 'Network' ]),
			E('div', { 'class': 'td left' }, [ 'Source' ]),
			E('div', { 'class': 'td left' }, [ 'Metric' ])
		]));

		for (var idx = 0; idx < data[0].attached_network.length; idx++) {
			tr.appendChild(E('div', { 'class': 'tr' }, [
				E('div', { 'class': 'td left', 'width': '33%' }, [ data[0].attached_network[idx].node ]),
				E('div', { 'class': 'td left' }, [ data[0].attached_network[idx].attached_net ]),
				E('div', { 'class': 'td left' }, [ data[0].attached_network[idx].attached_net_src ]),
				E('div', { 'class': 'td left' }, [ data[0].attached_network[idx].domain_metric_out ])
			]));
		}

		return [ menu, tr ];
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
