import ActionTypes from './ActionTypes';

const initialState = {
	model: {index: 0, name: 'tmodel_seir'}
}

export function runModelReducer(state = initialState, action) {

	switch (action.type) {
		// case ActionTypes.SET_RUNMODEL: {
		// 	return Object.assign({}, state, {
		// 			[action.payload.key]: action.payload.data
    //   });
		// }
		case ActionTypes.SET_MODEL: {
			return Object.assign({}, state, {
					model: action.model
      });
		}
		default:
			return state
	}
}
