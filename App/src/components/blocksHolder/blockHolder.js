import React from 'react'
import {Block} from '../block/block'
import './blockHolder.scss'

export const BlocksHolder = () => {

	return (
		<div>
			<div>
				<div><span className={'bh-title'}>Results</span></div>
				<div className={'bh-info-container'}>
					<span className={'bh-info'}>Scenario last executed May 2 2020 at 12:34</span></div>
			</div>
			<div className={'blocks spt3'}>
				<Block
					title={'First Peak'}
					number={4}
					description={'days away'}
					backgroundColor={'#86134F'}
					borderBottomColor={'#86134F'}
					textColor={'white'}
				/>
				<Block
					title={'Hospital Occupancy'}
					number={4}
					description={'days until peak'}
					borderBottomColor={'#235A61'}
				/>
				<Block
					title={'ICU Occupancy'}
					number={5}
					description={'days until peak'}
					borderBottomColor={'#DD5757'}/>
				<Block
					title={'Ventilator Occupancy'}
					number={6}
					description={'days until peak'}
					borderBottomColor={'#2A2383'}/>
			</div>
		</div>
	)
}
