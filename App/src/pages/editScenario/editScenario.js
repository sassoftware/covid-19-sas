import React, {useEffect, useState} from 'react'
import {Tabs, Tab, Button, InlineNotification, Loading, OverflowMenu, OverflowMenuItem} from 'carbon-components-react'
import "./editScenario.scss"
import {useDispatch, useSelector} from 'react-redux';
import {useHistory, useParams} from 'react-router';
import SocialDistancing from './SocialDistancing'
import ModelTuning from './ModelTuning'
import {
	fetchSingleProject,
	removeScenario as _removeScenario,
	cloneScenario as _cloneScenario
} from '../projectProperties/projectActions'
import HospitalAndVirus from './hospitalAndVirus'
import ActionTypes from '../projectProperties/ActionTypes'
import adapterService from '../../adapterService/adapterService'
import moment from 'moment'
import constants from '../../config/constants'
import AlertActionTypes from '../../components/customAlert/ActionTypes'
import OutputChart from './outputChart/outputChart'
import ProjectActionTypes from '../projectProperties/ActionTypes'

moment.updateLocale('en', {
	monthsShort: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
});

const modelList = ['tmodel_sir', 'tmodel_seir', 'tmodel_seir_fit_i']

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
		disabled: false,
		requireTitle: false,
		// onClick: action('onClick'),
	}),
};

const EditScenario = (props) => {
	const dispatch = useDispatch();
	const history = useHistory();
	const {uri, scenarioName} = useParams()
	const projects = useSelector(state => state.projectList.projects)
	const {projectContent, projectMetadata} = useSelector(state => state.project);
	const projectUri = projectMetadata && projectMetadata.uri.split('/').pop()
	const {save} = useSelector(state => state.project);
	const [scenario, setScenario] = useState(projectContent ? projectContent.savedScenarios.find(conf => conf.scenario === scenarioName) : {})
	const scenarioIndex = projectContent && projectContent.savedScenarios.findIndex(conf => conf.scenario === scenarioName)
	const [error, setError] = useState('')
	const [running, setRunning] = useState(false)

	useEffect(() => {
		projectContent && setScenario(projectContent.savedScenarios.find(conf => conf.scenario === scenarioName))
	}, [scenarioName, projectContent])

	useEffect(() => {
		if (uri !== null && uri !== "noProject" && (!projectMetadata || (projectMetadata && projectMetadata.uri.split('/').pop() !== uri))) {
			const newProject = projects.find(el => el.uri === '/files/files/' + uri)
			if (newProject) {
				dispatch({
					type: ActionTypes.SELECT_PROJECT,
					payload: newProject
				})
			}
			fetchSingleProject(dispatch, uri, save);
		}
		return () => {

		}
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [uri, projects])

	const runModel = async () => {
		setRunning(true)
		let ISOChangeDate = []
		ISOChangeDate.push("'" + new moment(scenario.ISOChangeDate, constants.DATE_FORMAT).format('DDMMMYYYY') + "'d")
		ISOChangeDate.push("'" + new moment(scenario.ISOChangeDateTwo, constants.DATE_FORMAT).format('DDMMMYYYY') + "'d")
		ISOChangeDate.push("'" + new moment(scenario.ISOChangeDate3, constants.DATE_FORMAT).format('DDMMMYYYY') + "'d")
		ISOChangeDate.push("'" + new moment(scenario.ISOChangeDate4, constants.DATE_FORMAT).format('DDMMMYYYY') + "'d")
		ISOChangeDate = ISOChangeDate.join(':')

		let SocialDistancingChange = []
		SocialDistancingChange.push((scenario.SocialDistancingChange / 100).toFixed(3))
		SocialDistancingChange.push((scenario.SocialDistancingChangeTwo / 100).toFixed(3))
		SocialDistancingChange.push((scenario.SocialDistancingChange3 / 100).toFixed(3))
		SocialDistancingChange.push((scenario.SocialDistancingChange4 / 100).toFixed(3))
		SocialDistancingChange = SocialDistancingChange.join(':')

		const preparedData = [
			{
				"scenario": scenario.scenario,
				"IncubationPeriod": scenario.IncubationPeriod,
				"InitRecovered": Number(scenario.InitRecovered / 100),
				"RecoveryDays": scenario.RecoveryDays,
				"doublingtime": scenario.doublingtime,
				"KnownAdmits": scenario.KnownAdmits,
				"Population": scenario.Population,
				"SocialDistancing": Number(scenario.SocialDistancing / 100),
				"MarketSharePercent": Number(scenario.MarketSharePercent / 100),
				"Admission_Rate": Number(scenario.Admission_Rate / 100),
				"ICUPercent": Number(scenario.ICUPercent / 100),
				"VentPErcent": Number(scenario.VentPErcent / 100),
				"ISOChangeDate": ISOChangeDate,
				"ISOChangeEvent": "Social Distance:Essential Businesses:Shelter In Place:Reopen",
				"ISOChangeWindow": "1:1:1:1",
				"SocialDistancingChange": SocialDistancingChange,
				"FatalityRate": Number(scenario.FatalityRate / 100),
				"plots": "NO"
			}
		]
		const data = adapterService.createTable(preparedData, 'INPUT_SCENARIOS');
		try {
			const res = await adapterService.call(dispatch, 'getData/runModel', data)
			const models = {}
			modelList.forEach(m => models[m] = res[m])
			const newScenario = Object.assign({}, scenario, {lastRunModel: models, oldModel: false});

			const index = projectContent.savedScenarios.findIndex(el => el.scenario === scenario.scenario);

			dispatch({
				type: ProjectActionTypes.SET_SCENARIO,
				payload: {
					configuration: newScenario,
					count: 1,
					index
				}
			})

			//setRunModel(dispatch, `${projectUri}-${scenario.scenario}`, res.tmodel_seir);
		} catch (e) {
			setError(e.message)
		} finally {
			setRunning(false)
		}
	}

	const removeScenario = (scenarioIndex) => {
		dispatch({
			type: AlertActionTypes.OPEN_CONFIRMATION,
			payload: {
				open: true,
				message: "Proces is ireversibile, are you sure you want to delete scenario?",
				title: 'Delete Scenario',
				primaryButton: 'Yes',
				action: () => {
					_removeScenario(dispatch, scenarioIndex)
					history.push('/')
				}
			}
		})
	}

	const generateName = (scenario) => {
		let numOfCopy = 0;
		let savedScenarios = projectContent.savedScenarios;
		for (let i = 0; i < savedScenarios.length; i++) {
			if (savedScenarios[i].scenario.slice(0, scenario.length) === scenario) {
				numOfCopy += 1;
			}
		}
		return `${scenario} (copy ${numOfCopy})`;
	}

	const cloneScenario = (currentScenario) => {
		let clonedScenarioName = generateName(currentScenario.scenario);
		let clonedScenario = Object.assign({}, currentScenario, {
			scenario: clonedScenarioName
		})
		dispatch({
			type: AlertActionTypes.OPEN_CONFIRMATION,
			payload: {
				open: true,
				message: "Are you sure you want to clone scenario?",
				title: 'Clone Scenario',
				primaryButton: 'Yes',
				action: () => {
					_cloneScenario(dispatch, clonedScenario)
					history.push(`/project/${projectUri}/scenario/${clonedScenario.scenario}`)
				}
			}
		})
	}

	return (
		<div className={'scenario'}>
			{
				projectContent && scenario ? <div>
					<div className={'flex align-items-start lyb2'}>
						<OverflowMenu {...overflowProps.menu()} className={'spr5'}>
							<OverflowMenuItem
								{...overflowProps.menuItem()}
								itemText="Rename Scenario"
								onClick={() => props.openDialog(scenarioName)}
							/>
							<OverflowMenuItem
								{...overflowProps.menuItem()}
								itemText="Clone Scenario"
								requireTitle
								onClick={() => cloneScenario(scenario)}
							/>
							<OverflowMenuItem {...overflowProps.menuItem()} itemText="Add to Comparison"/>
							<OverflowMenuItem
								{...overflowProps.menuItem()}
								itemText="Delete Scenario"
								hasDivider
								isDelete
								onClick={() => removeScenario(scenarioIndex)}
							/>
						</OverflowMenu>
						<div className={'flex flex-column'}>
							<div className={'scenarioTitle'}><span className={'sc'}>{scenario.scenario}</span></div>
							<div className={'scenarioSubtitle spl1 spt2'}>Scenario {scenario.created_at &&
							<span>created at {moment(scenario.created_at).format('MMMM D YYYY [at] H:mm')}</span>}</div>
						</div>
					</div>
					<div className={'lyb3'}>
						<div style={{width: '100%'}}>
							<Tabs type="container">
								<Tab
									href="#"
									id="socdist"
									label="Social Distancing"
								>
									<SocialDistancing/>
								</Tab>
								<Tab
									href="#"
									id="hnv"
									label="Hospital and Virus"
								>
									<HospitalAndVirus/>
								</Tab>
								<Tab
									href="#"
									id="model"
									label='Model Tuning'
								>
									<ModelTuning/>
								</Tab>
							</Tabs>
						</div>
					</div>
					<div className={'flex lyb3'}>
						<Button id={'runModel'} className={'spt5 spb5 spr5'} kind='primary' onClick={runModel} disabled={running}>Run Model
							{running &&
							<Loading className={'runModelSpinner'} description="Active loading indicator" withOverlay={false} small={true}/>}
						</Button>
						{error && <InlineNotification
							kind={'error'}
							title={error}
						/>}
						{(scenario.oldModel && scenario.lastRunModel) ? <InlineNotification
							kind={'warning'}
							title={"Parameters have been changed since the last time this model was run"}
						/> : null}
					</div>

					<OutputChart loading={running}/>
				</div> : <Loading description="Active loading indicator" withOverlay={false}/>
			}
		</div>
	)
}

export default EditScenario
