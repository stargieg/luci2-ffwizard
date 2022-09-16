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

		var tr = E('div', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			E('div', { 'class': 'td left' }, [ 'Hostname' ]),
			E('div', { 'class': 'td left' }, [ 'Orginator' ]),
			E('div', { 'class': 'td left' }, [ 'MAC' ]),
			E('div', { 'class': 'td left' }, [ 'Interface' ]),
			E('div', { 'class': 'td left' }, [ 'Metric' ]),
			E('div', { 'class': 'td left' }, [ 'raw' ])
		]));

		if ( data && data[0] && data[0].neighbors ) {
			for (var idx = 0; idx < data[0].neighbors.length; idx++) {
				tr.appendChild(E('div', { 'class': 'tr' }, [
					E('div', { 'class': 'td left' }, [ E('a',{ 'href': 'https://' + data[0].neighbors[idx].hostname + '/cgi-bin-olsr2-neigh.html'},data[0].neighbors[idx].hostname) ]),
					E('div', { 'class': 'td left' }, [ E('a',{ 'href': 'https://[' + data[0].neighbors[idx].originator + ']/cgi-bin-olsr2-neigh.html'},data[0].neighbors[idx].originator) ]),
					E('div', { 'class': 'td left' }, [ data[0].neighbors[idx].lladdr ]),
					E('div', { 'class': 'td left' }, [ data[0].neighbors[idx].interface ]),
					E('div', { 'class': 'td left' }, [ data[0].neighbors[idx].metric_in ]),
					E('div', { 'class': 'td left' }, [ data[0].neighbors[idx].metric_in_raw ])
				]));
			}
		}

		return tr;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
