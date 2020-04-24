				/* use proc datasets to apply labels to each column of output data table
					except INPUTS which is documented right after the %EasyRun definition
				 */
					PROC DATASETS LIB=WORK NOPRINT;
						MODIFY MODEL_FINAL;
							LABEL
								ADMIT_DATE = "Date of Admission"
								DATE = "Date of Infection"
								DAY = "Day of Pandemic"
								HOSP = "Newly Hospitalized"
								HOSPITAL_OCCUPANCY = "Hospital Census"
								MARKET_HOSP = "Regional Newly Hospitalized"
								MARKET_HOSPITAL_OCCUPANCY = "Regional Hospital Census"
								ICU = "Newly Hospitalized - ICU"
								ICU_OCCUPANCY = "Hospital Census - ICU"
								MARKET_ICU = "Regional Newly Hospitalized - ICU"
								MARKET_ICU_OCCUPANCY = "Regional Hospital Census - ICU"
								MedSurgOccupancy = "Hospital Medical and Surgical Census (non-ICU)"
								Market_MedSurg_Occupancy = "Regional Medical and Surgical Census (non-ICU)"
								VENT = "Newly Hospitalized - Ventilator"
								VENT_OCCUPANCY = "Hospital Census - Ventilator"
								MARKET_VENT = "Regional Newly Hospitalized - Ventilator"
								MARKET_VENT_OCCUPANCY = "Regional Hospital Census - Ventilator"
								DIAL = "Newly Hospitalized - Dialysis"
								DIAL_OCCUPANCY = "Hospital Census - Dialysis"
								MARKET_DIAL = "Regional Newly Hospitalized - Dialysis"
								MARKET_DIAL_OCCUPANCY = "Regional Hospital Census - Dialysis"
								ECMO = "Newly Hospitalized - ECMO"
								ECMO_OCCUPANCY = "Hospital Census - ECMO"
								MARKET_ECMO = "Regional Newly Hospitalized - ECMO"
								MARKET_ECMO_OCCUPANCY = "Regional Hospital Census - ECMO"
								Deceased_Today = "New Hospital Mortality"
								Fatality = "New Hospital Mortality"
								Total_Deaths = "Cumulative Hospital Mortality"
								Market_Deceased_Today = "New Regional Mortality"
								Market_Fatality = "New Regional Mortality"
								Market_Total_Deaths = "Cumulative Regional Mortality"
								N = "Region Population"
								S_N = "Current Susceptible Population"
								E_N = "Current Exposed Population"
								I_N = "Current Infected Population"
								R_N = "Current Recovered Population"
								NEWINFECTED = "Newly Infected Population"
								ModelType = "Model Type Used to Generate Scenario"
								SCALE = "Ratio of Previous Day Population to Current Day Population"
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario ID"
								Scenarioname = "Scenario Name Short"
								LOWER_HOSPITAL_OCCUPANCY="Lower Bound: Hospital Census"
								LOWER_ICU_OCCUPANCY="Lower Bound: Hospital Census - ICU"
								LOWER_VENT_OCCUPANCY="Lower Bound: Hospital Census - Ventilator"
								LOWER_ECMO_OCCUPANCY="Lower Bound: Hospital Census - ECMO"
								LOWER_DIAL_OCCUPANCY="Lower Bound: Hospital Census - Dialysis"
								UPPER_HOSPITAL_OCCUPANCY="Upper Bound: Hospital Census"
								UPPER_ICU_OCCUPANCY="Upper Bound: Hospital Census - ICU"
								UPPER_VENT_OCCUPANCY="Upper Bound: Hospital Census - Ventilator"
								UPPER_ECMO_OCCUPANCY="Upper Bound: Hospital Census - ECMO"
								UPPER_DIAL_OCCUPANCY="Upper Bound: Hospital Census - Dialysis"
								PEAK_HOSPITAL_OCCUPANCY = "Peak Starts: Hospital Census"
								PEAK_ICU_OCCUPANCY = "Peak Starts: Hospital Census - ICU"
								PEAK_VENT_OCCUPANCY = "Peak Starts: Hospital Census - Ventilator"
								PEAK_ECMO_OCCUPANCY = "Peak Starts: Hospital Census - ECMO"
								PEAK_DIAL_OCCUPANCY = "Peak Starts: Hospital Census - Dialysis"
								PEAK_I_N = "Peak Starts: Current Infected Population"
								PEAK_FATALITY = "Peak Starts: New Hospital Mortality"
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