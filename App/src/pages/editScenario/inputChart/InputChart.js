import React from 'react'
import './inputChart.scss'
import {connect} from 'react-redux'
import {withRouter} from 'react-router'
import Highcharts from 'highcharts'
import HighchartsReact from 'highcharts-react-official'
import variwide from 'highcharts/modules/variwide'
import draggablePoints from 'highcharts/modules/draggable-points'
import Slider, {Handle} from 'rc-slider'
import 'rc-slider/assets/index.css';
import 'rc-tooltip/assets/bootstrap.css';
import moment from 'moment'
import {inputChartOptions} from './inputChartOptions'
import {setScenario} from '../../projectProperties/projectActions'
import constants from '../../../config/constants'

variwide(Highcharts)
draggablePoints(Highcharts)

const Range = Slider.Range

// By default the text is rendered inside the handle, so we need to take it out
// white-space: nowrap; ensures that it doesn't break on a new line, due to the handle being very small
const Val = (props) => <div {...props} className={'handleValue'}/>
const MyHandle = function (props) {
	const {value, dragging, index, ...rest} = props;

	return (
		<Handle style={{
			display: 'flex',
			justifyContent: 'flex-start'
		}} key={index} value={value} {...rest}>
			{dragging && <Val>{new moment(value).format('D MMM')}</Val>}
			{!dragging && <Val>{new moment(value).format('D MMM')}</Val>}
		</Handle>
	);
}

const day = 1000 * 60 * 60 * 24 // milicecond * minute * hour * day

class InputChart extends React.Component {
	constructor(props) {
		super(props)
		const scenarioName = props.match.params.scenarioName
		this.scenario = props.project.savedScenarios.find(conf => conf.scenario === scenarioName)
		this.scenarioIndex = props.project.savedScenarios.findIndex(conf => conf.scenario === scenarioName)

		this.state = {
			res: '',
			chart: null,
			rangeValue: [
				// Number(new moment(this.scenario.DAY_ZERO, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDate, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDateTwo, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDate3, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDate4, constants.DATE_FORMAT).format('x')),
			],
			distancing: [
				this.scenario.SocialDistancing,
				this.scenario.SocialDistancingChange,
				this.scenario.SocialDistancingChangeTwo,
				this.scenario.SocialDistancingChange3,
				this.scenario.SocialDistancingChange4,
			],
			zeroDay: Number(new moment(this.scenario.DAY_ZERO, constants.DATE_FORMAT).format('x')),
			nDays: this.scenario.N_DAYS
		}
	}

	componentWillUnmount() {
		if (this.timeoutResizing) {
			clearTimeout(this.timeoutResizing)
		}
	}


	componentWillReceiveProps(nextProps) {
		if ((this.props.match.params.scenarioName !== nextProps.match.params.scenarioName) ||
			this.props.project !== nextProps.project
		) {
			this.scenario = nextProps.project.savedScenarios.find(conf => conf.scenario === nextProps.match.params.scenarioName)
			this.scenarioIndex = nextProps.project.savedScenarios.findIndex(conf => conf.scenario === nextProps.match.params.scenarioName)

			this.setState({
				rangeValue: [
					// Number(new moment(this.scenario.DAY_ZERO, constants.DATE_FORMAT).format('x')),
					Number(new moment(this.scenario.ISOChangeDate, constants.DATE_FORMAT).format('x')),
					Number(new moment(this.scenario.ISOChangeDateTwo, constants.DATE_FORMAT).format('x')),
					Number(new moment(this.scenario.ISOChangeDate3, constants.DATE_FORMAT).format('x')),
					Number(new moment(this.scenario.ISOChangeDate4, constants.DATE_FORMAT).format('x'))
				],
				distancing: [
					this.scenario.SocialDistancing,
					this.scenario.SocialDistancingChange,
					this.scenario.SocialDistancingChangeTwo,
					this.scenario.SocialDistancingChange3,
					this.scenario.SocialDistancingChange4,
				],
				zeroDay: Number(new moment(this.scenario.DAY_ZERO, constants.DATE_FORMAT).format('x')),
				nDays: this.scenario.N_DAYS
			})
		}

		if (this.props.leftPanel !== nextProps.leftPanel) {
			this._fireResizeManually()
		}
	}

	onRangeChange = (e) => {
		this.setState({rangeValue: e})
	}

	setScenario = e => {
		const [change2, change3, change4, change5] = e
		const conf = Object.assign({}, this.scenario)
		// conf.DAY_ZERO = new moment(start1).format(constants.DATE_FORMAT)
		conf.ISOChangeDate = new moment(change2).format(constants.DATE_FORMAT)
		conf.ISOChangeDateTwo = new moment(change3).format(constants.DATE_FORMAT)
		conf.ISOChangeDate3 = new moment(change4).format(constants.DATE_FORMAT)
		conf.ISOChangeDate4 = new moment(change5).format(constants.DATE_FORMAT)
		this.props.setScenario(conf, this.scenarioIndex)
	}

	dropCb = e => {
		let newPoint = Math.round(e.newPoint.y)
		if (newPoint < 0) newPoint = 0
		if (newPoint > 100) newPoint = 100
		const distancingName = e.target.name
		const conf = Object.assign({}, this.scenario)
		conf[distancingName] = newPoint
		this.props.setScenario(conf, this.scenarioIndex)
	}

	_fireResizeManually = () => {
		this.timeoutResizing = setTimeout(() => {
			const evt = document.createEvent('UIEvents');
			evt.initUIEvent('resize', true, false, window, 0);
			window.dispatchEvent(evt);
		}, 201); // wait just 1 millisecond more than transition open/close
	}


	render() {
		const options = inputChartOptions(this.state.zeroDay, this.state.nDays, this.state.rangeValue, this.state.distancing, day, this.dropCb)
		return <div>
			<div className={'chartWrapper'}>
				<div className={'rangeWrapper'}>
					<div className={'blueLine'}></div>
					<Range
						// count={3}
						min={this.state.zeroDay}
						max={this.state.zeroDay + this.state.nDays * day}
						// defaultValue={[this.state.start1, this.state.start2, this.state.start3, this.state.start4, this.state.end4]}
						value={this.state.rangeValue}
						onChange={this.onRangeChange}
						onAfterChange={this.setScenario}
						step={day}
						allowCross={false}
						tipFormatter={v => new moment(v).format(constants.DATE_FORMAT)}
						pushable
						handle={MyHandle}
					/>
				</div>

				{options && <HighchartsReact
					allowChartUpdate={true}
					highcharts={Highcharts}
					options={options}
				/>}
			</div>
		</div>
	}
}


function mapStateToProps(state) {
	return {
		project: state.project.projectContent,
		leftPanel: state.home.leftPanel
	}
}

function mapDispatchToProps(dispatch) {
	return {
		setScenario: (conf, index) => setScenario(dispatch, conf, index)
	}
}


export default withRouter(connect(mapStateToProps, mapDispatchToProps)(InputChart))

