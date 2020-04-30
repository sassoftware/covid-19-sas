	/* PROC TMODEL SEIR APPROACH - WITH OHIO FIT INTERVENE */
		/* these are the calculations for variables used from above:
X_IMPORT: parameters.sas
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 AND &HAVE_SASETS = YES AND %SYMEXIST(ISOChangeDate1) %THEN %DO;

X_IMPORT: fit_input.sas

			/* Fit Model with Proc (t)Model (SAS/ETS) */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA = STORE.FIT_INPUT OUTMODEL=SEIRMOD_I NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA = STORE.FIT_INPUT OUTMODEL=SEIRMOD_I NOPRINT; %END;
					/* Parameters of interest */
					PARMS R0 &R_T. I0 &I. RI -1 DI &ISOChangeDate1.;
					BOUNDS 1 <= R0 <= 13;
					RESTRICT RI + R0 > 0;
					/* Fixed values */
					N = &Population.;
					INF = &RecoveryDays.;
					SIGMAINV = &SIGMAINV.;
					STEP = CDF('NORMAL',DATE, DI, 1);
					/* Differential equations */
					GAMMA = 1 / INF;
					BETA = (R0 + RI*STEP) * GAMMA / N;
					/* Differential equations */
					/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
					DERT.S_N = -BETA * S_N * I_N;
					/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
					DERT.E_N = BETA * S_N * I_N - SIGMAINV * E_N;
					/* c. inflow from b. - outflow through recovery or death during illness*/
					DERT.I_N = SIGMAINV * E_N - GAMMA * I_N;
					/* d. Recovered and death humans through "promotion" inflow from c.*/
					DERT.R_N = GAMMA * I_N;
					CUMULATIVE_CASE_COUNT = I_N + R_N;
					/* Fit the data */
					FIT CUMULATIVE_CASE_COUNT INIT=(S_N=&Population. E_N=0 I_N=I0 R_N=0) / TIME=TIME DYNAMIC OUTPREDICT OUTACTUAL OUT=FIT_PRED LTEBOUND=1E-10 OUTEST=FIT_PARMS
						%IF &HAVE_V151. = YES %THEN %DO; OPTIMIZER=ORMP(OPTTOL=1E-5) %END;;
					OUTVARS S_N E_N I_N R_N;
				QUIT;

			/* Prepare output: fit data and parameter data */
				DATA FIT_PRED;
					SET FIT_PRED;
					LABEL CUMULATIVE_CASE_COUNT='Cumulative Incidence';
					FORMAT ModelType $30. DATE DATE9.; 
					DATE = &FIRST_CASE. + TIME - 1;
					ModelType="SEIR with PROC (T)MODEL-Fit R0";
X_IMPORT: keys.sas
				run;
				DATA FIT_PARMS;
					SET FIT_PARMS;
					FORMAT ModelType $30.; 
					ModelType="SEIR with PROC (T)MODEL-Fit R0";
X_IMPORT: keys.sas
				run;

			/*Capture basline R0, date of Intervention effect, R0 after intervention*/
				PROC SQL NOPRINT;
					SELECT R0 INTO :R0_FIT FROM FIT_PARMS;
					SELECT "'"||PUT(DI,DATE9.)||"'"||"D" INTO :CURVEBEND1 FROM FIT_PARMS;
					SELECT SUM(R0,RI) INTO :R0_BEND_FIT FROM FIT_PARMS;
				QUIT;

			/*Calculate observed social distancing (and other interventions) percentage*/
				%LET SOC_DIST_FIT = %SYSEVALF(1 - &R0_BEND_FIT / &R0_FIT);

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
/*PARMS N &Population. R0 &R0_FIT. R0_c1 &R0_BEND_FIT. R0_c2 &R_T_Change_Two. R0_c3 &R_T_Change_3. R0_c4 &R_T_Change_4.; */
/*BOUNDS 1 <= R0 <= 13;*/
/*RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0, R0_c3 > 0, R0_c4 > 0;*/
/*GAMMA = &GAMMA.;*/
/*SIGMAINV = &SIGMAINV.;*/
/*change_0 = (TIME < (&CURVEBEND1. - &DAY_ZERO.));*/
/*change_1 = ((TIME >= (&CURVEBEND1. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));  */
/*change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));*/
/*change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));*/
/*change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         */
/*BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N + change_3*R0_c3*GAMMA/N + change_4*R0_c4*GAMMA/N;*/
					/* PARAMETER SETTINGS */ 
					/* this parameterization assumes: &CURVEBEND1 happens before ISOChangeDate1 - it works if this is not true but does not apply SocialDistancingChange1 to the period between */
					%LET jmax = %SYSFUNC(countw(&SocialDistancingChange.,:));
					PARMS N &Population. R0 &R0_FIT R0_c1f &R0_BEND_FIT %DO j = 1 %TO &jmax.; R0_c&j &&R_T_Change&j %END;;
					BOUNDS 1 <= R0 <= 13;
					RESTRICT R0 > 0, R0_c1f > 0 %DO j = 1 %TO &jmax; , R0_c&j > 0 %END;;
					GAMMA = &GAMMA.;
					SIGMAINV = &SIGMAINV.;
					change_0 = (TIME < (&CURVEBEND1 - &DAY_ZERO));
					change_1f = ((TIME >= (&CURVEBEND1. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate1 - &DAY_ZERO.)));
						%DO j = 1 %TO &jmax - 1;
							%let j2 = %eval(&j + 1);
							change_&j = ((TIME >= (&&ISOChangeDate&j - &DAY_ZERO.)) & (TIME < (&&ISOChangeDate&j2 - &DAY_ZERO.)));
						%END;
						change_&jmax = (TIME >= (&&ISOChangeDate&jmax - &DAY_ZERO));
					BETA = change_0*R0*GAMMA/N + change_1f*R0_c1f*GAMMA/N %DO j = 1 %TO &jmax; + change_&j*R0_c&j*GAMMA/N %END;; 
					/* DIFFERENTIAL EQUATIONS */ 
					/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
					DERT.S_N = -BETA*S_N*I_N;
					/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
					DERT.E_N = BETA*S_N*I_N - SIGMAINV*E_N;
					/* c. inflow from b. - outflow through recovery or death during illness*/
					DERT.I_N = SIGMAINV*E_N - GAMMA*I_N;
					/* d. Recovered and death humans through "promotion" inflow from c.*/
					DERT.R_N = GAMMA*I_N;           
					/* SOLVE THE EQUATIONS */ 
					SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR_FIT_I;
				RUN;
				QUIT;

				DATA TMODEL_SEIR_FIT_I;
					FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;
					ModelType="SEIR with PROC (T)MODEL-Fit R0";
					ScenarioName="&Scenario.";
X_IMPORT: keys.sas
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
					drop table SEIRMOD_I;
				QUIT;

		%END;

		%IF &PLOTS. = YES AND &HAVE_SASETS = YES AND %SYMEXIST(ISOChangeDate1) %THEN %DO;

			%IF &ScenarioExist ~= 0 %THEN %DO;
				/* this is only needed to define macro varibles if the fit is being recalled.  
					If it is being run above these will already be defined */
					/*Capture basline R0, date of Intervention effect, R0 after intervention*/
						PROC SQL NOPRINT;
							SELECT R0 INTO :R0_FIT FROM FIT_PARMS;
							SELECT "'"||PUT(DI,DATE9.)||"'"||"D" INTO :CURVEBEND1 FROM FIT_PARMS;
							SELECT SUM(R0,RI) INTO :R0_BEND_FIT FROM FIT_PARMS;
						QUIT;

					/*Calculate observed social distancing (and other interventions) percentage*/
						%LET SOC_DIST_FIT = %SYSEVALF(1 - &R0_BEND_FIT / &R0_FIT);
			%END;

			/* Plot Fit of Actual v. Predicted */
			PROC SGPLOT DATA=work.FIT_PRED;
				WHERE _TYPE_  NE 'RESIDUAL' and ModelType='SEIR with PROC (T)MODEL-Fit R0' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Actual v. Predicted Infections in Region";
				TITLE2 "Initial R0: %SYSFUNC(round(&R0_FIT.,.01))";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
				SERIES X=DATE Y=CUMULATIVE_CASE_COUNT / LINEATTRS=(THICKNESS=2) GROUP=_TYPE_  MARKERS NAME="cases";
				FORMAT CUMULATIVE_CASE_COUNT COMMA10.;
			RUN;
			TITLE;TITLE2;TITLE3;

			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='SEIR with PROC (T)MODEL-Fit R0' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach";
				TITLE2 "Scenario: &Scenario., Initial Observed R0: %SYSFUNC(round(&R0_FIT.,.01))";
				TITLE3 "Adjusted Observed R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Observed Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
				TITLE4 "&sdchangetitle.";
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
