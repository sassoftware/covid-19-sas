import ActionTypes from './ActionTypes'

export function setRunModel(dispatch, key, data) {
	dispatch({
		type: ActionTypes.SET_RUNMODEL,
		payload: {
			key: key,
			data: data
		}
	})
}