import React, {Component} from 'react';
// import {
// 	Row, Col, Form,
// 	FormGroup,
// 	Button, InputGroup
// } from 'react-bootstrap'
import {Form, FormGroup, TextInput, Button, InlineLoading } from 'carbon-components-react'
import {withRouter} from 'react-router'
import adapterService from '../../../adapterService/adapterService'
import {connect} from 'react-redux'
import './login.scss'
import {Locked32, User32} from '@carbon/icons-react';

class Login extends Component {
	constructor(props) {
		super(props)
		this.state = {
			username: 'jimdemo',
			password: 'Bigballs1',
			error: '',
			loading: false
		}
		this.login = this.login.bind(this)
		this.validateEmail = this.validateEmail.bind(this)
		this.validatePassword = this.validatePassword.bind(this)
		this.onInputChange = this.onInputChange.bind(this)
	}

	login() {
		this.setState({error: '', validated: true, loading: true})
		/*
		adapterService.login(this.state.username, this.state.password)
			.then(res => {
				console.log('[LOGIN RES]', res)
				this.props.logging(false);
			})
			.catch(e => {
				debugger
				if (e === -1) {
					this.setState({error: 'Username or password invalid'})
				} else if (e === -2) {
					this.setState({error: 'Problem communicating with server'});
				} else {
					this.setState({error: 'SAS login error with status code ' + e})
					console.log('[ADAPT SERVICE - LOGIN ERROR]', e.message || e.stack)
				}
			})
		*/
		// })
		// }
		this.props.login(this.state.username, this.state.password)
			.then(res => {
				this.setState({...this.state, loading: false})
				console.log('login response', res)
			})
			.catch(e => {
				this.setState({error: e, loading: false})
			})
	}

	validateEmail() {
		if (!this.state.username) {
			return undefined
		}
		// const isEmail = RegExp(/^[a-zA-Z0-9.!#$%&’+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)$/).test(this.state.username.trim())
		const isOk = this.state.username.length > 4
		return isOk ? 'success' : 'error'
	}

	validatePassword() {
		if (!this.state.password) {
			return undefined
		}
		const isOk = this.state.password.length > 2
		return isOk ? 'success' : 'error'
	}

	onInputChange(e) {
		const name = e.target.name
		const value = e.target.value
		this.setState({
			[name]: value
		})
	}

	render() {
		return (
			<div className="spl5 form-container">
				<h1>Login</h1>
				<p>Sign In to your account</p>
				<Form>
					<FormGroup legendText="">
						<div className={'spt5 flex flex-row align-items-center '}>
							<User32 />
							<TextInput
								id="username"
								labelText=""
								placeholder="Username"
								name="username"
								value={this.state.username}
								onChange={this.onInputChange}/>
						</div>
						<div className={'spt5 flex flex-row align-items-center'}>
							<Locked32 />
							<TextInput.PasswordInput
								id="password"
								labelText= ""
								placeholder="Password"
								name="password"
								value={this.state.password}
								onChange={this.onInputChange} />
						</div>
					</FormGroup>
					<div className={'flex flex-row justify-content-between'}>
						{
							!this.state.loading?
								<Button className={'loginBtn'} onClick={this.login}>Login</Button> :
								<InlineLoading status='active' description="Loading..." />

						}
						<h5 className={'danger align-self-center spl5'}>
							{
								this.state.error !== ''? this.state.error : null
							}
						</h5>
					</div>

				</Form>

			</div>
		);
	}
}

function mapDispatchToProps(dispatch) {
	return {
		login: (u, p) => adapterService.login(dispatch, u, p)
	}
}
export default withRouter(connect(()=>({}), mapDispatchToProps)(Login));
