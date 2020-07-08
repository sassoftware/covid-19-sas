import {createStore, combineReducers, applyMiddleware} from 'redux';
import thunk from 'redux-thunk';
import {createLogger} from 'redux-logger';
import homeReducer from './pages/home/homeReducer'
import loginReducer from './components/loginModal/loginReducer'
import {adapterReducer} from './adapterService/adapterReducer' // eslint-disable-line no-unused-vars
import headerReducer from "./components/header/headerReducer" // eslint-disable-line no-unused-vars
import projectListReducer from './pages/projectList/projectListReducer';
import newProjectReducer from './components/newProject/newProjectReducer';
import { customAlertReducer } from './components/customAlert/customAlertReducer';
import { projectReducer } from './pages/projectProperties/projectReducer';
import {runModelReducer} from './pages/editScenario/outputChart/runModelReducer'

let middlewares = []

middlewares.push(thunk)

const showLogs = true

// if (process.env.NODE_ENV !== 'production') {
// 	if (showLogs) {
// 		middlewares.push(createLogger({
// 		  collapsed: true,
// 		  predicate: (getState, action) => action.type !== 'UPDATE_BBOX'
// 		}));
// 	}
// }
if (showLogs) {
	middlewares.push(createLogger({
		collapsed: true,
		predicate: (getState, action) => action.type !== 'UPDATE_BBOX'
	}));
}


const reducer = combineReducers({
	home: homeReducer,
	login: loginReducer,
	adapter: adapterReducer,
	header: headerReducer,
	projectList: projectListReducer,
	newProject: newProjectReducer,
	customAlert: customAlertReducer,
	project: projectReducer,
	runModel:runModelReducer
})

export function getStore(preloadedState) {
	return createStore(reducer, preloadedState,
		applyMiddleware(...middlewares)
	);
}
