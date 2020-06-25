import ActionTypes from './ActionTypes'

const initialState = {
    projects: [],
}

export default function projectListReducer (state = initialState, action) {
    switch (action.type) {
    case ActionTypes.FETCH_PROJECTS_RECIVED:
        return Object.assign({}, state, {projects: action.payload})
    default:
        return state
    }
}

