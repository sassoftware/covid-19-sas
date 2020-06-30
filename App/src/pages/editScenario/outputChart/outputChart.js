import React, {useEffect, useState} from 'react';
import Highcharts from 'highcharts'
import HC_more from 'highcharts/highcharts-more.js'
//import {tmodel_seir} from '../mock/outputData' 							// used for testing
import {getOutputChartOptions} from './outputChartOptions'
import {useSelector} from 'react-redux';
import {useParams} from 'react-router'
import {Column, Row} from 'carbon-components-react'
import './outputChart.scss'
import moment from 'moment'
import constants from '../../../config/constants'
import HC_patternFill from "highcharts-pattern-fill";
import highchartsMore from 'highcharts/highcharts-more';

highchartsMore(Highcharts);
HC_patternFill(Highcharts);
HC_more(Highcharts)
/**
 * Override the reset function, we don't need to hide the tooltips and
 * crosshairs.
 */
Highcharts.Pointer.prototype.reset = function () {
	return undefined;
};

/**
 * Highlight a point by showing tooltip, setting hover state and draw crosshair
 */
Highcharts.Point.prototype.highlightPoint = function (event) {
	// event = this.series.chart.pointer.normalize(event);
	this.onMouseOver(); // Show the hover markers
	this.series.chart.tooltip.refresh(this); // Show the tooltip
	// this.series.chart.xAxis[0].drawCrosshair(event, this); // Show the crosshair
};

const initalTooltipState = [
	{
		title: 'Hospital Census',
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'ICU',
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'Ventilator',
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'ECMO',
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'Dialysis',
		line: 0,
		low: 0,
		high: 0
	},
]

const OutputChart = () => {
	const {scenarioName} = useParams()
	const {fetchedProject} = useSelector(state => state.project);
	const [scenario, setScenario] = useState(fetchedProject ? fetchedProject.savedScenarios.find(conf => conf.scenario === scenarioName) : {})
	const [options, setOptions] = useState(null)
	const [tooltip, setTooltip] = useState(initalTooltipState)
	const tooltipRef = React.useRef(tooltip)
	const leftPanel = useSelector(state => state.home.leftPanel)


	useEffect(() => {
		setTimeout(() => {
			if (Highcharts.charts.length) {
				Highcharts.charts.forEach(chart => chart && chart.reflow())
			}
		}, 250)
	}, [leftPanel])

	useEffect(() => {
		const newScenario = fetchedProject.savedScenarios.find(conf => conf.scenario === scenarioName);
		setScenario(newScenario)
	}, [fetchedProject, scenarioName])

	useEffect(() => {
		//Check both conditions because of old projects
		if (scenario.lastRunModel !== undefined && scenario.lastRunModel !== null) {
			const rangeValue = [
				Number(new moment(scenario.ISOChangeDate, constants.DATE_FORMAT).format('x')),
				Number(new moment(scenario.ISOChangeDateTwo, constants.DATE_FORMAT).format('x')),
				Number(new moment(scenario.ISOChangeDate3, constants.DATE_FORMAT).format('x')),
				Number(new moment(scenario.ISOChangeDate4, constants.DATE_FORMAT).format('x')),
			]
			const distancing = [
				scenario.SocialDistancing,
				scenario.SocialDistancingChange,
				scenario.SocialDistancingChangeTwo,
				scenario.SocialDistancingChange3,
				scenario.SocialDistancingChange4,
			]
			const zeroDay = Number(new moment(scenario.DAY_ZERO, constants.DATE_FORMAT).format('x'))
			const nDays = scenario.N_DAYS
			const day = 1000 * 60 * 60 * 24
			const scenarioObject = {
				rangeValue: rangeValue,
				distancing: distancing,
				zeroDay: zeroDay,
				nDays: nDays,
				day: day
			}
			const options = getOutputChartOptions(scenario.lastRunModel, scenarioObject, 300);
			setOptions(options);
		} else {
			setOptions(null);
		}
	}, [scenario])

	useEffect(() => {
		if (options) {
			options.forEach((opt, i) => {
				const elId = 'chart' + i

				// Check if dom is already craeted
				let chartElement = document.getElementById(elId)

				// If dom is not created create one and assign a class to it
				if (!chartElement) {
					chartElement = document.createElement('div');
					chartElement.id = elId
					if (i === 0) {
						chartElement.className = "spb7";
					}
					else {
						chartElement.className = "spb5";
					}
				}

				chartElement.addEventListener('mousemove', handleTooltip)
				chartElement.addEventListener('touchmove', handleTooltip)
				chartElement.addEventListener('touchstart', handleTooltip)
				const containerElement = i < 2 ? 'leftColumn' : 'rightColumn'
				document.getElementById(containerElement).appendChild(chartElement);

				// remove old chart
				const currentChart = Highcharts.charts.find(chart => chart && chart.renderTo.id === elId)
				if (currentChart) {
					currentChart.destroy()
				}
				new Highcharts.chart(elId, opt)
			})
		}
	}, [options])

	const normalizeChartIndex = chart => {
		if (!chart) {
			throw new Error('Chart object is missing')
			return
		}
		let id = chart.renderTo.id
		if (!id) {
			return null
		} else {
			id = id.split('chart')[1]
			return id
		}
	}

	const handleTooltip = (e) => {
		let chart, point, range, i, event;
		const hCharts = Highcharts.charts
		// currentChart - chart where user is currently hovering
		const currentChart = hCharts.find(c => c && c.renderTo.id === e.currentTarget.id)

		// otherCharts - charts in group which points has to be highlighted and
		const otherCharts = hCharts.filter(c => c && c.renderTo.id && c.renderTo.id !== e.currentTarget.id)

		event = currentChart.pointer.normalize(e);
		point = currentChart.series[0].searchPoint(event, true);
		range = currentChart.series[1].searchPoint(event, true);
		if (point && range) {
			// highlight point of current chart
			point.highlightPoint(e)

			// create array with values for shared tooltip
			const newArray = [...tooltipRef.current]
			const normalizedIndex = normalizeChartIndex(currentChart)

			newArray[normalizedIndex].line = point.y
			newArray[normalizedIndex].low = range.options.low
			newArray[normalizedIndex].high = range.options.high

			// highlight linePoint and get values of points on other charts
			for (i = 0; i < otherCharts.length; i = i + 1) {
				chart = otherCharts[i];

				//let pointsFind = searchPoints(point, chart);
				let linePoint = chart.series[0].points[point.index]
				let rangePoint = chart.series[1].points[point.index]
				if (linePoint && rangePoint) {
					const newArray = [...tooltipRef.current]
					const normalizedIndex = normalizeChartIndex(chart)
					newArray[normalizedIndex].line = linePoint.y
					newArray[normalizedIndex].low = rangePoint.options.low
					newArray[normalizedIndex].high = rangePoint.options.high

					tooltipRef.current = [...newArray]
					setTooltip(newArray)
					linePoint.highlightPoint(e);
				}
			}
		}
	}

	return options ?
		<div className={'outputChart'}>
			<div className={'spb5'}>
				{/*<BlocksHolder/>*/}
			</div>
			<div className={'tooltipLegend'}>
				{tooltip.map((t, i) => <div key={i} className={'spb3'}>
					<div>{t.title}</div>
					<div>Current: {t.line} - low: {t.low} - high: {t.high}</div>
				</div>)}
			</div>
			<div id={'chartContainer'}>
				<Row>
					<Column id={'leftColumn'} lg={10} md={5}/>
					<Column id={'rightColumn'} lg={6} md={3}/>
				</Row>
			</div>
		</div>
		:
		null
}

export default OutputChart
