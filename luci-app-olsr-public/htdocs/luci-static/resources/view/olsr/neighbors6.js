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
		let hostname = E('a',{ 'href': 'https://' + row.ipAddress + '/cgi-bin-olsr-neigh.html'},row.ipAddress);
        tableData.push([
            hostname,
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
			E('th', { 'class': 'th left' }, [ 'Hostname' ])
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
