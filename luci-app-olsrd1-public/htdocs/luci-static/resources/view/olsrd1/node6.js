'use strict';
'require view';
'require ui';
'require rpc';
'require poll';

var callgetData = rpc.declare({
	object: 'status.olsrd1',
	method: 'getNode6'
});

function createTable(data) {
    let tableData = [];
    data.topology.forEach(row => {
		let node = E('a',{ 'href': 'https://' + row.destinationIP + '/cgi-bin-olsrd1-neigh.html'},row.destinationIP);
        tableData.push([
            node
        ])
    });
    return tableData;
};

return view.extend({
	title: _('OLSR mesh nodes IP6'),
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	render: function(data) {

		var tr = E('table', { 'class': 'table' });
		tr.appendChild(E('tr', { 'class': 'tr cbi-section-table-titles' }, [
			E('th', { 'class': 'th left' }, [ 'IP Address' ])
		]));
        poll.add(() => {
            Promise.all([
				callgetData()
            ]).then((results) => {
                cbi_update_table(tr, createTable(results[0]));
            })
        }, 30);

		return tr;
	}

});
