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

		var tr = E('div', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			//E('div', { 'class': 'td left', 'width': '33%' }, [ 'node' ]),
			E('div', { 'class': 'td left' }, [ 'IP Address' ])
		]));

		if ( data && data[0] && data[0].node ) {
			for (var idx = 0; idx < data[0].node.length; idx++) {
				tr.appendChild(E('div', { 'class': 'tr' }, [
					//E('div', { 'class': 'td left', 'width': '33%' }, [ 'Node' ]),
					E('div', { 'class': 'td left' }, [ E('a',{ 'href': 'https://[' + data[0].node[idx].node + ']/'},data[0].node[idx].node) ])
				]));
			}
		}

		return tr;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
