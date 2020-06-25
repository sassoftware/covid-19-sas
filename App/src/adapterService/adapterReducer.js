import ActionTypes from './ActionTypes'

import * as adapterLogs from 'h54s/src/logs';

var logs = {
	applicationLogs: [],
	debugData: [],
	sasErrors: [],
	failedRequests: []
  };

const initialState = {
	requests: new Map(),
	logs
}

export function adapterReducer(state = initialState, action) {
	switch (action.type) {
		case ActionTypes.SET_REQUEST: {
			const requests = new Map(state.requests.entries())
			const newLogs = JSON.parse(JSON.stringify(adapterLogs.get.getAllLogs()));
			let newParams = Object.assign({},requests.get(action.payload.promise), action.payload.params )
			if ( newLogs.debugData.length !== state.logs.debugData.length) {
				newParams = {...newParams, logTime: newLogs.debugData[newLogs.debugData.length -1].time}
			
			}
			requests.set(action.payload.promise, newParams)
			const ret =  Object.assign({}, state, {
				requests,
				logs: newLogs
			})
			return ret
		}
		case ActionTypes.REMOVE_REQUEST:
			const requestsToRemove = new Map(state.requests.entries())
			requestsToRemove.delete(action.payload)
			return Object.assign({}, state, {
				requests: requestsToRemove
			})
		case ActionTypes.CLEAR_REQUESTS: {
			return Object.assign({}, state, {
				requests: new Map()
			})
		}	
		default:
			return state
	}
}
