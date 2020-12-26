'use strict';
'require view';
'require ui';
'require rpc';

var callgetNeighbors = rpc.declare({
	object: 'status.olsrd2',
	method: 'getNeighbors'
});

return view.extend({
	title: _('OLSR2 mesh neighbors'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callgetNeighbors(), {}),
		]);
	},

	render: function(data) {

		var menu = E('ul',{ 'class': 'tabs'});
		menu.appendChild(E('li', { 'class': 'tabmenu-item-admin' }, [ E('a',{ 'href': '/cgi-bin/luci/admin'}, _('Admin')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-overview' }, [ E('a',{ 'href': '../olsr2'}, _('Overview')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-node' }, [ E('a',{ 'href': '../olsr2/node'}, _('Node')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-attachednetwork' }, [ E('a',{ 'href': '../olsr2/attachednetwork'}, _('Attachednetwork')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-neighbors active' }, [ E('a',{ 'href': '../olsr2/neighbors'}, _('Neighbors')) ]));

		var tr = E('div', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			E('div', { 'class': 'td left', 'width': '33%' }, [ 'Orginator' ]),
			E('div', { 'class': 'td left' }, [ 'Metric' ]),
			E('div', { 'class': 'td left' }, [ 'raw' ])
		]));

		for (var idx = 0; idx < data[0].neighbors.length; idx++) {
			tr.appendChild(E('div', { 'class': 'tr' }, [
				E('div', { 'class': 'td left', 'width': '33%' }, [ data[0].neighbors[idx].originator ]),
				E('div', { 'class': 'td left' }, [ data[0].neighbors[idx].metric_in ]),
				E('div', { 'class': 'td left' }, [ data[0].neighbors[idx].metric_in_raw ])
			]));
		}

		return [ menu, tr ];
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
