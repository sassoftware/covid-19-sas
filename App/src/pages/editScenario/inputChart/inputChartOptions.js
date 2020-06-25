const mainColor = '#f4f4f4'

export function inputChartOptions(zeroDay, nDays, rangeValue, distancing, day, dropCb) {
	const [change1, change2, change3, change4] = rangeValue
	const [d1, d2, d3, d4, d5] = distancing
	const maxDay = zeroDay + nDays * day

	return ({
			chart: {
				type: 'variwide'
			},
			credits: {
				enabled: false
			},
			title: false,
			subtitle: false,
			plotOptions: {
				series: {
					animation: false,
					stickyTracking: false,
					dragDrop: {
						draggableY: true,
						draggableX: false,
						// dragPrecisionY: 1,
						dragMaxY: 100,
						dragMinY: 0,
						dragHandle: {
							className: 'highchartsDragHandle',
							color: '#0378CD',
							cursor: undefined,
							lineColor: '#0378CD',
							lineWidth: 2,
							pathFormatter: undefined,
							zIndex: 901
						}
					},
					states: {
						inactive: {
							opacity: 1
						},
						hover: {
							brightness: -0.1 // darken
						}
					},
					point: {
						events: {
							drop: dropCb
						}
					}
				}
			},
			xAxis: {
				type: 'datetime',
				min: zeroDay,
				max: maxDay
			},
			yAxis: {
				min: 0,
				max: 100,
				floor: 0,
				ceiling: 100,
				title: {
					enabled: false
				},
			},
			legend: {
				enabled: false
			},
			series: [
				{
					name: 'Labor Costs',
					data: [
						{
							x: zeroDay,
							y: d1,
							// z: 4 * 1000 * 60 * 60 * 24,
							z: change1 - zeroDay,
							name: "SocialDistancing",
							color: mainColor
						},
						{
							x: change1,
							y: d2,
							// z: 4 * 1000 * 60 * 60 * 24,
							z: change2 - change1,
							name: "SocialDistancingChange",
							color: mainColor
						},
						{
							x: change2,
							y: d3,
							// z: 4 * 1000 * 60 * 60 * 24,
							z: change3 - change2,
							name: "SocialDistancingChangeTwo",
							color: mainColor
						},
						{
							x: change3,
							y: d4,
							// z: 4 * 1000 * 60 * 60 * 24,
							z: change4 - change3,
							name: "SocialDistancingChange3",
							color: mainColor
						},

						{
							x: change4,
							y: d5,
							// z: 4 * 1000 * 60 * 60 * 24,
							z: maxDay - change4,
							name: "SocialDistancingChange4",
							color: mainColor
						},

					],
					dataLabels: {
						enabled: true,
						format: '{point.y:.0f} %'
					},
					tooltip: {
						pointFormat: 'Distanicng: <b>{point.y}</b><br>',
						valueSuffix: '%'
						// pointFormat: (point) => { console.log(point)}
					},
					colorByPoint: true
				}
			],
			tooltip: {
				enabled: false
			}
		}
	)
}
