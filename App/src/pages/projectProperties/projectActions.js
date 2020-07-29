import ActionTypes from './ActionTypes'
import adapterService from '../../adapterService/adapterService'
import AlertActionTypes from '../../components/customAlert/ActionTypes'
import {history} from '../../index'

const filesPrefix = '/files/files/'

export async function getProjectContent(dispatch, file) {
	let uri = file;
	// Check if uri has /files/files/ alraady
	if (!file.includes(filesPrefix)) {
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

export async function fetchProjectMetadata(dispatch, uri) {
	try {
		let res = await adapterService.getFileDetails(dispatch, '/files/files/' + uri)
		return res.body
	} catch (e) {
		throw new Error(e.message)
	}
}

export async function fetchSingleProject(dispatch, file, dirty) {
	if (dirty) {
		dispatch({
			type: AlertActionTypes.OPEN_CONFIRMATION,
			payload: {
				open: true,
				message: "You have not saved changes made to this project, opening a new one will override these changes, do you wish to procced?",
				action: () => getProjectContent(dispatch, file),
				cancelAction: () => {
					let metadata = localStorage.getItem('projectMetadata')
					if (metadata) {
						metadata = JSON.parse(metadata)
						let uri = metadata.uri.split('/').pop()
						history.push(`/project/${uri}`);
					}
				}
			}
		})
	} else {
		getProjectContent(dispatch, file)
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
