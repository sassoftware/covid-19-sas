import ActionTypes from "./ActionTypes";

const initialState = {
	errorMessage: '',
	error: false,
	override: false,
}

export default function newProjectReducer(state = initialState, action) {
	switch (action.type) {

		case ActionTypes.CLEAR: {
			return Object.assign({}, state, {
				errorMessage: '',
				error: false,
				override: false
			})
		}

		case ActionTypes.SUBMIT_ERROR: {
			return Object.assign({}, state, {
				errorMessage: action.payload.message,
				error: action.payload.error,
				override: action.payload.override
			})
		}

		default:
			return state
	}
}
