/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, March 24, 2020     TIME: 3:27:13 PM
PROJECT: SAS_SIR_V1
PROJECT PATH: S:\BusDev\BUS_DEVLP_FILES\Analysis\COVID_19_RiskAnalytics\SAS_SIR_V1.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=SVG;
GOPTIONS XPIXELS=0 YPIXELS=0;
%macro HTML5AccessibleGraphSupported;
    %if %_SAS_VERCOMP_FV(9,4,4, 0,0,0) >= 0 %then ACCESSIBLE_GRAPH;
%mend;
FILENAME EGHTMLX TEMP;
ODS HTML5(ID=EGHTMLX) FILE=EGHTMLX
    OPTIONS(BITMAP_MODE='INLINE')
    %HTML5AccessibleGraphSupported
    ENCODING='utf-8'
    STYLE=HTMLBlue
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
;

/*   START OF NODE: Program   */
%LET _CLIENTTASKLABEL='Program';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='S:\BusDev\BUS_DEVLP_FILES\Analysis\COVID_19_RiskAnalytics\SAS_SIR_V1.egp';
%LET _CLIENTPROJECTPATHHOST='RK022115W31302L';
%LET _CLIENTPROJECTNAME='SAS_SIR_V1.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';


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
%let ICURoutineDays=3; /*how long a patient stays in Med/Surg bed after ICU*/
%let VENTLOS=10; /*Default vent LOS*/
%let ecmoPercent=.03; /*default percent of total admissions that need ECMO*/
%let ecmolos=6;
%let DialysisPercent=0.05; /*default percent of admissions that need Dialysis*/
%let DialysisLOS=11;
%let dayZero= '13MAR2020'd;
;
%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,KnownCOVID,SocialDistancing,MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent);
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
NewInfected=round(InfectedLag-S_N,1);
NewInfLagIncubation=lag&IncubationPeriod(NewInfected);

Market_HOSP = /*I_N*/round(NewInfLagIncubation * &HOSP_RATE,1) /* &MARKET_SHARE*/; 
Market_ICU = /*I_N*/round(NewInfLagIncubation * &ICU_RATE*&HOSP_RATE,1) /* &MARKET_SHARE*/; 
Market_VENT = /*I_N*/round(NewInfLagIncubation * &VENT_RATE*&HOSP_RATE,1) /* &MARKET_SHARE*/; 
MArket_ECMO = /*I_N*/round(NewInfLagIncubation * &ECMO *&Hosp_rate,1) /* &MARKET_SHARE*/; 
Market_DIAL = /*I_N*/round(NewInfLagIncubation * &DIAL *&Hosp_rate,1)/* &MARKET_SHARE*/; 

/* PENN_HOSP = Round(I_N*&HOSP_RATE * &MARKET_SHARE,1); */
	
 	HOSP = /*I_N*/round(NewInfLagIncubation * &HOSP_RATE * &MARKET_SHARE,1); 
 	ICU = /*I_N*/round(NewInfLagIncubation * &ICU_RATE * &MARKET_SHARE*&HOSP_RATE,1); 
 	VENT = /*I_N*/round(NewInfLagIncubation * &VENT_RATE * &MARKET_SHARE*&HOSP_RATE,1); 
	ECMO = /*I_N*/round(NewInfLagIncubation * &ECMO * &MARKET_SHARE*&Hosp_rate,1); 
	DIAL = /*I_N*/round(NewInfLagIncubation * &DIAL * &MARKET_SHARE*&Hosp_rate,1); 
	Med_Surg_Hosp=Hosp-ICU;
	Market_Med_Surg_Hosp=Market_Hosp-Market_ICU;

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

Cumulative_sum_Market_Hosp + Market_Hosp;
Cumulative_Sum_Market_ICU + Market_ICU;
Cumulative_Sum_Market_Vent + Market_Vent;
Cumulative_Sum_Market_ECMO + MArket_ECMO;
Cumulative_Sum_Market_DIAL + Market_DIAL;
;run;

data work. &Scenario; set work.cumulative_1;
format Scenarioname $30.;
ScenarioName="&Scenario";
Format date Date9.;
Date="&Dayzero"d+Day;

/* PENN_HOSP = PENN_HOSP-lag(PENN_HOSP); */

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

 ;
Hospital_Occupancy= round(Cumulative_Sum_Hosp-CumAdmitLagged,1);
/* Medical_Surg_Bed_Occupancy=round(); */
ICU_Occupancy= round(Cumulative_Sum_ICU-CumICULagged,1);
Vent_Occupancy= round(Cumulative_Sum_Vent-CumVentLagged,1);
ECMO_Occupancy= round(Cumulative_Sum_ECMO-CumECMOLagged,1);
DIAL_Occupancy= round(Cumulative_Sum_DIAL-CumDIALLagged,1);

Market_Hospital_Occupancy= round(Cumulative_sum_Market_Hosp-CumMarketAdmitLag,1);
MArket_ICU_Occupancy= round(Cumulative_Sum_Market_ICU-CumMarketICULag,1);
Market_Vent_Occupancy= round(Cumulative_Sum_Market_Vent-CumMarketVENTLag,1);
Market_ECMO_Occupancy= round(Cumulative_Sum_Market_ECMO-CumMarketECMOLag,1);
Market_DIAL_Occupancy= round(Cumulative_Sum_Market_DIAL-CumMarketDIALLag,1);
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
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=BASE_Scenario_two,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=BASE_Scenario_three,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=BASE_Scenario_one_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=BASE_Scenario_two_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=BASE_Scenario_three_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=Scenario_one_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=Scenario_two_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=Scenario_three_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=Scenario_one_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=Scenario_two_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=Scenario_three_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484,
SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);


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
%let dayZero= '09MAR2020'd;

%EasyRun(scenario=OHIO_BASE_Scenario_one,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.0,MarketSharePercent=1.0,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_two,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.2,MarketSharePercent=1.0,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_BASE_Scenario_three,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.4,MarketSharePercent=1.0,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125);

/* %EasyRun(scenario=BASE_Scenario_one_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14, */
/* doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484, */
/* SocialDistancing=0.0,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125); */
/*  */
/* %EasyRun(scenario=BASE_Scenario_two_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14, */
/* doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484, */
/* SocialDistancing=0.2,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125); */
/*  */
/* %EasyRun(scenario=BASE_Scenario_three_Inc,IncubationPeriod=10,InitRecovered=0,RecoveryDays=14, */
/* doublingtime=5,KnownAdmits=10,KnownCOVID=46,Population=4390484, */
/* SocialDistancing=0.4,MarketSharePercent=.29,Admission_Rate=.075,ICUPercent=0.25,VentPErcent=0.125); */

%EasyRun(scenario=OHIO_Scenario_one_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.0,MarketSharePercent=1.0,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_two_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.2,MarketSharePercent=1.0,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_three_5Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.4,MarketSharePercent=1.0,Admission_Rate=.05,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_one_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.0,MarketSharePercent=1.0,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_two_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.2,MarketSharePercent=1.0,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);

%EasyRun(scenario=OHIO_Scenario_three_3Prcnt,IncubationPeriod=0,InitRecovered=0,RecoveryDays=14,
doublingtime=5,KnownAdmits=1,KnownCOVID=4,Population=11689442,
SocialDistancing=0.4,MarketSharePercent=1.0,Admission_Rate=.03,ICUPercent=0.25,VentPErcent=0.125);




%let DlabPush=Yes;
%macro addtoDL(ExistingTabName, DesiredTabName, Libref);
data work.rownumtab; set work.&ExistingTabName;
rownum=_N_;run;
data work.rownumtab_move; set work.rownumtab(keep=rownum);set work.rownumtab;run;

proc sql noprint; drop table &Libref .&DesiredTabName;quit;
DATA &Libref .&DesiredTabName (FASTLOAD=YES FASTEXPORT=YES SESSIONS=4);
     SET WORK.rownumtab_move;RUN;
	 proc sql noprint; drop table work.rownumtab, work.rownumtab_move;quit;
%mend;
libname DL_RA teradata server=tdprod1 database=DL_RiskAnalytics;
%macro Y_N;
%if &DlabPush=Yes %then 
%addtoDL(names,COVID_SIR_REsults_1,DL_RA) 
%addtoDL(names,COVID_SIR_REsults_1,DL_COV)
;
%else ;
%mend;
%Y_N;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
