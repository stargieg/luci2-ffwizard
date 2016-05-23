L2.registerController('ServicesAutoconfController',
['$q', '$scope', 'l2rpc', 'l2uci', 'gettext', function($q, $scope, l2rpc, l2uci, l2autoconf, gettext) {
	var self = this;

	$scope.test = this.test = function() {
		console.debug('Test!!');
		return 'xxx';
	};

	//$scope.getStatus();
}]);
