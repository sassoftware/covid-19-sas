import ActionTypes from './ActionTypes'
import adapterService from '../../adapterService/adapterService'
import ADAPTER_SETTINGS from '../../adapterService/config'
import {PROJECT_EXTENTION} from '../../components/newProject/newProjectActions'
import {getSelfUriFromLinks} from '../../components/utils'

export function setMainSpinner(dispatch, payload) {
	dispatch({
		type: ActionTypes.MAIN_SPINNER,
		payload
	})
}

export async function fetchProjects(dispatch) {

	let url = "/folders/folders/@item?path=" + ADAPTER_SETTINGS.metadataRoot;
	try {
		setMainSpinner(dispatch, true);
		let res = await adapterService.managedRequest(dispatch, 'get', url, {});
		const afiUrl = getSelfUriFromLinks(res.body)
		if (afiUrl !== '') {
			let url = afiUrl + "/members?filter=and(eq('contentType', 'file'),endsWith('name','" + PROJECT_EXTENTION + "'))&limit=10000";
			res = await adapterService.managedRequest(dispatch, 'get', url, {});
			dispatch({
				type: ActionTypes.FETCH_PROJECTS_RECIVED,
				payload: res.body.items
			})
		}
	} catch (e) {
		console.log("FETCH_PROJECTS_ERROR: ", e);
	} finally {
		setMainSpinner(dispatch, false);
	}
}
