/* directory path for files: COVID_19.sas (this file), libname store */
%let homedir = C:\COVID19\;

/* the storage location for the MODEL_FINAL table and the SCENARIOS table */
libname store "&homedir.";

/*Example Scenario Parameters*/
%LET scenario=Scenario_DrS_00_40_run_12;
%LET IncubationPeriod=0;
%LET InitRecovered=0;
%LET RecoveryDays=14;
%LET doublingtime=5;
%LET KnownAdmits=10;
%LET KnownCOVID=46;
%LET Population=4390484;
%LET SocialDistancing=0;
%LET MarketSharePercent=0.29;
%LET Admission_Rate=0.075;
%LET ICUPercent=0.45;
%LET VentPErcent=0.35;
%LET ISOChangeDate='31MAY2020'd;
%LET SocialDistancingChange=0.25;
%LET ISOChangeDateTwo='06AUG2020'd;
%LET SocialDistancingChangeTwo=0.5;
%LET FatalityRate=;
%LET plots=YES;
			
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

FILENAME OHIO "&homedir.COVIDSummaryData.csv";

/*DOWNLOAD CSV*/
PROC HTTP 
	URL="https://coronavirus.ohio.gov/static/COVIDSummaryData.csv"
	METHOD= "GET" 
	OUT=OHIO;
RUN;

PROC IMPORT OUT= WORK.OHIO_RAW 
            DATAFILE= "&homedir.COVIDSummaryData.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 GUESSINGROWS=2000; 
RUN;

PROC SQL;
	CREATE TABLE OHIO_SUMMARY AS 
	SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
	FROM OHIO_RAW
	WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
		'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
		'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
	GROUP BY CALCULATED DATE
	ORDER BY CALCULATED DATE;
QUIT;

PROC SQL NOPRINT;
	SELECT MIN(DATE) INTO :FIRST_CASE FROM OHIO_SUMMARY;
	SELECT MAX(DATE) INTO :LATEST_CASE FROM OHIO_SUMMARY;
QUIT;

DATA ALLDATES;
	FORMAT DATE DATE9.;
	DO DATE = &FIRST_CASE TO &LATEST_CASE;
		TIME = DATE - &FIRST_CASE + 1;
		OUTPUT;
	END;
RUN;

DATA STORE.OHIO_SUMMARY;
	MERGE ALLDATES OHIO_SUMMARY;
	BY DATE;
	CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
RUN;

proc model data =STORE.OHIO_SUMMARY outmodel=seirmod;
	/* Parameters of interest */
	parms R0 &R_T i0 &I;
	bounds 1 <= R0 <= 13;

	/* Fixed values */
	N = &S;
	inf = &RECOVERY_DAYS;
	sigma=&sigma;

	/* Differential equations */
	gamma = 1/inf;
	beta = R0*gamma/N;

	/* Differential equations */
	/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
	DERT.S_N = -BETA*S_N*I_N;
	/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
	DERT.E_N = BETA*S_N*I_N-SIGMA*E_N;
	/* c. inflow from b. - outflow through recovery or death during illness*/
	DERT.I_N = SIGMA*E_N-GAMMA*I_N;
	/* d. Recovered and death humans through "promotion" inflow from c.*/
	DERT.R_N = GAMMA*I_N;
	CUMULATIVE_CASE_COUNT = I_N + R_N;
	/* Fit the data */
	fit CUMULATIVE_CASE_COUNT init=(S_N=&S E_N=0 I_N=i0 R_N=0) / time=date dynamic outpredict outactual out=epipred/*(rename=v=i)*/ 
                                     /*optimizer=ormp(opttol=1e-5)*/ ltebound=1e-10;
	outvars S_N E_N I_N R_N;
quit;

data epipred;
   set epipred;
   label CUMULATIVE_CASE_COUNT='Cumulative Incidence';
run;

/*Plot results*/
proc sgplot data=epipred;
    where _type_  ne 'RESIDUAL';
    series x=date y=CUMULATIVE_CASE_COUNT / lineattrs=(thickness=2) group=_type_  markers name="cases";
    format CUMULATIVE_CASE_COUNT comma10.;
run;

/*DATA FOR PROC TMODEL APPROACHES*/
	DATA DINIT(Label="Initial Conditions of Simulation"); 
		DO TIME = 0 TO &N_DAYS; 
			S_N = &S. - (&I/&DIAGNOSED_RATE) - &R;
			E_N = &E;
			I_N = &I/&DIAGNOSED_RATE;
			R_N = &R;
			R0  = &R_T;
			OUTPUT; 
		END; 
	RUN;

proc model data=DINIT model=seirmod;
	solve CUMULATIVE_CASE_COUNT / /*time=date*/ out=epifore/*(rename=v=i)*/ /*solveprint*/;
quit;

DATA epifore;
				FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
				ModelType="TMODEL - SEIR";
				ScenarioName="&scenario";
/*				ScenarioIndex=&ScenarioIndex.;*/
/*				ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');*/
				LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
					ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
				RETAIN LAG_S LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
					CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
				LAG_S = S_N; 
				LAG_E = E_N; 
				LAG_I = I_N; 
				LAG_R = R_N; 
				LAG_N = N; 
				SET epifore(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				N = SUM(S_N, E_N, I_N, R_N);
				SCALE = LAG_N / N;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE * &MARKET_SHARE;
					ICU = NEWINFECTED * &ICU_RATE * &MARKET_SHARE * &HOSP_RATE;
					VENT = NEWINFECTED * &VENT_RATE * &MARKET_SHARE * &HOSP_RATE;
					ECMO = NEWINFECTED * &ECMO_RATE * &MARKET_SHARE * &HOSP_RATE;
					DIAL = NEWINFECTED * &DIAL_RATE * &MARKET_SHARE * &HOSP_RATE;
					Fatality = NEWINFECTED * &Fatality_Rate * &MARKET_SHARE*&Hosp_rate;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE;
					MARKET_ICU = NEWINFECTED * &ICU_RATE * &HOSP_RATE;
					MARKET_VENT = NEWINFECTED * &VENT_RATE * &HOSP_RATE;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE * &HOSP_RATE;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE * &HOSP_RATE;
					Market_Fatality = NEWINFECTED * &Fatality_Rate *&Hosp_rate;
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
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS(CUMULATIVE_SUM_MARKET_DIAL));
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
					DATE = "&DAY_ZERO"D + DAY;
					ADMIT_DATE = SUM(DATE, 0);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP LAG: CUM: ;
			RUN;

PROC SGPLOT DATA=epifore;
	TITLE "Daily Occupancy - PROC MODEL SEIR Fit Approach";
/*	TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";*/
/*	TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";*/
/*	TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";*/
	SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
	SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
	SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
	SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
	SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
	XAXIS LABEL="Date";
	YAXIS LABEL="Daily Occupancy";
RUN;
TITLE; TITLE2; TITLE3; TITLE4;
