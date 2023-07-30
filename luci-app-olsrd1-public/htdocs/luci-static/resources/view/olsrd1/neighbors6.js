'use strict';
'require view';
'require ui';
'require rpc';
'require poll';

var callgetData = rpc.declare({
	object: 'status.olsrd1',
	method: 'getNeighbors6'
});

function createTable(data) {
    let tableData = [];
    data.neighbors.forEach(row => {
		let hostname = E('a',{ 'href': 'https://' + row.hostname + '/cgi-bin-olsrd1-neigh.html'},row.hostname);
		let orginator = E('a',{ 'href': 'https://[' + row.originator + ']/cgi-bin-olsrd1-neigh.html'},row.originator);
        tableData.push([
            hostname,
            orginator,
            row.lladdr,
            row.interface,
            row.lq,
            row.nlq,
            row.cost,
            row.signal,
            row.noise,
            row.snr
        ])
    });
    return tableData;
};

return view.extend({
	title: _('OLSR mesh neighbors IP6'),
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,


	render: function(data) {

		var tr = E('table', { 'class': 'table' });
		tr.appendChild(E('tr', { 'class': 'tr cbi-section-table-titles' }, [
			E('th', { 'class': 'th left' }, [ 'Hostname' ]),
			E('th', { 'class': 'th left' }, [ 'Orginator' ]),
			E('th', { 'class': 'th left' }, [ 'MAC' ]),
			E('th', { 'class': 'th left' }, [ 'Interface' ]),
			E('th', { 'class': 'th left' }, [ 'LQ' ]),
			E('th', { 'class': 'th left' }, [ 'NLQ' ]),
			E('th', { 'class': 'th left' }, [ 'ETX' ]),
			E('th', { 'class': 'th left' }, [ 'Signal' ]),
			E('th', { 'class': 'th left' }, [ 'Noise' ]),
			E('th', { 'class': 'th left' }, [ 'SNR' ])
		]));
        poll.add(() => {
            Promise.all([
				callgetData()
            ]).then((results) => {
                cbi_update_table(tr, createTable(results[0]));
            })
        }, 30);
        return tr

	}

});
