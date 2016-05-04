L2.invoke(['l2network', 'gettext', function(l2network, gettext) {
	l2network.registerProtocolHandler({
		protocol:    'batadv',
		description: gettext('B.A.T.M.A.N. Advanced'),
		tunnel:      false,
		virtual:     true
	});
}]);
