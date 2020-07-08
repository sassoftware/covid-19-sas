import React from 'react'
import Highcharts from 'highcharts'
import HighchartsReact from 'highcharts-react-official'
import {connect} from 'react-redux'
import {withRouter} from 'react-router'
import {horizontalChartOptions} from './horizontalChartOptions'


class HorizontalChart extends React.Component {
	constructor(props) {
        super(props)
		const scenarioName = props.match.params.scenarioName
		this.scenario = props.project.savedScenarios.find(conf => conf.scenario === scenarioName)
		this.scenarioIndex = props.project.savedScenarios.findIndex(conf => conf.scenario === scenarioName)
		this.state = {
            res: '',
			chart: null
		}
	}

	componentWillReceiveProps(nextProps) {
		if ((this.props.match.params.scenarioName !== nextProps.match.params.scenarioName) ||
			this.props.project !== nextProps.project
		) {
			this.scenario = nextProps.project.savedScenarios.find(conf => conf.scenario === nextProps.match.params.scenarioName)
			this.scenarioIndex = nextProps.project.savedScenarios.findIndex(conf => conf.scenario === nextProps.match.params.scenarioName)
		}
	}


	resizeCharts = () => {
		this.state.chart && setTimeout(() => {
			this.state.chart.chart && this.state.chart.chart.reflow()
		}, 250)
	}

	chartRef = (ref) => {
		this.setState({chart: ref})
	}

	render() {
		// this.resizeCharts()
		const options = horizontalChartOptions(this.scenario.MarketSharePercent,this.scenario.Admission_Rate,this.scenario.ICUPercent,this.scenario.VentPErcent,this.scenario.FatalityRate)
		return <div onresize={this.resizeCharts()}>
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

export default withRouter(connect(mapStateToProps, null)(HorizontalChart))

