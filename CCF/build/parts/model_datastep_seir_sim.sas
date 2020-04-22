	/* DATA STEP APPROACH FOR SEIR */
		/* these are the calculations for variables used from above:
X_IMPORT: parameters.sas
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 %THEN %DO;
			DATA DS_SEIR_SIM;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;		
				ModelType="DS - SEIR";
				ScenarioName="&Scenario.";
X_IMPORT: keys.sas
				/* prevent range below zero on each loop */
				 DO SIGMA = &SIGMA-0.4 TO &SIGMA+0.4 BY 0.2;
				 IF SIGMA >= 0 THEN DO;
                    DO RECOVERYDAYS = &RecoveryDays.-4 TO &RecoveryDays.+4 BY 2;
					IF RECOVERYDAYS >= 0 THEN DO;
                        DO SOCIALD = &SocialDistancing.-.2 TO &SocialDistancing.+.2 BY .1;
						IF SOCIALD >= 0 THEN DO; 
							GAMMA = 1 / RECOVERYDAYS;
							kBETA = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
											&Population. * (1 - SOCIALD);
							BETAChange = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
											&Population. * (1 - &SocialDistancingChange.);
							BETAChangeTwo = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
											&Population. * (1 - &SocialDistancingChangeTwo.);
							BETAChange3 = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
											&Population. * (1 - &SocialDistancingChange3.);
							BETAChange4 = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
											&Population. * (1 - &SocialDistancingChange4.);
							byinc = 0.1;
							DO DAY = 0 TO &N_DAYS. by byinc;
								IF DAY = 0 THEN DO;
									S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
									E_N = &E.;
									I_N = &I. / &DiagnosedRate.;
									R_N = &InitRecovered.;
									BETA = kBETA;
									N = SUM(S_N, E_N, I_N, R_N);
								END;
								ELSE DO;
									BETA = LAG_BETA * (1 - &BETA_DECAY.);
									S_N = LAG_S - (BETA * LAG_S * LAG_I)*byinc;
									E_N = LAG_E + (BETA * LAG_S * LAG_I - &SIGMA. * LAG_E)*byinc;
									I_N = LAG_I + (&SIGMA. * LAG_E - GAMMA * LAG_I)*byinc;
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
								LAG_S = S_N;
								LAG_E = E_N;
								LAG_I = I_N;
								LAG_R = R_N;
								LAG_N = N;
								DATE = &DAY_ZERO. + int(DAY); /* need current date to determine when to put step change in Social Distancing */
								IF date = &ISOChangeDate. THEN BETA = BETAChange;
								ELSE IF date = &ISOChangeDateTwo. THEN BETA = BETAChangeTwo;
								ELSE IF date = &ISOChangeDate3. THEN BETA = BETAChange3;
								ELSE IF date = &ISOChangeDate4. THEN BETA = BETAChange4;
								LAG_BETA = BETA;
								IF abs(DAY - round(DAY,1)) < byinc/10 THEN DO;
									DATE = &DAY_ZERO. + round(DAY,1); /* brought forward from post-processing: examine location impact on ISOChangeDate* */
									OUTPUT;
								END;
							END;
						END;
						END;
					END;
					END;
				END;
				END;
				DROP LAG: BETA byinc kBETA GAMMA BETAChange:;
			RUN;

			DATA DS_SEIR;
				SET DS_SEIR_SIM;
				WHERE round(SIGMA,.1)=round(&Sigma.,.1) and round(RECOVERYDAYS,1)=round(&RecoveryDays.,1) and round(SOCIALD,.1)=round(&SocialDistancing.,.1);
X_IMPORT: postprocess.sas
				DROP CUM: SIGMA RECOVERYDAYS SOCIALD;
			RUN;

		/* calculate key output measures for all scenarios as input to uncertainty bounds */
            /* use a skeleton from the normal post-processing to processes every scenario.
                by statement used for separating scenarios - order by in sql above prepares this
                note that lag function used in conditional logic can be very tricky.
                The code below has logic to override the lag at the start of each by group.
            */
			DATA DS_SEIR_SIM;
X_IMPORT: keys.sas
				RETAIN counter CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET DS_SEIR_SIM;
                by SIGMA RECOVERYDAYS SOCIALD;
                    if first.SOCIALD then do;
                        counter = 1;
                        CUMULATIVE_SUM_HOSP=0;
                        CUMULATIVE_SUM_ICU=0;
                        CUMULATIVE_SUM_VENT=0;
                        CUMULATIVE_SUM_ECMO=0;
                        CUMULATIVE_SUM_DIAL=0;
                    end;
                    else do;
                        counter+1;
                    end;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(sum(S_N,E_N)),-1*sum(S_N,E_N)));
                        if counter<&IncubationPeriod then NEWINFECTED=.; /* reset the lag for by group */

					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;

					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;

                    CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
                        if counter<=&HOSP_LOS then CUMADMITLAGGED=.; /* reset the lag for by group */
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
                        if counter<=&ICU_LOS then CUMICULAGGED=.; /* reset the lag for by group */
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
                        if counter<=&VENT_LOS then CUMVENTLAGGED=.; /* reset the lag for by group */
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
                        if counter<=&ECMO_LOS then CUMECMOLAGGED=.; /* reset the lag for by group */
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
                        if counter<=&DIAL_LOS then CUMDIALLAGGED=.; /* reset the lag for by group */

					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					
                    HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					
				/* END: Common Post-Processing Across each Model Type and Approach */
                KEEP ModelType ScenarioIndex DATE HOSPITAL_OCCUPANCY ICU_OCCUPANCY VENT_OCCUPANCY ECMO_OCCUPANCY DIAL_OCCUPANCY SIGMA RECOVERYDAYS SOCIALD;
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

			PROC APPEND base=work.MODEL_FINAL data=DS_SEIR NOWARN FORCE; run;
			PROC SQL; drop table DS_SEIR; QUIT;

		%END;

		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='DS - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
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

			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='DS - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach With Uncertainty Bounds";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
				TITLE5 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate3., date10.), date9.): %SYSFUNC(round(&R_T_Change_3.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange3.*100)%";
				TITLE6 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate4., date10.), date9.): %SYSFUNC(round(&R_T_Change_4.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange4.*100)%";
					
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
			TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;
		%END;
