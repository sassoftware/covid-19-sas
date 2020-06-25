import React, {useState, useEffect} from 'react'
import {Modal, TextInput} from 'carbon-components-react'
import "./newScenario.scss"
import {useDispatch, useSelector} from 'react-redux'
import DefaultScenarioConfig from './defaultScenarioConfig'
import {useHistory} from 'react-router-dom'
import ProjectActionTypes from '../../pages/projectProperties/ActionTypes'

const NewScenario = (props) => {

	const history = useHistory()
	const dispatch = useDispatch();
	const [name, setName] = useState('');
	const [error, setError] = useState({status: false, message: ''});

	const {fetchedProject, selectedProject} = useSelector(state => state.project);
	const projectUri = selectedProject && selectedProject.uri.split('/').pop()


	const submit = () => {
		setError({...error, status: false})
		if (name === '') {
			setError({status: true, message: "Please enter a name for the configuration"})
			return;
		}

		if (fetchedProject === null || selectedProject === null) {
			setError({status: true, message: "No project selected, select one from the list or create a new one"})
			return;
		}

		if (fetchedProject.savedScenarios === undefined) {
			setError({status: true, message: "You are trying to use an old project with an outdated structure"})
			return;
		}

		if (fetchedProject.savedScenarios.filter(conf => conf.scenario === name).length !== 0) {
			setError({status: true, message: "A configuration with this name already exists"})
			return;
		}

		try {

			if (props.edit === null){
				const configuration = JSON.parse(JSON.stringify(DefaultScenarioConfig))
				configuration.scenario = name
				configuration.created_at = new Date().getTime()

				dispatch({
					type: ProjectActionTypes.SET_SCENARIO,
					payload: {
						configuration: configuration,
						count: 0, //How much to delete
						index: fetchedProject.savedScenarios.length
					}
				})

				props.close();
				history.push(`/project/${projectUri}/scenario/${configuration.scenario}`)
			}
			else {
				const index = fetchedProject.savedScenarios.findIndex(el => el.scenario === props.edit);
                const configuration = {
                    ...fetchedProject.savedScenarios.find(el => el.scenario === props.edit),
                    scenario: name
				}

                dispatch({
                    type: ProjectActionTypes.SET_SCENARIO,
                    payload: {
                        configuration,
                        count: 1,
                        index
                    }
                })
                history.replace(`/project/${projectUri}/scenario/${configuration.scenario}`)
                props.close();
			}


			// project.savedScenarios.push(configuration);
			//
			// //CREATE BLOB
			// const forBlob = JSON.stringify(project)
			// let blob = new Blob([forBlob], {type: "octet/stream"});
			//
			// debugger
			// const res = adapterService.updateFile(dispatch, selectedProject.uri, blob, project.lastModified);
			//
			// res.then(r => console.log("ADD CONFIGURATION RESULT: ", r))
			// 	.catch(e => console.log("ADD CONFIGURATION ERROR: ", e))
		}
		catch (e) {
			console.log("ADD CONFIGURATION ERROR: ", e)
		}
	}

	useEffect(() => {
        if (props.edit !== null) setName(props.edit)
        else setName('')
        return () => {

        }
    }, [props])

	return (
		<div className="newScenario">
			<Modal
				modalHeading="Add new Scenario"
				primaryButtonText="Add"
				secondaryButtonText="Cancel"
				title="New Scenario"
				onRequestSubmit={submit}
				open={props.open}
				onRequestClose={() => {
					setError({...error, status: false});
					setName('');
					props.close();
				}}>
				<TextInput
					id={'name'}
					invalid={error.status}
					invalidText={error.message}
					value={name}
					onChange={e => setName(e.target.value)}
					labelText="Scenario name"
				/>
			</Modal>
		</div>
	)
}

export default NewScenario
