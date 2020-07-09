import React from 'react'
import Highcharts from 'highcharts'
import HighchartsReact from 'highcharts-react-official'
import variwide from 'highcharts/modules/variwide'
import moment from 'moment'
import constants from '../../../../config/constants'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { variwideChartOptions } from './variwideChartOptions'

variwide(Highcharts)

const day = 1000 * 60 * 60 * 24 // milicecond * minute * hour * day

class VariwideChart extends React.Component {
	constructor(props) {
		super(props)
		const scenarioName = props.match.params.scenarioName
		this.scenario = props.project.savedScenarios.find(conf => conf.scenario === scenarioName)
		this.scenarioIndex = props.project.savedScenarios.findIndex(conf => conf.scenario === scenarioName)

		this.state = {
			res: '',
			rangeValue: [
				Number(new moment(this.scenario.ISOChangeDate, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDateTwo, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDate3, constants.DATE_FORMAT).format('x')),
				Number(new moment(this.scenario.ISOChangeDate4, constants.DATE_FORMAT).format('x')),
			],
			chart: null,
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

	componentWillReceiveProps(nextProps) {
		if ((this.props.match.params.scenarioName !== nextProps.match.params.scenarioName) ||
			this.props.project !== nextProps.project
		) {
			this.scenario = nextProps.project.savedScenarios.find(conf => conf.scenario === nextProps.match.params.scenarioName)
			this.scenarioIndex = nextProps.project.savedScenarios.findIndex(conf => conf.scenario === nextProps.match.params.scenarioName)

			this.setState({
				rangeValue: [
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
	}


	resizeCharts = () => {
		this.state.chart && setTimeout(() => {
			this.state.chart.chart && this.state.chart.chart.reflow()
		}, 250)
	}

	chartRef = (ref) => {
		this.setState({ chart: ref })
	}

	render() {
		const options = variwideChartOptions(this.state.zeroDay, this.state.nDays, this.state.rangeValue, this.state.distancing, day)
		return <div>
			<div className={'chartWrapper'}>
				{options && <HighchartsReact
					allowChartUpdate={true}
					highcharts={Highcharts}
					options={options}
					ref={this.chartRef}
				/>}
			</div>
		</div>
	}
}

function mapStateToProps(state) {
	return {
		project: state.project.projectContent
	}
}

export default withRouter(connect(mapStateToProps, null)(VariwideChart))

