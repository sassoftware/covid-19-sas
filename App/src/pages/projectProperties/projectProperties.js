import React, {useEffect, useState} from 'react'
import {useSelector, useDispatch} from 'react-redux'
import {useParams, useHistory} from 'react-router-dom';
import {InlineNotification, OverflowMenu, OverflowMenuItem, Modal, Button} from 'carbon-components-react'
import './projectProperties.scss'
import {fetchSingleProject} from './projectActions'
import ActionTypes from './ActionTypes'
import QRcode from 'qrcode.react';
import AlertActionTypes from '../../components/customAlert/ActionTypes'
import adapterService from '../../adapterService/adapterService'
import { Share32 } from '@carbon/icons-react';

export const QRModal = (props) => {
	return (
		<Modal modalHeading="Share project" className={'qrModal'} open={props.open} onRequestClose={() => props.close()}
					 passiveModal>
			<QRcode value={props.value} size={window.innerWidth < 500 ? 250 : 500}/>
		</Modal>
	)
}


const overflowProps = {
	menu: () => ({
		direction: 'bottom',
		ariaLabel: 'Options',
		iconDescription: '',
		flipped: false,
		light: false,
		// onClick: action('onClick'),
		// onFocus: action('onFocus'),
		// onKeyDown: action('onKeyDown'),
		// onClose: action('onClose'),
		// onOpen: action('onOpen'),
	}),
	menuItem: () => ({
		// className: 'some-class',
		disabled: false,
		requireTitle: false,
		// onClick: action('onClick'),
	}),
};

const ProjectProperties = (props) => {
	const dispatch = useDispatch();
	const history = useHistory();
	const {projects} = useSelector(state => state.projectList)
  const {uri} = useParams() //This is used for initial render to see if the project should be fetched from the server
  const shareURL = window.location.href;
  const [clipNoification, setClipNotification] = useState(false);

	const {fetchedProject, selectedProject, save} = useSelector(state => state.project);
	const [error, setError] = useState('')

	useEffect(() => {
		if (uri !== null && uri !== "noProject" && (!selectedProject || (selectedProject && selectedProject.uri.split('/').pop() !== uri))) {
			const project = projects.find(p => (p.uri === '/files/files/' + uri))
			if (project) {
				dispatch({
					type: ActionTypes.SELECT_PROJECT,
					payload: project
				})
				fetchSingleProject(dispatch, project.uri, save);
			}
		}
		return () => {

		}
	// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [uri, projects])

	const deleteProject = () => {
		dispatch({
			type: AlertActionTypes.OPEN_CONFIRMATION,
			payload: {
				open: true,
				message: "Proces is ireversibile, are you sure you want to delete project?",
				title: 'Delete Project',
				primaryButton: 'Delete',
				action: () => {
					// TODO remove project
					setError('')
					adapterService.deleteItem(dispatch, selectedProject.uri)
						.then(() => {
							history.push('/projectList')
						})
						.catch(e => {
							setError(e.message)
						})

				}
			}
		})
  }
  
  const share = (action) => {

		if (save) {
			dispatch({
				type: AlertActionTypes.OPEN_CONFIRMATION,
				payload: {
					open: true,
					action,
					params: null,
					message: "Changes to this project have not been saved and will not be seen on any other device, do you still wish to proceed?"
				}
			})
		}
		else {
      action();
		}
  }

  const copy = () => {
    navigator.clipboard.writeText(shareURL);
    setClipNotification(true);

    setTimeout(() => {
      setClipNotification(false)
    }, 2000)
  }

	const openQR = () => {

		if (save) {
			dispatch({
				type: AlertActionTypes.OPEN_CONFIRMATION,
				payload: {
					open: true,
					action: () => props.openQR(window.location.href),
					params: null,
					message: "Changes to this project have not been saved and will not be seen on any other device, do you still wish to proceed?"
				}
			})
		}
		else {
			props.openQR(window.location.href)
		}
	}


	return (
		<div>
			{selectedProject ? <div>
				<div className={'lyb2 flex align-items-center'}>
					<OverflowMenu {...overflowProps.menu()} className={'spr5'}>
						<OverflowMenuItem
							{...overflowProps.menuItem()}
							itemText="Rename project"
							primaryFocus
							onClick={() => props.openDialog(selectedProject.name)}
						/>
						<OverflowMenuItem
							{...overflowProps.menuItem()}
							itemText='Share project'
							requireTitle
							// onClick={() => copyToClipboard(window.location.href)}
							onClick={openQR}
						/>

						<OverflowMenuItem
							{...overflowProps.menuItem()}
							itemText='Delete Project'
							requireTitle
							onClick={deleteProject}
						/>
					</OverflowMenu>
					<h2>{fetchedProject?.name}</h2>
				</div>
				{error && <InlineNotification kind={'error'} title={error}/>}
				<div className={'info lyb4'}>
					<h4 className={'propertie'}>Project Properties</h4>

					<div className={'propertie'}>
						<p>Folder Location</p>
						<p style={{fontWeight: 'bold'}}>{selectedProject.parentFolderUri}</p>
					</div>
					<div className={'propertie'}>
						<p>Created by</p>
						<p style={{fontWeight: 'bold'}}>{selectedProject.createdBy}</p>

					</div>
					<div className={'propertie'}>
						<p>Project file URI</p>
						<p style={{fontWeight: 'bold'}}>{selectedProject.uri}</p>

					</div>

          <div className={'propertie'}>
						<p>Project last modified on:</p>
						<p style={{fontWeight: 'bold'}}>{selectedProject.modifiedTimeStamp}</p>

					</div>

				</div>
				{/* <NewProject open={openDialog} close={() => setOpenDialog(false)} edit={project.name} /> */}

        {
          shareURL !== ''?  <div className={'share info flex flex-row lyb4'}>

              <div className={'shareInfo'}>
                <h4 className={'propertie'}>Share project</h4>
                <div className={'propertie '}>
                    <p>Project URL</p>
                    <p className={'link'}>{shareURL}</p>
                </div>
                <Button renderIcon={Share32} className={'propertie'} onClick={() => share(copy)} >Copy URL</Button>
              </div>
              <div  className={'propertie'}>
                <QRcode onClick={() => share(() => props.openQR(shareURL))} 
                        className={'qr'} 
                        value={shareURL} 
                        size={220} />
              </div>
            </div>: null
        }

        {
          clipNoification? <InlineNotification kind="info" title="URL copied to clipboard"/> :null
        }

			</div> : <h1>Project is not loaded</h1>}
		</div>

	)
}

export default ProjectProperties
