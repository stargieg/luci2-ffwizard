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
		var node = data[0];
			
		var fields = [];
		for (var idx = 0; idx < node.node.length; idx++) {
			fields.push(_('Node'), node.node[idx].node);
		}
			
		var table = E('div', { 'class': 'table' });

		for (var i = 0; i < fields.length; i += 2) {
			table.appendChild(E('div', { 'class': 'tr' }, [
				E('div', { 'class': 'td left', 'width': '33%' }, [ fields[i] ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 1] != null) ? fields[i + 1] : '?' ])
			]));
		}

		return table;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
