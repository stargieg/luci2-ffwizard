L2.registerController('StatusOlsrd2Controller',
['$q', '$scope', 'l2rpc', 'l2system', '$timeout', 'l2spin', 'gettext', function($q, $scope, l2rpc, l2system, $timeout, l2spin, gettext) {
	angular.extend($scope, {
		getNeighborsList: l2rpc.declare({
			object: 'status.olsrd2',
			method: 'getNHDPinfo',
			expect: { neighbors: [ ] }
		}),
		
		getStatus: function() {
			return $scope.getNeighborsList().then(function(neighbors) {
				$scope.neighbors = neighbors;
				$scope.$timeout = $timeout($scope.getStatus, 5000);
			});
		}
	});

	l2spin.open();
	$scope.getStatus().then(l2spin.close);
	
	$scope.$on('$destroy', function() {
		$timeout.cancel($scope.$timeout);
	});
}]);
