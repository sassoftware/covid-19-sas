        /* TMODEL APPROACH FOR SEIR - adds SIMULATION APPROACH TO UNCERTAINTY BOUNDS */
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation");  
                    S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
                    E_N = &E.;
                    I_N = &I. / &DiagnosedRate.;
                    R_N = &InitRecovered.;
                    *R0  = &R_T.;
                    /* prevent range below zero on each loop */
                    DO SIGMA = IFN(&SIGMA<0.3,0,&SIGMA-.3) to &SIGMA+.3 by .1; /* range of .3, increment by .1 */
                        DO RECOVERYDAYS = IFN(&RecoveryDays<5,0,&RecoveryDays.-5) to &RecoveryDays.+5 by 1; /* range of 5, increment by 1*/
                            DO SOCIALD = IFN(&SocialDistancing<.1,0,&SocialDistancing.-.1) to &SocialDistancing.+.1 by .05; 
                                GAMMA = 1 / RECOVERYDAYS;
                                BETA = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - SOCIALD);
								BETAChange = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - &SocialDistancingChange.);
								BETAChangeTwo = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - &SocialDistancingChangeTwo.);
								BETAChange3 = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - &SocialDistancingChange3.);
								BETAChange4 = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - &SocialDistancingChange4.);
                                DO R0 = IFN((BETA / GAMMA * &Population.)-2<2,0,(BETA / GAMMA * &Population.)-2) to (BETA / GAMMA * &Population.)+2 by .2; /* range of 2, increment by .1*/
                                    DO TIME = 0 TO &N_DAYS. by 1;
                                        R_T = BETA / GAMMA * &Population.;
                                        R_T_Change = BETAChange / GAMMA * &Population.;
                                        R_T_Change_Two = BETAChangeTwo / GAMMA * &Population.;
                                        R_T_Change_3 = BETAChange3 / GAMMA * &Population.;
                                        R_T_Change_4 = BETAChange4 / GAMMA * &Population.;
                                        OUTPUT; 
                                    END;
                                END;
                            END;
                        END;
                    END;  
				RUN;

			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT performance nthreads=4 bypriority=1 partpriority=0; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
                PARMS N &Population.;
                BOUNDS 1 <= R_T <= 13;
				RESTRICT R_T > 0, R_T_Change > 0, R_T_Change_Two > 0, R_T_Change_3 > 0, R_T_Change_4 > 0;
                change_0 = (TIME < (&ISOChangeDate. - &DAY_ZERO.));
				change_1 = ((TIME >= (&ISOChangeDate. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));   
				change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));
				change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));
				change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         
				BETA = change_0*R_T*GAMMA/N + change_1*R_T_Change*GAMMA/N + change_2*R_T_Change_Two*GAMMA/N + change_3*R_T_Change_3*GAMMA/N + change_4*R_T_Change_4*GAMMA/N;
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
				SOLVE S_N E_N I_N R_N / TIME=TIME OUT = TMODEL_SEIR_SIM; 
                by Sigma RECOVERYDAYS SOCIALD R0;
			RUN;
			QUIT;

            /* round time to integers - precision */
            proc sql;
                create table TMODEL_SEIR_SIM as
                    select sum(S_N,E_N) as SE, Sigma, RECOVERYDAYS, SOCIALD, R0, round(Time,1) as Time
                    from TMODEL_SEIR_SIM
                    order by Sigma, RECOVERYDAYS, SOCIALD, R0, Time
                ;
            quit;

            /* use a skeleton from the normal post-processing to processes every scenario.
                by statement used for separating scenarios - order by in sql above prepares this
                note that lag function used in conditional logic can be very tricky.
                The code below has logic to override the lag at the start of each by group.
            */
			DATA TMODEL_SEIR_SIM;
				FORMAT ModelType $30. DATE date9. Scenarioname $30. ScenarioNameUnique $100.;
				ModelType="TMODEL - SEIR";
				ScenarioName="&Scenario.";
X_IMPORT: keys.sas
				RETAIN counter CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET TMODEL_SEIR_SIM(RENAME=(TIME=DAY));
                by Sigma RECOVERYDAYS SOCIALD R0;
                    if first.R0 then do;
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
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SE),-1*SE));
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
					
					DATE = &DAY_ZERO. + DAY;
				/* END: Common Post-Processing Across each Model Type and Approach */
                KEEP ModelType ScenarioIndex DATE HOSPITAL_OCCUPANCY ICU_OCCUPANCY VENT_OCCUPANCY ECMO_OCCUPANCY DIAL_OCCUPANCY Sigma RECOVERYDAYS SOCIALD R0;
			RUN;

            PROC SQL noprint;
                create table TMODEL_SEIR as
                    select * from
                        (select * from work.TMODEL_SEIR) B 
                        left join
                        (select min(HOSPITAL_OCCUPANCY) as LOWER_HOSPITAL_OCCUPANCY label="Lower Bound: Current Hospitalized Census", 
                                min(ICU_OCCUPANCY) as LOWER_ICU_OCCUPANCY label="Lower Bound: Current Hospital ICU Census", 
                                min(VENT_OCCUPANCY) as LOWER_VENT_OCCUPANCY label="Lower Bound: Current Hospital Ventilator Patients", 
                                min(ECMO_OCCUPANCY) as LOWER_ECMO_OCCUPANCY label="Lower Bound: Current Hospital Patients", 
                                min(DIAL_OCCUPANCY) as LOWER_DIAL_OCCUPANCY label="Lower Bound: Current Hospital Patients",
                                max(HOSPITAL_OCCUPANCY) as UPPER_HOSPITAL_OCCUPANCY label="Upper Bound: Current Hospitalized Census", 
                                max(ICU_OCCUPANCY) as UPPER_ICU_OCCUPANCY label="Upper Bound: Current Hospital ICU Census", 
                                max(VENT_OCCUPANCY) as UPPER_VENT_OCCUPANCY label="Upper Bound: Current Hospital Ventilator Patients", 
                                max(ECMO_OCCUPANCY) as UPPER_ECMO_OCCUPANCY label="Upper Bound: Current Hospital Patients", 
                                max(DIAL_OCCUPANCY) as UPPER_DIAL_OCCUPANCY label="Upper Bound: Current Hospital Patients",
                                Date, ModelType, ScenarioIndex
                            from TMODEL_SEIR_SIM
                            group by Date, ModelType, ScenarioIndex
                        ) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                drop table TMODEL_SEIR_SIM;
            QUIT;