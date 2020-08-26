import React from 'react'
import {Modal} from 'carbon-components-react'
import {useSelector, useDispatch} from 'react-redux'
import ActionTypes from './ActionTypes'

const CustomAlert = () => {

	const dispatch = useDispatch();
	const {open, action, cancelAction, message, title = 'Attention', primaryButton = 'Proceed', secondaryButton = 'Cancel', passive = false} = useSelector(state => state.customAlert);

	return (
		<Modal
			passiveModal={passive}
			open={open}
			modalHeading={title}
			onRequestSubmit={() => {
				action();
				dispatch({
					type: ActionTypes.CLOSE_CONFIRMATION
				})
			}}
			onRequestClose={() => {
				cancelAction && cancelAction()
				dispatch({
					type: ActionTypes.CLOSE_CONFIRMATION
				})
			}}
			primaryButtonText={primaryButton}
			secondaryButtonText={secondaryButton}
		>
			<h1>{message}</h1>
		</Modal>
	)

}

export default CustomAlert
