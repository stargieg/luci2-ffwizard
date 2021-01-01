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

		var fields = [
			_('Version'), data[0].version[0].version_text,
			_('Commit'), data[0].version[0].version_commit,
			_('LAN IP'), data[1].lan[0].lan,
			_('LAN Source IP'), data[1].lan[0].lan_src,
			_('Domain'), data[1].lan[0].domain,
			_('Domain metric'), data[1].lan[0].domain_metric,
			_('Domain metric outgoing'), data[1].lan[0].domain_metric_out,
			_('domain_metric_out_raw'), data[1].lan[0].domain_metric_out_raw,
			_('Domain distance'), data[1].lan[0].domain_distance
		];

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
