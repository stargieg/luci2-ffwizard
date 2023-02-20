'use strict';
'require view';
'require ui';
'require rpc';
'require poll';

var callgetData = rpc.declare({
	object: 'status.olsr',
	method: 'getNeighbors6'
});

function createTable(data) {
    let tableData = [];
    data.neighbors.forEach(row => {
		let hostname = E('a',{ 'href': 'https://' + row.hostname + '/cgi-bin-olsr2-neigh.html'},row.hostname);
		let orginator = E('a',{ 'href': 'https://[' + row.originator + ']/cgi-bin-olsr2-neigh.html'},row.originator);
        tableData.push([
            hostname,
            orginator,
            row.lladdr,
            row.interface,
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
			E('th', { 'class': 'th left' }, [ 'Interface' ])
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
