import React, {useEffect, useState} from 'react';
import {useSelector, useDispatch} from 'react-redux';
import {useHistory} from 'react-router-dom'
import {setScenario as _setScenarioToStore} from '../projectProperties/projectActions'
import {
	Row,
	Column,
	NumberInput,
	FormLabel
} from 'carbon-components-react'
import Slider from 'rc-slider'


const NumberInputProps = {
	id: 'numberInput',
	min: 0,
	step: 1,
	className: 'numberInput'
}


const slider_marks = {0: '0', 50: '', 100: '100'}

// TODO make ui in two columns
const HospitalAndVirus = (props) => {
	const history = useHistory();
	const dispatch = useDispatch();
	const setScenarioToStore = (conf, index) => _setScenarioToStore(dispatch, Object.assign({}, conf, {oldModel: true}), index)
	const name = history.location.pathname.split('/').reverse()[0];
	const project = useSelector(state => state.project.projectContent);
	const [scenario, setScenario] = useState(project.savedScenarios.find(conf => conf.scenario === name))
	const scenarioIndex = project.savedScenarios.findIndex(conf => conf.scenario === name)
	const [s, setS] = useState({...scenario})

	useEffect(() => {
		setScenario(project.savedScenarios.find(conf => conf.scenario === name))
	}, [name, project])

	useEffect(() => {
		setS({...scenario})
	}, [scenario])

	return (
		<Row className={'hnv'}>
			<Column sm={4} md={4} lg={8} className={'spb5'}>
				<Row>
					<Column sm={4} md={4} lg={8} className={'spb5'}>
						<NumberInput
							{...NumberInputProps}
							label={'# of people in region of interest'}
							value={s.Population.toFixed(1)}
							onChange={e => setScenarioToStore({...s, Population: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</Column>

					<Column sm={4} md={4} lg={8} className={'spb5'}>
						<NumberInput
							{...NumberInputProps}
							label={'# of people in hospital on day 0'}
							value={s.KnownAdmits.toFixed(1)}
							onChange={e => setScenarioToStore({...s, KnownAdmits: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</Column>
				</Row>
				<Row>
					<Column sm={4} md={4} lg={8} className={'spb5'}>
						<NumberInput
							{...NumberInputProps}
							label={'Incubation period (days)'}
							value={s.IncubationPeriod.toFixed(1)}
							onChange={e => setScenarioToStore({...s, IncubationPeriod: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</Column>

					<Column sm={4} md={4} lg={8} className={'spb5'}>
						<NumberInput
							{...NumberInputProps}
							label={'Doubling time'}
							value={s.doublingtime.toFixed(1)}
							onChange={e => setScenarioToStore({...s, doublingtime: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</Column>
				</Row>

				<Row>
					<Column sm={4} md={4} lg={8} className={'spb5'}>
						<NumberInput
							{...NumberInputProps}
							label={'Initial recovered patients'}
							value={s.InitRecovered.toFixed(1)}
							onChange={e => setScenarioToStore({...s, InitRecovered: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</Column>

					<Column sm={4} md={4} lg={8} className={'spb5'}>
						<NumberInput
							{...NumberInputProps}
							label={'Recovery (days)'}
							value={s.RecoveryDays.toFixed(1)}
							onChange={e => setScenarioToStore({...s, RecoveryDays: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
						/>
					</Column>
				</Row>
			</Column>

			<Column sm={4} md={4} lg={8}>
				<FormLabel>Anticipated share in region admitted to hospital of interest</FormLabel>
				<div className={'flex justify-content-start align-items-center inputGroup lyb3'}>
					<div className={'sliderWrapper spr6'}>
						<Slider
							className={'spr6'}
							marks={slider_marks}
							min={0}
							max={100}
							step={1}
							value={s.MarketSharePercent}
							onChange={v => setS(Object.assign({},s , {MarketSharePercent:v}))}
							onAfterChange={v => setScenarioToStore({...s, MarketSharePercent: v}, scenarioIndex)}
						/>
					</div>
					<NumberInput
						{...NumberInputProps}
						label={''}
						value={s.MarketSharePercent}
						onChange={e => setScenarioToStore({...s, MarketSharePercent: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</div>

				<FormLabel>Percentage of Infected in region who will be hospitalized</FormLabel>
				<div className={'flex justify-content-between align-items-center inputGroup lyb3'}>
					<div className={'sliderWrapper spr6'}>
						<Slider
							className={'spr6'}
							marks={slider_marks}
							min={0}
							max={100}
							step={1}
							value={s.Admission_Rate}
							onChange={v => setS(Object.assign({},s , {Admission_Rate:v}))}
							onAfterChange={v => setScenarioToStore({...s, Admission_Rate: v}, scenarioIndex)}
						/>
					</div>
					<NumberInput
						{...NumberInputProps}
						label={''}
						value={s.Admission_Rate}
						onChange={e => setScenarioToStore({...s, Admission_Rate: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</div>

				<FormLabel>Percentage of hospitalized patients who will require ICU</FormLabel>
				<div className={'flex justify-content-between align-items-center inputGroup lyb3'}>
					<div className={'sliderWrapper spr6'}>
						<Slider
							className={'spr6'}
							marks={slider_marks}
							min={0}
							max={100}
							step={1}
							value={s.ICUPercent}
							onChange={v => setS(Object.assign({},s , {ICUPercent:v}))}
							onAfterChange={v => setScenarioToStore({...s, ICUPercent: v}, scenarioIndex)}
						/>
					</div>
					<NumberInput
						{...NumberInputProps}
						label={''}
						value={s.ICUPercent}
						onChange={e => setScenarioToStore({...s, ICUPercent: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</div>
				<FormLabel>Percentage of hospitalized patients who will require Ventilators</FormLabel>
				<div className={'flex justify-content-between align-items-center inputGroup lyb3'}>
					<div className={'sliderWrapper spr6'}>
						<Slider
							className={'spr6'}
							marks={slider_marks}
							min={0}
							max={100}
							step={1}
							value={s.VentPErcent}
							onChange={v => setS(Object.assign({},s , {VentPErcent:v}))}
							onAfterChange={v => setScenarioToStore({...s, VentPErcent: v}, scenarioIndex)}
						/>
					</div>
					<NumberInput
						{...NumberInputProps}
						label={''}
						value={s.VentPErcent}
						onChange={e => setScenarioToStore({...s, VentPErcent: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</div>
				<FormLabel>Percentage of hospitalized patients who will die</FormLabel>
				<div className={'flex justify-content-between align-items-center inputGroup lyb1'}>
					<div className={'sliderWrapper spr6'}>
						<Slider
							className={'spr6'}
							marks={slider_marks}
							min={0}
							max={100}
							step={1}
							value={s.FatalityRate}
							onChange={v => setS(Object.assign({},s , {FatalityRate:v}))}
							onAfterChange={v => setScenarioToStore({...s, FatalityRate: v}, scenarioIndex)}
						/>
					</div>
					<NumberInput
						{...NumberInputProps}
						label={''}
						value={s.FatalityRate}
						onChange={e => setScenarioToStore({...s, FatalityRate: e.imaginaryTarget.valueAsNumber}, scenarioIndex)}
					/>
				</div>
			</Column>
		</Row>
	)
}

export default HospitalAndVirus
