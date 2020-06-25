import ActionTypes from './ActionTypes'

const initalState = {
	leftPanel: true,
	mainSpinner: false,
	userData: null,
	dataLabels: null
}

export default function homeReducer(state = initalState, action) {
	switch (action.type) {
		case ActionTypes.SET_LEFT_PANEL:
			return Object.assign({}, state,{leftPanel: action.state})
		case ActionTypes.SET_USER_DATA:
			return Object.assign({}, state, {
				userData: action.payload
			})
		case ActionTypes.SET_DATA_LABELS: {
			return Object.assign({}, state, {
				dataLabels: action.payload
			})
		}
		default:
			return state
	}
}
