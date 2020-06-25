import React from 'react'
import {connect} from 'react-redux'
import LogHeader from '../../components/logHeader/logHeader'
import '../../assets/style/colors.scss';
import { CloseFilled32 } from '@carbon/icons-react'
// import {data} from './dummyData';
import { Accordion, AccordionItem } from 'carbon-components-react';

class DebugLogs extends React.Component {


	shouldLogCollapse = (log) => {

		if (this.props.history.location.state === undefined) return false;

		if (this.props.history.location.state.forCollapse === null) return false;

		return new Date(this.props.history.location.state.forCollapse).getTime() === new Date(log.time).getTime();
	}

	render() {

		const debugData = this.props.logs.debugData
		//const debugData = data
		return (
			<div>
				<div  className={'close'}>
					<CloseFilled32 onClick={() => this.props.history.replace('/')} />
				</div>


				<h2 style={{textAlign: 'center'}}> Debug Logs</h2>
				<div className="spt5">
					{debugData && debugData.length > 0 ?
						<Accordion>
							{debugData.map((log, index) =>{
								const shouldCollapse = this.shouldLogCollapse(log);
								return (
									<div >
										<AccordionItem

											open={shouldCollapse}
											key={index}
											title={(<LogHeader log={log}/>)}>
											<div dangerouslySetInnerHTML={{__html: log.debugHtml}}>

											</div>
										</AccordionItem>
									</div>
								)
							}

							)}
						</Accordion>

						: <h4 style={{textAlign: 'center'}} className={'danger'}> Debug List is empty!</h4>}
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

export default connect(mapStateToProps)(DebugLogs)
