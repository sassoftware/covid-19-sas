import React from 'react';
import './userInfoDropDown.scss'
import adapterService from "../../adapterService/adapterService";
import {connect} from 'react-redux'
import {Toggle, InlineLoading} from "carbon-components-react"
import {withRouter} from 'react-router'
import Badge from "../badge/badge";
import toastr from 'toastr'
import {getUserData, setUserData} from '../../pages/home/homeActions'
import {clearRequests} from '../../adapterService/adapterActions'
import {UserAvatarFilled32, Logout20, MisuseOutline20, CheckmarkOutline20} from "@carbon/icons-react";
import {
	SwitcherItem,
	Switcher,
	SwitcherDivider
} from "carbon-components-react/lib/components/UIShell";


export class UserInfoDropDown extends React.PureComponent {
	constructor(props) {
		super(props);
		this.statusBarShow = this.statusBarShow.bind(this);
		this.logout = this.logout.bind(this);
		this.handleSwitchChange = this.handleSwitchChange.bind(this);
		this.state = {
			statusBar: false,
			debugMode: false,
			requests: []
		}
	}

	UNSAFE_componentWillReceiveProps(nextProps) {
		if (this.props.requests !== nextProps.requests) {
			this.getRequestsList(nextProps)
		}
	}

	getRequestsList(props) {
		const requests = Array.from(props.requests.values()).reverse()

		// Requests where the program name is only a substring
		const subRequests = requests.map(el => {
			let sub;
			if (el.program.slice(-1) === '/') {
				sub = el.program.split('/').reverse()[1]
			}
			else {
				sub = el.program.split('/').reverse()[0]
			}
			return {
				...el,
				program: sub
			}
		})

		let loading = false;
		for (let file of requests) {
			if (file.running) {
				loading = true;
				break;
			}
		}

		this.loading = loading;
		this.setState({
			loading,
			requests: subRequests
		})
	}

	componentDidMount() {
		this.props.getUserData()
		this.getRequestsList(this.props)
		let debugMode;
		const debugModeLocalStore = localStorage.getItem('debugMode');
		if (debugModeLocalStore) {
			debugModeLocalStore === 'true' ? debugMode = true : debugMode = false
			this.setState({
				debugMode: debugMode
			}, () => {
				adapterService.setDebugMode(this.state.debugMode)
			})
		}
	}

	logout() {
		adapterService.logout()
			.then(() => {
				// This will trigger getting user's data and
				// creating of fresh csrf token for login form
				// which will pop up automatically
				this.props.setUserData(null)
				this.props.getUserData()
			})
			.catch(e => {
				toastr.error('Something went wrong!')
			})
	}

	statusBarShow(show) {
		this.setState({
			statusBar: show
		})
	}

	handleSwitchChange() {
		this.setState({
			debugMode: !this.state.debugMode
		}, () => {
			adapterService.setDebugMode(this.state.debugMode)
		})
	}

	handleRequestClick = (request) => {

		if (this.state.debugMode) {
			this.props.history.replace({
				pathname: '/debugLogs',
				state: {
					forCollapse: request.logTime !== undefined ? request.logTime : null
				}
			});
			this.props.closeSideNav()
		}

	}

	getMenuLink = () => {
		const username = this.props.userData && (this.props.userData.name || (this.props.userData.userInfo && this.props.userData.userInfo[0].USERNAME))
		const avatar = this.props.userData && (this.props.userData.userAvatar || (this.props.userData.userInfo && this.props.userData.userInfo[0].AVATAR_URI))
		return (
			<div
				className={'info-header'}
				onClick={() => this.setState({statusBar: !this.state.statusBar})}
				// onMouseEnter={() => this.statusBarShow(true)}
				// onMouseLeave={() => this.statusBarShow(false)}
			>
				{
					this.props.userData ? <img src={avatar} alt="avatar"/> : <UserAvatarFilled32 className="avatar"/>
				}

				{this.props.userData ? <span className={'title spl5'}>{username}</span> :
					<span className={'title spl5'}>Not logged in</span>
				}

			</div>
		)

	}

	render() {

		return (
			<Switcher aria-label="Sidenav">
				<SwitcherItem aria-label="Toggle" className={'spt5'}>
					<div className={'item'}>
						Debug Mode
						<Toggle id="debugToggle" className={'debugToggle'}
										toggled={this.state.debugMode} onClick={this.handleSwitchChange}

						/>
					</div>
				</SwitcherItem>
				<SwitcherItem aria-label="Applicationslogs" className={'spt5'} onClick={() => {
					this.props.history.replace('/applicationLogs');
					this.props.closeSideNav()
				}}>
					<div className={'item'}>
						<span>Application Logs</span>
						<Badge background={'#737373'}
									 value={this.props.logs && this.props.logs.applicationLogs.length > 0 ? this.props.logs.applicationLogs.length : 0}
									 color={'#ffffff'}/>
					</div>
				</SwitcherItem>
				<SwitcherItem aria-label="Debug" className={'spt5'} onClick={() => {
					this.props.history.replace(`${this.state.debugMode ? '/debugLogs' : '/failedRequests'}`)
					this.props.closeSideNav()
				}}>
					{!this.state.debugMode &&
					<
						div className={'item'}>
						<span>Failed Requests</span>
						<Badge background={'#e12200'}
									 value={this.props.logs && this.props.logs.failedRequests.length > 0 ? this.props.logs.failedRequests.length : 0}
									 color={'#ffffff'}/>
					</div>}
					{this.state.debugMode &&
					<
						div className={'item'}>
						<span>Debug Logs</span>
						<Badge background={'#0079b8'}
									 value={this.props.logs && this.props.logs.debugData.length > 0 ? this.props.logs.debugData.length : 0}
									 color={'#ffffff'}/>
					</div>}
				</SwitcherItem>
				<SwitcherItem aria-label="Error" className={'spt5'} onClick={() => {

					this.props.history.replace('/errorLogs')
					this.props.closeSideNav()
				}}>
					<div className={'item'}>
						<span>Errors</span>
						<Badge background={'#fdcf08'}
									 value={this.props.logs && this.props.logs.sasErrors.length > 0 ? this.props.logs.sasErrors.length : 0}
									 color={'#000000'}/>
					</div>
				</SwitcherItem>
				<SwitcherDivider/>
				<div className={'requests flex-grow-1 flex-fill'}>
					{this.state.requests.map((request, index) =>
						<SwitcherItem aria-label="request.program" onClick={() => this.handleRequestClick(request)} key={index}>
							<div className={`request ${request.running ? 'inProgress' : ''}`}>
								<div className={'text'}>{request.program}</div>
								{!request.running && request.successful && <CheckmarkOutline20 className={'check'}/>}
								{!request.running && !request.successful && <MisuseOutline20 className={'error'}/>}
								{request.running && <InlineLoading className={'inlineLoading'} description=""/>}
							</div>

						</SwitcherItem>)
					}
				</div>

				<SwitcherItem aria-label="Clear" onClick={() => this.props.clearRequests()}>Clear</SwitcherItem>
				<SwitcherDivider/>
				<SwitcherItem aria-label="Logout" onClick={this.logout}>
					<div className={'item'}>
						<div style={{verticalAlign: 'center'}}>Log Out</div>
						<Logout20 className={'logout'}/>
					</div>
				</SwitcherItem>

			</Switcher>

		)
	}
}


function mapStateToProps(state) {
	return {
		userData: state.home.userData,
		logs: state.adapter.logs,
		requests: state.adapter.requests
	}

}

function mapDispatchToProps(dispatch) {
	return {
		getUserData: () => getUserData(dispatch),
		setUserData: data => setUserData(dispatch, data),
		clearRequests: () => clearRequests(dispatch)
	}
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(UserInfoDropDown))

