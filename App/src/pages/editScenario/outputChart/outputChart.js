import React, {useEffect, useRef, useState} from 'react';
import Highcharts from 'highcharts'
import HC_more from 'highcharts/highcharts-more.js'
import {getOutputChartOptions} from './outputChartOptions'
import {useDispatch, useSelector} from 'react-redux';
import {useParams} from 'react-router'
import {Column, Row, Switch, ContentSwitcher} from 'carbon-components-react'
import './outputChart.scss'
import moment from 'moment'
import constants from '../../../config/constants'
import HC_patternFill from "highcharts-pattern-fill";
import highchartsMore from 'highcharts/highcharts-more';
import {setModel} from './runModelActions'
import VariwideChart from '../headerCharts/variwideChart/variwideChart'
import HorizontalChart from '../headerCharts/horizontalChart/horizontalChart'
import adapterService from '../../../adapterService/adapterService'

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
		date: 0,
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'ICU',
		date: 0,
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'Ventilator',
		date: 0,
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'ECMO',
		date: 0,
		line: 0,
		low: 0,
		high: 0
	},
	{
		title: 'Dialysis',
		date: 0,
		line: 0,
		low: 0,
		high: 0
	},
]

const SharedTooltip = props => {
	const {tooltip} = props
	const date = new moment(tooltip[0].date).utc()
	return <div className={'tooltipLegend'}>
		<div className={'date'}>
			<div>{date.format('MMMM')} {date.format('YYYY')}</div>
			<div>{date.format('D')}</div>
		</div>
		<div className={'total'}>
			<div>total census</div>
			<div>{tooltip[0].line}</div>
		</div>
		<div className={'total'}>
			<div>ICU patients</div>
			<div>{tooltip[1].line}</div>
		</div>
		<div className={'group'}>
			<div><span className={'num'}>{tooltip[2].line}</span> on ventilators</div>
			<div><span className={'num'}>{tooltip[3].line}</span> in ECMO</div>
			<div><span className={'num'}>{tooltip[4].line}</span> on Dialysis</div>
		</div>
		<div className={'additionalCharts'}>
			<VariwideChart/>
			<HorizontalChart/>
		</div>
	</div>
}

const OutputChart = () => {
	const dispatch = useDispatch();
	const {scenarioName} = useParams()
	const {projectContent} = useSelector(state => state.project);
	const [scenario, setScenario] = useState(projectContent ? projectContent.savedScenarios.find(conf => conf.scenario === scenarioName) : {})
	const [options, setOptions] = useState(null)
	const [tooltip, setTooltip] = useState(initalTooltipState)
	const tooltipRef = useRef(tooltip)
	const leftPanel = useSelector(state => state.home.leftPanel)
	const activeModel = useSelector(state => state.runModel.model)
	const [peak, setPeak] = useState(initalTooltipState)
	const peakRef = useRef(peak)


	const cleanupCharts = () => {
		for (let i = 0; i < Highcharts.charts.length; i = i + 1) {
			let chart = Highcharts.charts[i];
			chart.tooltip.hide()
			chart.series.forEach(s => {
				s.points.forEach(p => p.onMouseOut())
			})
		}
		setTooltip(peakRef.current)
	}

	useEffect(() => {
		setTimeout(() => {
			if (Highcharts.charts.length) {
				Highcharts.charts.forEach(chart => chart && chart.reflow())
			}
		}, 250)
	}, [leftPanel])

	useEffect(() => {
		const newScenario = projectContent.savedScenarios.find(conf => conf.scenario === scenarioName);
		setScenario(newScenario)
	}, [projectContent, scenarioName])

	useEffect(() => {
		//Check both conditions because of old projects
		if (scenario.lastRunModel !== undefined && scenario.lastRunModel !== null && scenario.lastRunModel[activeModel.name]) {
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
			const model = scenario.lastRunModel[activeModel.name]
			const options = getOutputChartOptions(model, scenarioObject, 250);
			setOptions(options);
		} else {
			setOptions(null);
		}
	}, [scenario, activeModel])

	useEffect(() => {
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
				const newArray = JSON.parse(JSON.stringify(tooltipRef.current))
				const normalizedIndex = normalizeChartIndex(currentChart)

				newArray[normalizedIndex].date = point.x
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
						// const newArray = JSON.parse(JSON.stringify(tooltipRef.current))
						const normalizedIndex = normalizeChartIndex(chart)
						newArray[normalizedIndex].date = linePoint.x
						newArray[normalizedIndex].line = linePoint.y
						newArray[normalizedIndex].low = rangePoint.options.low
						newArray[normalizedIndex].high = rangePoint.options.high


						linePoint.highlightPoint(e);
					}
				}
				tooltipRef.current = [...newArray]
				setTooltip(newArray)
			}
		}

		const normalizeChartIndex = chart => {
			if (!chart) {
				throw new Error('Chart object is missing')
			}
			let id = chart.renderTo.id
			if (!id) {
				return null
			} else {
				id = id.split('chart')[1]
				return parseInt(id)
			}
		}

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
					chartElement.addEventListener('mousemove', handleTooltip)
					chartElement.addEventListener('touchmove', handleTooltip)
					chartElement.addEventListener('touchstart', handleTooltip)
					chartElement.addEventListener('mouseleave', cleanupCharts)
					chartElement.addEventListener('touchend', cleanupCharts)
					const containerElement = i < 2 ? 'leftColumn' : 'rightColumn'
					document.getElementById(containerElement).appendChild(chartElement);
					const currentChart = Highcharts.charts.find(chart => chart && chart.renderTo.id === elId)
					if (currentChart) {
						currentChart.destroy()
					}
					new Highcharts.chart(elId, opt)
				} else {
					// Update chart if it already exists
					const currentChart = Highcharts.charts.find(chart => chart && chart.renderTo.id === elId)
					if (currentChart) {
						currentChart.update(opt)
					}
				}
			})
		}
	}, [options])


	// Set peak for current model
	useEffect(() => {
		const model = scenario.lastRunModel[activeModel.name]
		if (model) {
			const newPeak = getPeak(model)
			peakRef.current = newPeak
			setPeak(newPeak)
		}
	}, [scenario, activeModel])

	const getPeak = model => {
		const initState = JSON.parse(JSON.stringify(initalTooltipState))
		const columnMap = adapterService.getObjOfTable(model[0], 'NAME', 'VARNUM')
		const newPeak = model[1].reduce((acc, current) => {
			const newState = acc
			let timestamp = new Date(adapterService.fromSasDateTime(current[columnMap.DATETIME])).getTime()
			if (current[columnMap['HOSPITAL_OCCUPANCY']] > acc[0].line) {
				newState[0].line = current[columnMap['HOSPITAL_OCCUPANCY']]
				newState[0].date = timestamp
				newState[0].low = current[columnMap['LOWER_HOSPITAL_OCCUPANCY']]
				newState[0].height = current[columnMap['UPPER_HOSPITAL_OCCUPANCY']]

				newState[1].line = current[columnMap['DIAL_OCCUPANCY']]
				newState[1].date = timestamp
				newState[1].low = current[columnMap['LOWER_DIAL_OCCUPANCY']]
				newState[1].height = current[columnMap['UPPER_DIAL_OCCUPANCY']]

				newState[2].line = current[columnMap['VENT_OCCUPANCY']]
				newState[2].date = timestamp
				newState[2].low = current[columnMap['LOWER_VENT_OCCUPANCY']]
				newState[2].height = current[columnMap['UPPER_VENT_OCCUPANCY']]

				newState[3].line = current[columnMap['ICU_OCCUPANCY']]
				newState[3].date = timestamp
				newState[3].low = current[columnMap['LOWER_ICU_OCCUPANCY']]
				newState[3].height = current[columnMap['UPPER_ICU_OCCUPANCY']]

				newState[4].line = current[columnMap['ECMO_OCCUPANCY']]
				newState[4].date = timestamp
				newState[4].low = current[columnMap['LOWER_ECMO_OCCUPANCY']]
				newState[4].height = current[columnMap['UPPER_ECMO_OCCUPANCY']]
			}
			return newState
		}, initState)
		return newPeak
	}

	useEffect(() => {
		setTooltip(peak)
	},[peak])

	const onModelChange = (model) => {
		setModel(dispatch, model)
	}

	return options ?
		<div className={'outputChart'}>
			<div className={'spb5'}>
				{/*<BlocksHolder/>*/}
				<div className={'flex justify-content-end'}>
					<ContentSwitcher
						selectionMode="manual"
						onChange={onModelChange}
					>
						<Switch name="tmodel_seir" text="SEIR Model"/>
						<Switch name="tmodel_sir" text="SIR Model"/>
						<Switch name="tmodel_seir_fit_i" text="SEIR FIT I"/>
					</ContentSwitcher>
				</div>
			</div>
			<SharedTooltip tooltip={tooltip}/>
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
