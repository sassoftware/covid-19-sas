import ActionTypes from './ActionTypes'

const initalState = {
	leftPanel: true,
	userData: null
}

export default function homeReducer(state = initalState, action) {
	switch (action.type) {
		case ActionTypes.SET_LEFT_PANEL:
			return Object.assign({}, state,{leftPanel: action.state})
		case ActionTypes.SET_USER_DATA:
			return Object.assign({}, state, {
				userData: action.payload
			})
		default:
			return state
	}
}
