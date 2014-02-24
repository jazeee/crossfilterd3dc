### 
Developed by Jaz Singh 2014-02-15
###

angularApplication = angular.module('crossFilterApp', ['ngRoute','ngAnimate'])

angularApplication.factory('DataService' , ($q) ->
	generateGffData = () ->
		deferred = $q.defer()
		sourceFile = 'data/genome.gff'

		d3.gff(sourceFile, (rows) =>
			rows.forEach( (row) ->
				row.start = +row.start
				row.end = +row.end
				row.score = +row.score
			)
			gffData = crossfilter(rows)

			startDomain = d3.extent(rows, (row)->
				row.start
			)
			startExtent = startDomain[1] - startDomain[0]
			console.log(startExtent)

			start = gffData.dimension( (data) ->
				# Bin the data into 100 bins
				factor = 100 / startExtent
				Math.round(data.start * factor) / factor
			)
			startGroupValue = start.group().reduceCount()

			seqNames = gffData.dimension( (data) ->
				data.seqname
			)
			seqNamesGroup = seqNames.group()
			seqNamesGroupSum = seqNamesGroup.reduceSum( (data) ->
				data.start
			)
			seqNamesDomain = _.map(seqNamesGroup.reduceCount().top(25), (seqNameCount)->
				seqNameCount.key
			)
			barChart = dc.barChart('#dc-bar-chart')
			barChart
				.width(700)
				.height(200)
		        .margins({top: 10, right: 50, bottom: 30, left: 40})
				.dimension(start)
				.group(startGroupValue)
				.centerBar(true)
				.gap(1)
				.transitionDuration(500)
#				.x(d3.scale.ordinal().domain(seqNamesDomain))
				.x(d3.scale.linear().domain(startDomain))
				.elasticY(true)
			pieChart = dc.pieChart('#dc-pie-chart')
			pieChart
				.width(200)
				.height(200)
				.dimension(seqNames)
				.group(seqNamesGroupSum)
				.transitionDuration(500)
			dc.renderAll()
			deferred.resolve(gffData)
		)
		deferred.promise

	return {
		generateGffData: generateGffData
		resetAllFilters: ->
			dc.filterAll()
			dc.renderAll()
	}
)

angularApplication.controller('HomeController' , ($scope, $location, DataService) ->
	DataService.generateGffData().then((gffData) ->
		$scope.gffData = gffData
		$scope.gffResults = gffData.groupAll().reduceCount().value()
	)
	
	$scope.resetAllFilters = ->
		DataService.resetAllFilters()
)

angularApplication.config([
	'$routeProvider',
	($routeProvider) ->
		$routeProvider.when('/home', {
			templateUrl: 'fragments/home.html',
			controller: 'HomeController',
		}).otherwise({
			redirectTo: '/home'
		})
])
