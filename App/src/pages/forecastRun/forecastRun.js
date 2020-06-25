import React, { useState } from 'react'
import { Tabs, Tab, Checkbox, Select, TextInput } from 'carbon-components-react'
import "./forecastRun.scss";

const initialDistributions = [
    {
        label: "Burr",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Exponential",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Gamma",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Generalized Pareto",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Inverse Gaussian",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Lognormaln",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Pareto",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Scaled Tweedie",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Tweedie",
        value: null,
        checked: false,
        category: ''
    },
    {
        label: "Weibull",
        value: null,
        checked: false,
        category: ''
    }
]

const TabContent = (props) => {

    return ( <div className={'flex flex-row justify-content-start  flex-wrap'}>

            <div className={'sp7'}>
                <p className={'spb3'}>Effects</p>
                <div className={'darkBackground'}>
                    <Checkbox labelText="afjl;kfslk;d" />
                    <Checkbox></Checkbox>
                    <Checkbox></Checkbox>
                    <Checkbox></Checkbox>
                </div>
            </div>
            <div className={'sp7 lyl4'}>
                <div className={'flex flex-row spb3'}>
                    <Checkbox indeterminate={props.checkAll.indeterminate} checked={props.checkAll.checked}
                        onChange={e => props.handleCheckAll(!props.checkAll.indeterminate && e, props.distributions)}  id={`checkAll: ${props.category}`} />
                    <p> Candidate Distribution</p>
                </div>

                <div className={'darkBackground'}>
                    {
                        props.distributions.map(dis =>
                            <Checkbox checked={dis.checked} labelText={dis.label} id={`${dis.label} ${dis.category}`}
                                        onChange={e => props.distributionSingleCheck(dis.label, e, props.distributions)}/>)
                    }
                </div>
            </div>
            <div className={'flex flex-column justify-content-between sp7 darkBackground lyl4' }>
                <Select labelText="Distribution selection criterion" ></Select>
                <Select labelText="Selection criterion"></Select>
                <Select labelText="Selection criterion"></Select>

            </div>
        </div>
    )
}

const ForecastRun = () => {

    const [severityDistributions, setSeverityDistributions] = useState(initialDistributions.map( dis => {return {...dis, category: 'severity'}}));
    const [severityDisCheck, setSeverityDisCheck] = useState({
        indeterminate: false,
        checked: false
    });

    const [countDistribution, setCountDistributions] = useState(initialDistributions.map( dis => {return {...dis, category: 'count'}}));
    const [countDisCheck, setCountDisCheck] = useState( {
        indeterminate: false,
        checked: false
    })

    const handleSingleCheck = (id, value, array) => {

        return {
            newArray: array.map(dis => {
                if (dis.label === id){
                    dis.checked = value
                }
                return dis;
            }),

            checkAll: {
                indeterminate: (array.find(dis => dis.checked) !== undefined && array.find(dis => !dis.checked) !== undefined)? true : false,
                checked: array.find(dis => !dis.checked) === undefined
            }
        }
        // setArray()

        // (array.find(dis => dis.checked) !== undefined)? setCheck({indeterminate: true}) : setCheck({indeterminate: false});
        // if (array.find(dis => !dis.checked) === undefined) setCheck({checked: true}) ;
    }

    const handleCheckAll = (value, array) => {

        return {
            newArray: array.map(dis => {return {...dis, checked: value}}),
            checkAll: { checked: value}
        }

        // setSeverityDisCheck({checked: value})

        // setSeverityDistributions(severityDistributions.map(dis => {return {...dis, checked: value}}))
    }

    return (
        <div className={'forecastRun'}>
            <div className={'lyb4'}>
                <h2>Name placholder</h2>
            </div>

            <div className={'spb5 fit'}>
                <h4 className={'spb5'}>Fit</h4>


                <div style={{ width: '100%'}}>
                    <Tabs type="container">
                        <Tab
                        href="#"
                        id="severity"
                        label="Severity"
                        >
                            <TabContent
                                category="severity"
                                distributions={severityDistributions}
                                checkAll={severityDisCheck}
                                handleCheckAll={(value, array) => {
                                    const {newArray, checkAll} = handleCheckAll(value, array);
                                    setSeverityDistributions(newArray);
                                    setSeverityDisCheck(checkAll);
                                }}
                                distributionSingleCheck={(id, value, array) => {
                                    const {newArray, checkAll} = handleSingleCheck(id, value, array);
                                    console.log(checkAll)
                                    setSeverityDistributions(newArray);
                                    setSeverityDisCheck(checkAll)
                                }}
                                />
                        </Tab>
                        <Tab
                        href="#"
                        id="count"
                        label="Count"
                        >
                            <TabContent
                                category="count"
                                distributions={countDistribution}
                                checkAll={countDisCheck}
                                handleCheckAll={(value, array) => {
                                    const {newArray, checkAll} = handleCheckAll(value, array);
                                    setCountDistributions(newArray);
                                    setCountDisCheck(checkAll);
                                }}
                                distributionSingleCheck={(id, value, array) => {
                                    const {newArray, checkAll} = handleSingleCheck(id, value, array);
                                    setCountDistributions(newArray);
                                    setCountDisCheck(checkAll);
                                }}/>
                        </Tab>
                        <Tab
                        href="#"
                        id="copula"
                        label='Copula'
                        >
                            <div className={'flex flex-row'}>

                                <div className={'sp7'}>
                                    <p className={'spb3'}>Candidate models</p>
                                    <Checkbox />
                                    <Checkbox />
                                    <Checkbox />
                                </div>

                                <div className={'sp7'}>
                                    <Select className={'spb3'} labelText="Model selection criteria"></Select>
                                    <TextInput className={'spb3'} type="number" labelText="Joint probability draws"/>
                                    <TextInput className={'spb3'} type="number" labelText="Seed"/>
                                </div>

                            </div>
                        </Tab>
                    </Tabs>
                    </div>
            </div>
        </div>
    )
}

export default ForecastRun
