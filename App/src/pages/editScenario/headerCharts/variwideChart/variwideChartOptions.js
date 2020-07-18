import { dateFormat } from "highcharts"

const seriesColor = '#0378CD'
const borderColor = '#f4f4f4'
const labelColor = 'rgb(180,180,180)'

export function variwideChartOptions(zeroDay, nDays, rangeValue, distancing, day) {
	const [change1, change2, change3, change4] = rangeValue
	const [d1, d2, d3, d4, d5] = distancing
	const maxDay = zeroDay + nDays * day

	return ({
		chart: {
			type: 'variwide',
			height: 150,
			width: 200
		},
		credits: {
			enabled: false
		},
		title: {
			text: "Social Distancing",
			style: {
				color: labelColor,
				fontSize: 12
			}
		},
		subtitle: false,
		xAxis: {
			type: 'datetime',
			min: zeroDay,
			max: maxDay,
			labels: {
				style: {
					color: labelColor
				}
			}
		},
		yAxis: {
			min: 0,
			max: 100,
			labels: {
				enabled: false
			},
			title: {
				enabled: false
			},
			gridLineWidth: 0
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
						z: change1 - zeroDay,
						name: "SocialDistancing",
					},
					{
						x: change1,
						y: d2,
						z: change2 - change1,
						name: "SocialDistancingChange",
					},
					{
						x: change2,
						y: d3,
						z: change3 - change2,
						name: "SocialDistancingChangeTwo",
					},
					{
						x: change3,
						y: d4,
						z: change4 - change3,
						name: "SocialDistancingChange3",
					},

					{
						x: change4,
						y: d5,
						z: maxDay - change4,
						name: "SocialDistancingChange4",
					},

				],
				color: seriesColor,
				borderColor: borderColor,
				dataLabels: {
					enabled: false
				}
			}
		],
		tooltip: {
			enabled: true,
			formatter: function () {
				let tooltipMessage = `Start date: <b>${dateFormat('%e - %b - %Y', new Date(this.x))}</b><br/>
										End date: <b>${dateFormat('%e - %b - %Y', new Date(this.point.z + this.x))}</b><br/>
										Distanicng: <b>${this.y}%</b><br>`;
				return tooltipMessage;
			}
		}
	}
	)
}
