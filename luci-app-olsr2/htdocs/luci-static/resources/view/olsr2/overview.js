'use strict';
'require view';
'require ui';
'require rpc';

var callgetVersion = rpc.declare({
	object: 'status.olsrd2',
	method: 'getVersion'
});
var callgetLan = rpc.declare({
	object: 'status.olsrd2',
	method: 'getLan'
});

return view.extend({
	title: _('Version'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callgetVersion(), {}),
			L.resolveDefault(callgetLan(), {}),
		]);
	},

	render: function(data) {

		var fields = [];
		if ( data && data[0] && data[0].version && data[0].version[0] ) {
			if ( data[0].version[0].version_text != undefined ) {
					fields.push(_('Version'));
					fields.push(data[0].version[0].version_text);
			}
			if ( data[0].version[0].version_commit != undefined) {
					fields.push(_('GIT commit'));
					fields.push(data[0].version[0].version_commit);
			}
		}
		if ( data && data[1] && data[1].lan && data[1].lan[0] ) {
			if ( data[1].lan[0].lan != undefined ) {
					fields.push(_('LAN IP'));
					fields.push(data[1].lan[0].lan);
			}
			if ( data[1].lan[0].domain != undefined) {
					fields.push(_('Domain'));
					fields.push(data[1].lan[0].domain);
			}
			if ( data[1].lan[0].domain_metric != undefined) {
					fields.push(_('Domain metric'));
					fields.push(data[1].lan[0].domain_metric);
			}
			if ( data[1].lan[0].domain_metric_out != undefined) {
					fields.push(_('Domain metric outgoing'));
					fields.push(data[1].lan[0].domain_metric_out);
			}
			if ( data[1].lan[0].domain_metric_out_raw != undefined) {
					fields.push(_('domain_metric_out_raw'));
					fields.push(data[1].lan[0].domain_metric_out_raw);
			}
			if ( data[1].lan[0].domain_distance != undefined) {
					fields.push(_('Domain distance'));
					fields.push(data[1].lan[0].domain_distance);
			}
		}
		var tr = E('div',{ 'class': 'table'});
		for (var i = 0; i < fields.length; i += 2) {
			tr.appendChild(E('div', { 'class': 'tr' }, [
				E('div', { 'class': 'td left', 'width': '33%' }, [ fields[i] ]),
				E('div', { 'class': 'td left' }, [ (fields[i + 1] != null) ? fields[i + 1] : '?' ])
			]));
		}

		return tr;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
