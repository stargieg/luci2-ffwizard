'use strict';
'require view';
'require ui';
'require rpc';
'require poll';

var callgetVersion = rpc.declare({
	object: 'status.olsrd1',
	method: 'getVersion'
});

function createTable(data) {
    let tableData = [];
	if ( data && data[0] && data[0].version && data[0].version[0] ) {
		if ( data[0].version[0].version_text != undefined ) {
			tableData.push([_('Version'),data[0].version[0].version_text]);
		}
		if ( data[0].version[0].version_commit != undefined) {
			tableData.push([_('GIT commit'),data[0].version[0].version_commit]);
		}
	}
    return tableData;
}

return view.extend({
	title: _('Version'),
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	render: function() {

		var tr = E('table',{ 'class': 'table'});
		tr.appendChild(E('tr', { 'class': 'tr cbi-section-table-titles' }, [
			E('th', { 'class': 'th left' }),
			E('th', { 'class': 'th left' })
		]));
        poll.add(() => {
            Promise.all([
				callgetVersion()
            ]).then((results) => {
                cbi_update_table(tr, createTable(results));
            })
        }, 30);

		return tr;
	}

});
