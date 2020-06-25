import ActionTypes from './ActionTypes'

export function setShouldLogin(dispatch, state) {
	dispatch({
		type: ActionTypes.SET_SHOULD_LOGIN,
		state
	})
}
