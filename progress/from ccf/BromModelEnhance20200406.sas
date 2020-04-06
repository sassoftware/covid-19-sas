/*SAS Studio program COVID_19*/
/*%STPBegin;*/

/*need to add: Shift to the right based on X days input (for delay in admission)*/
/* ICU step down (this would be x% of ICU LOS is ICU and the rest is added to )  */
/*Basic parameter input for 'Non Covid beds occupied'  */
/*Mild/Severe/Critical  */
%let homedir = /sas/data/ccf_preprod/finance/sas/EA_COVID_19/COVID_Scenarios;
libname store "&homedir.";
libname DL_RA teradata server=tdprod1 database=DL_RiskAnalytics;
libname DL_COV teradata server=tdprod1 database=DL_COVID;
libname CovData '/sas/data/ccf_preprod/finance/sas/EA_COVID_19/CovidData';
proc datasets lib=work kill;run;quit;

proc sql; 
connect to teradata(Server=tdprod1);
create table CovData.PullRealCovid as select * from connection to teradata 

(
Select COVID_RESULT_V.*, DEP_STATE from DL_COVID.COVID_RESULT_V
LEFT JOIN (SELECT DISTINCT COVID_FACT_V.patient_identifier,COVID_FACT_V.DEP_STATE from DL_COVID.COVID_FACT_V) dep_st
on dep_st.patient_identifier = COVID_RESULT_V.patient_identifier
WHERE COVIDYN = 'YES' and DEP_STATE='OH'and discharge_Cat in ('Inpatient','Discharged To Home');
)

;quit;
PROC SQL;
   CREATE TABLE CovData.PullRealAdmitCovid AS 
   SELECT /* AdmitDate */
            (datepart(t1.HSP_ADMIT_DTTM)) FORMAT=Date9. AS AdmitDate, 
          /* COUNT_DISTINCT_of_patient_identi */
            (COUNT(DISTINCT(t1.patient_identifier))) AS TrueDailyAdmits, 
          /* SumICUNum_1 */
            (SUM(input(t1.ICU, 3.))) AS SumICUNum_1, 
          /* SumICUNum */
            (SUM(case when t1.ICU='YES' then 1
            else case when t1.ICU='1' then 1 else 0
            end end)) AS SumICUNum
      FROM CovData.PULLREALCOVID t1
      GROUP BY (CALCULATED AdmitDate);
QUIT;
PROC SQL;
   CREATE TABLE CovData.RealCovid_DischargeDt AS 
   SELECT /* COUNT_of_patient_identifier */
            (COUNT(t1.patient_identifier)) AS TrueDailyDischarges, 
          /* DischargDate */
            (datepart(t1.HSP_DISCH_DTTM)) FORMAT=Date9. AS DischargDate, 
          /* SUMICUDISCHARGE */
            (SUM(Case when t1.DISCHARGEICUYN ='YES' then 1
            else case when t1.DISCHARGEICUYN ='1' then 1
            else 0
            end end)) AS SUMICUDISCHARGE
      FROM CovData.PULLREALCOVID t1
      WHERE (CALCULATED DischargDate) NOT = .
      GROUP BY (CALCULATED DischargDate);
QUIT;

%macro 
EasyRun(
Scenario,
IncubationPeriod,
InitRecovered,
RecoveryDays,
ISOChangeDate,
ISOChangeDateTwo,
ISOChangeDate3,/*product of house*/
ISOChangeDate4,/*product of house*/
SocialDistancingChange,
SocialDistancingChangeTwo,
SocialDistancingChange3,/*product of house*/
SocialDistancingChange4,/*product of house*/
doublingtime,
Population,
KnownAdmits,
KnownCOVID,
SocialDistancing,
MarketSharePercent,
Admission_Rate,
ICUPercent,
VentPErcent,
FatalityRate,
DeathRt,
Diagnosed_Rate,
LOS,
ICULOS, 
VENTLOS,
ecmoPercent,
ecmolos,
DialysisPercent, 
DialysisLOS,
dayZero,
GeographyInput
);

/* Translate CCF code macro (%EASYRUN) inputs to variables used in this code 
	these variables come in from the macro call above
	this section show the name mapping to how they are used in this code
*/



/*UNUSED VARIABLES*/
%LET DAYS_TO_HOSP = 0;
%LET E = 0;
%LET DEATH_RATE=&deathrt;
%LET SIGMA = 0.90;
%LET BETA_DECAY = 0.0;


%let day_Zero= &Dayzero;

%LET ECMO_RATE=&ecmoPercent; 
%LET ECMO_LOS=&ecmolos;

%LET DIAL_RATE=&DialysisPercent;
%LET DIAL_LOS=&DialysisLOS;


%LET HOSP_RATE = %SYSEVALF(&ADMISSION_RATE*&DIAGNOSED_RATE);
%LET CURRENT_HOSP = &KNOWN_CASES;
%LET S_DEFAULT = &Population.;
%LET KNOWN_INFECTIONS = &KnownCOVID.;
%LET KNOWN_CASES = &KnownAdmits.;
/*Doubling time before social distancing (days)*/
%LET DOUBLING_TIME = &doublingtime.;

/*Initial Number of Recovered*/
%LET R = &InitRecovered.;
%LET RECOVERY_DAYS = &RecoveryDays.;

%Let Fatality_rate = &fatalityrate;
%LET KNOWN_INFECTIONS = &KnownCOVID; /*prompt variable */
%LET KNOWN_CASES = &KnownAdmits; /*prompt variable */

%LET CURRENT_HOSP = &KNOWN_CASES; 

%LET DOUBLING_TIME = &DoublingTime; 
 
%LET HOSP_RATE = &Admission_Rate*&Diagnosed_Rate; 
 
%LET ICU_RATE = &ICUPercent*&Diagnosed_Rate;  

%LET VENT_RATE = &VentPercent*&Diagnosed_Rate; 
 
%LET HOSP_LOS = &LOS; 
 
%LET ICU_LOS = &ICULOS; 

%LET VENT_LOS = &VENTLOS; 

%let ECMO=&EcmoPercent;
%let ECMO_LOS = &ECMOLOS;

%let DIAL=&DialysisPercent;
%let DIAL_LOS=&DialysisLOS;

%LET MARKET_SHARE =&MarketSharePercent; 

%LET S = &S_DEFAULT; 

%LET N_DAYS = 365;

/*Currently Known Regional Infections (only used to compute detection rate - does not change projections*/


/*ISOLATION CHANGE STUFF*/
%Let ISO_Change_Date = &ISOChangeDate.;
%LET RELATIVE_CONTACT_RATE_Change = &SocialDistancingChange.;

%Let ISO_Change_Date_Two = &ISOChangeDateTwo.;
%LET RELATIVE_CONTACT_RATE_Change_Two = &SocialDistancingChangeTwo.;

%Let ISO_Change_Date_3 = &ISOChangeDate3.;/*product of house*/
%LET RELATIVE_CONTACT_RATE_Change_3 = &SocialDistancingChange3.;/*product of house*/

%Let ISO_Change_Date_4 = &ISOChangeDate4.;/*product of house*/
%LET RELATIVE_CONTACT_RATE_Change_4 = &SocialDistancingChange4.;/*product of house*/




/*Social distancing (% reduction in social contact)*/ 
%LET RELATIVE_CONTACT_RATE = &SocialDistancing;
%LET INITIAL_INFECTIONS = &KNOWN_INFECTIONS;
%LET TOTAL_INFECTIONS = %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE);
%LET DETECTION_PROB = %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS);
%LET I = %SYSEVALF(&INITIAL_INFECTIONS / &DETECTION_PROB);
%LET INTRINSIC_GROWTH_RATE = %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1);
%LET GAMMA = %SYSEVALF(1/&RECOVERY_DAYS);
%LET BETA = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE));
%LET BETA_Change = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change));
%LET BETA_Change_Two = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_Two));
%LET BETA_Change_3 = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_3));  /*product of house*/
%LET BETA_Change_4 = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_4)); /*product of house*/



/*R_T is R_0 after distancing*/
%LET R_T = %SYSEVALF(&BETA / &GAMMA * &S);
%LET R_NAUGHT = %SYSEVALF(&R_T / (1-&RELATIVE_CONTACT_RATE));
/*doubling time after distancing*/
%LET DOUBLING_TIME_T = %SYSEVALF(1/%SYSFUNC(LOG2(&BETA*&S - &GAMMA + 1)));

%PUT _ALL_; 

DATA DINIT(Label="Initial Conditions of Simulation"); 
	S_N = &S. - (&I/&DIAGNOSED_RATE) - &R;
	E_N = &E;
	I_N = &I/&DIAGNOSED_RATE;
	R_N = &R;
	R0  = &R_T;
	DO TIME = 0 TO &N_DAYS; 
		OUTPUT; 
	END; 
RUN;
%IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
	PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from store.scenarios; quit;
%END;
%ELSE %DO; %LET ScenarioIndex_Base = 0; %END;
/* store all the macro variables that set up this scenario in PARMS dataset */
DATA PARMS;
	set sashelp.vmacro(where=(scope='EASYRUN'));
	if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS') then delete;
	ScenarioIndex = &ScenarioIndex_Base. + 1;
RUN;

/* Check to see if PARMS (this scenario) has already been run before in SCENARIOS dataset */
%IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
	PROC SQL noprint;
		/* has this scenario been run before - all the same parameters and value - no more and no less */
		select count(*) into :ScenarioExist from
			(select t1.ScenarioIndex, t2.ScenarioIndex
				from 
					(select *, count(*) as cnt 
						from PARMS
						where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX')
						group by ScenarioIndex) t1
					join
					(select * from store.SCENARIOS
						where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX')) t2
					on t1.name=t2.name and t1.value=t2.value
				group by t1.ScenarioIndex, t2.ScenarioIndex, t1.cnt
				having count(*) = t1.cnt)
		; 
	QUIT;
%END; 
%ELSE %DO; 
	%LET ScenarioExist = 0;
%END;

/* If this is a new scenario then run it and append results to MODEL_FINAL dataset and scenario (PARMS) to the SCENARIO dataset */
%IF &ScenarioExist = 0 %THEN %DO;
	PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex from work.parms; QUIT;

/*CREATE SHELL DATA SET*/ 
DATA DS_SIR;
			FORMAT ModelType $30. Scenarioname $100. date ADMIT_DATE Date9.;		
			ModelType="DS - SIR";
			ScenarioName="&Scenario";
/* 			ScenarioIndex=&ScenarioIndex.; */
			LABEL Hospital_Occupancy="Hospital Occupancy" ICU_Occupancy="ICU Occupancy" VENT_Occupancy="Ventilator Utilization"
				ECMO_Occupancy="ECMO Utilization" DIAL_Occupancy="Dialysis Utilization";
			LENGTH METHOD $15.;
			DO DAY = 0 TO &N_DAYS;
				IF DAY = 0 THEN DO;
					S_N = &S - (&I/&DIAGNOSED_RATE) - &R;
					I_N = &I/&DIAGNOSED_RATE;
					R_N = &R;
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
				IF date = &ISO_Change_Date THEN LAG_BETA = &BETA_Change;
				IF date = &ISO_Change_Date THEN BETA = &BETA_Change;
				
				IF date = &ISO_Change_Date_Two THEN LAG_BETA = &BETA_Change_Two;
				IF date = &ISO_Change_Date_Two THEN BETA = &BETA_Change_Two;
				
				IF date = &ISO_Change_Date_3 THEN LAG_BETA = &BETA_Change_3;
				IF date = &ISO_Change_Date_3 THEN BETA = &BETA_Change_3;
				
				IF date = &ISO_Change_Date_4 THEN LAG_BETA = &BETA_Change_4;
				IF date = &ISO_Change_Date_4 THEN BETA = &BETA_Change_4;
				
				
				
				
				
				NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(S_N),-1*S_N));
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
				Hospital_Occupancy= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
				ICU_Occupancy= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
				Vent_Occupancy= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
				ECMO_Occupancy= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
				DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
				Deceased_Today = Fatality;
				Total_Deaths = Cumulative_sum_fatality;
				MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
				Market_Hospital_Occupancy= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
				Market_ICU_Occupancy= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
				Market_Vent_Occupancy= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
				Market_ECMO_Occupancy= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
				Market_DIAL_Occupancy= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
				Market_Deceased_Today = Market_Fatality;
				Market_Total_Deaths = cumulative_Sum_Market_Fatality;
				Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
				Date = "&DAY_ZERO"D + DAY;
				ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				METHOD = "SIR - DATA Step";
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
 
/* PROC SGPLOT DATA=DS_SIR; */
/* 	TITLE "New Admissions - DATA Step Approach"; */
/* 	SERIES X=DAY Y=HOSP; */
/* 	SERIES X=DAY Y=ICU; */
/* 	SERIES X=DAY Y=VENT; */
/* 	SERIES X=DAY Y=ECMO; */
/* 	SERIES X=DAY Y=DIAL; */
/* 	XAXIS LABEL="Days from Today"; */
/* 	YAXIS LABEL="Daily Admits/ICU/ECMO/DIAL"; */
/* RUN; */
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
 
/*pull real COVID admits and ICU*/

proc sql; 
create table work.DS_Sir_2 as select t1.*,t2.TrueDailyAdmits, t2.SumICUNum
	from work.ds_sir t1 left join CovData.PullRealAdmitCovid t2 on (t1.Date=t2.AdmitDate);
create table work.DS_SIR_3 as select t1.*,t2.TrueDailyDischarges, t2.SumICUDISCHARGE as SumICUNum_Discharge
	from work.ds_SIR_2 t1 left join CovData.RealCovid_DischargeDt t2 on (t1.Date=t2.DischargDate);
;quit;

data work.DS_SIR_FINALTABLE; set work.DS_SIR_3;
format Scenarioname $550.;
format INPUT_Social_DistancingCombo $90.;
ScenarioName="&Scenario";
CumSumTrueAdmits + TrueDailyAdmits;
CumSumTrueDischarges + TrueDailyDischarges;
CumSumICU + SumICUNum;
CumSumICUDischarge + SumICUNum_Discharge;


True_CCF_Occupancy=CumSumTrueAdmits-CumSumTrueDischarges;

TrueCCF_ICU_Occupancy=CumSumICU-CumSumICUDischarge;
/*day logic for tableau views*/
if date>(today()-3) then Hospital_Occupancy_PP=Hospital_Occupancy; else Hospital_Occupancy_PP=.;
if date>(today()-3) then ICU_Occupancy_PP=ICU_Occupancy; else ICU_Occupancy_PP=.;
if date>(today()-3) then Vent_Occupancy_PP=Vent_Occupancy; else Vent_Occupancy_PP=.;
if date>(today()-3) then ECMO_Occupancy_PP=ECMO_Occupancy; else ECMO_Occupancy_PP=.;
if date>(today()-3) then DIAL_Occupancy_PP=DIAL_Occupancy; else DIAL_Occupancy_PP=.;

if date>today() then True_CCF_Occupancy=.;
if date>today() then TrueCCF_ICU_Occupancy=.;

INPUT_Geography="&GeographyInput";

INPUT_Recovery_Time				=&RecoveryDays;
INPUT_Doubling_Time				=&doublingtime;
INPUT_Starting_Admits			=&KnownAdmits;

INPUT_Population				=&Population;
INPUT_Social_DistancingCombo	="&SocialDistancing"||"/"||"&SocialDistancingChange"||"/"||"&SocialDistancingChangeTwo"||"/"||"&SocialDistancingChange3"||"/"||"&SocialDistancingChange4";
INPUT_Social_Distancing_Date	=Put(&dayZero,date9.) ||" - "|| put(&iso_change_date,date9.) ||" - "|| put(&iso_change_date_two,date9.) ||" - "|| put(&iso_change_date_3,date9.) ||" - "|| put(&iso_change_date_4,date9.);
INPUT_Market_Share				=&MarketSharePercent;
INPUT_Admit_Percent_of_Infected	=&Admission_Rate;
INPUT_ICU_Percent_of_Admits		=&ICUPercent;
INPUT_Vent_Percent_of_Admits	=&VentPErcent;
/*paste overarching scenario variables*/
INPUT_Mortality_RateInput		=&DeathRt;

INPUT_Length_of_Stay			=&LOS; 
INPUT_ICU_LOS					=&ICULOS; 
INPUT_Vent_LOS					=&VENTLOS; 
INPUT_Ecmo_Percent_of_Admits	=&ecmoPercent; 
INPUT_Ecmo_LOS_Input			=&ecmolos;
INPUT_Dialysis_PErcent			=&DialysisPercent; 
INPUT_Dialysis_LOS				=&DialysisLOS;
INPUT_Time_Zero					="&dayZero"d;
;run;


;
PROC APPEND base=store.MODEL_FINAL data=work.DS_SIR_FINALTABLE NOWARN FORCE; run;
PROC APPEND base=store.SCENARIOS data=PARMS; run;
%end;
%mend;

%macro run_scenarios(ds);
	/* import file */
	PROC IMPORT DATAFILE="&homedir./&ds."
		DBMS=CSV
		OUT=run_scenarios
		REPLACE;
		GETNAMES=YES;
	RUN;
	/* extract column names into space delimited string stored in macro variable &names */
	PROC SQL noprint;
		select name into :names separated by ' '
	  		from dictionary.columns
	  		where memname = 'RUN_SCENARIOS';
		select name into :dnames separated by ' '
	  		from dictionary.columns
	  		where memname = 'RUN_SCENARIOS' and substr(format,1,4)='DATE';
	QUIT;
	/* change date variables to character and of the form 'ddmmmyyyy'd */
	%DO i = 1 %TO %sysfunc(countw(&dnames.));
		%LET dname = %scan(&dnames,&i);
		data run_scenarios(drop=x);
			set run_scenarios(rename=(&dname.=x));
			&dname.="'"||put(x,date9.)||"'d";
		run;
	%END;
	/* build a call to %EasyRun for each row in run_scenarios */
	%GLOBAL cexecute;
	%DO i=1 %TO %sysfunc(countw(&names.));
		%LET next_name = %scan(&names, &i);
		%IF &i = 1 %THEN %DO;
			%LET cexecute = "&next_name.=",&next_name.; 
		%END;
		%ELSE %DO;
			%LET cexecute = &cexecute ,", &next_name.=",&next_name;
		%END;
	%END;
%mend;

%include '/sas/data/ccf_preprod/finance/sas/EA_COVID_19/COVID_MACRO_INCLUDE_v4.sas';
/* %let DeathRt=0; */
/* %let Diagnosed_Rate=1.0;  */
/* %let LOS=10;  */
/* %let ICULOS=9;  */
/* %let VENTLOS=10;  */
/* %let ecmoPercent=.01; */
/* %let ecmolos=6; */
/* %let DialysisPercent=0.01;  */
/* %let DialysisLOS=11; */
/* %let dayZero= '05MAR2020'd; */

proc datasets lib=store; delete MODEL_FINAL SCENARIOS;run;quit;
%run_scenarios(run_scenarios.csv);
	/* use the &cexecute variable and the run_scenario dataset to run all the scenarios with call execute */
	data _null_;
		set run_scenarios;
		call execute(cats('%nrstr(%EasyRun(',&cexecute.,'));'));
	run;