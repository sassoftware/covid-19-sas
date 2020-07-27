import ActionTypes from './ActionTypes'

const initialState = {
	projects: [],
	mainSpinner: false
}

export default function projectListReducer (state = initialState, action) {
    switch (action.type) {
    case ActionTypes.FETCH_PROJECTS_RECIVED:
        return Object.assign({}, state, {projects: action.payload})
    case ActionTypes.MAIN_SPINNER:
        return Object.assign({}, state, {mainSpinner: action.payload})
    default:
        return state
    }
}

