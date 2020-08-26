export default {
	Admission_Rate: 1, 							//"Percentage of Infected patients in the region who will be hospitalized"
	BETA_DECAY: 1, 									//"Factor (%) used for daily reduction of Beta",
	DAY_ZERO: "2020/1/1", 					//"Date of the first COVID-19 case", //string
	DIAL_LOS: 1, 										//"Average DIAL Length of Stay",
	DIAL_RATE: 1, 									//"Default percent of admissions that need Dialysis",
	DiagnosedRate: 1, 							//"Factor to adjust admission_rate contributing to via MarketSharePercent I (see calculation for I)",
	E: 1, 													//"Initial Number of Exposed (infected but not yet infectious)",
	ECMO_LOS: 1, 										//"Average ECMO Length of Stay",
	ECMO_RATE: 1, 									//"Default percent of total admissions that need ECMO",
	FatalityRate: 1, 								//"Percentage of hospitalized patients who will die",
	HOSP_LOS: 1, 										//"Average Hospital Length of Stay",
	ICUPercent: 1, 									//"Percentage of hospitalized patients who will require ICU",
	ICU_LOS: 1, 										//"Average ICU Length of Stay",
	ISOChangeDate: "2020/13/3", 		//"Date of first change from baseline in social distancing parameter", //string
	ISOChangeDateTwo: "2020/29/6",	//"Date of second change in social distancing parameter", //string
	ISOChangeDate3: "2020/24/9", 		//"Date of third change in social distancing parameter", //string
	ISOChangeDate4: "2020/22/11", 		//"Date of fourth change in social distancing parameter", // string
	IncubationPeriod: 1, 						//"Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right",
	InitRecovered: 1, 							//"Initial number of Recovered patients, assumed to have immunity to future infection",
	KnownAdmits: 1, 								//"Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections",
	MarketSharePercent: 1, 					//"Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest",
	N_DAYS: 365, 											//"Number of days to project",
	Population: 1, 									//"Number of people in region of interest, assumed to be well mixed and independent of other populations",
	RecoveryDays: 1, 								//"Number of days a patient is considered infectious (the amount of time it takes to recover or die)",
	SIGMA: 1, 											//"Rate of latent individuals Exposed and transported to the infectious stage during each time period",
	scenario: 1, 										//"Scenario Name to be stored as a character variable, combined with automatically-generated ScenarioIndex to create a unique ID",
	SocialDistancing: 0, 						//"Baseline Social distancing (% reduction in social contact compared to normal activity)",
	SocialDistancingChange: 1, 			//"Second value of social distancing (% reduction in social contact compared to normal activity)",
	SocialDistancingChange3: 3, 		//"Fourth value of social distancing (% reduction in social contact compared to normal activity)",
	SocialDistancingChange4: 4, 		//"Fifth value of social distancing (% reduction in social contact compared to normal activity)",
	SocialDistancingChangeTwo: 2,		//"Third value of social distancing (% reduction in social contact compared to normal activity)",
	VENT_LOS: 1, 										//"Average Vent Length of Stay",
	VentPErcent: 1, 								//"Percentage of hospitalized patients who will require Ventilators",
	doublingtime: 1, 								//"Baseline Infection Doubling Time without social distancing",
	plots: "NO", 										//"YES/NO display plots in output" // string
	created_at: 1590492100022,				//"Timestamp when scenario has been created"
	lastRunModel: {},
	oldModel: false,
}
