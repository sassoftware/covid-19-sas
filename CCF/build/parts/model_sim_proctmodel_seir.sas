    /* TMODEL APPROACH FOR SEIR - SIMULATION APPROACH TO BOUNDS*/
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation");  
                    S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
                    E_N = &E.;
                    I_N = &I. / &DiagnosedRate.;
                    R_N = &InitRecovered.;
                    *R0  = &R_T.;
                    /* what if range dips below zero? */
                    DO SIGMA = &SIGMA-.3 to &SIGMA+.3 by .1; /* range of .3, increment by .1 */
                        DO RECOVERYDAYS = &RecoveryDays.-5 to &RecoveryDays.+5 by 1; /* range of 5, increment by 1*/
                            DO SOCIALD = &SocialDistancing.-.1 to &SocialDistancing.+.1 by .05; 
                                GAMMA = 1 / RECOVERYDAYS;
                                BETA = ((2 ** (1 / &doublingtime.) - 1) + GAMMA) / 
                                                &Population. * (1 - SOCIALD);
                                DO R0 = (BETA / GAMMA * &Population.)-2 to (BETA / GAMMA * &Population.)+2 by .1; /* range of 2, increment by .1*/
                                    DO TIME = 0 TO &N_DAYS.;
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
				SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR; 
                by Sigma RECOVERYDAYS SOCIALD R0;
			RUN;
			QUIT;


            proc sql;
                create table TMODEL_SEIR as
                    select Sigma,R0,Gamma,S_N,E_N,I_N,R_N,Time
                    from TMODEL_SEIR
                    order by Sigma,R0, SOCIALD, Gamma,Time;
            quit;
            data TMODEL_SEIR;
                set TMODEL_SEIR;
                format date date9.;
                *date="&CurrentDate"d+time-1;
                DATE = &DAY_ZERO. + Time;
            run;
            proc sql;
                create table TMODEL_SEIR as	
                    select min(I_N) as lower, max(I_N) as upper, mean(I_N) as middle, Date
                    from TMODEL_SEIR
                    group by Date
                ;
            quit;

            PROC SGPLOT DATA=TMODEL_SEIR;
                TITLE "TMODEL SEIR - Plot of I with bounds from simulation";
                band x=Date lower=lower upper=upper / legendlabel="Band for I" name="band1";
                SERIES X=DATE Y=middle / LINEATTRS=(THICKNESS=2);
                XAXIS LABEL="Date";
                YAXIS LABEL="I";
            RUN;
