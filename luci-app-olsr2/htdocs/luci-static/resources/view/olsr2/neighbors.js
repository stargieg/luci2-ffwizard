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
		var neighbors = data[0];
			
		var fields = [];
		for (var idx = 0; idx < neighbors.neighbors.length; idx++) {
			fields.push(neighbors.neighbors[idx].originator,
				neighbors.neighbors[idx].metric_in,
				neighbors.neighbors[idx].metric_in_raw
				);
		}
			
		var table = E('div',{ 'class': 'olsr'});
		table.appendChild(E('ul', { 'class': 'tabs' }, [
			E('li', { 'class': 'tabmenu-item-admin' }, [ E('a',{ 'href': '/cgi-bin/luci/admin'}, _(' Admin')) ]),
			E('li', { 'class': 'tabmenu-item-overview' }, [ E('a',{ 'href': '../olsr2'}, _('Overview')) ]),
			E('li', { 'class': 'tabmenu-item-node' }, [ E('a',{ 'href': '../olsr2/node'}, _('Node')) ]),
			E('li', { 'class': 'tabmenu-item-attachednetwork' }, [ E('a',{ 'href': '../olsr2/attachednetwork'}, _('Attachednetwork')) ]),
			E('li', { 'class': 'tabmenu-item-neighbors' }, [ E('a',{ 'href': '../olsr2/neighbors'}, _('Neighbors')) ]),
		]));

		table.appendChild(E('div', { 'class': 'table' }));
		for (var i = 0; i < fields.length; i += 3) {
			table.appendChild(E('div', { 'class': 'tr' }, [
				E('div', { 'class': 'td left', 'width': '33%' }, [ fields[i] ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 1] != null) ? fields[i + 1] : '?' ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 2] != null) ? fields[i + 2] : '?' ])
			]));
		}

		return table;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
