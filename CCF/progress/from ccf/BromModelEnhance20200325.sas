/*SAS Studio program COVID_19*/
/*%STPBegin;*/

/*need to add: Shift to the right based on X days input (for delay in admission)*/
/* ICU step down (this would be x% of ICU LOS is ICU and the rest is added to )  */
/*Basic parameter input for 'Non Covid beds occupied'  */
/*Mild/Severe/Critical  */

libname DL_RA teradata server=tdprod1 database=DL_RiskAnalytics;
libname DL_COV teradata server=tdprod1 database=DL_COVID;

%let DeathRt=0;
/* %let IncubationPeriod=10; */
/*below rate is based on documentation that shows 86% of cases are unconfirmed*/
%let Diagnosed_Rate=1.0; /*factor to adjust %admission to make sense multiplied by Total I*/
%let LOS=7; /*default 7 length of stay for all scenarios*/
%let ICULOS=9; /*default ICU LOS*/
*%let ICURoutineDays=3; /*how long a patient stays in Med/Surg bed after ICU*/
%let VENTLOS=10; /*Default vent LOS*/
%let ecmoPercent=.03; /*default percent of total admissions that need ECMO*/
%let ecmolos=6;
%let DialysisPercent=0.05; /*default percent of admissions that need Dialysis*/
%let DialysisLOS=11;
%let dayZero= '13MAR2020'd;

;
%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,KnownCOVID,SocialDistancing,MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate);
%LET S_DEFAULT =&Population;  /*prompt variable &Population*/

%Let Fatality_rate = &fatalityrate;
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


%PUT _ALL_; 
 
/*CREATE SHELL DATA SET*/ 
DATA SHELL; 
	DO DAY = 0 TO &N_DAYS; 
 		IF DAY = 0 THEN DO; 
 			S_N = &S - (&I/&Diagnosed_Rate) - &InitRecovered; 
 			I_N = &I/&Diagnosed_Rate; 
 			R_N = &R + &InitRecovered;  
 			BETA=&BETA; 
 			N = SUM(S_N, I_N, R_N); 
 			OUTPUT; 
 		END; 
 		ELSE DO; 
 			S_N = .; 
 			I_N = .; 
 			R_N = .; 
 			BETA = .; 
 			N = SUM(S_N, I_N, R_N); 
 			OUTPUT; 
 		END; 
 	END; 
 RUN; 
 
DATA DS1; 
 	RETAIN LAG_S LAG_I LAG_R LAG_N LAG_BETA; 
 	LAG_S = S_N; 
 	LAG_I = I_N; 
 	LAG_R = R_N; 
 	LAG_N = N; 
 	LAG_BETA = BETA; 
 	SET SHELL; 
 	IF _N_ = 1 THEN DO; 
 		OUTPUT; 
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
 		OUTPUT; 
 	END; 
 	DROP LAG: BETA; 
 RUN; 
 
DATA DS_FINAL; 
 	SET DS1;
/* add Lagg HOSP/ICU/VENT/ECMO/DIAL*/ 
InfectedLag=lag(S_N);
NewInfected=InfectedLag-S_N;
NewInfLagIncubation=lag&IncubationPeriod(NewInfected);

Market_HOSP = /*I_N*/NewInfLagIncubation * &HOSP_RATE /* &MARKET_SHARE*/; 
Market_ICU = /*I_N*/ NewInfLagIncubation * &ICU_RATE*&HOSP_RATE /* &MARKET_SHARE*/; 
Market_VENT = /*I_N*/ NewInfLagIncubation * &VENT_RATE*&HOSP_RATE *&ICU_RATE /* &MARKET_SHARE*/; 
MArket_ECMO = /*I_N*/NewInfLagIncubation * &ECMO *&Hosp_rate /* &MARKET_SHARE*/; 
Market_DIAL = /*I_N*/NewInfLagIncubation * &DIAL *&Hosp_rate/* &MARKET_SHARE*/; 
Market_Fatality = /*I_N*/NewInfLagIncubation* &Fatality_rate *&HOSP_RATE/* &MARKET_SHARE*/; 
/* PENN_HOSP = Round(I_N*&HOSP_RATE * &MARKET_SHARE,1); */
	
 	HOSP = /*I_N*/NewInfLagIncubation * &HOSP_RATE * &MARKET_SHARE; 
 	ICU = /*I_N*/NewInfLagIncubation * &ICU_RATE * &MARKET_SHARE*&HOSP_RATE; 
 	VENT = /*I_N*/NewInfLagIncubation * &VENT_RATE * &MARKET_SHARE*&HOSP_RATE /*&ICU_RATE*/; 
	ECMO = /*I_N*/NewInfLagIncubation * &ECMO * &MARKET_SHARE*&Hosp_rate; 
	DIAL = /*I_N*/NewInfLagIncubation * &DIAL * &MARKET_SHARE*&Hosp_rate; 
	Fatality = /*I_N*/NewInfLagIncubation * &Fatality_Rate * &MARKET_SHARE*&Hosp_rate;
	
/* if _N_=1 then Market_HOSP=Market_HOSP+&KnownAdmits; */
/* if _N_=1 then HOSP=HOSP+&KnownAdmits; */
 RUN; 
 
PROC SGPLOT DATA=DS_FINAL;
	TITLE "New Admissions - DATA Step Approach";
	SERIES X=DAY Y=HOSP;
	SERIES X=DAY Y=ICU;
	SERIES X=DAY Y=VENT;
	SERIES X=DAY Y=ECMO;
	SERIES X=DAY Y=DIAL;
	XAXIS LABEL="Days from Today";
	YAXIS LABEL="Daily Admits/ICU/ECMO/DIAL";
RUN;
/* PROC SGPLOT DATA=DS_FINAL; */
/* 	TITLE "New Events, LOG SCALE";*/
/*YAXIS type=LOG LOGSTYLE=LOGEXPAND LOGBASE=10; */
/* 	SERIES X=DAY Y=HOSP; */
/* 	SERIES X=DAY Y=ICU; */
/* 	SERIES X=DAY Y=VENT; */
/*	SERIES X=DAY Y=ECMO; */
/*	SERIES X=DAY Y=DIAL; */
/* 	XAXIS LABEL="Days from Today"; */
/* 	YAXIS LABEL="Daily Events"; */
/* RUN; */
/* */
 
/*TITLE; */
data work.cumulative_1;set work.ds_final;
retain Cumulative_sum_Hosp Cumulative_Sum_ICU Cumulative_Sum_Vent Cumulative_Sum_ECMO Cumulative_Sum_DIAL
Cumulative_sum_Market_Hosp Cumulative_Sum_Market_ICU Cumulative_Sum_Market_Vent Cumulative_Sum_Market_ECMO Cumulative_Sum_Market_DIAL
;
Cumulative_sum_Hosp + Hosp;
Cumulative_Sum_ICU + ICU;
Cumulative_Sum_Vent+VENT;
Cumulative_Sum_Ecmo+ECMO;
Cumulative_Sum_DIAL+DIAL;
Cumulative_sum_fatality + Fatality;

Cumulative_sum_Market_Hosp + Market_Hosp;
Cumulative_Sum_Market_ICU + Market_ICU;
Cumulative_Sum_Market_Vent + Market_Vent;
Cumulative_Sum_Market_ECMO + MArket_ECMO;
Cumulative_Sum_Market_DIAL + Market_DIAL;
cumulative_Sum_Market_Fatality + Market_Fatality;


;run;

data work. &Scenario; set work.cumulative_1;
format Scenarioname $30.;
ScenarioName="&Scenario";
Format date Date9.;
Date="&Dayzero"d+Day;

/* PENN_HOSP = PENN_HOSP-lag(PENN_HOSP); */

CumAdmitLagged=lag&HOSP_LOS(Cumulative_sum_Hosp) ;
CumICULagged=lag&ICU_LOS(Cumulative_sum_ICU) ;
CumVentLagged=lag&VENT_LOS(Cumulative_sum_VENT) ;
CumECMOLagged=lag&ECMO_LOS(Cumulative_sum_ECMO) ;
CumDIALLagged=lag&DIAL_LOS(Cumulative_sum_DIAL) ;


CumMarketAdmitLag=lag&HOSP_LOS(Cumulative_sum_Market_Hosp);
CumMarketICULag=lag&ICU_LOS(Cumulative_sum_Market_ICU);
CumMarketVENTLag=lag&VENT_LOS(Cumulative_sum_Market_VENT);
CumMarketECMOLag=lag&ECMO_LOS(Cumulative_sum_Market_ECMO);
CumMarketDIALLag=lag&DIAL_LOS(Cumulative_sum_Market_DIAL);
/*add temporary fields for calculating medSurgcensus*/

array fixingdot _Numeric_;
 do over fixingdot;
 	if fixingdot=. then fixingdot=0;
end;

 ;
Hospital_Occupancy=round(Cumulative_Sum_Hosp-CumAdmitLagged);
/* Medical_Surg_Bed_Occupancy=round(); */
ICU_Occupancy= round(Cumulative_Sum_ICU-CumICULagged);
Vent_Occupancy= round(Cumulative_Sum_Vent-CumVentLagged,1);
ECMO_Occupancy= round(Cumulative_Sum_ECMO-CumECMOLagged,1);
DIAL_Occupancy= round(Cumulative_Sum_DIAL-CumDIALLagged,1);
Deceased_Today = Fatality;
Total_Deaths = Cumulative_sum_fatality;

Market_Hospital_Occupancy= round(Cumulative_sum_Market_Hosp-CumMarketAdmitLag,1);
MArket_ICU_Occupancy= round(Cumulative_Sum_Market_ICU-CumMarketICULag,1);
Market_Vent_Occupancy= round(Cumulative_Sum_Market_Vent-CumMarketVENTLag,1);
Market_ECMO_Occupancy= round(Cumulative_Sum_Market_ECMO-CumMarketECMOLag,1);
Market_DIAL_Occupancy= round(Cumulative_Sum_Market_DIAL-CumMarketDIALLag,1);

Market_Deceased_Today = Market_Fatality;
Market_Total_Deaths = cumulative_Sum_Market_Fatality;


MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
/* Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy+lag&ICULOS(ICU)-lag&ICURoutineDays(TEmpLagICU); */

drop TEmpLagICU tempRoutineLagICU;
;run;


/* PROC SGPLOT DATA=&Scenario; */
/* 	TITLE "DailyCensus";  */
/*	YAXIS type=LOG LOGSTYLE=LOGEXPAND LOGBASE=10;*/
/* 	SERIES X=DAY Y=Hospital_Occupancy; */
/* 	SERIES X=DAY Y=ICU_Occupancy; */
/* 	SERIES X=DAY Y=Vent_Occupancy; */
/*	SERIES X=DAY Y=ECMO_Occupancy;*/
/*	SERIES X=DAY Y=DIAL_Occupancy; */
/* 	XAXIS LABEL="Days from Today"; */
/* 	YAXIS LABEL="Daily Admissions"; */
/*	type=LOG LOGSTYLE=LOGEXPAND LOGBASE=10;*/
/* RUN; */
/* proc datasets lib= work kill;run;quit;*/
 
 proc datasets noprint lib=work; 
delete 
Cumulative_1 
DS_Final
DS1
_PRODSAVAIL
SHELL
NAMES
;run;quit;

proc SQL; select MEMNAME into : MEMNAMES separated by ' ' 
from dictionary.tables where libname='WORK';quit;
%put &MEMNAMES;

data names; set &MEMNAMES;run;
%mend;
%EasyRun(scenario=BASE_Scenario_one,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=BASE_Scenario_two,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=BASE_Scenario_three,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

/* %EasyRun(scenario=BASE_Scenario_one_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14, */
/* doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484, */
/* SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01); */
/*  */
/* %EasyRun(scenario=BASE_Scenario_two_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14, */
/* doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484, */
/* SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01); */
/*  */
/* %EasyRun(scenario=BASE_Scenario_three_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14, */
/* doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484, */
/* SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01); */

%EasyRun(scenario=Scenario_one_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=Scenario_two_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=Scenario_three_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=Scenario_one_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=Scenario_two_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);

%EasyRun(scenario=Scenario_three_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125,FatalityRate = 0.01);


/* START ICU = 45% and vent = 81% OF icu*/
%EasyRun(scenario=Scenario_75_iso_0,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_75_iso_20,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.20,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_75_iso_40,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.40,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_5_iso_0,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_5_iso_20,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.20,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_5_iso_40,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.40,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_35_iso_0,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.035,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_35_iso_20,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.20,MarketSharePercent=.29,Admission_Rate=.035,ICUPercent=0.45,VentPErcent=0.35);

%EasyRun(scenario=Scenario_35_iso_40,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.40,MarketSharePercent=.29,Admission_Rate=.035,ICUPercent=0.45,VentPErcent=0.35);
/* END ICU = 45% and vent = 81% OF icu*/


/*Ohio total running*/
%let DeathRt=0;
/* %let IncubationPeriod=10; */
/*below rate is based on documentation that shows 86% of cases are unconfirmed*/
%let Diagnosed_Rate=1.0; /*factor to adjust %admission to make sense multiplied by Total I*/
%let LOS=7; /*default 7 length of stay for all scenarios*/
%let ICULOS=9; /*default ICU LOS*/
%let ICURoutineDays=3; /*how long a patient stays in Med/Surg bed after ICU*/
%let VENTLOS=10; /*Default vent LOS*/
%let ecmoPercent=.03; /*default percent of total admissions that need ECMO*/
%let ecmolos=6;
%let DialysisPercent=0.05; /*default percent of admissions that need Dialysis*/
%let DialysisLOS=11;
%let dayZero= '16MAR2020'd;

%EasyRun(scenario=OHIO_BASE_Scenario_one,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=50,Population=11689442,
SocialDistancing=0.0,MarketSharePercent=1.0,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_BASE_Scenario_two,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.2,MarketSharePercent=1.0,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_BASE_Scenario_three,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.4,MarketSharePercent=1.0,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_one_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.0,MarketSharePercent=1.0,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_two_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.2,MarketSharePercent=1.0,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_three_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.4,MarketSharePercent=1.0,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_one_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.0,MarketSharePercent=1.0,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_two_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.2,MarketSharePercent=1.0,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_three_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=3,KnownAdmits=17,KnownCOVID=247,Population=11689442,
SocialDistancing=0.4,MarketSharePercent=1.0,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);




