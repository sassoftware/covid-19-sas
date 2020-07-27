import React from 'react'
import './home.scss'
import {withRouter} from 'react-router'
import {Content} from "carbon-components-react/lib/components/UIShell";

const Home = () => (<Content id='main-content'>
		<div className={'home'}>
			<h1 className={'lyb3'}>CoV-19 App</h1>
			<h4 className={'spb3'}>A CSA PWA front end to <span
				className={'text-bold'}>github.com/sassoftware/covid-19-sas</span></h4>
			<p>This page is a placeholder for instructions and documentation.</p>
		</div>
	</Content>
)


export default withRouter(Home)

