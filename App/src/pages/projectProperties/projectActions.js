import ActionTypes from './ActionTypes'
import adapterService from '../../adapterService/adapterService'
import AlertActionTypes from '../../components/customAlert/ActionTypes'

const filesPrefix = '/files/files/'

async function request(dispatch, file) {
	let uri = file;
	// Check if uri has /files/files/ alraady
	if (! file.includes(filesPrefix)) {
		uri = filesPrefix + file;
	}

	try {
		// let res = await adapterService.getFileContent(dispatch, uri, {
		// 	cacheBust: true
		// });
		let res = await adapterService.getFileContent(dispatch, uri);
		res.body.lastModified = res.headers['last-modified'] || res.headers.get('Last-Modified');
		dispatch({
			type: ActionTypes.FETCH_SINGLE_PROJECT,
			payload: res.body
		})
	} catch (e) {
		console.log("SINGLE PROJECT ERROR: ", e);
	}
}

export async function fetchSingleProject(dispatch, file, dirty) {

	if (dirty) {
		dispatch({
			type: AlertActionTypes.OPEN_CONFIRMATION,
			payload: {
				open: true,
				message: "You have not saved changes made to this project, opening a new one will override these changes, do you wish to procced?",
				action: () => request(dispatch, file)
			}
		})
	} else {
		request(dispatch, file)
	}
}

export function selectProject(dispatch, payload) {
	dispatch({
		type: ActionTypes.SELECT_PROJECT,
		payload
	})
}

export function setScenario(dispatch, configuration, index) {
	dispatch({
		type: ActionTypes.SET_SCENARIO,
		payload: {
			configuration: configuration,
			count: 1, //How much to delete
			index: index
		}
	})
}

export function removeScenario(dispatch, index) {
	dispatch({
		type: ActionTypes.REMOVE_SCENARIO,
		payload: index
	})
}

export function cloneScenario(dispatch, clonedScenario) {
	dispatch({
		type: ActionTypes.CLONE_SCENARIO,
		payload: clonedScenario
	})
}
