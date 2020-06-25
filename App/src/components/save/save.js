import React, {useState} from 'react'
import {Save32} from '@carbon/icons-react'
import {useSelector, useDispatch} from 'react-redux'
import adapterService from '../../adapterService/adapterService';
import ActionTypes from '../../pages/projectProperties/ActionTypes'
import {Modal} from 'carbon-components-react';
import {PROJECT_EXTENTION} from '../newProject/newProjectActions'

async function updateFile(dispatch, uri, blob, lastModified) {
	const res = await adapterService.updateFile(dispatch, uri, blob, lastModified);
	return res
}
const ErrorModal = (props) => {
    return (
        <Modal
        open={props.open}
        modalHeading="Attention"
        passiveModal
        onRequestClose={() => props.close()}
        >
            <p> {props.message} </p>
        </Modal>
    )
}

const Save = (props) => {
    const dispatch = useDispatch();
    const {fetchedProject,  selectedProject, save } = useSelector(state => state.project);
    const [error, setError] = useState({
        status: false,
        message: '',
    })
    const submit = () => {
        const forBlob = JSON.stringify(fetchedProject);
        let blob = new Blob([forBlob], {type: "octet/stream"});
        let fileName = fetchedProject.name
				if (!fileName.endsWith(PROJECT_EXTENTION)) {
					fileName += PROJECT_EXTENTION
				}
        const dataObj = {
        	file:[blob, fileName]
        }
        const res = updateFile(dispatch, selectedProject.uri, dataObj, fetchedProject.lastModified);
        res.then( result => {
            console.log("SAVE RESULT: " , result);
            dispatch({
                type: ActionTypes.CHANGES_SAVED,
                payload: result.headers['last-modified'] || result.headers.get('Last-Modified')
            })
        })
        .catch(e => {
            if (e.status === 412) {
                setError({status: true, message: "Someone has already made changes to this file after last save"});
            }
            else {
                setError({status: true, message: e.message})
            }
            console.log("SAVE ERROR: ", e)
        })
    }
    return (
        <div>
            <Save32 onClick={() => {if(save) submit()}} style={{cursor: save ? 'pointer' : 'not-allowed', fill: `${save?  props.color : "rgb(150, 150, 150)" }`}} />
            <ErrorModal open={error.status} message={error.message} close={() => setError({status: false})} />
        </div>
    )
}

export default Save
