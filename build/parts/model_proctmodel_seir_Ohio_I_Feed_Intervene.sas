	/* PROC TMODEL SEIR APPROACH - WITH OHIO FIT INTERVENE */
		/* these are the calculations for variables used from above:
X_IMPORT: parameters.sas
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 AND &HAVE_SASETS = YES %THEN %DO;
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
					%IF &LATEST_CASE. < %eval(%sysfunc(today())-2) %THEN %DO;
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
							%IF &countnum. > 0 %THEN %DO;
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
								DO DATE = &FIRST_CASE. TO &LATEST_CASE.;
									TIME = DATE - &FIRST_CASE. + 1;
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
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD_I NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD_I NOPRINT; %END;
					/* Parameters of interest */
					PARMS R0 &R_T. I0 &I. RI -1 DI &ISOChangeDate.;
					BOUNDS 1 <= R0 <= 13;
					RESTRICT RI + R0 > 0;
					/* Fixed values */
					N = &Population.;
					INF = &RecoveryDays.;
					SIGMA = &SIGMA.;
					STEP = CDF('NORMAL',DATE, DI, 1);
					/* Differential equations */
					GAMMA = 1 / INF;
					BETA = (R0 + RI*STEP) * GAMMA / N;
					/* Differential equations */
					/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
					DERT.S_N = -BETA * S_N * I_N;
					/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
					DERT.E_N = BETA * S_N * I_N - SIGMA * E_N;
					/* c. inflow from b. - outflow through recovery or death during illness*/
					DERT.I_N = SIGMA * E_N - GAMMA * I_N;
					/* d. Recovered and death humans through "promotion" inflow from c.*/
					DERT.R_N = GAMMA * I_N;
					CUMULATIVE_CASE_COUNT = I_N + R_N;
					/* Fit the data */
					FIT CUMULATIVE_CASE_COUNT INIT=(S_N=&Population. E_N=0 I_N=I0 R_N=0) / TIME=TIME DYNAMIC OUTPREDICT OUTACTUAL OUT=EPIPRED_I LTEBOUND=1E-10 OUTEST=PARAMS
						%IF &HAVE_V151. = YES %THEN %DO; OPTIMIZER=ORMP(OPTTOL=1E-5) %END;;
					OUTVARS S_N E_N I_N R_N;
				QUIT;

				/*Capture basline R0, date of Intervention effect, R0 after intervention*/
				PROC SQL NOPRINT;
					SELECT R0 INTO :R0_FIT FROM PARAMS;
					SELECT "'"||PUT(DI,DATE9.)||"'"||"D" INTO :CURVEBEND1 FROM PARAMS;
					SELECT SUM(R0,RI) INTO :R0_BEND_FIT FROM PARAMS;
				QUIT;

				/*Calculate observed social distancing (and other interventions) percentage*/
				%LET SOC_DIST_FIT = %SYSEVALF(1 - &R0_BEND_FIT / &R0_FIT);

				%IF &PLOTS. = YES %THEN %DO;
					/* Plot Fit of Actual v. Predicted */
					DATA EPIPRED_I;
						SET EPIPRED_I;
						LABEL CUMULATIVE_CASE_COUNT='Cumulative Incidence';
						FORMAT DATE DATE9.; 
						DATE = &FIRST_CASE. + TIME -1;
					run;
					PROC SGPLOT DATA=EPIPRED_I;
						WHERE _TYPE_  NE 'RESIDUAL';
						TITLE "Actual v. Predicted Infections in Region";
						TITLE2 "Initial R0: %SYSFUNC(round(&R0_FIT.,.01))";
						TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
						SERIES X=DATE Y=CUMULATIVE_CASE_COUNT / LINEATTRS=(THICKNESS=2) GROUP=_TYPE_  MARKERS NAME="cases";
						FORMAT CUMULATIVE_CASE_COUNT COMMA10.;
					RUN;
					TITLE;TITLE2;TITLE3;
				%END;

			/* DATA FOR PROC TMODEL APPROACHES */
				DATA DINIT(Label="Initial Conditions of Simulation"); 
					FORMAT DATE DATE9.; 
					DO TIME = 0 TO &N_DAYS.; 
						S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
						E_N = &E.;
						I_N = &I. / &DiagnosedRate.;
						R_N = &InitRecovered.;
						R0  = &R_T.;
						DATE = &DAY_ZERO. + TIME;
						OUTPUT; 
					END; 
				RUN;

			/* Create SEIR Projections based R0 and first social distancing change from model fit above, plus additional change points */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA=DINIT NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA=DINIT NOPRINT; %END;
					/* PARAMETER SETTINGS */ 
					PARMS N &Population. R0 &R0_FIT. R0_c1 &R0_BEND_FIT. R0_c2 &R_T_Change_Two. R0_c3 &R_T_Change_3. R0_c4 &R_T_Change_4.; 
					BOUNDS 1 <= R0 <= 13;
					RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0, R0_c3 > 0, R0_c4 > 0;
					GAMMA = &GAMMA.;
					SIGMA = &SIGMA.;
					change_0 = (TIME < (&CURVEBEND1. - &DAY_ZERO.));
					change_1 = ((TIME >= (&CURVEBEND1. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));  
					change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));
					change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));
					change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         
					BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N + change_3*R0_c3*GAMMA/N + change_4*R0_c4*GAMMA/N;
					/* DIFFERENTIAL EQUATIONS */ 
					/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
					DERT.S_N = -BETA*S_N*I_N;
					/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
					DERT.E_N = BETA*S_N*I_N - SIGMA*E_N;
					/* c. inflow from b. - outflow through recovery or death during illness*/
					DERT.I_N = SIGMA*E_N - GAMMA*I_N;
					/* d. Recovered and death humans through "promotion" inflow from c.*/
					DERT.R_N = GAMMA*I_N;           
					/* SOLVE THE EQUATIONS */ 
					SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR_FIT_I;
				RUN;
				QUIT;

				DATA TMODEL_SEIR_FIT_I;
					FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
					ModelType="TMODEL - SEIR - OHIO FIT INTER";
					ScenarioName="&Scenario.";
					ScenarioIndex=&ScenarioIndex.;
					ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
					LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
						ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
					RETAIN LAG_S LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
						CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
					LAG_S = S_N; 
					LAG_E = E_N; 
					LAG_I = I_N; 
					LAG_R = R_N; 
					LAG_N = N; 
					SET TMODEL_SEIR_FIT_I(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
					N = SUM(S_N, E_N, I_N, R_N);
					SCALE = LAG_N / N;
X_IMPORT: postprocess.sas
					DROP LAG: CUM: ;
				RUN;

				PROC APPEND base=work.MODEL_FINAL data=TMODEL_SEIR_FIT_I NOWARN FORCE; run;
				PROC SQL; 
					drop table TMODEL_SEIR_FIT_I;
					drop table DINIT;
					drop table EPIPRED_I;
					drop table SEIRMOD_I;
					drop table PARAMS;
				QUIT;

		%END;

		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='TMODEL - SEIR - OHIO FIT INTER' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach";
				TITLE2 "Scenario: &Scenario., Initial Observed R0: %SYSFUNC(round(&R0_FIT.,.01))";
				TITLE3 "Adjusted Observed R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Observed Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
				TITLE5 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate3., date10.), date9.): %SYSFUNC(round(&R_T_Change_3.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange3.*100)%";
				TITLE6 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate4., date10.), date9.): %SYSFUNC(round(&R_T_Change_4.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange4.*100)%";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;
		%END;
