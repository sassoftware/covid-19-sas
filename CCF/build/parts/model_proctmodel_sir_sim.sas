	/*PROC TMODEL SIR APPROACH*/
		/* these are the calculations for variables used from above:
X_IMPORT: parameters.sas
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 AND &HAVE_SASETS = YES %THEN %DO;
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation");  
                    S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
                    E_N = &E.;
                    I_N = &I. / &DiagnosedRate.;
                    R_N = &InitRecovered.;
                    *R0  = &R_T.;
                    /* prevent range below zero on each loop */
                        DO RECOVERYDAYSfraction = 0.8 TO 1.2 BY 0.1;
						RECOVERYDAYS = RECOVERYDAYSfraction*&RecoveryDays;
						RECOVERYDAYSfraction = round(RECOVERYDAYSfraction,.00001);
							DO SOCIALDfraction = -.2 TO .2 BY 0.1;
							SOCIALD = SOCIALDfraction + &SocialDistancing;
							SOCIALDfraction = round(SOCIALDfraction,.00001);
							IF SOCIALD >=0 and SOCIALD<=1 THEN DO; 
                                GAMMA = 1 / RECOVERYDAYS;
                                BETA = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - SOCIALD);
								R_T = BETA / GAMMA * &Population.;
								%DO j = 1 %TO %SYSFUNC(countw(&SocialDistancingChange.,:));
									BETAChange&j = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
													&Population. * (1 - &&SocialDistancingChange&j);
									R_T_Change&j = BETAChange&j / GAMMA * &Population.;
								%END;								
								DO TIME = 0 TO &N_DAYS. by 1;
									OUTPUT; 
								END;
                            END;
							END;
                        END;
				RUN;

			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; performance nthreads=4 bypriority=1 partpriority=1; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
                PARMS N &Population.;
                BOUNDS 1 <= R_T <= 13;
				%LET jmax = %SYSFUNC(countw(&SocialDistancingChange.,:));
				RESTRICT R_T > 0 %DO j = 1 %TO &jmax; , R_T_Change&j > 0 %END;;
				%IF &jmax = 0 %THEN %DO; BETA = BETA; %END;
				%ELSE %DO;
					%DO j = 1 %TO &jmax;
						%LET j2 = %eval(&j + 1);
						%IF &j = 1 %THEN %DO; 
							change_0 = (TIME < (&&ISOChangeDate&j - &DAY_ZERO));
						%END;
						%IF &j = &jmax %THEN %DO;
							change_&j = (TIME >= (&&ISOChangeDate&j - &DAY_ZERO));
						%END;
						%ELSE %DO;
							change_&j = ((TIME >= (&&ISOChangeDate&j - &DAY_ZERO.)) & (TIME < (&&ISOChangeDate&j2 - &DAY_ZERO.)));
						%END;
					%END;
					BETA = change_0*R_T*GAMMA/N %DO j = 1 %TO &jmax; + change_&j*R_T_Change&j*GAMMA/N %END;; 
				%END;
				/* DIFFERENTIAL EQUATIONS */ 
				/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
				DERT.S_N = -BETA*S_N*I_N;
				/* c. inflow from b. - outflow through recovery or death during illness*/
				DERT.I_N = BETA*S_N*I_N - GAMMA*I_N;
				/* d. Recovered and death humans through "promotion" inflow from c.*/
				DERT.R_N = GAMMA*I_N;           
				/* SOLVE THE EQUATIONS */ 
				SOLVE S_N I_N R_N / TIME=TIME OUT = TMODEL_SIR_SIM; 
                by RECOVERYDAYSfraction SOCIALDfraction;
			RUN;
			QUIT;  

            /* use the center point of the ranges for the requested scenario inputs */
			DATA TMODEL_SIR_SIM;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9.;	
				ModelType="SIR with PROC (T)MODEL";
X_IMPORT: keys.sas
				RETAIN counter cumulative_sum_fatality cumulative_Sum_Market_Fatality;
				E_N = &E.;  /* placeholder for post-processing of SIR model */
				SET TMODEL_SIR_SIM(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				DAY = round(DAY,1);
                *WHERE RECOVERYDAYSfraction=1 and SOCIALDfraction=0;
				BY RECOVERYDAYSfraction SOCIALDfraction;
					IF first.SOCIALDfraction THEN counter = 1;
					ELSE counter + 1;
X_IMPORT: postprocess.sas
				DROP CUM: counter BETA GAMMA R_T:;
			RUN;

			DATA TMODEL_SIR; 
				SET TMODEL_SIR_SIM;
				WHERE RECOVERYDAYSfraction=1 and SOCIALDfraction=0;
				DROP RECOVERYDAYSfraction SOCIALDfraction;
			RUN;

            PROC SQL noprint;
                create table TMODEL_SIR as
                    select * from
                        (select * from work.TMODEL_SIR) B 
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
                            from TMODEL_SIR_SIM
                            group by Date, ModelType, ScenarioIndex
                        ) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                drop table TMODEL_SIR_SIM;
            QUIT;

			PROC APPEND base=work.MODEL_FINAL data=TMODEL_SIR NOWARN FORCE; run;
			PROC SQL; drop table TMODEL_SIR; drop table DINIT; QUIT;
			
		%END;

		%IF &PLOTS. = YES AND &HAVE_SASETS = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='SIR with PROC (T)MODEL' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "&sdchangetitle.";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3;

			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='SIR with PROC (T)MODEL' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SIR Approach With Uncertainty Bounds";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "&sdchangetitle.";
					
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
			TITLE; TITLE2; TITLE3;
		%END;