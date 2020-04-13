    /* TMODEL APPROACH FOR SEIR - adds SIMULATION APPROACH TO BOUNDS*/
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
                    DO SIGMA = IFN(&SIGMA<0.3,0,&SIGMA-.3) to &SIGMA+.3 by .1; /* range of .3, increment by .1 */
                        DO RECOVERYDAYS = IFN(&RecoveryDays<5,0,&RecoveryDays.-5) to &RecoveryDays.+5 by 1; /* range of 5, increment by 1*/
                            DO SOCIALD = IFN(&SocialDistancing<.1,0,&SocialDistancing.-.1) to &SocialDistancing.+.1 by .05; 
                                GAMMA = 1 / RECOVERYDAYS;
                                BETA = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - SOCIALD);
                                DO R0 = IFN((BETA / GAMMA * &Population.)-2<2,0,(BETA / GAMMA * &Population.)-2) to (BETA / GAMMA * &Population.)+2 by .2; /* range of 2, increment by .1*/
                                    DO TIME = 0 TO &N_DAYS. by 1;
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
				*PARMS N &Population. R0 &R_T. R0_c1 &R_T_Change. R0_c2 &R_T_Change_Two. R0_c3 &R_T_Change_3. R0_c4 &R_T_Change_4.;
				*BOUNDS 1 <= R0 <= 13;
				*RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0, R0_c3 > 0, R0_c4 > 0;
				*GAMMA = &GAMMA.;
				*SIGMA = &SIGMA.;
				*change_0 = (TIME < (&ISOChangeDate. - &DAY_ZERO.));
				*change_1 = ((TIME >= (&ISOChangeDate. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));   
				*change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));
				*change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));
				*change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         
				*BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N + change_3*R0_c3*GAMMA/N + change_4*R0_c4*GAMMA/N;
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
				SOLVE S_N E_N I_N R_N / TIME=TIME OUT = TMODEL_SEIR; 
                by Sigma RECOVERYDAYS SOCIALD R0;
			RUN;
			QUIT;


            proc sql;
                /* reorder data and round(time,1) becasue some time values are not integer? maybe nthreads artifact. */
                create table TMODEL_SEIR as
                    select Sigma, RECOVERYDAYS, SOCIALD, R0, S_N, E_N, I_N, R_N, round(Time,1) as Time
                    from TMODEL_SEIR
                    order by Sigma, RECOVERYDAYS, SOCIALD, R0, Time
                ;
                create table TMODEL_SEIR1 as
                    select sum(S_N,E_N) as SE, Sigma, RECOVERYDAYS, SOCIALD, R0,Time
                    from TMODEL_SEIR
                    order by Sigma, RECOVERYDAYS, SOCIALD, R0, Time
                ;
            quit;


			DATA TMODEL_SEIR2;
				FORMAT ModelType $30. DATE date9.;
				ModelType="TMODEL - SEIR";
				ScenarioIndex=&ScenarioIndex.;
                LABEL   HOSPITAL_OCCUPANCY="Current Hospitalized Census"
                        ICU_OCCUPANCY="Current Hospital ICU Census"
                        VENT_OCCUPANCY="Current Hospital Ventilator Patients"
                        ECMO_OCCUPANCY="Current Hospital ECMO Patients"
                        DIAL_OCCUPANCY="Current Hospital Dialysis Patients"
                ;
				RETAIN CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET TMODEL_SEIR1(RENAME=(TIME=DAY));
                by Sigma RECOVERYDAYS SOCIALD R0;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SE),-1*SE));
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
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;

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
            PROC SQL;
                create table TMODEL_SEIR3 as
                    select min(HOSPITAL_OCCUPANCY) as LOWER_HOSPITAL_OCCUPANCY, 
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
                    from TMODEL_SEIR2
                    group by Date
                ;
            QUIT;


            /* merge with lower and upper  columns with results from model in work.MODEL_FINAL*/
            PROC SQL;
                create table work.MODEL_FINAL as
                    select * from
                        (select * from work.MODEL_FINAL) B 
                        left join
                        (select * from work.TMODEL_SEIR3) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                *drop table TMODEL_SEIR;
                *drop table TMODEL_SEIR_LOWER;
                *drop table TMODEL_SEIR_UPPER;
            QUIT;
            data temp; set work.MODEL_FINAL; where modeltype="TMODEL - SEIR"; run;
        %END;

        %IF &PLOTS. = YES AND &HAVE_SASETS = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='TMODEL - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
				TITLE5 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate3., date10.), date9.): %SYSFUNC(round(&R_T_Change_3.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange3.*100)%";
				TITLE6 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate4., date10.), date9.): %SYSFUNC(round(&R_T_Change_4.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange4.*100)%";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
                BAND x=Date lower=LOWER_HOSPITAL_OCCUPANCY upper=UPPER_HOSPITAL_OCCUPANCY;
                *SERIES X=DATE Y=LOWER_HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
                *SERIES X=DATE Y=UPPER_HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;
        %END;