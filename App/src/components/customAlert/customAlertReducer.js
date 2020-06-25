import ActionTypes from './ActionTypes';

const initialState = {
  open: false,
  action: null,
  params: null,
  message: ''
}

export function customAlertReducer (state = initialState, action) {
  switch (action.type) {

  case ActionTypes.OPEN_CONFIRMATION: {
    return Object.assign({},state,{...action.payload})
  }

  case ActionTypes.CLOSE_CONFIRMATION: {
    return Object.assign({}, initialState)
  }

  default:
    return state
  }
}
