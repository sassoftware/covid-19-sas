import ActionTypes from './ActionTypes';

const initialState = {}

export function runModelReducer(state = initialState, action) {

	switch (action.type) {
		case ActionTypes.SET_RUNMODEL: {
			return Object.assign({}, state, {
					[action.payload.key]: action.payload.data
      });
		}
		default:
			return state
	}
}
