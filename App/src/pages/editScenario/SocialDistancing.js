import React, {useEffect, useState} from 'react';
import {useSelector, useDispatch} from 'react-redux';
import {Row, Column, NumberInput, DatePickerInput, DatePicker} from 'carbon-components-react'
import moment from 'moment'
import InputChart from './inputChart/InputChart'
import {useHistory} from 'react-router-dom'
import {setScenario as _setScenarioToStore} from '../projectProperties/projectActions'
import constants from '../../config/constants'
import {datePickerInput, datepickerProps} from './common'

const numInputProps = {
	className: 'percentageInput',
	label: 'Distancing (%)',
	name: 'second',
	min: 0,
	max: 100,
	step: 1,
	invalidText: 'from 0 to 100'
}

const SocialDistancing = (props) => {
	const history = useHistory();
	const dispatch = useDispatch();
	const setScenarioToStore = (conf, index) => _setScenarioToStore(dispatch, Object.assign({}, conf, {oldModel: true}), index)
	const name = history.location.pathname.split('/').reverse()[0];
	const project = useSelector(state => state.project.projectContent);
	const [scenario, setScenario] = useState(project.savedScenarios.find(conf => conf.scenario === name))
	const scenarioIndex = project.savedScenarios.findIndex(conf => conf.scenario === name)

	const [first, setFirst] = useState({date: '', distance: scenario.SocialDistancingChange})
	const [second, setSecond] = useState({date: '', distance: scenario.SocialDistancingChangeTwo})
	const [third, setThird] = useState({date: '', distance: scenario.SocialDistancingChange3})
	const [fourth, setFourth] = useState({date: '', distance: scenario.SocialDistancingChange4})

	useEffect(() => {
		setScenario(project.savedScenarios.find(conf => conf.scenario === name))
	}, [name, project])

	// useEffect(() => {
	// 	console.log('social distancing')
	// 	setScenarioToStore(dispatch, scenario, scenarioIndex)
	// }, [scenario])

	const handleDatePickerChange = e => {
		const v = e.target.value
		const n = e.target.name
		if (v && n) {
			const date = v
			switch (n) {
				case 'first':
					setFirst({...first, date})
					break;
				case 'second':
					setSecond({...second, date})
					break;
				case 'third':
					setThird({...third, date})
					break;
				case 'fourth':
					setFourth({...fourth, date})
					break;
				default:
					break;
			}
		}
	}

	const s = scenario // make it shorter for usage in code below
	return (
		<Row>
			<Column lg={6} md={3} sm={16} className={'spb5 pr0'}>
				<div className={'flex flex-content-start spt5'}>
					<DatePicker
						{...datepickerProps}
						value={Number(new moment(s.DAY_ZERO, constants.DATE_FORMAT).format('x'))}
						onChange={eventOrDates => {
							const value = eventOrDates.target ? eventOrDates.target.value : eventOrDates[0];
							setScenarioToStore({
								...s,
								DAY_ZERO: new moment(value).format(constants.DATE_FORMAT)
							}, scenarioIndex)
						}}
					>
						<DatePickerInput
							{...datePickerInput}
							name={'base'}
							labelText={'Date of first case'}
							id="date-picker-input-id"
							onChange={handleDatePickerChange}
						/>
					</DatePicker>
					<NumberInput
						{...numInputProps}
						label={'Base distancing'}
						id={'number-input'}
						value={s.SocialDistancing >= 0 ? s.SocialDistancing : ''}
						onChange={e => setScenarioToStore({
							...s,
							SocialDistancing: e.imaginaryTarget.valueAsNumber
						}, scenarioIndex)}
					/>
				</div>
				<div className={'flex flex-content-start spt5'}>
					<DatePicker
						{...datepickerProps}
						value={Number(new moment(s.ISOChangeDate, constants.DATE_FORMAT).format('x'))}
						onChange={eventOrDates => {
							const value = eventOrDates.target ? eventOrDates.target.value : eventOrDates[0];
							setScenarioToStore({
								...s,
								ISOChangeDate: new moment(value).format(constants.DATE_FORMAT)
							}, scenarioIndex)
						}}
					>
						<DatePickerInput
							{...datePickerInput}
							name={'first'}
							labelText={'First change'}
							id="date-picker-input-id-1"
							onChange={handleDatePickerChange}
						/>
					</DatePicker>
					<NumberInput
						{...numInputProps}
						id={'number-input-1'}
						value={s.SocialDistancingChange >= 0 ? s.SocialDistancingChange : ''}
						onChange={e => setScenarioToStore({
							...s,
							SocialDistancingChange: e.imaginaryTarget.valueAsNumber
						}, scenarioIndex)}
					/>
				</div>

				<div className={'flex flex-content-start spt5'}>
					<DatePicker
						name={'secondChange'}
						{...datepickerProps}
						value={Number(new moment(s.ISOChangeDateTwo, constants.DATE_FORMAT).format('x'))}
						onChange={eventOrDates => {
							const value = eventOrDates.target ? eventOrDates.target.value : eventOrDates[0];
							setScenarioToStore({
								...s,
								ISOChangeDateTwo: new moment(value).format(constants.DATE_FORMAT)
							}, scenarioIndex)
						}}
					>
						<DatePickerInput
							{...datePickerInput}
							labelText={'Second change'}
							id="date-picker-input-id-2"
							name={'second'}
							onChange={handleDatePickerChange}
						/>
					</DatePicker>
					<NumberInput
						{...numInputProps}
						id={'number-input-2'}
						value={s.SocialDistancingChangeTwo >= 0 ? s.SocialDistancingChangeTwo : ''}
						onChange={e => setScenarioToStore({
							...s,
							SocialDistancingChangeTwo: e.imaginaryTarget.valueAsNumber
						}, scenarioIndex)}
					/>
				</div>

				<div className={'flex flex-content-start spt5'}>
					<DatePicker
						{...datepickerProps}
						value={Number(new moment(s.ISOChangeDate3, constants.DATE_FORMAT).format('x'))}
						onChange={eventOrDates => {
							const value = eventOrDates.target ? eventOrDates.target.value : eventOrDates[0];
							setScenarioToStore({
								...s,
								ISOChangeDate3: new moment(value).format(constants.DATE_FORMAT)
							}, scenarioIndex)
						}}
					>
						<DatePickerInput
							{...datePickerInput}
							labelText={'Third change'}
							id="date-picker-input-id-3"
							name={'third'}
							onChange={handleDatePickerChange}
						/>
					</DatePicker>
					<NumberInput
						{...numInputProps}
						id={'number-input-3'}
						value={s.SocialDistancingChange3 >= 0 ? s.SocialDistancingChange3 : ''}
						// onChange={e => setSecond({...fourth, distance: e.imaginaryTarget.valueAsNumber})}
						onChange={e => setScenarioToStore({
							...s,
							SocialDistancingChange3: e.imaginaryTarget.valueAsNumber
						}, scenarioIndex)}
					/>
				</div>

				<div className={'flex flex-content-start spt5'}>
					<DatePicker
						{...datepickerProps}
						value={Number(new moment(s.ISOChangeDate4, constants.DATE_FORMAT).format('x'))}
						onChange={eventOrDates => {
							const value = eventOrDates.target ? eventOrDates.target.value : eventOrDates[0];
							setScenarioToStore({
								...s,
								ISOChangeDate4: new moment(value).format(constants.DATE_FORMAT)
							}, scenarioIndex)
						}}
					>
						<DatePickerInput
							{...datePickerInput}
							labelText={'Fourth change'}
							id="date-picker-input-id-4"
							name={'fourth'}
							onChange={handleDatePickerChange}
						/>
					</DatePicker>
					<NumberInput
						{...numInputProps}
						id={'number-input-4'}
						value={s.SocialDistancingChange4 >= 0 ? s.SocialDistancingChange4 : ''}
						// onChange={e => setSecond({...fourth, distance: e.imaginaryTarget.valueAsNumber})}
						onChange={e => setScenarioToStore({
							...s,
							SocialDistancingChange4: e.imaginaryTarget.valueAsNumber
						}, scenarioIndex)}
					/>
				</div>
			</Column>
			<Column lg={10} md={5} sm={16}>
				<InputChart/>
			</Column>
		</Row>
	)
}

export default SocialDistancing
