import React, {useState, useEffect} from 'react'
import {Modal, TextInput, TextArea} from 'carbon-components-react'
import './newProject.scss';
import {useDispatch, useSelector} from 'react-redux';
import {createNewProject} from './newProjectActions';
import ActionTypes from './ActionTypes';
import {useHistory} from 'react-router';
import ProjectActons from '../../pages/projectProperties/ActionTypes'


// Modal for creating new project
const NewProject = (props) => {
	const edit = props.edit || null
	const history = useHistory();

	const dispatch = useDispatch();

	const {error, errorMessage, override} = useSelector(state => state.newProject);
	const [project, setProject] = useState({
		name: '',
		description: ''
	});
	const {fetchedProject} = useSelector(state => state.project);
	// const [error, setError] = useState(false);
	const user = useSelector(state => state.home.userData)

	const submit = () => {
		dispatch({type: ActionTypes.CLEAR})
		if (props.edit === null) {
			const forSubmit = {
				name: project.name,
				savedScenarios: [],
				createdOn: new Date(),
				createdBy: user.name,
				description: project.description
			}

			const res = createNewProject(dispatch, project.name, forSubmit, override);

			res.then((res) => {
				console.log('response', res)
				props.close();
				history.push('/project/' + res);
			})
		} else {
			const newProject = {
				...fetchedProject,
				name: project.name,
				description: project.description
			}
			dispatch({
				type: ProjectActons.UPDATE_PROJECT,
				payload: newProject
			})

			props.close();
		}

	}

	useEffect(() => {
		if (props.edit !== null) setProject({...project, name: props.edit});
		else setProject({...project, name: ''})
	// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [edit])

	return (
		<Modal className={'newProject'} open={props.open}
					 primaryButtonText={`${props.edit !== null ? "Save" : "Add new project" }`} secondaryButtonText="Cancel"
					 onRequestClose={() => {
						 dispatch({type: ActionTypes.CLEAR})
						 props.close();
					 }}
					 onRequestSubmit={submit}
					 modalHeading={`${props.edit !== null ? "Edit project name" : "Add new project" }`}>
			<div className={'spb3'}>
				<TextInput id='projectName' labelText="Project name"
									 value={project.name}
									 onChange={e => setProject({...project, name: e.target.value})}
									 invalid={error}
									 invalidText={errorMessage}/>
			</div>

			<TextArea
				labelText="Project description"
				value={project.description}

				onChange={e => setProject({...project, description: e.target.value})}/>
		</Modal>
	)
}

export default NewProject
