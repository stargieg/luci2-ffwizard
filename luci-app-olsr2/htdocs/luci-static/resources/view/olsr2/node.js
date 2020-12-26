'use strict';
'require view';
'require ui';
'require rpc';

var callgetNode = rpc.declare({
	object: 'status.olsrd2',
	method: 'getNode'
});

return view.extend({
	title: _('OLSR2 mesh nodes'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callgetNode(), {})
		]);
	},

	render: function(data) {

		var menu = E('ul',{ 'class': 'tabs'});
		menu.appendChild(E('li', { 'class': 'tabmenu-item-admin' }, [ E('a',{ 'href': '/cgi-bin/luci/admin'}, _('Admin')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-overview' }, [ E('a',{ 'href': '../olsr2'}, _('Overview')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-node active' }, [ E('a',{ 'href': '../olsr2/node'}, _('Node')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-attachednetwork' }, [ E('a',{ 'href': '../olsr2/attachednetwork'}, _('Attachednetwork')) ]));
		menu.appendChild(E('li', { 'class': 'tabmenu-item-neighbors' }, [ E('a',{ 'href': '../olsr2/neighbors'}, _('Neighbors')) ]));

		var tr = E('div', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			//E('div', { 'class': 'td left', 'width': '33%' }, [ 'node' ]),
			E('div', { 'class': 'td left' }, [ 'IP Address' ])
		]));

		for (var idx = 0; idx < data[0].node.length; idx++) {
			tr.appendChild(E('div', { 'class': 'tr' }, [
				//E('div', { 'class': 'td left', 'width': '33%' }, [ 'Node' ]),
				E('div', { 'class': 'td left' }, [ data[0].node[idx].node ])
			]));
		}

		return [ menu, tr ];
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
