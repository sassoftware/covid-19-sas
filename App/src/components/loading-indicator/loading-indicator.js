import React from 'react'
import {connect} from "react-redux";
import './loading-indicator.scss'

class LoadingIndicator extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      requests: [],
      loading: false,
      callsListToogle: false
    }
    this.toogleDropDown = this.toogleDropDown.bind(this)
  }

  componentDidMount() {
    this.getRequestsList(this.props)
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
   if (this.props.requests !== nextProps.requests) {
    this.getRequestsList(nextProps)
   }
  }

  getRequestsList (props) {
    const requests = Array.from(props.requests.values()).reverse()

    let loading = false;
    for (let file of requests) {
      if (file.running) {
        loading = true;
        break;
      }
    }

    this.loading = loading;
    this.setState({
      loading,
      requests
    })
  }

  toogleDropDown() {
    this.setState({
      callsListToogle: !this.state.callsListToogle
    })
  }

  indicatorColor = () => {
    if (this.state.loading) return 'orange';
    if (!this.state.loading && this.state.requests.length > 0 &&  !this.state.requests[0].successful) return 'red'
    if (!this.state.loading && this.state.requests.length > 0 &&  this.state.requests[0].successful)  return 'green'
  }


  render() {
    return (
      <div className={'loadingIndicator'}>
        <div className={'pulseLoader'} onClick={this.toogleDropDown} title={'Toggle notification bar'}>

        <svg className={'dot'} height="10" width="10">
          <circle cx="5" cy="5" r="4" stroke="black" strokeWidth="1" 
              fill={this.indicatorColor()}/>
        </svg>
        
        </div>
      </div>
    )
  }
}

function mapStateToProps(store) {
  return {
    requests: store.adapter.requests
  }
}

export default (connect(mapStateToProps)(LoadingIndicator))

