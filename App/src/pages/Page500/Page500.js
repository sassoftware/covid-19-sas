import React, {Component} from 'react';
import {Col, Card, Row, Button} from 'react-bootstrap';

class Page500 extends Component {
	render() {
		return (
			<div className="app flex-row align-items-center">
				<Card>
					<Row className="justify-content-center">
						<Col md="6">
              <span className="clearfix">
                <h1 className="float-left display-3 mr-4">500</h1>
                <h4 className="pt-3">Houston, we have a problem!</h4>
                <p className="text-muted float-left">The page you are looking for is temporarily unavailable.</p>
              </span>
							<Button className={'mb-4'} color="info" onClick={() => {
								this.props.history.push('/')
							}}>Get back to home</Button>
						</Col>
					</Row>
				</Card>
			</div>
		);
	}
}

export default Page500;
