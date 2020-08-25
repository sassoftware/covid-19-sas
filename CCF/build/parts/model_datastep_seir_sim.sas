	/* DATA STEP APPROACH FOR SEIR */
		/* these are the calculations for variables used from above:
X_IMPORT: parameters.sas
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 %THEN %DO;
			DATA DS_SEIR_SIM;
				FORMAT DATE DATE9.;
X_IMPORT: keys.sas
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
							kBETA = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
											&Population. * (1 - SOCIALD);
							%DO j = 1 %TO &ISOChangeLoop;
								BETAChange&j = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
												&Population. * ((&&SocialDistancingChange&j)/&&ISOChangeWindow&j);
							%END;				
							byinc = 0.1;
							DO DAY = 0 TO &N_DAYS. by byinc;
								IF DAY = 0 THEN DO;
									S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
									E_N = &E.;
									I_N = &I. / &DiagnosedRate.;
									R_N = &InitRecovered.;
									BETA = kBETA;
										SocialDistancing = SOCIALD;
									N = SUM(S_N, E_N, I_N, R_N);
								END;
								ELSE DO;
									BETA = LAG_BETA;
									S_N = LAG_S - (BETA * LAG_S * LAG_I)*byinc;
									E_N = LAG_E + (BETA * LAG_S * LAG_I - SIGMAINV * LAG_E)*byinc;
									I_N = LAG_I + (SIGMAINV * LAG_E - GAMMA * LAG_I)*byinc;
									R_N = LAG_R + (GAMMA * LAG_I)*byinc;
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
								/* prepare for tomorrow (DAY+1) */
									/* remember todays values for SEIR */
										LAG_S = S_N;
										LAG_E = E_N;
										LAG_I = I_N;
										LAG_R = R_N;
										LAG_N = N;
										LAG_BETA = BETA;
									/* output integer days and make BETA adjustments*/
										IF abs(DAY - round(DAY,1)) < byinc/10 THEN DO;
											DATE = &DAY_ZERO. + round(DAY,1); /* brought forward from post-processing: examine location impact on ISOChangeDate* */
											/* implement shifts in SocialDistancing on and over date ranges */
												%IF &ISOChangeLoop > 0 %THEN %DO;
													%DO j = 1 %TO &ISOChangeLoop;
														%IF &j > 1 %THEN %DO; ELSE %END;
															IF &&ISOChangeDate&j <= date < &&ISOChangeDate&j + &&ISOChangeWindow&j THEN DO;
																BETAChange = BETAChange&j.;
																SocialDistancing = SocialDistancing + &&SocialDistancingChange&j/&&ISOChangeWindow&j;
															END;
													%END;
													ELSE BETAChange = 0;
												%END;
												%ELSE %DO; BETAChange = 0; %END;
											/* adjust BETA for tomorrow */
												LAG_BETA = BETA - BETAChange;
											OUTPUT;
										END;
							END;
						END;
						END;
					END;
				END;
				DROP LAG: byinc kBETA BETAChange:;
			RUN;

			DATA DS_SEIR_SIM;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9.;		
				ModelType="SEIR with Data Step";
				RETAIN counter cumulative_sum_fatality cumulative_Sum_Market_Fatality;
				SET DS_SEIR_SIM;
				*WHERE SIGMAfraction=1 and RECOVERYDAYSfraction=1 and SOCIALDfraction=0;
				BY SIGMAfraction RECOVERYDAYSfraction SOCIALDfraction;
					IF first.SOCIALDfraction THEN counter = 1;
					ELSE counter + 1;
X_IMPORT: postprocess.sas
				DROP CUM: counter SIGMAINV RECOVERYDAYS SOCIALD GAMMA;
			RUN;

			DATA DS_SEIR;
				SET DS_SEIR_SIM;
				WHERE SIGMAfraction=1 and RECOVERYDAYSfraction=1 and SOCIALDfraction=0;
				DROP SIGMAfraction RECOVERYDAYSfraction SOCIALDfraction;
			RUN;

		/* merge scenario data with uncertain bounds */
            PROC SQL noprint;
                create table DS_SEIR as
                    select * from
                        (select * from work.DS_SEIR) B 
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
                            from DS_SEIR_SIM
                            group by Date, ModelType, ScenarioIndex
                        ) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                drop table DS_SEIR_SIM;
            QUIT;

B_IMPORT: boemska_ds_seir.sas

			PROC APPEND base=work.MODEL_FINAL data=DS_SEIR NOWARN FORCE; run;
				PROC SQL; drop table DS_SEIR; QUIT;

		%END;

		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='SEIR with Data Step' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach";
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
				where ModelType='SEIR with Data Step' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach With Uncertainty Bounds";
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
