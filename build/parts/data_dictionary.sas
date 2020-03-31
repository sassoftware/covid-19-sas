    /* use proc datasets to apply labels to each column of MODEL_FINAL and SCENARIOS
        optional for efficiency: check to see if this has already be done, if not do it
    */
PROC DATASETS LIB=STORE;
	MODIFY MODEL_FINAL;
		LABEL
			ADMIT_DATE = "Date of Admission"
			DATE = "Date of Infection"
			DAY = "Day of Pandemic"
			DIAL = "New Dialysis Patients"
			DIAL_OCCUPANCY = "Current Dialysis Patients"
			Deceased_Today = "New Deceased Patients"
			ECMO = "New ECMO Patients"
			ECMO_OCCUPANCY = "Current ECMO Patients"
			E_N = "Exposed Population"
			Fatality = "New Deceased Patients"
			HOSP = "New Hospitalized Patients"
			HOSPITAL_OCCUPANCY = "Current Hospitalized Patients"
			ICU = "New ICU Patients"
			ICU_OCCUPANCY = "Current ICU Patients"
			I_N = "Infected Population"
			MARKET_DIAL = "Region New Dialysis Patients"
			MARKET_DIAL_OCCUPANCY = "Region Current Dialysis Patients"
			MARKET_ECMO = "Region New ECMO Patients"
			MARKET_ECMO_OCCUPANCY = "Region Current ECMO Patients"
			MARKET_HOSP = "Region New Hospitalized Patients"
			MARKET_HOSPITAL_OCCUPANCY = "Region Current Hospitalized Patients"
			MARKET_ICU = "Region New ICU Patients"
			MARKET_ICU_OCCUPANCY = "Region Current ICU Patients"
			MARKET_VENT = "Region New Ventilator Patients"
			MARKET_VENT_OCCUPANCY = "Region Current Ventilator Patients"
			Market_Deceased_Today = "Region New Deceased Patients"
			Market_Fatality = "Region New Deceased Patients"
			Market_MEdSurg_Occupancy = "Region Medical and Surgical Occupancy (non-ICU)"
			Market_Total_Deaths = "Region Cumulative Deaths"
			MedSurgOccupancy = "Current Medical and Surgical Occupancy (non-ICU)"
			ModelType = "Model Type Used to Generate Scenario"
			N = "Region Population"
			NEWINFECTED = "New Infected Population"
			R_N = "Recovered Population"
			SCALE = "Ratio of Previous "
			S_N = "Susceptible Population"
			ScenarioIndex = "Unique Scenario ID"
			ScenarionNameUnique = "Unique Scenario Name"
			Scenarioname = "Scenario Name"
			Total_Deaths = "Cumulative Deaths"
			VENT = "New Ventilator Patients"
			VENT_OCCUPANCY = "Current Ventilator Patients";
RUN;
QUIT;

PROC CONTENTS DATA=STORE.MODEL_FINAL;
RUN;
