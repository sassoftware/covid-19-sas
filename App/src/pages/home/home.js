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
				<h1 className={'lyb3'}>CoV-19 App</h1>
				<h4 className={'spb3'}>A CSA PWA front end to <span className={'text-bold'}>github.com/sassoftware/covid-19-sas</span></h4>
				<p>This page is a placeholder for instructions and documentation.</p>
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

