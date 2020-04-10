	/* THIS CODE HAS MOVED INTO THE POSTPROCESSING.SAS FILE */
	
	/* use proc datasets to apply labels to each column of MODEL_FINAL and SCENARIOS
		optional for efficiency: check to see if this has already be done, if not do it
	*/
		PROC DATASETS LIB=STORE NOPRINT;
			MODIFY MODEL_FINAL;
				LABEL
					ADMIT_DATE = "Date of Admission"
					DATE = "Date of Infection"
					DAY = "Day of Pandemic"
					HOSP = "New Hospitalized Patients"
					HOSPITAL_OCCUPANCY = "Current Hospitalized Census"
					MARKET_HOSP = "New Region Hospitalized Patients"
					MARKET_HOSPITAL_OCCUPANCY = "Current Region Hospitalized Census"
					ICU = "New Hospital ICU Patients"
					ICU_OCCUPANCY = "Current Hospital ICU Census"
					MARKET_ICU = "New Region ICU Patients"
					MARKET_ICU_OCCUPANCY = "Current Region ICU Census"
					MedSurgOccupancy = "Current Hospital Medical and Surgical Census (non-ICU)"
					Market_MedSurg_Occupancy = "Current Region Medical and Surgical Census (non-ICU)"
					VENT = "New Hospital Ventilator Patients"
					VENT_OCCUPANCY = "Current Hospital Ventilator Patients"
					MARKET_VENT = "New Region Ventilator Patients"
					MARKET_VENT_OCCUPANCY = "Current Region Ventilator Patients"
					DIAL = "New Hospital Dialysis Patients"
					DIAL_OCCUPANCY = "Current Hospital Dialysis Patients"
					MARKET_DIAL = "New Region Dialysis Patients"
					MARKET_DIAL_OCCUPANCY = "Current Region Dialysis Patients"
					ECMO = "New Hospital ECMO Patients"
					ECMO_OCCUPANCY = "Current Hospital ECMO Patients"
					MARKET_ECMO = "New Region ECMO Patients"
					MARKET_ECMO_OCCUPANCY = "Current Region ECMO Patients"
					Deceased_Today = "New Hospital Mortality"
					Fatality = "New Hospital Mortality"
					Total_Deaths = "Cumulative Hospital Mortality"
					Market_Deceased_Today = "New Region Mortality"
					Market_Fatality = "New Region Mortality"
					Market_Total_Deaths = "Cumulative Region Mortality"
					N = "Region Population"
					S_N = "Current Susceptible Population"
					E_N = "Current Exposed Population"
					I_N = "Current Infected Population"
					R_N = "Current Recovered Population"
					NEWINFECTED = "New Infected Population"
					ModelType = "Model Type Used to Generate Scenario"
					SCALE = "Ratio of Previous Day Population to Current Day Population"
					ScenarioIndex = "Unique Scenario ID"
					ScenarioNameUnique = "Unique Scenario Name"
					Scenarioname = "Scenario Name"
					;
				MODIFY SCENARIOS;
				LABEL
					scope = "Source Macro for variable"
					name = "Name of the macro variable"
					offset = "Offset for long character macro variables (>200 characters)"
					value = "The value of macro variable name"
					ScenarioIndex = "Unique Scenario ID"
					Stage = "INPUT for input variables - MODEL for all variables"
					;
		RUN;
		QUIT;

		/*PROC CONTENTS DATA=STORE.MODEL_FINAL;*/
		/*RUN;*/
