import ActionTypes from './ActionTypes';

const initialState = {
	selectedProject: JSON.parse(localStorage.getItem("selectedProject")),
	fetchedProject: JSON.parse(localStorage.getItem("fetchedProject")),
	save: JSON.parse(localStorage.getItem('save'))
}

export function projectReducer(state = initialState, action) {

	switch (action.type) {

		case ActionTypes.SELECT_PROJECT: {
			localStorage.setItem("selectedProject", JSON.stringify(action.payload));
			return Object.assign({}, state, {selectedProject: action.payload})
		}

		case ActionTypes.FETCH_SINGLE_PROJECT: {
			localStorage.setItem("fetchedProject", JSON.stringify(action.payload))
			localStorage.setItem("save", JSON.stringify(false))
			return Object.assign({}, state, {
				fetchedProject: action.payload,
				save: false
			})
		}

		case ActionTypes.SET_SCENARIO: {
			const array = JSON.parse(JSON.stringify(state.fetchedProject.savedScenarios))
			array.splice(action.payload.index, action.payload.count, action.payload.configuration)
			const newProject = {
				...state.fetchedProject,
				savedScenarios: array
			}
			localStorage.setItem("fetchedProject", JSON.stringify(newProject));
			localStorage.setItem("save", JSON.stringify(true))
			return Object.assign({}, state, {
				fetchedProject: newProject,
				save: true
			})
		}

		case ActionTypes.REMOVE_SCENARIO: {
			const array = JSON.parse(JSON.stringify(state.fetchedProject.savedScenarios))
			array.splice(action.payload, 1)
			const newProject = Object.assign({}, state.fetchedProject, {
				savedScenarios: array
			})
			localStorage.setItem("fetchedProject", JSON.stringify(newProject));
			localStorage.setItem("save", JSON.stringify(true))
			return Object.assign({}, state, {
				fetchedProject: newProject,
				save: true
			})
		}


		case ActionTypes.UPDATE_PROJECT: {
			localStorage.setItem("save", JSON.stringify(true))
			return Object.assign({}, state, {
				fetchedProject: action.payload,
				save: true
			})
		}

		case ActionTypes.CHANGES_SAVED: {
			localStorage.setItem('save', JSON.stringify(false));
			const newProject = {
				...state.fetchedProject,
				lastModified: action.payload
			}
			return Object.assign({}, state, {
				save: false,
				fetchedProject: newProject
			})
		}

		case ActionTypes.OVERRIDE: {
			localStorage.setItem('save', JSON.stringify(false));
			return Object.assign({}, state, {save: false})
		}

		case ActionTypes.CLONE_SCENARIO: {
			localStorage.setItem("save", JSON.stringify(true))
			const array = JSON.parse(JSON.stringify(state.fetchedProject.savedScenarios))
			array.push(action.payload);
			const newProject = Object.assign({}, state.fetchedProject, {
				savedScenarios: array
			})
			return Object.assign({}, state, {
				fetchedProject: newProject,
				save: true
			})
		}

		default:
			return state
	}
}
