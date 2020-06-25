import ActionTypes from './ActionTypes'

const initalState = {
	shouldLogin: false
}

function loginReducer(state = initalState, action) {
	switch(action.type) {
		case ActionTypes.SET_SHOULD_LOGIN:
			return Object.assign({}, state, {
				shouldLogin: action.state
			})
		default:
			return state
	}
}

export default loginReducer
