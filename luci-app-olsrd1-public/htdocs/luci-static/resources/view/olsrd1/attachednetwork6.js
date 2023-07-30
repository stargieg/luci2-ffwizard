'use strict';
'require view';
'require ui';
'require rpc';
'require poll';

var callgetData = rpc.declare({
	object: 'status.olsrd1',
	method: 'getAttached_network6'
});

function createTable(data) {
    let tableData = [];
    data.hna.forEach(row => {
		let node = E('a',{ 'href': 'https://' + row.gateway + '/cgi-bin-olsrd1-neigh.html'},row.gateway);
        let attached_net = row.destination + '/' + row.genmask;
        tableData.push([
            node,
            attached_net,
            row.validityTime
        ])
    });
    return tableData;
}

return view.extend({
	title: _('OLSR networks ipv6'),
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	render: function(data) {

		var tr = E('table', { 'class': 'table' });
		tr.appendChild(E('div', { 'class': 'tr cbi-section-table-titles' }, [
			E('th', { 'class': 'th left' }, [ 'IP address' ]),
			E('th', { 'class': 'th left' }, [ 'Network' ]),
			E('th', { 'class': 'th left' }, [ 'validityTime' ])
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
