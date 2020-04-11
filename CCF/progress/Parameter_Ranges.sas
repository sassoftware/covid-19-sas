%LET S_DEFAULT = 4390000;
%LET KNOWN_INFECTIONS = 150;
%LET KNOWN_CASES = 37;
/*Doubling time before social distancing (days)*/
%LET DOUBLING_TIME = 5;
/*Initial Number of Exposed (infected but not yet infectious)*/
%LET E = 0;
/*Initial Recovered*/
%LET R = 0;
%LET RECOVERY_DAYS = 14;
/*Social distancing (% reduction in social contact)*/
%LET RELATIVE_CONTACT_RATE = 0.00;
/*Hospital Market Share (%)*/
%LET MARKET_SHARE = 0.29;
/*Admission Rate*/
%LET ADMISSION_RATE=0.075;
/*ICU %(total infections)*/
%LET ICU_RATE = %SYSEVALF(0.02*&DIAGNOSED_RATE);
/*Ventilated %(total infections)*/
%LET VENT_RATE = %SYSEVALF(0.01*&DIAGNOSED_RATE);




/*factor to adjust %admission to make sense multiplied by Total I*/
%LET DIAGNOSED_RATE=1.0; 
/*Hospital Length of Stay*/
%LET HOSP_LOS = 7;
/*ICU Length of Stay*/
%LET ICU_LOS = 9;
/*Vent Length of Stay*/
%LET VENT_LOS = 10;
/*default percent of total admissions that need ECMO*/
%LET ECMO_RATE=0.03; 
%LET ECMO_LOS=28;
/*default percent of admissions that need Dialysis*/
%LET DIAL_RATE=0.09;
%LET DIAL_LOS=10;
%LET DEATH_RATE=0.00;
%LET N_DAYS = 365;
%LET BETA_DECAY = 0.0;
/*Average number of days from infection to hospitalization*/
%LET DAYS_TO_HOSP = 0;
/*Date of first COVID-19 Case*/
%LET DAY_ZERO = 13MAR2020;
