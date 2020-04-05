	/* DATA STEP APPROACH FOR SIR */
		/* these are the calculations for variablez used from above:
X_IMPORT: parameters.sas
		*/
		DATA DS_SIR;
			FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;		
			ModelType="DS - SIR";
			ScenarioName="&Scenario.";
			ScenarioIndex=&ScenarioIndex.;
			ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
			LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
				ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
			DO DAY = 0 TO &N_DAYS.;
				IF DAY = 0 THEN DO;
					S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
					I_N = &I./&DiagnosedRate.;
					R_N = &InitRecovered.;
					BETA = &BETA.;
					N = SUM(S_N, I_N, R_N);
				END;
				ELSE DO;
					BETA = LAG_BETA * (1- &BETA_DECAY.);
					S_N = LAG_S -BETA * LAG_S * LAG_I;
					I_N = LAG_I + BETA * LAG_S * LAG_I - &GAMMA. * LAG_I;
					R_N = LAG_R + &GAMMA. * LAG_I;
					N = SUM(S_N, I_N, R_N);
					SCALE = LAG_N / N;
					IF S_N < 0 THEN S_N = 0;
					IF I_N < 0 THEN I_N = 0;
					IF R_N < 0 THEN R_N = 0;
					S_N = SCALE*S_N;
					I_N = SCALE*I_N;
					R_N = SCALE*R_N;
				END;
				LAG_S = S_N;
				E_N = 0; LAG_E = E_N; /* placeholder for post-processing of SIR model */
				LAG_I = I_N;
				LAG_R = R_N;
				LAG_N = N;
				IF date = &ISOChangeDate. THEN BETA = &BETAChange.;
				ELSE IF date = &ISOChangeDateTwo. THEN BETA = &BETAChangeTwo.;
				LAG_BETA = BETA;
X_IMPORT: postprocess.sas
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=DS_SIR;
				where ModelType='DS - SIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
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
		PROC APPEND base=store.MODEL_FINAL data=DS_SIR NOWARN FORCE; run;
		PROC SQL; drop table DS_SIR; QUIT;
T_IMPORT: sim_model_datastep_sir.sas