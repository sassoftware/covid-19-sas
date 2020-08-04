import React, {useRef, useState} from 'react'
import {Save32} from '@carbon/icons-react'
import {useSelector, useDispatch} from 'react-redux'
import adapterService from '../../adapterService/adapterService';
import ActionTypes from '../../pages/projectProperties/ActionTypes'
import {Modal} from 'carbon-components-react';
import {PROJECT_EXTENTION} from '../newProject/newProjectActions'
import './save.scss'
import moment from 'moment'

async function updateFile(dispatch, uri, blob, lastModified) {
	const res = await adapterService.updateFile(dispatch, uri, blob, lastModified);
	return res
}

const PopupModal = (props) => {
	const {fileMeta: meta} = props
	return (
		<Modal
			open={props.status}
			modalHeading="Attention"
			onRequestSubmit={props.onOverride}
			onRequestClose={() => props.close()}
			primaryButtonText={props.primaryButtonText || 'Override'}
			secondaryButtonText={props.secondaryButtonText || 'Cancel'}
			passiveModal={props.passiveModal || false}
		>
			<p> {props.message} </p>
			{meta && <div className={'spt5'}>
				<div>Modified by: {meta.modifiedBy}</div>
				<div>Last modified: {moment(meta.modifiedTimeStamp).format('DD-MM-YYYY HH:mm')}</div>
			</div>}
		</Modal>
	)
}

const Save = (props) => {
	const dispatch = useDispatch();
	const {projectContent, projectMetadata, save} = useSelector(state => state.project);
	const [popup, setPopup] = useState({
		status: false,
		message: '',
		fileMeta: null
	})
	const popupRef = useRef(popup)

	const dipsatchChangesSaved = (result) => {
		dispatch({
			type: ActionTypes.CHANGES_SAVED,
			payload: result.headers['last-modified'] || result.headers.get('Last-Modified')
		})
		setPopup({
			status: false,
			message: '',
			fileMeta: null
		})
	}
	const getProjectBlob = () => {
		const forBlob = JSON.stringify(projectContent);
		let blob = new Blob([forBlob], {type: "octet/stream"});
		let fileName = projectContent.name
		if (!fileName.endsWith(PROJECT_EXTENTION)) {
			fileName += PROJECT_EXTENTION
		}
		const dataObj = {
			file: [blob, fileName]
		}
		return dataObj
	}
	const onOverride = () => {
		const dataObj = getProjectBlob()
		const res = updateFile(dispatch, projectMetadata.uri, dataObj, popupRef.current.fileMeta.lastModified);
		res.then(dipsatchChangesSaved)
	}
	const submit = () => {
		const dataObj = getProjectBlob()
		const projectUri = projectMetadata.uri
		const res = updateFile(dispatch, projectUri, dataObj, projectContent.lastModified);
		res.then(dipsatchChangesSaved)
			.catch(e => {
				if (e.status === 412) {
					adapterService.getFileDetails(dispatch, projectUri)
						.then(res => {
							res.body.lastModified = res.headers['last-modified'] || res.headers.get('Last-Modified');
							const fileMeta = res.body
							setPopup({
								status: true,
								message: "It looks like this file has been changed outside of this session. Would you like to overwrite it?",
								fileMeta,
								onOverride
							});
							popupRef.current = {
								status: true,
								message: "It looks like this file has been changed outside of this session. Would you like to overwrite it?",
								fileMeta,
								onOverride
							}
						})
						.catch(e => {
							setPopup({
								status: true,
								message: e.message,
								passiveModal: true
							})
						})
				}
				else {
					setPopup({
						status: true,
						message: e.message,
						passiveModal: true
					})
				}
				console.log("SAVE ERROR: ", e)
			})
	}
	return (
		<div>
			<Save32
				onClick={() => {
					if (save) submit()
				}}
				style={{cursor: save ? 'pointer' : 'not-allowed', fill: `${save ? props.color : "rgb(150, 150, 150)" }`}}
			/>
			<PopupModal
				close={() => setPopup({status: false})}
				{...popup}
			/>
		</div>
	)
}

export default Save
