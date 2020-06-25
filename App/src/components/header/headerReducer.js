import ActionTypes from './ActionTypes'

const initialState = {
	mainSpinner: false,
  update: false,
  offline: false,
}

export default function headerReducer(state = initialState, action) {
	switch (action.type) {
		case ActionTypes.MAIN_SPINNER:
			return Object.assign({}, state, {
				mainSpinner: action.payload
			})
		case ActionTypes.UPDATE_AVAILABLE: {
			return Object.assign({}, state, {update: action.payload})
    }
    case ActionTypes.SET_OFFLINE:
			return Object.assign({}, state, {
				offline: action.payload
			})

		default:
			return state
		}
}

