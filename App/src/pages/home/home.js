import React from 'react'
import './home.scss'
import {withRouter} from 'react-router'
import {Content} from "carbon-components-react/lib/components/UIShell";

const Home = () => (<Content id='main-content'>
		<div className={'home'}>
			<h1 className={'lyb3'}>Hospital Scenario Analysis</h1>
			<p>This application is a <a href="https://github.com/Boemska/create-sas-app">CSA</a> Progressive Web Application front end to <a href="https://github.com/sassoftware/covid-19-sas">github.com/sassoftware/covid-19-sas</a>. The App is an alternative user interface to the SAS Visual Analytics interface. It is not as full-featured as the Visual Analytics app, instead focusing on simplicity, minimal load time, and context switching efficiency.</p>
			<br />
			<h2>Projects</h2>
			<p>A 'project' is a collection of one or more scenarios grouped together into a project file. Projects allow users to Share work with colleagues, either by copying and pasting a link, or for camera-enabled devices, showing the QR code on the project properties page to a colleague so they can simply point their device's camera at it. Assuming they are connected to the same VPN and have the necessary authorisation within the Folders service to read your project, it will load on an instance of the app on their device.</p>
			<br />
			<h2>Scenarios</h2>
			<p>A 'scenario' is a combination of model input parameters that drives a model output. Once you have configured a scenario, clicking "Run Model" will send your scenario to the SAS Viya server to be run. Multiple scenarios can be saved within the same project, and compared and contrasted within that project.</p>
		</div>
	</Content>
)


export default withRouter(Home)

