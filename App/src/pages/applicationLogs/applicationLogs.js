import React from 'react'
import {connect} from 'react-redux'
import LogHeader from '../../components/logHeader/logHeader'

import { CloseFilled32 } from '@carbon/icons-react'

class ApplicationLogs extends React.Component {

	render() {
		const applicationLogs = this.props.logs.applicationLogs
		return (
			<div>
				<div  className={'close'}>
					<CloseFilled32  onClick={() => this.props.history.replace('/')} />
				</div>
				<div>


					<h2 style={{textAlign: 'center'}}> Application Logs</h2>
					<div className="spt5">
						{applicationLogs && applicationLogs.length > 0
							? applicationLogs.map((log, index) =>
								<div className={`log-item ${(index % 2) === 0? 'grayBackground': ''}`} key={index}>
									<LogHeader log={log}/>
									<br/>
									<pre>{log.message}</pre>
								</div>) : <h4 style={{textAlign: 'center'}} className={'danger'}>Application logs list is empty!</h4>
						}
					</div>
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

export default connect(mapStateToProps)(ApplicationLogs)
