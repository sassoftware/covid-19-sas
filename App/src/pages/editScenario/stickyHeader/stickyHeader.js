import React, {useState} from 'react';

import useDocumentScrollThrottled from './useDocumentScrollThrottled';
import VariwideChart from '../headerCharts/variwideChart/variwideChart'
import HorizontalChart from '../headerCharts/horizontalChart/horizontalChart'

function StickyHeader() {
	const [shouldHideHeader, setShouldHideHeader] = useState(false);

	const MINIMUM_SCROLL = 120;
	const TIMEOUT_DELAY = 400;

	useDocumentScrollThrottled(callbackData => {
		const {previousScrollTop, currentScrollTop} = callbackData;
		const isScrolledDown = previousScrollTop < currentScrollTop;
		const isMinimumScrolled = currentScrollTop > MINIMUM_SCROLL;

		setTimeout(() => {
			setShouldHideHeader(isScrolledDown && isMinimumScrolled);
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
