				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					Cumulative_sum_fatality + Fatality;
					CUMULATIVE_SUM_MARKET_HOSP + MARKET_HOSP;
					CUMULATIVE_SUM_MARKET_ICU + MARKET_ICU;
					CUMULATIVE_SUM_MARKET_VENT + MARKET_VENT;
					CUMULATIVE_SUM_MARKET_ECMO + MARKET_ECMO;
					CUMULATIVE_SUM_MARKET_DIAL + MARKET_DIAL;
					cumulative_Sum_Market_Fatality + Market_Fatality;
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_MARKET_DIAL));
					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					Deceased_Today = Fatality;
					Total_Deaths = Cumulative_sum_fatality;
					MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
					MARKET_HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
					MARKET_ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
					MARKET_VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
					MARKET_ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
					MARKET_DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
					Market_Deceased_Today = Market_Fatality;
					Market_Total_Deaths = cumulative_Sum_Market_Fatality;
					Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					DATE = &DAY_ZERO. + DAY;
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
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
						Deceased_Today = "New Hospital Mortality: Fatality=Deceased_Today"
						Fatality = "New Hospital Mortality: Fatality=Deceased_Today"
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
				/* END: Common Post-Processing Across each Model Type and Approach */
