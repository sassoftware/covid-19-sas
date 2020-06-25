import React, {Component} from 'react';
import {Button, Col, Card, Row} from 'react-bootstrap';
import {withRouter} from 'react-router'

class Page404 extends Component {
	render() {
		return (
			<div className="app flex-row align-items-center">
				<Card>
					<Row className="justify-content-center">
						<Col md="6">
							<div className="clearfix">
								<h1 className="float-left display-3 mr-4">404</h1>
								<h4 className="pt-3">Oops! You're lost.</h4>
								<p className="text-muted float-left">The page you are looking for was not found.</p>
								<Button className={'mb-4'} color="info" onClick={() => {
									this.props.history.push('/')
								}}>Get back on the right path</Button>
							</div>

						</Col>
					</Row>
				</Card>
			</div>
		);
	}
}

export default withRouter(Page404);
