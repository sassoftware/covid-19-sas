import React, {useState, useEffect} from 'react';
import './App.scss';
import {Switch, Route} from 'react-router-dom';
import Home from './pages/home/home'
import Header from './components/header/header'
import Page500 from './pages/Page500/Page500'
import Page404 from './pages/Page404/Page404'
import LoginModal from './components/loginModal/loginModal'
import ApplicationLogs from './pages/applicationLogs/applicationLogs'
import FailedRequests from './pages/failedRequests/failedRequests'
import ErrorLogs from './pages/errorLogs/errorLogs'
import DebugLogs from './pages/debugLogs/debugLogs'
import {Content, ToastNotification} from 'carbon-components-react';
import {LeftPanel} from './components/leftPanel/leftPanel';
import {ProjectList} from './pages/projectList/projectList';
import NewProject from './components/newProject/newProject';
import ProjectProperties, {QRModal} from './pages/projectProperties/projectProperties';
import EditScenario from './pages/editScenario/editScenario';
import ForecastRun from './pages/forecastRun/forecastRun';
import {useDispatch, useSelector} from 'react-redux';
import NewScenario from './components/newScenario/newScenario';
import CustomAlert from './components/customAlert/customAlert'
import {fetchProjects} from './pages/projectList/projectListActions'
import PWAPrompt from 'react-ios-pwa-prompt'
import ActionTypes from './pages/home/ActionTypes'

function App() {

	const toglePanel = useSelector(state => state.home.leftPanel)
	const [togleDialog, setTogleDialog] = useState({open: false, edit: null});
	const [scenarioDialog, setScenarioDialog] = useState({open: false, edit: null});
	const [qrModal, setQRModal] = useState({open: false, value: ''});
	const update = useSelector(state => state.header.update)

	const dispatch = useDispatch();

	useEffect(() => {
		fetchProjects(dispatch)
		return () => {

		}
	}, [dispatch])

	const setToglePanel = state => {
		dispatch({
			type: ActionTypes.SET_LEFT_PANEL,
			state
		})
	}

	return (
		<div className="App">
			<div>
				<Header openDialog={() => setTogleDialog({open: true, edit: null})} toglePanel={toglePanel}
								triggerPanel={() => setToglePanel(!toglePanel)}/>
				<LeftPanel newProject={() => setTogleDialog({open: true, edit: null})} toglePanel={toglePanel}
									 openDataConfDialog={() => setScenarioDialog({open: true, edit: null})}/>

				{/* <div className={'main'}> */}
				<Content className={`${!toglePanel ? "noMargin" : 'withMargin'}`}>
					{/* <div className={'mainContainer'}> */}
					{
						update ? <ToastNotification
							timeout={0}
							title="Attention"
							kind={'info'}
							subtitle="A new version of this app is avaliable, refresh the page to view the changes"
							caption=""/> : null
					}


					<Switch>
						<Route exact path='/' component={Home}/>
						<Route path='/error' component={Page500}/>
						<Route exact path='/applicationLogs' component={ApplicationLogs}/>
						<Route exact path='/errorLogs' component={ErrorLogs}/>
						<Route exact path='/failedRequests' component={FailedRequests}/>
						<Route exact path='/debugLogs' component={DebugLogs}/>
						<Route exact path='/projectList'>
							<ProjectList/>
						</Route>
						<Route exact path='/project/:uri'>
							<ProjectProperties openQR={(value) => setQRModal({open: true, value})}
																 openDialog={edit => setTogleDialog({open: true, edit: edit})}/>
						</Route>
						<Route exact path='/project/:uri/scenario/:scenarioName'>
							<EditScenario openDialog={edit => setScenarioDialog({open: true, edit})}/>
						</Route>
						<Route exact path='/forecastRun'>
							<ForecastRun/>
						</Route>
						<Route component={Page404}/>
					</Switch>

					{/* </div> */}
				</Content>
				{/* </div> */}


				<LoginModal/>
				<PWAPrompt/>
				<NewProject open={togleDialog.open} close={() => setTogleDialog(false)} edit={togleDialog.edit}/>
				<NewScenario open={scenarioDialog.open} close={() => setScenarioDialog({open: false, edit: null})}
										 edit={scenarioDialog.edit}/>
				<QRModal open={qrModal.open} value={qrModal.value} close={() => setQRModal({open: false, value: ''})}/>
				<CustomAlert/>
			</div>
		</div>
	);
}

export default App;
