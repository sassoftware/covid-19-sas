import React, {useState} from 'react';
import useDocumentScrollThrottled from './useDocumentScrollThrottled';
import VariwideChart from '../headerCharts/variwideChart/variwideChart'
import HorizontalChart from '../headerCharts/horizontalChart/horizontalChart'
import './stickyHeader.scss';

function StickyHeader() {
	const [shouldHideHeader, setShouldHideHeader] = useState(false);

	const MINIMUM_SCROLL = 300;
	const TIMEOUT_DELAY = 10;

	useDocumentScrollThrottled(callbackData => {
		const {currentScrollTop} = callbackData;
		const isMinimumScrolled = currentScrollTop > MINIMUM_SCROLL;

		setTimeout(() => {
			setShouldHideHeader(isMinimumScrolled);
		}, TIMEOUT_DELAY);
	});

	const isVisible = shouldHideHeader ? 'show' : '';

	return (
		<div className={`stickyHeader ${isVisible}`}>
			<VariwideChart/>
			<HorizontalChart/>
		</div>
	);
}

export default StickyHeader;
