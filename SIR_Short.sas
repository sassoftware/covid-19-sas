%LET S_DEFAULT = 4119405;
%LET KNOWN_INFECTIONS = 91;
%LET KNOWN_CASES = 4;
/*Currently Hospitalized COVID-19 Patients*/
%LET CURRENT_HOSP = &KNOWN_CASES;
/*Doubling time before social distancing (days)*/
%LET DOUBLING_TIME = 6;
/*Social distancing (% reduction in social contact)*/
%LET RELATIVE_CONTACT_RATE = 0.00;
/*Hospitalization %(total infections)*/
%LET HOSP_RATE = 0.05;
/*ICU %(total infections)*/
%LET ICU_RATE = 0.02;
/*Ventilated %(total infections)*/
%LET VENT_RATE = 0.01;
/*Hospital Length of Stay*/
%LET HOSP_LOS = 7;
/*ICU Length of Stay*/
%LET ICU_LOS = 9;
/*Vent Length of Stay*/
%LET VENT_LOS = 10;
/*Hospital Market Share (%)*/
%LET MARKET_SHARE = 0.15;
/*Regional Population*/
%LET S = &S_DEFAULT;
/*Currently Known Regional Infections (only used to compute detection rate - does not change projections*/
%LET INITIAL_INFECTIONS = &KNOWN_INFECTIONS;
%LET TOTAL_INFECTIONS = %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE);
%LET DETECTION_PROB = %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS);
%LET I = %SYSEVALF(&INITIAL_INFECTIONS / &DETECTION_PROB);
%LET R = 0;
%LET INTRINSIC_GROWTH_RATE = %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1);
%LET RECOVERY_DAYS = 14;
%LET GAMMA = %SYSEVALF(1/&RECOVERY_DAYS);
%LET BETA = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE));
/*R_T is R_0 after distancing*/
%LET R_T = %SYSEVALF(&BETA / &GAMMA * &S);
%LET R_NAUGHT = %SYSEVALF(&R_T / (1-&RELATIVE_CONTACT_RATE));
/*doubling time after distancing*/
%LET DOUBLING_TIME_T = %SYSEVALF(1/%SYSFUNC(LOG2(&BETA*&S - &GAMMA + 1)));
%LET N_DAYS = 200;
%LET BETA_DECAY = 0.0;

%PUT _ALL_;

/* DATA SET APPROACH */
DATA DS_FINAL;
	DO DAY = 0 TO &N_DAYS;
		IF DAY = 0 THEN DO;
			S_N = &S;
			I_N = &I;
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
		HOSP = I_N * &HOSP_RATE * &MARKET_SHARE;
		ICU = I_N * &ICU_RATE * &MARKET_SHARE;
		VENT = I_N * &VENT_RATE * &MARKET_SHARE;
		OUTPUT;
	END;
	DROP LAG: BETA;
RUN;

PROC SGPLOT DATA=DS_FINAL;
	TITLE "New Admissions - DATA Step Approach";
	SERIES X=DAY Y=HOSP;
	SERIES X=DAY Y=ICU;
	SERIES X=DAY Y=VENT;
	XAXIS LABEL="Days from Today";
	YAXIS LABEL="Daily Admissions";
RUN;

TITLE;

/*PROC MODEL APPROACH*/

DATA DINIT(Label="Initial Coditions of Simulation"); 
	S = &S;
	I = &I; 
	R = &R;
	R_NAUGHT=&R_NAUGHT;
	DO TIME = 0 TO &N_DAYS; 
		OUTPUT; 
	END; 
RUN;

*Solvig the ODEs with Proc Model;
PROC TMODEL DATA = DINIT;
/* PARAMETER SETTINGS */ 
	PARMS N &S. R_NAUGHT &R_NAUGHT. ; 
	GAMMA = &GAMMA.;    	         
	BETA = R_NAUGHT*GAMMA/N;
	/* DIFFERENTIAL EQUATIONS */ 
	DERT.S = -BETA*S*I; 				
	DERT.I = BETA*S*I-GAMMA*I;   
	DERT.R = GAMMA*I;           
/* SOLVE THE EQUATIONS */ 
	SOLVE S I R / OUT = TMODEL_FINAL; 
RUN;
QUIT;

DATA TMODEL_FINAL;
	SET TMODEL_FINAL;
	HOSP = I * &HOSP_RATE * &MARKET_SHARE;
	ICU = I * &ICU_RATE * &MARKET_SHARE;
	VENT = I * &VENT_RATE * &MARKET_SHARE;
RUN;

PROC SGPLOT DATA=TMODEL_FINAL;
	TITLE "New Admissions - PROC MODEL Approach";
	SERIES X=TIME Y=HOSP;
	SERIES X=TIME Y=ICU;
	SERIES X=TIME Y=VENT;
	XAXIS LABEL="Days from Today";
	YAXIS LABEL="Daily Admissions";
RUN;

/* Post Process DS_FINAL and TMODEL_FINAL to:
calculate cumulative values
*/
/*
IDEA: Merge DS_FINAL and TMODEL_FINAL into FINAL.  
user variable model= to specify DS or TMODEL
synchronize variable names I_N & I for instance
*/
/* 
Ideas for more features:

*/

TITLE;

CAS;

CASLIB _ALL_ ASSIGN;

PROC CASUTIL;
	DROPTABLE INCASLIB="CASUSER" CASDATA="PROJECT_DS" QUIET;
	LOAD DATA=WORK.DS_FINAL CASOUT="PROJECT_DS" OUTCASLIB="CASUSER" PROMOTE;
QUIT;


PROC CASUTIL;
	DROPTABLE INCASLIB="CASUSER" CASDATA="PROJECT_MODEL" QUIET;
	LOAD DATA=WORK.TMODEL_FINAL CASOUT="PROJECT_MODEL" OUTCASLIB="CASUSER" PROMOTE;
QUIT;

CAS CASAUTO TERMINATE;
