import React from 'react'
import {connect} from 'react-redux'
import LogHeader from '../../components/logHeader/logHeader'
import {CloseFilled32} from '@carbon/icons-react'

class FailedRequests extends React.Component {

	render() {
		const failedRequests = this.props.logs.failedRequests
		return (
			<div>
				<div className={'close'}>
					<CloseFilled32 onClick={() => this.props.history.replace('/')}/>
				</div>

				<h2 style={{textAlign: 'center'}}> Failed Requests</h2>
				<div className="spt5">
					{failedRequests && failedRequests.length > 0
						? failedRequests.map((log, index) =>
							<div className={`log-item ${(index % 2) === 0 ? 'grayBackground' : ''}`} key={index}>
								<LogHeader log={log}/>
								<br/>
								<pre>{log.message}</pre>
							</div>) : <h4 style={{textAlign: 'center'}} className={'danger'}>Failed Requests list is empty!</h4>
					}
				</div>
			</div>
		)
	}
}

function mapStateToProps(state) {
	return {
		logs: state.adapter.logs
	}
}

export default connect(mapStateToProps)(FailedRequests)
