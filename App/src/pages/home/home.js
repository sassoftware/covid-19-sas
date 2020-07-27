import React from 'react'
import './home.scss'
import {managedRequest, call} from './homeActions'
import {connect} from 'react-redux'
import {withRouter} from 'react-router'
import {Content} from "carbon-components-react/lib/components/UIShell";

class Home extends React.Component {
	constructor() {
		super()
		this.state = {
			res: ''
		}
	}

	managedRequest = async () => {
		this.setState({res: ''})
		const sasProgram = 'common/startupService'
		const options = {
			sasProgram,
			dataObj: null,
			params: null
		}
		const res = await this.props.managedRequest(options)
		this.setState({res})
	}

	call = async () => {
		this.setState({res: ''})
		const sasProgram = 'common/startupService'
		const res = await this.props.call(sasProgram)
		this.setState({res})
	}

	chart1Ref = (ref) => {
		this.setState({chart1: ref})
	}
	chart2Ref = (ref) => {
		this.setState({chart2: ref})
	}

	onRangeChange = (e) => {
		this.setState({rangeValue: e})
	}

	render() {
		return <Content id='main-content'>
			<div className={'home'} ref={e => {
				this.mainContainer = e
			}}>
				<h1 className={'lyb3'}>Hospital Scenario Analysis</h1>
				<p>This application is a <a href="https://github.com/Boemska/create-sas-app">CSA</a> Progressive Web Application front end to <a href="https://github.com/sassoftware/covid-19-sas">github.com/sassoftware/covid-19-sas</a>. The App is an alternative user interface to the SAS Visual Analytics interface. It is not as full-featured as the Visual Analytics app, instead focusing on simplicity, minimal load time, and context switching efficiency.</p>
				<br />
				<h2 className={'lyb3'}>Projects</h2>
				<p>A 'project' is a collection of one or more scenarios created by different people. Projects allow users to Share work with colleagues, either by copying and pasting a link, or for camera-enabled devices, showing a QR code to a colleague so they can just point their device's camera at it. If they are connected to the network, and are authorised within the Files service to read your project, it will load on an instance of the app on their device.</p>
				<br />
				<h2 className={'lyb3'}>Scenarios</h2>
				<p>Each project can contain multiple 'scenarios'. Each scenarios can be adjusted using the different 'levers' to create the scenario. Each of the components on the scenario generation screen can be used to create the scenario providing an intuitive, and multi-device friendly experience. Once you have configured the scenario, clicking "Run Model" will send your scenario to the SAS Viya server to be run. </p>
			</div>
		</Content>
	}
}


function mapStateToProps(store) {
	return {
	}
}

function mapDispatchToProps(dispatch) {
	return {
		managedRequest: options => managedRequest(dispatch, options),
		call: program => call(dispatch, program)
	}
}


export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Home))

