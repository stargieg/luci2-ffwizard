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
		var version = data[0],
			lan = data[1];

		var fields = [
			_('Version'), version.version[0].version_text,
			_('Commit'), version.version[0].version_commit,
			_('LAN IP'), lan.lan[0].lan,
			_('LAN Source IP'), lan.lan[0].lan_src,
			_('Domain'), lan.lan[0].domain,
			_('Domain metric'), lan.lan[0].domain_metric,
			_('Domain metric outgoing'), lan.lan[0].domain_metric_out,
			_('domain_metric_out_raw'), lan.lan[0].domain_metric_out_raw,
			_('Domain distance'), lan.lan[0].domain_distance
		];

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
