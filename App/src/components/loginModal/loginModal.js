import React from 'react'
import Login from './Login/Login'
import {connect} from 'react-redux'
import './loginModal.scss'
import { Modal } from 'carbon-components-react'

class LoginModal extends React.PureComponent {
	render() {

		return (
			<Modal open={this.props.shouldLogin}
					passiveModal
					 >
				<Login />
			</Modal>
		)

		// return (<Modal bssize="small" className={'h100 flex-important align-items-center'}
		// 	show={this.props.shouldLogin}
		// 	dialogClassName="loginModal"
		// >
		// 	<Modal.Body>
		// 		<Login />
		// 	</Modal.Body>
		// </Modal>)
	}
}

function mapStateToProps(state) {
	return {
		shouldLogin: state.login.shouldLogin
	}
}

export default connect(mapStateToProps)(LoginModal)
