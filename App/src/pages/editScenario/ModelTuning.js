import React, {useEffect, useState} from 'react';
import {useSelector, useDispatch} from 'react-redux';
import {useHistory} from 'react-router-dom'
import {setScenario as _setScenarioToStore} from '../projectProperties/projectActions'
import {
	Row,
	Column,
	NumberInput,
	DatePickerInput,
	DatePicker,
	FormLabel
} from 'carbon-components-react'
import moment from 'moment'
import Slider from 'rc-slider'
import {datePickerInput, datepickerProps} from './common'
import constants from '../../config/constants'


const NumberInputProps = {
	id: 'number-input',
	max: 100,
	min: 0,
	step: 1,
	className: 'numberInput'
}

const slider_marks = {0: '0', 50: '', 100: '100'}


const ModelTuning = (props) => {
	const history = useHistory();
	const dispatch = useDispatch();
	const setScenarioToStore = (conf, index) => _setScenarioToStore(dispatch, Object.assign({}, conf, {oldModel: true}), index)
	const name = history.location.pathname.split('/').reverse()[0];
	const project = useSelector(state => state.project.projectContent);
	const [scenario, setScenario] = useState(project.savedScenarios.find(conf => conf.scenario === name))
	const scenarioIndex = project.savedScenarios.findIndex(conf => conf.scenario === name)

	useEffect(() => {
		setScenario(project.savedScenarios.find(conf => conf.scenario === name))
	}, [name, project])


	const handleDatePickerChange = e => {
		const v = e.target.value
		const n = e.target.name
		if (v && n) {
			const date = new Date(v).getTime()
			setScenarioToStore({...s, DAY_ZERO: new moment(date).format(constants.DATE_FORMAT)}, scenarioIndex)
		}
	}

	const s = {...scenario}
	return (
		<div>
			<Row>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<DatePicker
						{...datepickerProps}
						value={Number(new moment(s.DAY_ZERO, constants.DATE_FORMAT).format('x'))}
						onChange={eventOrDates => {
							const value = eventOrDates.target ? eventOrDates.target.value : eventOrDates[0];
							setScenarioToStore({...s, DAY_ZERO: new moment(value).format(constants.DATE_FORMAT)}, scenarioIndex)
						}}
					>
						<DatePickerInput
							{...datePickerInput}
							name={'firstCovidCase'}
							labelText={'Date of first COVID-19 case'}
							id="date-picker-input-id"
							onChange={handleDatePickerChange}
						/>
					</DatePicker>
				</Column>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Diagnosed Rate adjustment factor'}
						value={s.DiagnosedRate.toFixed(1)}
						onChange={e => setScenarioToStore({...s, DiagnosedRate: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Average ECMO length of stay'}
						value={s.ECMO_LOS}
						onChange={e => setScenarioToStore({...s, ECMO_LOS: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
			</Row>
			<Row>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Numbers of days to project'}
						min={0}
						max={365}
						step={1}
						value={s.N_DAYS}
						onChange={e => setScenarioToStore({...s, N_DAYS: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Initial number of exposed'}
						value={s.E}
						onChange={e => setScenarioToStore({...s, E: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Average ICU length of stay'}
						value={s.ICU_LOS}
						onChange={e => setScenarioToStore({...s, ICU_LOS: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
			</Row>
			<Row className={'spb5'}>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Average Hospital length of stay'}
						value={s.HOSP_LOS}
						onChange={e => setScenarioToStore({...s, HOSP_LOS: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
				<Column sm={8} md={2} lg={4}>
					{/*empty column cell*/}
				</Column>
				<Column sm={8} md={2} lg={4} className={'spb5'}>
					<NumberInput
						{...NumberInputProps}
						label={'Average dialysis length of stay'}
						value={s.DIAL_LOS}
						onChange={e => setScenarioToStore({...s, DIAL_LOS: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</Column>
			</Row>
			<Row className={'spb5'}>
				<Column md={4} lg={8} className={'spb5'}>
					<FormLabel>Rate of latent individuals exposed (%)</FormLabel>
					<div className={'flex justify-content-start align-items-center inputGroup'}>
						<div className={'sliderWrapper spr6'}>
							<Slider
								className={'spr6'}
								marks={slider_marks}
								min={0}
								max={100}
								step={1}
								value={s.SIGMA}
								onChange={v => setScenarioToStore({...s, SIGMA: v}, scenarioIndex)}
							/>
						</div>
						<NumberInput
							{...NumberInputProps}
							label={''}
							value={s.SIGMA.toFixed(1)}
							onChange={e => setScenarioToStore({...s, SIGMA: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</div>
				</Column>
				<Column md={4} lg={8}>
					<FormLabel>Total admission that need ecmo (%)</FormLabel>
					<div className={'flex justify-content-start align-items-center inputGroup'}>
						<div className={'sliderWrapper spr6'}>
							<Slider
								className={'spr6'}
								marks={slider_marks}
								min={0}
								max={100}
								step={1}
								value={s.ECMO_RATE}
								onChange={v => setScenarioToStore({...s, ECMO_RATE: v}, scenarioIndex)}
							/>
						</div>
						<NumberInput
							{...NumberInputProps}
							label={''}
							value={s.ECMO_RATE.toFixed(1)}
							onChange={e => setScenarioToStore({...s, ECMO_RATE: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</div>
				</Column>
			</Row>
			<Row className={'spb5'}>
				<Column md={4} lg={8} className={'spt5'}>
					<FormLabel>Factor (%) used for daily reduction of Beta (%)</FormLabel>
					<div className={'flex justify-content-start align-items-center inputGroup'}>
						<div className={'sliderWrapper spr6'}>
							<Slider
								className={'spr6'}
								marks={slider_marks}
								min={0}
								max={100}
								step={1}
								value={s.BETA_DECAY}
								onChange={v => setScenarioToStore({...s, BETA_DECAY: v}, scenarioIndex)}
							/>
						</div>
						<NumberInput
							{...NumberInputProps}
							label={''}
							value={s.BETA_DECAY.toFixed(1)}
							onChange={e => setScenarioToStore({...s, BETA_DECAY: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</div>
				</Column>
				<Column md={4} lg={8} className={'spt5'}>
					<FormLabel>Total admission that need dialysis (%)</FormLabel>
					<div className={'flex justify-content-start align-items-center inputGroup'}>
						<div className={'sliderWrapper spr6'}>
							<Slider
								className={'spr6'}
								marks={slider_marks}
								min={0}
								max={100}
								step={1}
								value={s.DIAL_RATE}
								onChange={v => setScenarioToStore({...s, DIAL_RATE: v}, scenarioIndex)}
							/>
						</div>
						<NumberInput
							{...NumberInputProps}
							label={''}
							value={s.DIAL_RATE.toFixed(1)}
							onChange={e => setScenarioToStore({...s, DIAL_RATE: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</div>
				</Column>
			</Row>
		</div>
	)
}

export default ModelTuning
