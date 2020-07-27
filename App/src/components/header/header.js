import React from 'react'
// import LogoImg from '../../assets/images/blogo.svg'
import './header.scss'
import LoadingIndicator from '../loading-indicator/loading-indicator'
import UserInfoDropDown from '../userInfoDropDown/userInfoDropDown'
import {withRouter} from 'react-router'
import {connect} from 'react-redux'
import {removeRequest} from '../../adapterService/adapterActions'
import moment from 'moment'
import {
	Header as CarbonHeader,
	HeaderGlobalBar,
	HeaderPanel,
	HeaderName
} from "carbon-components-react/lib/components/UIShell";
import {Close32, Menu32, UserAvatarFilled32, Warning32, Information32} from '@carbon/icons-react';
import { Button } from 'carbon-components-react'

const logs = ['/applicationLogs', '/errorLogs', '/failedRequests', '/debugLogs'];

class Header extends React.PureComponent {

	constructor(props) {
		super(props)
		this.requestsWatcherInterval = null;
		this.state = {
			toogleSidenav: false,
			toogleNewProjectDialog: false
		}
	}

	requestsWatcher = () => {
		this.requestsWatcherInterval = setInterval(() => {
			Array.from(this.props.requests.keys()).forEach(key => {
				let param = this.props.requests.get(key)
				let timeDiff = moment().diff(moment(param.timestamp), 'seconds')
				if (timeDiff > 360) {
					this.props.removeRequest(key)
				}
			})
		})
	}

	componentDidMount() {
		// this.requestsWatcher();
	}

	componentWillUnmount() {
		clearInterval(this.requestsWatcherInterval);
	}

	routing = () => {
		//console.log(logs.includes(this.props.history.location.pathname))
		if (logs.includes(this.props.history.location.pathname)) {
			this.props.history.replace('/')
		}
		else {
			this.props.history.push('/')
		}

	}

	render() {
		const avatar = this.props.userData && (this.props.userData.userAvatar || (this.props.userData.userInfo && this.props.userData.userInfo[0].AVATAR_URI))
		const username = this.props.userData && (this.props.userData.name || (this.props.userData.userInfo && this.props.userData.userInfo[0].USERNAME))
		return (
			<CarbonHeader aria-label="Boemska Platform">
				<div onClick={() => this.props.triggerPanel()} style={{marginLeft: '10px'}}>
					{
						!this.props.toglePanel ? <Menu32 className={'headerIcon'}/> : <Close32 className={'headerIcon'}/>
					}
				</div>
				{/* <HeaderName className={'name'} onClick={() => this.routing()} prefix="">
							<img src={LogoImg} alt={'logo'} className={'logo'} />
						</HeaderName> */}
				<HeaderName children="" prefix="Hospital Scenario Analysis"></HeaderName>
				<HeaderGlobalBar>
					{
						this.props.update?
							<Button renderIcon={Warning32} className={'spr5'} onClick={() => window.location.reload()}>New update available </Button>	: null
					}
          {
            this.props.offline?
              <Button renderIcon={Information32} className={'spr5'}>App working in offline mode </Button>	: null
          }

					<LoadingIndicator/>

					<div className={'avatarHolder'}>
						{this.props.userData ? <img src={avatar} className="user-avatar" alt="avatar"/> : <UserAvatarFilled32 className="avatar"/>}
					</div>
					<div onClick={() => this.setState({...this.state, toogleSidenav: !this.state.toogleSidenav})}>
						{this.props.userData ? <span className={'title spl5 spr5'}>{username}</span> :
							<span className={'title spl5 spr5'}>Not logged in</span>
						}
					</div>
				</HeaderGlobalBar>

				<HeaderPanel aria-label="Sidenav" expanded={this.state.toogleSidenav}>
					<UserInfoDropDown
						closeSideNav={() => this.setState({...this.state, toogleSidenav: !this.state.toogleSidenav})}/>
				</HeaderPanel>

				{/* <NewProject edit={null} open={this.state.toogleNewProjectDialog} close={() => this.setState({...this.state, toogleNewProjectDialog: false})} /> */}
			</CarbonHeader>
		)
	}
}

function mapStateToProps(state) {
	return {
		requests: state.adapter.requests,
		userData: state.home.userData,
    update: state.header.update,
    offline: state.header.offline
	}
}

function mapDispatchToProps(dispatch) {
	return {
		removeRequest: (promise) => removeRequest(dispatch, promise),

	}
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Header))

