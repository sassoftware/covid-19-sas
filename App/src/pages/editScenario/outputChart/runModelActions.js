import ActionTypes from './ActionTypes'

export function setModel(dispatch, model) {
	dispatch({
		type: ActionTypes.SET_MODEL,
		model
	})
}
