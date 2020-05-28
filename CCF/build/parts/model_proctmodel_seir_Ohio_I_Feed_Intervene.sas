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
                    S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
                    E_N = &E.;
                    I_N = &I. / &DiagnosedRate.;
                    R_N = &InitRecovered.;
                    /* prevent range below zero on each loop */
                    DO SIGMAfraction = 0.8 TO 1.2 BY 0.1;
					SIGMAINV = 1/(SIGMAfraction*&SIGMA.);
					SIGMAfraction = round(SIGMAfraction,.00001);
					DO RECOVERYDAYSfraction = 0.8 TO 1.2 BY 0.1;
                    RECOVERYDAYS = RECOVERYDAYSfraction * &RecoveryDays;
					RECOVERYDAYSfraction = round(RECOVERYDAYSfraction,.00001);
                        DO SOCIALDfraction = -.1 TO .1 BY 0.025;
						SOCIALD = SOCIALDfraction + &SocialDistancing;
						SOCIALDfraction = round(SOCIALDfraction,.00001);
						IF SOCIALD >=0 and SOCIALD<=1 THEN DO; 
                                GAMMA = 1 / RECOVERYDAYS;
								BETA = (&R0_FIT * GAMMA / &Population);
								/* relative change to BETA at CURVEBEND1 - amount of BETA removed */
								BETAChange1 = ((&R0_FIT - &R0_BEND_FIT) * GAMMA / &Population);
								SocialDistancing = 0;
                                DO TIME = 0 TO &N_DAYS. by 1;
									IF &DAY_ZERO + TIME > &CURVEBEND1 THEN SocialDistancing = &SOC_DIST_FIT;
                                    OUTPUT; 
                                END;
                            END;
                        END;
						END;
					END; 
				RUN;

			/* Create SEIR Projections based R0 and first social distancing change from model fit above, plus additional change points */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA=DINIT NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA=DINIT NOPRINT; %END;
					/* construct BETA with additive changes */
						BETAv = BETA - (&DAY_ZERO + TIME > &CURVEBEND1) * BETAChange1;
					/* DIFFERENTIAL EQUATIONS */ 
					/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
					DERT.S_N = -BETAv*S_N*I_N;
					/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
					DERT.E_N = BETAv*S_N*I_N - SIGMAINV*E_N;
					/* c. inflow from b. - outflow through recovery or death during illness*/
					DERT.I_N = SIGMAINV*E_N - GAMMA*I_N;
					/* d. Recovered and death humans through "promotion" inflow from c.*/
					DERT.R_N = GAMMA*I_N;           
					/* SOLVE THE EQUATIONS */ 
					SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR_SIM_FIT_I;
					by SIGMAfraction RECOVERYDAYSfraction SOCIALDfraction;
					id TIME SocialDistancing BETAv;
				RUN;
				QUIT;

				DATA TMODEL_SEIR_SIM_FIT_I;
					FORMAT ModelType $30. DATE ADMIT_DATE DATE9.;
					ModelType="SEIR with PROC (T)MODEL-Fit R0";
X_IMPORT: keys.sas
					RETAIN counter cumulative_sum_fatality cumulative_Sum_Market_Fatality;
					SET TMODEL_SEIR_SIM_FIT_I(RENAME=(TIME=DAY BETAv=BETA) DROP=_ERRORS_ _MODE_ _TYPE_ BETA);
					DAY = round(DAY,1);
					*WHERE SIGMAfraction=1 and RECOVERYDAYSfraction=1 and SOCIALDfraction=0;
					BY SIGMAfraction RECOVERYDAYSfraction SOCIALDfraction;
						IF first.SOCIALDfraction THEN counter = 1;
						ELSE counter + 1;
X_IMPORT: postprocess.sas
					DROP CUM: counter SIGMAINV GAMMA BETAChange:;
				RUN;

				DATA TMODEL_SEIR_FIT_I; 
					SET TMODEL_SEIR_SIM_FIT_I;
					WHERE SIGMAfraction=1 and RECOVERYDAYSfraction=1 and SOCIALDfraction=0;
					DROP SIGMAfraction RECOVERYDAYSfraction SOCIALDfraction;
				RUN;

				PROC SQL noprint;
					create table TMODEL_SEIR_FIT_I as
						select * from
							(select * from work.TMODEL_SEIR_FIT_I) B 
							left join
							(select min(HOSPITAL_OCCUPANCY) as LOWER_HOSPITAL_OCCUPANCY, 
									min(ICU_OCCUPANCY) as LOWER_ICU_OCCUPANCY, 
									min(VENT_OCCUPANCY) as LOWER_VENT_OCCUPANCY, 
									min(ECMO_OCCUPANCY) as LOWER_ECMO_OCCUPANCY, 
									min(DIAL_OCCUPANCY) as LOWER_DIAL_OCCUPANCY,
									max(HOSPITAL_OCCUPANCY) as UPPER_HOSPITAL_OCCUPANCY, 
									max(ICU_OCCUPANCY) as UPPER_ICU_OCCUPANCY, 
									max(VENT_OCCUPANCY) as UPPER_VENT_OCCUPANCY, 
									max(ECMO_OCCUPANCY) as UPPER_ECMO_OCCUPANCY, 
									max(DIAL_OCCUPANCY) as UPPER_DIAL_OCCUPANCY,
									Date, ModelType, ScenarioIndex
								from TMODEL_SEIR_SIM_FIT_I
								group by Date, ModelType, ScenarioIndex
							) U 
							on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
						order by ScenarioIndex, ModelType, Date
					;
					drop table TMODEL_SEIR_SIM_FIT_I;
				QUIT;

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

			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='SEIR with PROC (T)MODEL-Fit R0' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach With Uncertainty Bounds";
				TITLE2 "Scenario: &Scenario., Initial Observed R0: %SYSFUNC(round(&R0_FIT.,.01))";
				TITLE3 "Adjusted Observed R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Observed Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
				TITLE4 "&sdchangetitle.";
				
                BAND x=DATE lower=LOWER_HOSPITAL_OCCUPANCY upper=UPPER_HOSPITAL_OCCUPANCY / fillattrs=(color=blue transparency=.8) name="b1";
                BAND x=DATE lower=LOWER_ICU_OCCUPANCY upper=UPPER_ICU_OCCUPANCY / fillattrs=(color=red transparency=.8) name="b2";
                BAND x=DATE lower=LOWER_VENT_OCCUPANCY upper=UPPER_VENT_OCCUPANCY / fillattrs=(color=green transparency=.8) name="b3";
                BAND x=DATE lower=LOWER_ECMO_OCCUPANCY upper=UPPER_ECMO_OCCUPANCY / fillattrs=(color=brown transparency=.8) name="b4";
                BAND x=DATE lower=LOWER_DIAL_OCCUPANCY upper=UPPER_DIAL_OCCUPANCY / fillattrs=(color=purple transparency=.8) name="b5";
                SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(color=blue THICKNESS=2) name="l1";
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(color=red THICKNESS=2) name="l2";
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(color=green THICKNESS=2) name="l3";
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(color=brown THICKNESS=2) name="l4";
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(color=purple THICKNESS=2) name="l5";
                keylegend "l1" "l2" "l3" "l4" "l5";
                
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4;

		%END;
