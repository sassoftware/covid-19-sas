/*PROC TMODEL SEIR APPROACH*/
	%IF &HAVE_SASETS = YES %THEN %DO;
		/*Location to which CSV data will be saved*/
			FILENAME OHIO "&homedir.COVIDSummaryData.csv";

		/*DOWNLOAD CSV*/
			PROC HTTP 
				URL="https://coronavirus.ohio.gov/static/COVIDSummaryData.csv"
				METHOD= "GET" 
				OUT=OHIO;
			RUN;

			PROC IMPORT OUT= WORK.OHIO_RAW 
			            DATAFILE= "&homedir.COVIDSummaryData.csv" 
			            DBMS=CSV REPLACE;
			     GETNAMES=YES;
			     DATAROW=2; 
				 GUESSINGROWS=2000; 
			RUN;

			PROC SQL;
				CREATE TABLE OHIO_SUMMARY AS 
				SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
				FROM OHIO_RAW
				WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
					'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
					'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
				GROUP BY CALCULATED DATE
				ORDER BY CALCULATED DATE;
			QUIT;

			PROC SQL NOPRINT;
				SELECT MIN(DATE) INTO :FIRST_CASE FROM OHIO_SUMMARY;
				SELECT MAX(DATE) INTO :LATEST_CASE FROM OHIO_SUMMARY;
			QUIT;

			DATA ALLDATES;
				FORMAT DATE DATE9.;
				DO DATE = &FIRST_CASE TO &LATEST_CASE;
					TIME = DATE - &FIRST_CASE + 1;
					OUTPUT;
				END;
			RUN;

			DATA STORE.OHIO_SUMMARY;
				MERGE ALLDATES OHIO_SUMMARY;
				BY DATE;
				CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
			RUN;

		%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD NOPRINT; %END;
		%ELSE %DO; PROC MODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD NOPRINT; %END;
			/* Parameters of interest */
			PARMS R0 &R_T I0 &I;
			BOUNDS 1 <= R0 <= 13;
			/* Fixed values */
			N = &S;
			INF = &RECOVERY_DAYS;
			SIGMA=&SIGMA;
			/* Differential equations */
			GAMMA = 1/INF;
			BETA = R0*GAMMA/N;
			/* Differential equations */
			/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
			DERT.S_N = -BETA*S_N*I_N;
			/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
			DERT.E_N = BETA*S_N*I_N-SIGMA*E_N;
			/* c. inflow from b. - outflow through recovery or death during illness*/
			DERT.I_N = SIGMA*E_N-GAMMA*I_N;
			/* d. Recovered and death humans through "promotion" inflow from c.*/
			DERT.R_N = GAMMA*I_N;
			CUMULATIVE_CASE_COUNT = I_N + R_N;
			/* Fit the data */
			FIT CUMULATIVE_CASE_COUNT INIT=(S_N=&S E_N=0 I_N=I0 R_N=0) / TIME=DATE DYNAMIC OUTPREDICT OUTACTUAL OUT=EPIPRED LTEBOUND=1E-10
			%IF &HAVE_V151 = YES %THEN %DO; OPTIMIZER=ORMP(OPTTOL=1E-5) %END;
			/*%ELSE %DO; %END;*/
			;
			OUTVARS S_N E_N I_N R_N;
		QUIT;

		DATA EPIPRED;
		   SET EPIPRED;
		   LABEL CUMULATIVE_CASE_COUNT='Cumulative Incidence';
		RUN;

		%IF &PLOTS. = YES %THEN %DO;
			/*Plot Fit of Actual v. Predicted */
			PROC SGPLOT DATA=EPIPRED;
				WHERE _TYPE_  NE 'RESIDUAL';
				TITLE "Actual v. Predicted Infections in Region";
				SERIES X=DATE Y=CUMULATIVE_CASE_COUNT / LINEATTRS=(THICKNESS=2) GROUP=_TYPE_  MARKERS NAME="cases";
				FORMAT CUMULATIVE_CASE_COUNT COMMA10.;
			RUN;
			TITLE;
		%END;

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

		/*Create SEIR Projections based on model fit above*/
		PROC MODEL DATA=DINIT MODEL=SEIRMOD;
			SOLVE CUMULATIVE_CASE_COUNT / /*TIME=DATE*/ OUT=TMODEL_SEIR_FIT;
		QUIT;

			DATA TMODEL_SEIR_FIT;
				FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
				ModelType="TMODEL - SEIR - FIT";
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
				SET TMODEL_SEIR_FIT(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				N = SUM(S_N, E_N, I_N, R_N);
				SCALE = LAG_N / N;
X_IMPORT: postprocess.sas
				DROP LAG: CUM: ;
			RUN;
			%IF &PLOTS. = YES %THEN %DO;
				PROC SGPLOT DATA=TMODEL_SEIR_FIT;
					where ModelType='TMODEL - SEIR - FIT' and ScenarioIndex=&ScenarioIndex.;
					TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach";
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
			PROC APPEND base=store.MODEL_FINAL data=TMODEL_SEIR_FIT NOWARN FORCE; run;
			PROC SQL; drop table TMODEL_SEIR_FIT; drop table DINIT; QUIT;
		%END;
