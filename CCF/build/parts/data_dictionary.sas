				/* use proc datasets to apply labels to each column of output data table
					except INPUTS which is documented right after the %EasyRun definition
				 */
					PROC DATASETS LIB=WORK NOPRINT;
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
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								Scenarioname = "Scenario Name"
								LOWER_HOSPITAL_OCCUPANCY="Lower Bound: Current Hospitalized Census"
								LOWER_ICU_OCCUPANCY="Lower Bound: Current Hospital ICU Census"
								LOWER_VENT_OCCUPANCY="Lower Bound: Current Hospital Ventilator Patients"
								LOWER_ECMO_OCCUPANCY="Lower Bound: Current Hospital ECMO Patients"
								LOWER_DIAL_OCCUPANCY="Lower Bound: Current Hospital Dialysis Patients"
								UPPER_HOSPITAL_OCCUPANCY="Upper Bound: Current Hospitalized Census"
								UPPER_ICU_OCCUPANCY="Upper Bound: Current Hospital ICU Census"
								UPPER_VENT_OCCUPANCY="Upper Bound: Current Hospital Ventilator Patients"
								UPPER_ECMO_OCCUPANCY="Upper Bound: Current Hospital ECMO Patients"
								UPPER_DIAL_OCCUPANCY="Upper Bound: Current Hospital Dialysis Patients"
								PEAK_HOSPITAL_OCCUPANCY = "Day Peak Hospital Occupancy First Occurs"
								PEAK_ICU_OCCUPANCY = "Day Peak ICU Occupancy First Occurs"
								PEAK_VENT_OCCUPANCY = "Day Peak Ventilator Patients First Occurs"
								PEAK_ECMO_OCCUPANCY = "Day Peak ECMO Patients First Occurs"
								PEAK_DIAL_OCCUPANCY = "Day Peak Dialysis Patients First Occurs"
								PEAK_I_N = "Day Peak Current Infected Population First Occurs"
								PEAK_FATALITY = "Day Peak New Hospital Mortality First Occurs"
								;
							MODIFY SCENARIOS;
							LABEL
								scope = "Source Macro for variable"
								name = "Name of the macro variable"
								offset = "Offset for long character macro variables (>200 characters)"
								value = "The value of macro variable name"
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								Stage = "INPUT for input variables - MODEL for all variables"
								;
							MODIFY INPUTS;
							LABEL
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								;
P_IMPORT: fit_recall_label.sas
D_IMPORT: fit_recall_label.sas
T_IMPORT: fit_recall_label.sas
U_IMPORT: fit_recall_label.sas

					RUN;
					QUIT;