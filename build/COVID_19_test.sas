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
    /* descriptions for the input fields of this macro:
        Scenario - Scenario Name to be stored as a character variable, combined with automatically-generated ScenarioIndex to create a unique ID
        IncubationPeriod - Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right
        InitRecovered - Initial number of Recovered patients, assumed to have immunity to future infection
        RecoveryDays - Number of days a patient is considered infectious (the amount of time it takes to recover or die)
        doublingtime - Baseline Doubling Time without social distancing
        Population - Number of people in region of interest, assumed to be well mixed and independent of other populations
        KnownAdmits - Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections
        KnownCOVID - Number of known COVID-19 patients in the region at Day 0, not used in S(E)IR calculations
        SocialDistancing - Baseline Social distancing (% reduction in social contact compared to normal activity)
        ISOChangeDate - Date of first change from baseline in social distancing parameter
        SocialDistancingChange - Second value of social distancing (% reduction in social contact compared to normal activity)
        ISOChangeDateTwo - Date of second change in social distancing parameter
        SocialDistancingChangeTwo - Third value of social distancing (% reduction in social contact compared to normal activity)
        MarketSharePercent - Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest
        Admission_Rate - Percentage of Infected patients in the region who will be hospitalized
        ICUPercent - Percentage of hospitalized patients who will require ICU
        VentPErcent - Percentage of hospitalized patients who will require Ventilators
        FatalityRate - Percentage of hospitalized patients who will die
        plots - YES/NO display plots in output
    */


    /* create an index, ScenarioIndex for this run by incrementing the max value of ScenarioIndex in SCENARIOS dataset */
        %IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
            PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from store.scenarios; quit;
        %END;
        %ELSE %DO; %LET ScenarioIndex_Base = 0; %END;
    /* store all the macro variables that set up this scenario in PARMS dataset */
        DATA PARMS;
            set sashelp.vmacro(where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE') then delete;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
            STAGE='INPUT';
        RUN;

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

        DATA PARMS;
            set PARMS sashelp.vmacro(in=i where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE') then delete;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
            if i then STAGE='MODEL';
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
                            on t1.name=t2.name and t1.value=t2.value and t1.STAGE=t2.STAGE
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
        PROC SQL; drop table PARMS; QUIT;
    /* If this is a new scenario then run it */
    %IF &ScenarioExist = 0 %THEN %DO;

	/*PROC TMODEL SEIR APPROACH*/
		%IF &HAVE_SASETS = YES %THEN %DO;
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
			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
				PARMS N &S. R0 &R_T. R0_c1 &R_T_Change. R0_c2 &R_T_Change_Two.; 
				BOUNDS 1 <= R0 <= 13;
				RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0;
				GAMMA = &GAMMA.;
				SIGMA = &SIGMA;
				change_0 = (TIME < (&ISO_Change_Date - "&DAY_ZERO"D));
				change_1 = ((TIME >= (&ISO_Change_Date - "&DAY_ZERO"D)) & (TIME < (&ISO_Change_Date_Two - "&DAY_ZERO"D)));   
				change_2 = (TIME >= (&ISO_Change_Date_Two - "&DAY_ZERO"D)); 	         
				BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N;
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
					ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP LAG: CUM: ;
			RUN;
			%IF &PLOTS. = YES %THEN %DO;
				PROC SGPLOT DATA=TMODEL_SEIR;
					where ModelType='TMODEL - SEIR' and ScenarioIndex=&ScenarioIndex.;
					TITLE "Daily Occupancy - PROC TMODEL SEIR Approach";
					TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
					TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
					TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
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
			PROC SQL; drop table TMODEL_SEIR; drop table DINIT; QUIT;
		%END;

	/*PROC TMODEL SIR APPROACH*/
		%IF &HAVE_SASETS = YES %THEN %DO;
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
			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
				PARMS N &S. R0 &R_T. R0_c1 &R_T_Change. R0_c2 &R_T_Change_Two.;
				BOUNDS 1 <= R0 <= 13;
				RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0;
				GAMMA = &GAMMA.;
				change_0 = (TIME < (&ISO_Change_Date - "&DAY_ZERO"D));
				change_1 = ((TIME >= (&ISO_Change_Date - "&DAY_ZERO"D)) & (TIME < (&ISO_Change_Date_Two - "&DAY_ZERO"D)));   
				change_2 = (TIME >= (&ISO_Change_Date_Two - "&DAY_ZERO"D)); 	         
				BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N;
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
					ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP LAG: CUM:;
			RUN;
			%IF &PLOTS. = YES %THEN %DO;
				PROC SGPLOT DATA=TMODEL_SIR;
					where ModelType='TMODEL - SIR' and ScenarioIndex=&ScenarioIndex.;
					TITLE "Daily Occupancy - PROC TMODEL SIR Approach";
					TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
					TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
					TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
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
			PROC SQL; drop table TMODEL_SIR; drop table DINIT; QUIT;
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
					ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=DS_SIR;
				where ModelType='DS - SIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
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
	/* DATA STEP APPROACH FOR SIR - SIMULATION APPROACH TO BOUNDS*/
		DATA DS_SIR_SIM;
			FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;		
			ModelType="DS - SIR - SIM";
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
					ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;

		%END;
		PROC APPEND base=store.MODEL_FINAL_SIM data=DS_SIR_SIM NOWARN FORCE; run;
		PROC SQL; drop table DS_SIR_SIM; QUIT;
		
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
					ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=DS_SEIR;
				where ModelType='DS - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
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

	/* PROC TMODEL SEIR APPROACH - WITH OHIO FIT */
		%IF &HAVE_SASETS = YES %THEN %DO;
			/*DOWNLOAD CSV - only if STORE.OHIO_SUMMARY does not have data for yesterday */
				/* the file appears to be updated throughout the day but partial data for today could cause issues with fit */
				%IF %sysfunc(exist(STORE.OHIO_SUMMARY)) %THEN %DO;
					PROC SQL NOPRINT; 
						SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.OHIO_SUMMARY;
						SELECT MAX(DATE) into :LATEST_CASE FROM STORE.OHIO_SUMMARY; 
					QUIT;
				%END;
				%ELSE %DO;
					%LET LATEST_CASE=0;
				%END;
					%IF &LATEST_CASE < %eval(%sysfunc(today())-1) %THEN %DO;
						FILENAME OHIO URL "https://coronavirus.ohio.gov/static/COVIDSummaryData.csv";
						OPTION VALIDVARNAME=V7;
						PROC IMPORT file=OHIO OUT=WORK.OHIO_SUMMARY DBMS=CSV REPLACE;
							GETNAMES=YES;
							DATAROW=2;
							GUESSINGROWS=20000000;
						RUN; 
						/* check to make sure column 1 is county and not VAR1 - sometime the URL is pulled quickly and this gets mislabeled*/
							%let dsid=%sysfunc(open(WORK.OHIO_SUMMARY));
							%let countnum=%sysfunc(varnum(&dsid.,var1));
							%let rc=%sysfunc(close(&dsid.));
							%IF &countnum > 0 %THEN %DO;
								data WORK.OHIO_SUMMARY; set WORK.OHIO_SUMMARY; rename VAR1=COUNTY; run;
							%END;
						/* Prepare Ohio Data For Model - add rows for missing days (had no activity) */
							PROC SQL NOPRINT;
								CREATE TABLE STORE.OHIO_SUMMARY AS 
									SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
									FROM WORK.OHIO_SUMMARY
									WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
										'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
										'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
									GROUP BY CALCULATED DATE
									ORDER BY CALCULATED DATE;
								SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.OHIO_SUMMARY;
								SELECT MAX(DATE) INTO :LATEST_CASE FROM STORE.OHIO_SUMMARY;
								DROP TABLE WORK.OHIO_SUMMARY;
							QUIT;

							DATA ALLDATES;
								FORMAT DATE DATE9.;
								DO DATE = &FIRST_CASE TO &LATEST_CASE;
									TIME = DATE - &FIRST_CASE + 1;
									OUTPUT;
								END;
							RUN;

							DATA STORE.OHIO_SUMMARY;
								MERGE ALLDATES STORE.OHIO_SUMMARY;
								BY DATE;
								CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
							RUN;

							PROC SQL NOPRINT;
								drop table ALLDATES;
							QUIT; 
					%END;

			/* Fit Model with Proc (t)Model (SAS/ETS) */
				%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD NOPRINT; %END;
					/* Parameters of interest */
					PARMS R0 &R_T I0 &I;
					BOUNDS 1 <= R0 <= 13;
					/* Fixed values */
					N = &S;
					INF = &RECOVERY_DAYS;
					SIGMA=&SIGMA;
					/* Differential equations */
					GAMMA = 1/INF;
					BETA = R0*GAMMA/N;
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
					FIT CUMULATIVE_CASE_COUNT INIT=(S_N=&S E_N=0 I_N=I0 R_N=0) / TIME=TIME DYNAMIC OUTPREDICT OUTACTUAL OUT=EPIPRED LTEBOUND=1E-10
						%IF &HAVE_V151 = YES %THEN %DO; OPTIMIZER=ORMP(OPTTOL=1E-5) %END;;
					OUTVARS S_N E_N I_N R_N;
				QUIT;

				%IF &PLOTS. = YES %THEN %DO;
					/* Plot Fit of Actual v. Predicted */
					DATA EPIPRED;
						SET EPIPRED;
						LABEL CUMULATIVE_CASE_COUNT='Cumulative Incidence';
						FORMAT DATE DATE9.; 
						DATE = &FIRST_CASE + TIME -1;
					run;
					PROC SGPLOT DATA=EPIPRED;
						WHERE _TYPE_  NE 'RESIDUAL';
						TITLE "Actual v. Predicted Infections in Region";
						SERIES X=DATE Y=CUMULATIVE_CASE_COUNT / LINEATTRS=(THICKNESS=2) GROUP=_TYPE_  MARKERS NAME="cases";
						FORMAT CUMULATIVE_CASE_COUNT COMMA10.;
					RUN;
					TITLE;
				%END;

			/* DATA FOR PROC TMODEL APPROACHES */
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

			/* Create SEIR Projections based on model fit above */
				%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA=DINIT MODEL=SEIRMOD NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA=DINIT MODEL=SEIRMOD NOPRINT; %END;
					SOLVE CUMULATIVE_CASE_COUNT / TIME=TIME OUT=TMODEL_SEIR_FIT;
				QUIT;

				DATA TMODEL_SEIR_FIT;
					FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
					ModelType="TMODEL - SEIR - OHIO FIT";
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
					SET TMODEL_SEIR_FIT(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
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
					ADMIT_DATE = SUM(DATE, &DAYS_TO_HOSP.);
				/* END: Common Post-Processing Across each Model Type and Approach */
					DROP LAG: CUM: ;
				RUN;
				%IF &PLOTS. = YES %THEN %DO;
					PROC SGPLOT DATA=TMODEL_SEIR_FIT;
						where ModelType='TMODEL - SEIR - FIT' and ScenarioIndex=&ScenarioIndex.;
						TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach";
						TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
						TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
						TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
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
				PROC APPEND base=store.MODEL_FINAL data=TMODEL_SEIR_FIT NOWARN FORCE; run;
				PROC SQL; 
					drop table TMODEL_SEIR_FIT;
					drop table DINIT;
					drop table EPIPRED;
					drop table SEIRMOD;
				QUIT;
		%END;

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
                    TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
                    TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
                    SERIES X=DATE Y=HOSPITAL_OCCUPANCY / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                    XAXIS LABEL="Date";
                    YAXIS LABEL="Daily Occupancy";
                RUN;
                TITLE; TITLE2; TITLE3; TITLE4;
            %END;	
        %END;

    %END;

	/* use proc datasets to apply labels to each column of MODEL_FINAL and SCENARIOS
		optional for efficiency: check to see if this has already be done, if not do it
	*/
		PROC DATASETS LIB=STORE NOPRINT;
			MODIFY MODEL_FINAL;
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
					Deceased_Today = "New Hospital Mortality"
					Fatality = "New Hospital Mortality"
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
					ScenarionNameUnique = "Unique Scenario Name"
					Scenarioname = "Scenario Name"
					;
				MODIFY SCENARIOS;
				LABEL
					scope = "Source Macro for variable"
					name = "Name of the macro variable"
					offset = "Offset for long character macro variables (>200 characters)"
					value = "The value of macro variable name"
					ScenarioIndex = "Unique Scenario ID"
					Stage = "INPUT for input variables - MODEL for all variables"
					;
		RUN;
		QUIT;

		/*PROC CONTENTS DATA=STORE.MODEL_FINAL;*/
		/*RUN;*/

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
FatalityRate=,
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
FatalityRate=,
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
FatalityRate=,
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