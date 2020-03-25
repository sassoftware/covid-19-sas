/*SAS Studio program COVID_19*/

%macro EasyRun(Scenario,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,KnownCOVID,SocialDistancing,MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent);

%let DeathRt=0;
%let Diagnosed_Rate=1.0; /*factor to adjust %admission to make sense multiplied by Total I*/
%let LOS=7; /*default 7 length of stay for all scenarios*/
%let ICULOS=9; /*default ICU LOS*/
%let VENTLOS=10; /*Default vent LOS*/
%let ecmoPercent=.03; /*default percent of total admissions that need ECMO*/
%let ecmolos=28;
%let DialysisPercent=0.09; /*default percent of admissions that need Dialysis*/
%let DialysisLOS=10;

%LET S_DEFAULT =&Population;  /*prompt variable &Population*/
%LET KNOWN_INFECTIONS = &KnownCOVID; /*prompt variable */
%LET KNOWN_CASES = &KnownAdmits; /*prompt variable */
/*Currently Hospitalized COVID-19 Patients*/ 
%LET CURRENT_HOSP = &KNOWN_CASES; 
/*Doubling time before social distancing (days)*/ 
%LET DOUBLING_TIME = &DoublingTime; 
/*Social distancing (% reduction in social contact)*/ 
%LET RELATIVE_CONTACT_RATE = &SocialDistancing; 
/*Hospitalization %(total infections)*/ 
%LET HOSP_RATE = &Admission_Rate*&Diagnosed_Rate; 
/*ICU %(total infections)*/ 
%LET ICU_RATE = &ICUPercent*&Diagnosed_Rate; 
/*Ventilated %(total infections)*/ 
%LET VENT_RATE = &VentPercent*&Diagnosed_Rate; 
/*Hospital Length of Stay*/ 
%LET HOSP_LOS = &LOS; 
/*ICU Length of Stay*/ 
%LET ICU_LOS = &ICULOS; 
/*Vent Length of Stay*/ 
%LET VENT_LOS = &VENTLOS; 
/*ECMO %of ADmissions*/
%let ECMO=&EcmoPercent;
%let ECMO_LOS = &ECMOLOS;
/*Dialysis Variables*/
%let DIAL=&DialysisPercent;
%let DIAL_LOS=&DialysisLOS;
/*Hospital Market Share (%)*/ 
%LET MARKET_SHARE =&MarketSharePercent; 
/*Regional Population*/ 
%LET S = &S_DEFAULT; 
/*Currently Known Regional Infections (only used to compute detection rate - does not change projections*/ 
%LET INITIAL_INFECTIONS = &KNOWN_INFECTIONS; 
%LET TOTAL_INFECTIONS = %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE); 
%LET DETECTION_PROB = %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS); 
%LET I = %SYSEVALF(&INITIAL_INFECTIONS / &DETECTION_PROB); 
%LET R = 0; 
%LET INTRINSIC_GROWTH_RATE = %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1); 
%LET RECOVERY_DAYS = &RecoveryDays; 
%LET GAMMA = %SYSEVALF(1/&RECOVERY_DAYS); 
%LET BETA = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE)); 
/*R_T is R_0 after distancing*/ 
%LET R_T = %SYSEVALF(&BETA / &GAMMA * &S); 
%LET R_NAUGHT = %SYSEVALF(&R_T / (1-&RELATIVE_CONTACT_RATE)); 
/*doubling time after distancing*/ 
%LET DOUBLING_TIME_T = %SYSEVALF(1/%SYSFUNC(LOG2(&BETA*&S - &GAMMA + 1))); 
%LET N_DAYS = /*&ModelDays*/365; 
%LET BETA_DECAY = 0.0; 
/*Average number of days from infection to hospitalization*/
%LET DAYS_TO_HOSP = 0;
/*Date of first COVID-19 Case*/
%LET DAY_ZERO = 13MAR2020;


/* create an index, ScenarioIndex for this run by incrementing the max value of ScenarioIndex in SCENARIOS dataset */
%IF %SYSFUNC(exist(work.scenarios)) %THEN %DO;
	PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from work.scenarios; quit;
%END;
%ELSE %DO; %LET ScenarioIndex_Base = 0; %END;
/* store all the macro variables that set up this scenario in PARMS dataset */
DATA PARMS;
	set sashelp.vmacro(where=(scope='EASYRUN'));
	if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS') then delete;
	ScenarioIndex = &ScenarioIndex_Base. + 1;
RUN;

/* Check to see if PARMS (this scenario) has already been run before in SCENARIOS dataset */
%IF %SYSFUNC(exist(work.scenarios)) %THEN %DO;
	PROC SQL noprint;
		/* has this scenario been run before - all the same parameters and value - no more and no less */
		select count(*) into :ScenarioExist from
			(select t1.ScenarioIndex, t2.ScenarioIndex
				from 
					(select *, count(*) as cnt 
						from PARMS
						where name not in ('SCENARIO','SCENARIOINDEX_BASE')
						group by ScenarioIndex) t1
					join
					(select * from SCENARIOS
						where name not in ('SCENARIO','SCENARIOINDEX_BASE')) t2
					on t1.name=t2.name and t1.value=t2.value
				group by t1.ScenarioIndex, t2.ScenarioIndex, t1.cnt
				having count(*) = t1.cnt)
		; 
	QUIT;
%END; 
%ELSE %DO; %LET ScenarioExist = 0; %END;

/* If this is a new scenario then run it and append results to MODEL_FINAL dataset and scenario (PARMS) to the SCENARIO dataset */
%IF &ScenarioExist = 0 %THEN %DO;
	
	/* DATA SET APPROACH - ModelType=DS */
	DATA DS_STEP;
		format ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
		ModelType="DS";
		ScenarioName="&Scenario";
		DO DAY = 0 TO &N_DAYS;
			IF DAY = 0 THEN DO;
				S_N = &S - (&I/&Diagnosed_Rate) - &InitRecovered; 
				I_N = &I/&Diagnosed_Rate; 
				R_N = &R + &InitRecovered; 
				BETA=&BETA;
				N = SUM(S_N, I_N, R_N);
			END;
			ELSE DO;
				BETA = LAG_BETA * (1- &BETA_DECAY);
				S_N = (-BETA * LAG_S * LAG_I) + LAG_S;
				I_N = (BETA * LAG_S * LAG_I - &GAMMA * LAG_I) + LAG_I;
				R_N = &GAMMA * LAG_I + LAG_R;
				N = SUM(S_N, I_N, R_N);
				SCALE = LAG_N / N;
				IF S_N < 0 THEN S_N = 0;
				IF I_N < 0 THEN I_N = 0;
				IF R_N < 0 THEN R_N = 0;
				S_N = SCALE*S_N;
				I_N = SCALE*I_N;
				R_N = SCALE*R_N;
			END;
			LAG_S = S_N;
			LAG_I = I_N;
			LAG_R = R_N;
			LAG_N = N;
			LAG_BETA = BETA;
			/* add Lagg HOSP/ICU/VENT/ECMO/DIAL*/ 
	/*			InfectedLag=lag(S_N);*/
	/*			NewInfected=round(InfectedLag-S_N,1);*/
				NEWINFECTED=ROUND(SUM(LAG(S_N),-1*S_N),1);
				IF NEWINFECTED < 0 THEN NEWINFECTED=0;
				Market_HOSP = /*I_N*/round(NewInfected * &HOSP_RATE,1) /* &MARKET_SHARE*/; 
				Market_ICU = /*I_N*/round(NewInfected * &ICU_RATE,1) /* &MARKET_SHARE*/; 
				Market_VENT = /*I_N*/round(NewInfected * &VENT_RATE,1) /* &MARKET_SHARE*/; 
				MArket_ECMO = /*I_N*/round(NewInfected * &ECMO *&Hosp_rate,1) /* &MARKET_SHARE*/; 
				Market_DIAL = /*I_N*/round(NewInfected * &DIAL *&Hosp_rate,1)/* &MARKET_SHARE*/; 
				HOSP = /*I_N*/round(NewInfected * &HOSP_RATE * &MARKET_SHARE,1); 
				ICU = /*I_N*/round(NewInfected * &ICU_RATE * &MARKET_SHARE,1); 
				VENT = /*I_N*/round(NewInfected * &VENT_RATE * &MARKET_SHARE,1); 
				ECMO = /*I_N*/round(NewInfected * &ECMO * &MARKET_SHARE*&Hosp_rate,1); 
				DIAL = /*I_N*/round(NewInfected * &DIAL * &MARKET_SHARE*&Hosp_rate,1); 
			/* cumulative sum */
				Cumulative_sum_Hosp + Hosp;
				Cumulative_Sum_ICU + ICU;
				Cumulative_Sum_Vent + VENT;
				Cumulative_Sum_Ecmo + ECMO;
				Cumulative_Sum_DIAL + DIAL;
	
				Cumulative_sum_Market_Hosp + Market_Hosp;
				Cumulative_Sum_Market_ICU + Market_ICU;
				Cumulative_Sum_Market_Vent + Market_Vent;
				Cumulative_Sum_Market_ECMO + MArket_ECMO;
				Cumulative_Sum_Market_DIAL + Market_DIAL;
			/* more calcs */
				CumAdmitLagged=round(lag&HOSP_LOS(Cumulative_sum_Hosp),1) ;
				CumICULagged=round(lag&ICU_LOS(Cumulative_sum_ICU),1) ;
				CumVentLagged=round(lag&VENT_LOS(Cumulative_sum_VENT),1) ;
				CumECMOLagged=round(lag&ECMO_LOS(Cumulative_sum_ECMO),1) ;
				CumDIALLagged=round(lag&DIAL_LOS(Cumulative_sum_DIAL),1) ;
	
				CumMarketAdmitLag=Round(lag&HOSP_LOS(Cumulative_sum_Market_Hosp));
				CumMarketICULag=Round(lag&ICU_LOS(Cumulative_sum_Market_ICU));
				CumMarketVENTLag=Round(lag&VENT_LOS(Cumulative_sum_Market_VENT));
				CumMarketECMOLag=Round(lag&ECMO_LOS(Cumulative_sum_Market_ECMO));
				CumMarketDIALLag=Round(lag&DIAL_LOS(Cumulative_sum_Market_DIAL));
	
				array fixingdot _Numeric_;
				do over fixingdot;
					if fixingdot=. then fixingdot=0;
				end;
	
				Hospital_Occupancy= round(Cumulative_Sum_Hosp-CumAdmitLagged,1);
				ICU_Occupancy= round(Cumulative_Sum_ICU-CumICULagged,1);
				Vent_Occupancy= round(Cumulative_Sum_Vent-CumVentLagged,1);
				ECMO_Occupancy= round(Cumulative_Sum_ECMO-CumECMOLagged,1);
				DIAL_Occupancy= round(Cumulative_Sum_DIAL-CumDIALLagged,1);
	
				Market_Hospital_Occupancy= round(Cumulative_sum_Market_Hosp-CumMarketAdmitLag,1);
				MArket_ICU_Occupancy= round(Cumulative_Sum_Market_ICU-CumMarketICULag,1);
				Market_Vent_Occupancy= round(Cumulative_Sum_Market_Vent-CumMarketVENTLag,1);
				Market_ECMO_Occupancy= round(Cumulative_Sum_Market_ECMO-CumMarketECMOLag,1);
				Market_DIAL_Occupancy= round(Cumulative_Sum_Market_DIAL-CumMarketDIALLag,1);	
				DATE = "&DAY_ZERO"D + DAY;
				ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);			
			OUTPUT;
		END;
		DROP LAG: BETA CUM:;
	RUN;
	
	PROC APPEND base=MODEL_FINAL data=DS_STEP; run;
	PROC APPEND base=SCENARIOS data=PARMS; run;

%END;

%mend;

%EasyRun(scenario=Scenario_one,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=37,KnownCOVID=150,Population=4390000,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.02,VentPErcent=0.01);

%EasyRun(scenario=Scenario_two,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=37,KnownCOVID=150,Population=4390000,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.02,VentPErcent=0.01);

/* this will compare the DS_FINAL above to the SCENARIO_ONE output from BromEnhancedModel_V2.sas - show equal rows/columns
proc compare base=DS_FINAL compare=SCENARIO_ONE; run;
*/

PROC SGPLOT DATA=DS_FINAL;
	TITLE "Daily Occupancy - Data Step Approach";
	SERIES X=DATE Y=HOSPITAL_OCCUPANCY;
	SERIES X=DATE Y=ICU_OCCUPANCY;
	SERIES X=DATE Y=VENT_OCCUPANCY;
	SERIES X=DATE Y=ECMO_OCCUPANCY;
	SERIES X=DATE Y=DIAL_OCCUPANCY;
	XAXIS LABEL="Date";
	YAXIS LABEL="Daily Occupancy";
RUN;
TITLE;

CAS;

CASLIB _ALL_ ASSIGN;

PROC CASUTIL;
	DROPTABLE INCASLIB="CASUSER" CASDATA="PROJECT_DS" QUIET;
	LOAD DATA=WORK.DS_FINAL CASOUT="PROJECT_DS" OUTCASLIB="CASUSER" PROMOTE;
QUIT;

CAS CASAUTO TERMINATE;
