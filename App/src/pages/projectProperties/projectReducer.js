import ActionTypes from './ActionTypes';

const initialState = {
	projectMetadata: JSON.parse(localStorage.getItem("projectMetadata")),
	projectContent: JSON.parse(localStorage.getItem("projectContent")),
	save: JSON.parse(localStorage.getItem('save'))
}

export function projectReducer(state = initialState, action) {

	switch (action.type) {

		case ActionTypes.SELECT_PROJECT: {
			localStorage.setItem("projectMetadata", JSON.stringify(action.payload));
			return Object.assign({}, state, {projectMetadata: action.payload})
		}

		case ActionTypes.FETCH_SINGLE_PROJECT: {
			localStorage.setItem("projectContent", JSON.stringify(action.payload))
			localStorage.setItem("save", JSON.stringify(false))
			return Object.assign({}, state, {
				projectContent: action.payload,
				save: false
			})
		}

		case ActionTypes.SET_SCENARIO: {
			const array = JSON.parse(JSON.stringify(state.projectContent.savedScenarios))
			array.splice(action.payload.index, action.payload.count, action.payload.configuration)
			const newProject = {
				...state.projectContent,
				savedScenarios: array
			}
			localStorage.setItem("projectContent", JSON.stringify(newProject));
			localStorage.setItem("save", JSON.stringify(true))
			return Object.assign({}, state, {
				projectContent: newProject,
				save: true
			})
		}

		case ActionTypes.REMOVE_SCENARIO: {
			const array = JSON.parse(JSON.stringify(state.projectContent.savedScenarios))
			array.splice(action.payload, 1)
			const newProject = Object.assign({}, state.projectContent, {
				savedScenarios: array
			})
			localStorage.setItem("projectContent", JSON.stringify(newProject));
			localStorage.setItem("save", JSON.stringify(true))
			return Object.assign({}, state, {
				projectContent: newProject,
				save: true
			})
		}


		case ActionTypes.UPDATE_PROJECT: {
			localStorage.setItem("save", JSON.stringify(true))
			return Object.assign({}, state, {
				projectContent: action.payload,
				save: true
			})
		}

		case ActionTypes.CHANGES_SAVED: {
			localStorage.setItem('save', JSON.stringify(false));
			const newProject = {
				...state.projectContent,
				lastModified: action.payload
      }
      localStorage.setItem('projectContent', JSON.stringify(newProject));
			return Object.assign({}, state, {
				save: false,
				projectContent: newProject
			})
		}

		case ActionTypes.OVERRIDE: {
			localStorage.setItem('save', JSON.stringify(false));
			return Object.assign({}, state, {save: false})
		}

		case ActionTypes.CLONE_SCENARIO: {
			localStorage.setItem("save", JSON.stringify(true))
			const array = JSON.parse(JSON.stringify(state.projectContent.savedScenarios))
			array.push(action.payload);
			const newProject = Object.assign({}, state.projectContent, {
				savedScenarios: array
			})
			return Object.assign({}, state, {
				projectContent: newProject,
				save: true
			})
		}

		default:
			return state
	}
}
