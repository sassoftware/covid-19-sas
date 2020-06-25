import ActionTypes from './ActionTypes'

export function setRequest(dispatch, promise, params) {
	dispatch({
		type: ActionTypes.SET_REQUEST,
		payload: {promise, params}
	})
}

export function removeRequest(dispatch, promise) {
	dispatch({
		type: ActionTypes.REMOVE_REQUEST,
		payload: promise
	})
}

export function clearRequests(dispatch) {
	dispatch({
		type: ActionTypes.CLEAR_REQUESTS
	})
}
