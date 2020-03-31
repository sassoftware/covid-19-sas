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
X_IMPORT: postprocess.sas
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
