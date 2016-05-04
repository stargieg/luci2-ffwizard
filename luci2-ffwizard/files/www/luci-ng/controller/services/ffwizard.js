L2.registerController('ServicesFfwizardController',
['$q', '$scope', 'l2rpc', 'l2uci', 'gettext', function($q, $scope, l2rpc, l2uci, l2ffwizard, gettext) {
	var self = this;

	$scope.test = this.test = function() {
		console.debug('Test!!');
		return 'xxx';
	};

	//$scope.getStatus();
}]);
