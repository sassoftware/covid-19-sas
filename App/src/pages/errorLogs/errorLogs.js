import React from 'react'
import {connect} from 'react-redux'
import LogHeader from '../../components/logHeader/logHeader'
import { CloseFilled32 } from '@carbon/icons-react'

class ErrorLogs extends React.Component{
	render() {
		const sasErrors = this.props.logs.sasErrors
		return(
			<div>
								<div  className={'close'}>
					<CloseFilled32  onClick={() => this.props.history.replace('/')} />
				{/* <GoBack/> */}
				</div>

				{/* <GoBack/> */}
				<h2 style={{textAlign: 'center'}} > Error Logs</h2>
				<div className="spt5">
					{ sasErrors && sasErrors.length >0
						? sasErrors.map((log, index) =>
							<div className={`log-item ${(index % 2) === 0? 'grayBackground': ''}`} key={index}>
								<LogHeader/>
								<br/>
								<pre>{log.message}</pre>
							</div>):<h4 style={{textAlign: 'center'}} className={'danger'}>Error logs list is empty!</h4>
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

export default connect(mapStateToProps)(ErrorLogs)
