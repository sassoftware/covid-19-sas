	/* DATA STEP APPROACH FOR SIR - SIMULATION APPROACH TO BOUNDS*/
		/* these are the calculations for variables used from above:
X_IMPORT: parameters.sas
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 %THEN %DO;
			DATA DS_SIR_SIM;
				FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;		
				ModelType="DS - SIR - SIM";
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
				LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
					ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
				CALL STREAMINIT(2019);
				DO SIM = 1 to 100;
					DO DAY = 0 TO &N_DAYS.;
						IF DAY = 0 THEN DO;
							S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
							I_N = &I. / &DiagnosedRate.;
							R_N = &InitRecovered.;
							BETA = &BETA.;
							N = SUM(S_N, I_N, R_N);
						END;
						ELSE DO;
							BETA = LAG_BETA * (1- &BETA_DECAY.);
							poisson = rand('POISson', BETA * LAG_S * LAG_I);
							S_N = LAG_S - poisson;
							I_N = LAG_I + poisson - &GAMMA. * LAG_I;
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
						E_N = &E.; LAG_E = E_N;  /* placeholder for post-processing of SIR model */
						LAG_I = I_N;
						LAG_R = R_N;
						LAG_N = N;
						IF date = &ISOChangeDate. THEN BETA = &BETAChange.;
						ELSE IF date = &ISOChangeDateTwo. THEN BETA = &BETAChangeTwo.;
						ELSE IF date = &ISOChangeDate3. THEN BETA = &BETAChange3.;
						ELSE IF date = &ISOChangeDate4. THEN BETA = &BETAChange4.;
						LAG_BETA = BETA;
X_IMPORT: postprocess.sas
						OUTPUT;
					END;
				END;
				DROP LAG: BETA CUM: poisson;
			RUN;

			PROC APPEND base=work.MODEL_FINAL_SIM data=DS_SIR_SIM NOWARN FORCE; run;
			PROC SQL; drop table DS_SIR_SIM; QUIT;

		%END;

		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='DS - SIR - SIM' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SEIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
				TITLE5 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate3., date10.), date9.): %SYSFUNC(round(&R_T_Change_3.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange3.*100)%";
				TITLE6 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate4., date10.), date9.): %SYSFUNC(round(&R_T_Change_4.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange4.*100)%";
				SERIES X=DATE Y=I_N / LINEATTRS=(THICKNESS=2) GROUP=SIM;
				*SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;
		%END;
		