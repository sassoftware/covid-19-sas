
/* SAS Program COVID_19 
Cleveland Clinic and SAS Collaboarion

These models are only as good as their inputs. Input values for this type of model are very dynamic and may need to be evaluated across wide ranges and reevaluated as the epidemic progresses.  This work is currently defaulting to values for the population studied in the Cleveland Clinic and SAS collaboration.  You need to evaluate each parameter for your population of interest.

SAS and Cleveland Clinic are not responsible for any misuse of these techniques.
*/

/* directory path for files: COVID_19.sas (this file), libname store */
%let homedir = /Local_Files/covid;

/* the storage location for the MODEL_FINAL table and the SCENARIOS table */
libname store "&homedir.";

/* Depending on which SAS products you have and which releases you have these options will turn components of this code on/off */
%LET HAVE_SASETS = YES; /* YES implies you have SAS/ETS software, this enable the PROC MODEL methods in this code.  Without this the Data Step SIR model still runs */
%LET HAVE_V151 = NO; /* YES implies you have products verison 15.1 (latest) and switches PROC MODEL to PROC TMODEL for faster execution */


%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,KnownCOVID,SocialDistancing,ISOChangeDate,SocialDistancingChange,ISOChangeDateTwo,SocialDistancingChangeTwo,MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate,plots=no);


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
	%LET S_DEFAULT = &Population.;
	%LET KNOWN_INFECTIONS = &KnownCOVID.;
	%LET KNOWN_CASES = &KnownAdmits.;
	/*Doubling time before social distancing (days)*/
	%LET DOUBLING_TIME = &doublingtime.;
	/*Initial Number of Exposed (infected but not yet infectious)*/
	%LET E = 0;
	/*Initial Number of Recovered*/
	%LET R = &InitRecovered.;
	%LET RECOVERY_DAYS = &RecoveryDays.;
	/*Baseline Social distancing (% reduction in social contact)*/
	%LET RELATIVE_CONTACT_RATE = &SocialDistancing.;
	/*Hospital Market Share (%)*/
	%LET MARKET_SHARE = &MarketSharePercent.;
	%LET ADMISSION_RATE= &Admission_Rate.;
	/*factor to adjust %admission to make sense multiplied by Total I*/
	%LET DIAGNOSED_RATE=1.0; 
	/*ICU %(total infections)*/
	%LET ICU_RATE = %SYSEVALF(&ICUPercent.*&DIAGNOSED_RATE);
	/*Ventilated %(total infections)*/
	%LET VENT_RATE = %SYSEVALF(&VentPErcent.*&DIAGNOSED_RATE);
	%Let Fatality_rate = &fatalityrate;
	/*Average number of days from infection to hospitalization*/
	%LET DAYS_TO_HOSP = 0;
	/*Isolation Changes*/
	%Let ISO_Change_Date = &ISOChangeDate.;
	%LET RELATIVE_CONTACT_RATE_Change = &SocialDistancingChange.;
	%Let ISO_Change_Date_Two = &ISOChangeDateTwo.;
	%LET RELATIVE_CONTACT_RATE_Change_Two = &SocialDistancingChangeTwo.;


	/*Parameters assumed to be constant across scenarios*/
	/*Currently Hospitalized COVID-19 Patients*/
	%LET CURRENT_HOSP = &KNOWN_CASES;
	/*Hospitalization %(total infections)*/
	%LET HOSP_RATE = %SYSEVALF(&ADMISSION_RATE*&DIAGNOSED_RATE);
	/*Hospital Length of Stay*/
	%LET HOSP_LOS = 7;
	/*ICU Length of Stay*/
	%LET ICU_LOS = 9;
	/*Vent Length of Stay*/
	%LET VENT_LOS = 10;
	/*default percent of total admissions that need ECMO*/
	%LET ECMO_RATE=0.03; 
	%LET ECMO_LOS=6;
	/*default percent of admissions that need Dialysis*/
	%LET DIAL_RATE=0.05;
	%LET DIAL_LOS=11;
	%LET DEATH_RATE=0.00;
	/*rate of latent individuals Exposed transported to the infectious stage each time period*/
	%LET SIGMA = 0.90;
	/*Days to project*/
	%LET N_DAYS = 365;
	%LET BETA_DECAY = 0.0;
	/*Date of first COVID-19 Case*/
	%LET DAY_ZERO = 13MAR2020;


	/*Parameters derived from other inputs*/
	/*Regional Population*/
	%LET S = &S_DEFAULT;
	/*Currently Known Regional Infections (only used to compute detection rate - does not change projections*/
	%LET INITIAL_INFECTIONS = &KNOWN_INFECTIONS;
	%LET TOTAL_INFECTIONS = %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE);
	%LET DETECTION_PROB = %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS);
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


	/*DATA FOR PROC TMODEL APPROACHES*/
	DATA DINIT(Label="Initial Conditions of Simulation"); 
			DO TIME = 0 TO &N_DAYS; 
			S_N = &S. - (&I/&DIAGNOSED_RATE) - &R;
			E_N = &E;
			I_N = &I/&DIAGNOSED_RATE;
			R_N = &R;
			R0  = &R_T;
			IF TIME >= (&ISO_Change_Date - "&DAY_ZERO"D) then R0  = &R_T_Change;
			IF TIME >= (&ISO_Change_Date_Two - "&DAY_ZERO"D) then R0  = &R_T_Change_Two;
			OUTPUT; 
		END; 
	RUN;

    /* create an index, ScenarioIndex for this run by incrementing the max value of ScenarioIndex in SCENARIOS dataset */
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
                            where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT')
                            group by ScenarioIndex) t1
                        join
                        (select * from store.SCENARIOS
                            where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT')) t2
                        on t1.name=t2.name and t1.value=t2.value
                    group by t1.ScenarioIndex, t2.ScenarioIndex, t1.cnt
                    having count(*) = t1.cnt)
            ; 
        QUIT;
    %END; 
    %ELSE %DO; 
        %LET ScenarioExist = 0;
    %END;
    %IF &ScenarioExist = 0 %THEN %DO;
        PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex from work.parms; QUIT;
        PROC APPEND base=store.SCENARIOS data=PARMS; run;
    %END;
    %ELSE %DO;
        PROC SQL; drop table DINIT; QUIT;
    %END;
    PROC SQL; drop table PARMS; QUIT;
    /* If this is a new scenario then run it */
    %IF &ScenarioExist = 0 %THEN %DO;


	/*PROC TMODEL SEIR APPROACH*/
		%IF &HAVE_SASETS = YES %THEN %DO;
			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
				PARMS N &S. R0 &R_T. ; 
				GAMMA = &GAMMA.;
				SIGMA = &SIGMA;
				BETA = R0*GAMMA/N;
				/* DIFFERENTIAL EQUATIONS */ 
				/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
				DERT.S_N = -BETA*S_N*I_N;
				/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
				DERT.E_N = BETA*S_N*I_N-SIGMA*E_N;
				/* c. inflow from b. - outflow through recovery or death during illness*/
				DERT.I_N = SIGMA*E_N-GAMMA*I_N;
				/* d. Recovered and death humans through "promotion" inflow from c.*/
				DERT.R_N = GAMMA*I_N;           
				/* SOLVE THE EQUATIONS */ 
				SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR; 
			RUN;
			QUIT;

			DATA TMODEL_SEIR;
				FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
				ModelType="TMODEL - SEIR";
				ScenarioName="&Scenario";
				ScenarioIndex=&ScenarioIndex.;
				ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
				LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
					ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
				RETAIN LAG_S LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
					CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
				LAG_S = S_N; 
				LAG_E = E_N; 
				LAG_I = I_N; 
				LAG_R = R_N; 
				LAG_N = N; 
				SET TMODEL_SEIR(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				N = SUM(S_N, E_N, I_N, R_N);
				SCALE = LAG_N / N;
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
				ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				DROP LAG: CUM: ;
			RUN;
			%IF &PLOTS. = YES %THEN %DO;
				PROC SGPLOT DATA=TMODEL_SEIR;
					where ModelType='TMODEL - SEIR' and ScenarioIndex=&ScenarioIndex.;
					TITLE "Daily Occupancy - PROC TMODEL SEIR Approach";
					TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
					TITLE3 "Adjusted R0 after &ISOChangeDate: %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
					TITLE4 "Adjusted R0 after &ISOChangeDateTwo: %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
					SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					XAXIS LABEL="Date";
					YAXIS LABEL="Daily Occupancy";
				RUN;
				TITLE; TITLE2; TITLE3; TITLE4;
			%END;
			PROC APPEND base=store.MODEL_FINAL data=TMODEL_SEIR; run;
			PROC SQL; drop table TMODEL_SEIR; QUIT;
		%END;

	/*PROC TMODEL SIR APPROACH*/
		%IF &HAVE_SASETS = YES %THEN %DO;
			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
				PARMS N &S. R0 &R_T. ; 
				GAMMA = &GAMMA.;    	         
				BETA = R0*GAMMA/N;
				/* DIFFERENTIAL EQUATIONS */ 
				DERT.S_N = -BETA*S_N*I_N; 				
				DERT.I_N = BETA*S_N*I_N-GAMMA*I_N;   
				DERT.R_N = GAMMA*I_N;           
				/* SOLVE THE EQUATIONS */ 
				SOLVE S_N I_N R_N / OUT = TMODEL_SIR; 
			RUN;
			QUIT;

			DATA TMODEL_SIR;
				FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;	
				ModelType="TMODEL - SIR";
				ScenarioName="&Scenario";
				ScenarioIndex=&ScenarioIndex.;
				ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
				LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
					ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
				RETAIN LAG_S LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
					CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
				E_N = &E;
				LAG_S = S_N; 
				LAG_E = E_N; 
				LAG_I = I_N; 
				LAG_R = R_N; 
				LAG_N = N; 
				SET TMODEL_SIR(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				N = SUM(S_N, E_N, I_N, R_N);
				SCALE = LAG_N / N;
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
				ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				DROP LAG: CUM:;
			RUN;
			%IF &PLOTS. = YES %THEN %DO;
				PROC SGPLOT DATA=TMODEL_SIR;
					where ModelType='TMODEL - SIR' and ScenarioIndex=&ScenarioIndex.;
					TITLE "Daily Occupancy - PROC TMODEL SIR Approach";
					TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
					TITLE3 "Adjusted R0 after &ISOChangeDate: %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
					TITLE4 "Adjusted R0 after &ISOChangeDateTwo: %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
					SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
					XAXIS LABEL="Date";
					YAXIS LABEL="Daily Occupancy";
				RUN;
				TITLE; TITLE2; TITLE3; TITLE4;
			%END;
			PROC APPEND base=store.MODEL_FINAL data=TMODEL_SIR NOWARN FORCE; run;
			PROC SQL; drop table TMODEL_SIR; QUIT;
		%END;

	/* DATA STEP APPROACH FOR SIR */
		DATA DS_SIR;
			FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;		
			ModelType="DS - SIR";
			ScenarioName="&Scenario";
			ScenarioIndex=&ScenarioIndex.;
			ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
			LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
				ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
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
				E_N = &E;
				LAG_S = S_N;
				LAG_E = E_N;
				LAG_I = I_N;
				LAG_R = R_N;
				LAG_N = N;

				IF date = &ISO_Change_Date THEN BETA = &BETA_Change;
				ELSE IF date = &ISO_Change_Date_Two THEN BETA = &BETA_Change_Two;
	
				LAG_BETA = BETA;
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
				Market_MedSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
				DATE = "&DAY_ZERO"D + DAY;
				ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				OUTPUT;
			END;
			DROP LAG: /*BETA*/ CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=DS_SIR;
				where ModelType='DS - SIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
				TITLE3 "Adjusted R0 after &ISOChangeDate: %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
				TITLE4 "Adjusted R0 after &ISOChangeDateTwo: %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4;
		%END;
		PROC APPEND base=store.MODEL_FINAL data=DS_SIR NOWARN FORCE; run;
		PROC SQL; drop table DS_SIR; QUIT;

	/* DATA STEP APPROACH FOR SEIR */
		DATA DS_SEIR;
			FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;		
			ModelType="DS - SEIR";
			ScenarioName="&Scenario";
			ScenarioIndex=&ScenarioIndex.;
			ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
			LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
				ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
			DO DAY = 0 TO &N_DAYS;
				IF DAY = 0 THEN DO;
					S_N = &S - (&I/&DIAGNOSED_RATE) - &R;
					E_N = &E;
					I_N = &I/&DIAGNOSED_RATE;
					R_N = &R;
					BETA=&BETA;
					N = SUM(S_N, E_N, I_N, R_N);
				END;
				ELSE DO;
					BETA = LAG_BETA * (1- &BETA_DECAY);
					S_N = (-BETA * LAG_S * LAG_I) + LAG_S;
					E_N = (BETA * LAG_S * LAG_I) - &SIGMA * LAG_E + LAG_E;
					I_N = (&SIGMA * LAG_E - &GAMMA * LAG_I) + LAG_I;
					R_N = &GAMMA * LAG_I + LAG_R;
					N = SUM(S_N, E_N, I_N, R_N);
					SCALE = LAG_N / N;
					IF S_N < 0 THEN S_N = 0;
					IF E_N < 0 THEN E_N = 0;
					IF I_N < 0 THEN I_N = 0;
					IF R_N < 0 THEN R_N = 0;
					S_N = SCALE*S_N;
					E_N = SCALE*E_N;
					I_N = SCALE*I_N;
					R_N = SCALE*R_N;
				END;
				LAG_S = S_N;
				LAG_E = E_N;
				LAG_I = I_N;
				LAG_R = R_N;
				LAG_N = N;

				IF date = &ISO_Change_Date THEN BETA = &BETA_Change;
				ELSE IF date = &ISO_Change_Date_Two THEN BETA = &BETA_Change_Two;
	
				LAG_BETA = BETA;
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
				ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=DS_SEIR;
				where ModelType='DS - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
				TITLE3 "Adjusted R0 after &ISOChangeDate: %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
				TITLE4 "Adjusted R0 after &ISOChangeDateTwo: %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4;
		%END;
		PROC APPEND base=store.MODEL_FINAL data=DS_SEIR NOWARN FORCE; run;
		PROC SQL; drop table DS_SEIR; QUIT;
        PROC SQL; drop table DINIT; QUIT;

        %IF &PLOTS. = YES %THEN %DO;
            /* if multiple models for a single scenarioIndex then plot them */
            PROC SQL noprint;
                select count(*) into :scenplot from (select distinct ModelType from store.MODEL_FINAL where ScenarioIndex=&ScenarioIndex.);
            QUIT;
            %IF &scenplot > 1 %THEN %DO;
                PROC SGPLOT DATA=store.MODEL_FINAL;
                    where ScenarioIndex=&ScenarioIndex.;
                    TITLE "Daily Hospital Occupancy - All Approaches";
                    TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
                    TITLE3 "Adjusted R0 after &ISOChangeDate: %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
                    TITLE4 "Adjusted R0 after &ISOChangeDateTwo: %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
                    SERIES X=DATE Y=HOSPITAL_OCCUPANCY / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                    XAXIS LABEL="Date";
                    YAXIS LABEL="Daily Occupancy";
                RUN;
                TITLE; TITLE2; TITLE3; TITLE4;
            %END;	
        %END;

    %END;

%mend;
/*Test runs of EasyRun macro*/
%EasyRun(
scenario=Scenario_DrS_00_20_run_1,
IncubationPeriod=0,
InitRecovered=0,
RecoveryDays=14,
doublingtime=5,
KnownAdmits=10,
KnownCOVID=46,
Population=4390484,
SocialDistancing=0,
MarketSharePercent=0.29,
Admission_Rate=0.075,
ICUPercent=0.45,
VentPErcent=0.35,
ISOChangeDate='31MAR2020'd,
SocialDistancingChange=0,
ISOChangeDateTwo='06APR2020'd,
SocialDistancingChangeTwo=0.2,
plots=YES	
);
	
%EasyRun(
scenario=Scenario_DrS_00_40_run_1,
IncubationPeriod=0,
InitRecovered=0,
RecoveryDays=14,
doublingtime=5,
KnownAdmits=10,
KnownCOVID=46,
Population=4390484,
SocialDistancing=0,
MarketSharePercent=0.29,
Admission_Rate=0.075,
ICUPercent=0.45,
VentPErcent=0.35,
ISOChangeDate='31MAR2020'd,
SocialDistancingChange=0,
ISOChangeDateTwo='06APR2020'd,
SocialDistancingChangeTwo=0.4,
plots=YES	
);
	
%EasyRun(
scenario=Scenario_DrS_00_40_run_12,
IncubationPeriod=0,
InitRecovered=0,
RecoveryDays=14,
doublingtime=5,
KnownAdmits=10,
KnownCOVID=46,
Population=4390484,
SocialDistancing=0,
MarketSharePercent=0.29,
Admission_Rate=0.075,
ICUPercent=0.45,
VentPErcent=0.35,
ISOChangeDate='31MAY2020'd,
SocialDistancingChange=0.25,
ISOChangeDateTwo='06AUG2020'd,
SocialDistancingChangeTwo=0.5,
plots=YES	
);

/* Scenarios can be run in batch by specifying them in a sas dataset.
    In the example below, this dataset is created by reading scenarios from an csv file: run_scenarios.csv
    An example run_scenarios.csv file is provided with this code.

	You could also use other files as input sources.  For example, with an excel file you could use libname XLSX.
*/
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

%run_scenarios(run_scenarios.csv);
	/* use the &cexecute variable and the run_scenario dataset to run all the scenarios with call execute */
	data _null_;
		set run_scenarios;
		call execute(cats('%nrstr(%EasyRun(',&cexecute.,'));'));
	run;




/* uncomment the following section to load/replace the files in CAS - Viya based Visual Analytics, Visual Statistics, ... */
/*
CAS;

CASLIB _ALL_ ASSIGN;

PROC CASUTIL;
	DROPTABLE INCASLIB="CASUSER" CASDATA="PROJECT_DS" QUIET;
	LOAD DATA=store.MODEL_FINAL CASOUT="PROJECT_DS" OUTCASLIB="CASUSER" PROMOTE;
	DROPTABLE INCASLIB="CASUSER" CASDATA="PROJECT_SCENARIOS" QUIET;
	LOAD DATA=store.SCENARIOS CASOUT="PROJECT_SCENARIOS" OUTCASLIB="CASUSER" PROMOTE;
QUIT;

CAS CASAUTO TERMINATE;
*/