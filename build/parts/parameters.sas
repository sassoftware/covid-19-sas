			/* Translate CCF code macro (%EASYRUN) inputs to variables used in this code 
				these variables come in from the macro call above
				this section show the name mapping to how they are used in this code
			*/
			/*%LET scenario=BASE_Scenario_one;*/
			/*%LET IncubationPeriod=0;*/ /* Used with this name */
			/*%LET InitRecovered=0;*/ /* R */
			/*%LET RecoveryDays=14;*/ /* RECOVERY_DAYS */
			/*%LET doublingtime=5;*/ /* DOUBLING_TIME */
			/*%LET KnownAdmits=10;*/ /* KNOWN_CASES */
			/*%LET KnownCOVID=46;*/ /* KNOWN_INFECTIONS */
			/*%LET Population=4390484;*/ /* S_DEFAULT */
			/*%LET SocialDistancing=0.0;*/ /* RELATIVE_CONTACT_RATE */
			/*%LET MarketSharePercent=0.29;*/ /* MARKET_SHARE */
			/*%LET Admission_Rate=0.075;*/ /* same name below */
			/*%LET ICUPercent=0.25;*/ /* used in ICU_RATE */
			/*%LET VentPErcent=0.125;*/ /* used in VENT_RATE */
			/*%LET FatalityRate=;*/ /* Fatality_rate */


			/* Dynamic Variables across Scenario Runs */
			/*Number of people in region of interest, assumed to be well mixed and independent of other populations*/
			%LET S_DEFAULT = &Population.;
			/*Number of known COVID-19 patients in the region at Day 0, not used in S(E)IR calculations*/
			%LET KNOWN_INFECTIONS = &KnownCOVID.;
			/*Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections*/
			%LET KNOWN_CASES = &KnownAdmits.;
			/*Doubling time before social distancing (days)*/
			%LET DOUBLING_TIME = &doublingtime.;
			/*Initial Number of Exposed (infected but not yet infectious)*/
			%LET E = 0;
			/*Initial number of Recovered patients, assumed to have immunity to future infection*/
			%LET R = &InitRecovered.;
			/*Number of days a patient is considered infectious (the amount of time it takes to recover or die)*/
			%LET RECOVERY_DAYS = &RecoveryDays.;
			/*Baseline Social distancing (% reduction in social contact)*/
			%LET RELATIVE_CONTACT_RATE = &SocialDistancing.;
			/*Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest*/
			%LET MARKET_SHARE = &MarketSharePercent.;
			/*Percentage of Infected patients in the region who will be hospitalized*/
			%LET ADMISSION_RATE= &Admission_Rate.;
			/*factor to adjust %admission to make sense multiplied by Total I*/
			%LET DIAGNOSED_RATE=1.0; 
			/*Percentage of hospitalized patients who will require ICU*/
			%LET ICU_RATE = %SYSEVALF(&ICUPercent.*&DIAGNOSED_RATE);
			/*Percentage of hospitalized patients who will require Ventilators*/
			%LET VENT_RATE = %SYSEVALF(&VentPErcent.*&DIAGNOSED_RATE);
			/*Percentage of hospitalized patients who will die*/
			%Let Fatality_rate = &fatalityrate;
			/*Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right*/
			%LET DAYS_TO_HOSP = &IncubationPeriod.;
			/*Date of first change from baseline in social distancing parameter*/
			%Let ISO_Change_Date = &ISOChangeDate.;
			/*Second value of social distancing (% reduction in social contact compared to normal activity)*/
			%LET RELATIVE_CONTACT_RATE_Change = &SocialDistancingChange.;
			/*Date of second change in social distancing parameter*/
			%Let ISO_Change_Date_Two = &ISOChangeDateTwo.;
			/*Third value of social distancing (% reduction in social contact compared to normal activity)*/
			%LET RELATIVE_CONTACT_RATE_Change_Two = &SocialDistancingChangeTwo.;


			/*Parameters assumed to be constant across scenarios*/
			/*Currently Hospitalized COVID-19 Patients*/
			%LET CURRENT_HOSP = &KNOWN_CASES;
			/*Hospitalization %(total infections)*/
			%LET HOSP_RATE = %SYSEVALF(&ADMISSION_RATE*&DIAGNOSED_RATE);
			/*Average Hospital Length of Stay*/
			%LET HOSP_LOS = 7;
			/*Average ICU Length of Stay*/
			%LET ICU_LOS = 9;
			/*Average Vent Length of Stay*/
			%LET VENT_LOS = 10;
			/*default percent of total admissions that need ECMO*/
			%LET ECMO_RATE=0.03; 
			%LET ECMO_LOS=6;
			/*default percent of admissions that need Dialysis*/
			%LET DIAL_RATE=0.05;
			%LET DIAL_LOS=11;
			/*rate of latent individuals Exposed transported to the infectious stage each time period*/
			%LET SIGMA = 0.90;
			/*Days to project*/
			%LET N_DAYS = 365;
			/*Factor (%) used for daily reduction of Beta*/
			%LET BETA_DECAY = 0.00;
			/*Date of first COVID-19 Case*/
			%LET DAY_ZERO = 13MAR2020;


			/*Parameters derived from other inputs*/
			/*Regional Population*/
			%LET S = &S_DEFAULT;
			/*Currently Known Regional Infections (only used to compute detection rate - does not change projections*/
			%LET INITIAL_INFECTIONS = &KNOWN_INFECTIONS;
			/*Extrapolated number of Infections in the Region at Day 0*/
			%LET TOTAL_INFECTIONS = %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE);
			%LET DETECTION_PROB = %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS);
			/*Number of Infections in the Region at Day 0 - Equal to TOTAL_INFECTIONS*/
			%LET I = %SYSEVALF(&INITIAL_INFECTIONS / &DETECTION_PROB);
			%LET INTRINSIC_GROWTH_RATE = %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1);
			%LET GAMMA = %SYSEVALF(1/&RECOVERY_DAYS);
			%LET BETA = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE));
			%LET BETA_Change = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change));
			%LET BETA_Change_Two = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_Two));
			/*R_T is R_0 after distancing*/
			%LET R_T = %SYSEVALF(&BETA / &GAMMA * &S);
			%LET R_T_Change = %SYSEVALF(&BETA_Change / &GAMMA * &S);
			%LET R_T_Change_Two = %SYSEVALF(&BETA_Change_Two / &GAMMA * &S);
			%LET R_NAUGHT = %SYSEVALF(&R_T / (1-&RELATIVE_CONTACT_RATE));
			/*doubling time after distancing*/
			%LET DOUBLING_TIME_T = %SYSEVALF(1/%SYSFUNC(LOG2(&BETA*&S - &GAMMA + 1)));
