/* SAS Program COVID_19 
Cleveland Clinic and SAS Collaboarion

These models are only as good as their inputs. 
Input values for this type of model are very dynamic and may need to be evaluated across wide ranges and reevaluated as the epidemic progresses.  
This work is currently defaulting to values for the population studied in the Cleveland Clinic and SAS collaboration.
You need to evaluate each parameter for your population of interest.
*/

/* directory path for files: COVID_19.sas (this file), libname store */
    %let homedir = /Local_Files/covid-19-sas/ccf;

/* the storage location for the MODEL_FINAL table and other output tables - when &ScenarioSource=BATCH */
    libname store "&homedir.";

/* Depending on which SAS products you have and which releases you have these options will turn components of this code on/off */
    %LET HAVE_SASETS = YES; /* YES implies you have SAS/ETS software, this enable the PROC MODEL methods in this code.  Without this the Data Step SIR model still runs */
    %LET HAVE_V151 = NO; /* YES implies you have products verison 15.1 (latest) and switches PROC MODEL to PROC TMODEL for faster execution */

/* User Interface Switches - these are used if you using the code within SAS Visual Analytics UI */
    %LET ScenarioSource = UI;
    %LET CASSource = casuser; 
    /* NOTES: 
        - &ScenarioSource = UI overrides the behavior of the %EasyRun macro
        - &CASSource is the location of the results tables you want the macro to read from in determining if a scenario has been run before: can be a libname or caslib
        - libname STORE is still used to read only the contents of the FIT_INPUT table
            - The UI will not attempt to update the FIT_INPUT table, only ScenarioSource = BATCH does this currently
        - An active CAS session and CASLIB are needed for &CASSource to be available to the %EasyRun macro if you set &CASSource to a caslib
        - At the end of execution all the output tables holding just the current scenario will be in WORK
        - If &ScenarioExist = 0 then the files in WORK contain a new scenario
            - Else, %ScenarioExist > 0, the files in WORK contain a recalled, previously run scenario identified by the columns ScenarioIndex, ScenarioSource, ScenarioUser, ScenarionNameUnique
                - The column Scenario will contain the name entered in the UI as the name is not used in matching previous scenarios
                - these global macro variables will have recalled scenario information in this case (empty when &ScenarioExist=0): &ScenerioIndex_Recall, &ScenarioUser_Recall, &Scenario_Source_Recall, &ScenarioNameUnique_Recall
        - The code assumes that the files it is creating are not in the current SAS workspace.  If there are files with the same name then unexpected behavior will cause issues: appending new data to existing data without warning.
    */

%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,
                SocialDistancing,ISOChangeDate,SocialDistancingChange,ISOChangeDateTwo,SocialDistancingChangeTwo,
                ISOChangeDate3,SocialDistancingChange3,ISOChangeDate4,SocialDistancingChange4,
                MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate,
                plots=no,N_DAYS=365,DiagnosedRate=1.0,E=0,SIGMA=0.90,DAY_ZERO='13MAR2020'd,BETA_DECAY=0.0,
                ECMO_RATE=0.03,DIAL_RATE=0.05,HOSP_LOS=7,ICU_LOS=9,VENT_LOS=10,ECMO_LOS=6,DIAL_LOS=11);

    DATA INPUTS;
        FORMAT
            Scenario                    $200.     
            IncubationPeriod            BEST12.    
            InitRecovered               BEST12.  
            RecoveryDays                BEST12.    
            doublingtime                BEST12.    
            Population                  BEST12.    
            KnownAdmits                 BEST12.    
            SocialDistancing            BEST12.    
            ISOChangeDate               DATE9.    
            SocialDistancingChange      BEST12.    
            ISOChangeDateTwo            DATE9.    
            SocialDistancingChangeTwo   BEST12.    
            ISOChangeDate3              DATE9.    
            SocialDistancingChange3     BEST12.    
            ISOChangeDate4              DATE9.    
            SocialDistancingChange4     BEST12.    
            MarketSharePercent          BEST12.    
            Admission_Rate              BEST12.    
            ICUPercent                  BEST12.    
            VentPErcent                 BEST12.    
            FatalityRate                BEST12.   
            plots                       $3.
            N_DAYS                      BEST12.
            DiagnosedRate               BEST12.
            E                           BEST12.
            SIGMA                       BEST12.
            DAY_ZERO                    DATE9.
            BETA_DECAY                  BEST12.
            ECMO_RATE                   BEST12.
            DIAL_RATE                   BEST12.
            HOSP_LOS                    BEST12.
            ICU_LOS                     BEST12.
            VENT_LOS                    BEST12.
            ECMO_LOS                    BEST12.
            DIAL_LOS                    BEST12.
        ;
        LABEL
            Scenario                    =   "Scenario Name to be stored as a character variable, combined with automatically-generated ScenarioIndex to create a unique ID"
            IncubationPeriod            =   "Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right"
            InitRecovered               =   "Initial number of Recovered patients, assumed to have immunity to future infection"
            RecoveryDays                =   "Number of days a patient is considered infectious (the amount of time it takes to recover or die)"
            doublingtime                =   "Baseline Infection Doubling Time without social distancing"
            Population                  =   "Number of people in region of interest, assumed to be well mixed and independent of other populations"
            KnownAdmits                 =   "Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections"
            SocialDistancing            =   "Baseline Social distancing (% reduction in social contact compared to normal activity)"
            ISOChangeDate               =   "Date of first change from baseline in social distancing parameter"
            SocialDistancingChange      =   "Second value of social distancing (% reduction in social contact compared to normal activity)"
            ISOChangeDateTwo            =   "Date of second change in social distancing parameter"
            SocialDistancingChangeTwo   =   "Third value of social distancing (% reduction in social contact compared to normal activity)"
            ISOChangeDate3              =   "Date of third change in social distancing parameter"
            SocialDistancingChange3     =   "Fourth value of social distancing (% reduction in social contact compared to normal activity)"
            ISOChangeDate4              =   "Date of fourth change in social distancing parameter"
            SocialDistancingChange4     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            MarketSharePercent          =   "Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest"
            Admission_Rate              =   "Percentage of Infected patients in the region who will be hospitalized"
            ICUPercent                  =   "Percentage of hospitalized patients who will require ICU"
            VentPErcent                 =   "Percentage of hospitalized patients who will require Ventilators"
            FatalityRate                =   "Percentage of hospitalized patients who will die"
            plots                       =   "YES/NO display plots in output"
            N_DAYS                      =   "Number of days to project"
            DiagnosedRate               =   "Factor to adjust admission_rate contributing to via MarketSharePercent I (see calculation for I)"
            E                           =   "Initial Number of Exposed (infected but not yet infectious)"
            SIGMA                       =   "Rate of latent individuals Exposed and transported to the infectious stage during each time period"
            DAY_ZERO                    =   "Date of the first COVID-19 case"
            BETA_DECAY                  =   "Factor (%) used for daily reduction of Beta"
            ECMO_RATE                   =   "Default percent of total admissions that need ECMO"
            DIAL_RATE                   =   "Default percent of admissions that need Dialysis"
            HOSP_LOS                    =   "Average Hospital Length of Stay"
            ICU_LOS                     =   "Average ICU Length of Stay"
            VENT_LOS                    =   "Average Vent Length of Stay"
            ECMO_LOS                    =   "Average ECMO Length of Stay"
            DIAL_LOS                    =   "Average DIAL Length of Stay"
        ;
        Scenario                    =   "&Scenario.";
        IncubationPeriod            =   &IncubationPeriod.;
        InitRecovered               =   &InitRecovered.;
        RecoveryDays                =   &RecoveryDays.;
        doublingtime                =   &doublingtime.;
        Population                  =   &Population.;
        KnownAdmits                 =   &KnownAdmits.;
        SocialDistancing            =   &SocialDistancing.;
        ISOChangeDate               =   &ISOChangeDate.;
        SocialDistancingChange      =   &SocialDistancingChange.;
        ISOChangeDateTwo            =   &ISOChangeDateTwo.;
        SocialDistancingChangeTwo   =   &SocialDistancingChangeTwo.;
        ISOChangeDate3              =   &ISOChangeDate3.;
        SocialDistancingChange3     =   &SocialDistancingChange3.;
        ISOChangeDate4              =   &ISOChangeDate4.;
        SocialDistancingChange4     =   &SocialDistancingChange4.;
        MarketSharePercent          =   &MarketSharePercent.;
        Admission_Rate              =   &Admission_Rate.;
        ICUPercent                  =   &ICUPercent.;
        VentPErcent                 =   &VentPErcent.;
        FatalityRate                =   &FatalityRate.;
        plots                       =   "&plots.";
        N_DAYS                      =   &N_DAYS.;
        DiagnosedRate               =   &DiagnosedRate.;
        E                           =   &E.;
        SIGMA                       =   &SIGMA.;
        DAY_ZERO                    =   &DAY_ZERO.;
        BETA_DECAY                  =   &BETA_DECAY.;
        ECMO_RATE                   =   &ECMO_RATE.;
        DIAL_RATE                   =   &DIAL_RATE.;
        HOSP_LOS                    =   &HOSP_LOS.;
        ICU_LOS                     =   &ICU_LOS.;
        VENT_LOS                    =   &VENT_LOS.;
        ECMO_LOS                    =   &ECMO_LOS.;
        DIAL_LOS                    =   &DIAL_LOS.;
    RUN;

    %IF &ScenarioSource = UI %THEN %DO;
        /* this session is only used for reading the SCENARIOS table in the global caslib when the UI is running the scenario */
        %LET PULLLIB=&CASSource.;
    %END;
    %ELSE %DO;
        %LET PULLLIB=store;
    %END;

    /* create an index, ScenarioIndex for this run by incrementing the max value of ScenarioIndex in SCENARIOS dataset */
        %IF %SYSFUNC(exist(&PULLLIB..scenarios)) %THEN %DO;
            PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from &PULLLIB..scenarios where ScenarioSource="&ScenarioSource."; quit;
            /* this may be the first ScenarioIndex for the ScenarioSource - catch and set to 0 */
            %IF &ScenarioIndex_Base = . %THEN %DO; %LET ScenarioIndex_Base = 0; %END;
        %END;
        %ELSE %DO; %LET ScenarioIndex_Base = 0; %END;
        %LET ScenarioIndex = %EVAL(&ScenarioIndex_Base + 1);

    /* store all the macro variables that set up this scenario in SCENARIOS dataset */
        DATA SCENARIOS;
            set sashelp.vmacro(where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE','PULLLIB') then delete;
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
            STAGE='INPUT';
        RUN;
        DATA INPUTS; 
            set INPUTS;
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
            label ScenarioIndex="Unique Scenario ID";
        RUN;

        /* Calculate Parameters form Macro Inputs Here - these are repeated as comments at the start of each model phase below */
			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);

        DATA SCENARIOS;
            set SCENARIOS sashelp.vmacro(in=i where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE','PULLLIB') then delete;
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
            if i then STAGE='MODEL';
        RUN;
    /* Check to see if SCENARIOS (this scenario) has already been run before in SCENARIOS dataset */
        %GLOBAL ScenarioExist;
        %IF %SYSFUNC(exist(&PULLLIB..scenarios)) %THEN %DO;
            PROC SQL noprint;
                /* has this scenario been run before - all the same parameters and value - no more and no less */
                select count(*) into :ScenarioExist from
                    (select t1.ScenarioIndex, t2.ScenarioIndex, t2.ScenarioSource, t2.ScenarioUser
                        from 
                            (select *, count(*) as cnt 
                                from work.SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIONNAMEUNIQUE','SCENARIOINDEX','SCENARIOSOURCE','SCENARIOUSER','SCENPLOT','PLOTS')
                                group by ScenarioIndex, ScenarioSource, ScenarioUser) t1
                            join
                            (select * from &PULLLIB..SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIONNAMEUNIQUE','SCENARIOINDEX','SCENARIOSOURCE','SCENARIOUSER','SCENPLOT','PLOTS')) t2
                            on t1.name=t2.name and t1.value=t2.value and t1.STAGE=t2.STAGE
                        group by t1.ScenarioIndex, t2.ScenarioIndex, t2.ScenarioSource, t2.ScenarioUser, t1.cnt
                        having count(*) = t1.cnt)
                ; 
            QUIT;
        %END; 
        %ELSE %DO; 
            %LET ScenarioExist = 0;
        %END;

    /* recall an existing scenario to SASWORK if it matched */
        %GLOBAL ScenarioIndex_recall ScenarioSource_recall ScenarioUser_recall ScenarioNameUnique_recall;
        %IF &ScenarioExist = 0 %THEN %DO;
            PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex from work.SCENARIOS; QUIT;
        %END;
        /*%ELSE %IF &PLOTS. = YES %THEN %DO;*/
        %ELSE %DO;
            /* what was a ScenarioIndex value that matched the requested scenario - store that in ScenarioIndex_recall ... */
            PROC SQL noprint; /* can this be combined with the similar code above that counts matching scenarios? */
				select t2.ScenarioIndex, t2.ScenarioSource, t2.ScenarioUser, t2.ScenarioNameUnique into :ScenarioIndex_recall, :ScenarioSource_recall, :ScenarioUser_recall, :ScenarioNameUnique_recall from
                    (select t1.ScenarioIndex, t2.ScenarioIndex, t2.ScenarioSource, t2.ScenarioUser, t2.ScenarioNameUnique
                        from 
                            (select *, count(*) as cnt 
                                from work.SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIONNAMEUNIQUE','SCENARIOINDEX','SCENARIOSOURCE','SCENARIOUSER','SCENPLOT','PLOTS')
                                group by ScenarioIndex) t1
                            join
                            (select * from &PULLLIB..SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIONNAMEUNIQUE','SCENARIOINDEX','SCENARIOSOURCE','SCENARIOUSER','SCENPLOT','PLOTS')) t2
                            on t1.name=t2.name and t1.value=t2.value and t1.STAGE=t2.STAGE
                        group by t1.ScenarioIndex, t2.ScenarioIndex, t2.ScenarioSource, t2.ScenarioUser, t1.cnt
                        having count(*) = t1.cnt)
                ;
            QUIT;
            /* pull the current scenario data to work for plots below */
            data work.MODEL_FINAL; set &PULLLIB..MODEL_FINAL; where ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall."; run;
            data work.FIT_PRED; set &PULLLIB..FIT_PRED; where ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall."; run;
            data work.FIT_PARMS; set &PULLLIB..FIT_PARMS; where ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall."; run;
            %LET ScenarioIndex = &ScenarioIndex_recall.;
        %END;

    /* Prepare to create request plots from input parameter plots= */
        %IF %UPCASE(&plots.) = YES %THEN %DO; %LET plots = YES; %END;
        %ELSE %DO; %LET plots = NO; %END;

	/*PROC TMODEL SEIR APPROACH*/
		/* these are the calculations for variables used from above:
			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 AND &HAVE_SASETS = YES %THEN %DO;
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation"); 
					DO TIME = 0 TO &N_DAYS.; 
						S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
						E_N = &E.;
						I_N = &I. / &DiagnosedRate.;
						R_N = &InitRecovered.;
						R0  = &R_T.;
						OUTPUT; 
					END; 
				RUN;
			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
				PARMS N &Population. R0 &R_T. R0_c1 &R_T_Change. R0_c2 &R_T_Change_Two. R0_c3 &R_T_Change_3. R0_c4 &R_T_Change_4.;
				BOUNDS 1 <= R0 <= 13;
				RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0, R0_c3 > 0, R0_c4 > 0;
				GAMMA = &GAMMA.;
				SIGMA = &SIGMA.;
				change_0 = (TIME < (&ISOChangeDate. - &DAY_ZERO.));
				change_1 = ((TIME >= (&ISOChangeDate. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));   
				change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));
				change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));
				change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         
				BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N + change_3*R0_c3*GAMMA/N + change_4*R0_c4*GAMMA/N;
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
			RUN;
			QUIT;

			DATA TMODEL_SEIR;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;
				ModelType="TMODEL - SEIR";
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				RETAIN LAG_S LAG_E LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
					CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
				LAG_S = S_N; 
				LAG_E = E_N; 
				LAG_I = I_N; 
				LAG_R = R_N; 
				LAG_N = N; 
				SET TMODEL_SEIR(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				N = SUM(S_N, E_N, I_N, R_N);
				SCALE = LAG_N / N;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					Cumulative_sum_fatality + Fatality;
					CUMULATIVE_SUM_MARKET_HOSP + MARKET_HOSP;
					CUMULATIVE_SUM_MARKET_ICU + MARKET_ICU;
					CUMULATIVE_SUM_MARKET_VENT + MARKET_VENT;
					CUMULATIVE_SUM_MARKET_ECMO + MARKET_ECMO;
					CUMULATIVE_SUM_MARKET_DIAL + MARKET_DIAL;
					cumulative_Sum_Market_Fatality + Market_Fatality;
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_MARKET_DIAL));
					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					Deceased_Today = Fatality;
					Total_Deaths = Cumulative_sum_fatality;
					MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
					MARKET_HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
					MARKET_ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
					MARKET_VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
					MARKET_ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
					MARKET_DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
					Market_Deceased_Today = Market_Fatality;
					Market_Total_Deaths = cumulative_Sum_Market_Fatality;
					Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					DATE = &DAY_ZERO. + round(DAY,1);
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP LAG: CUM: ;
			RUN;

        /* TMODEL APPROACH FOR SEIR - adds SIMULATION APPROACH TO UNCERTAINTY BOUNDS */
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation");  
                    S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
                    E_N = &E.;
                    I_N = &I. / &DiagnosedRate.;
                    R_N = &InitRecovered.;
                    *R0  = &R_T.;
                    /* prevent range below zero on each loop */
                    DO SIGMA = IFN(&SIGMA<0.3,0,&SIGMA-.3) to &SIGMA+.3 by .2; /* range of .3, increment by .1 */
                        DO RECOVERYDAYS = IFN(&RecoveryDays<5,0,&RecoveryDays.-5) to &RecoveryDays.+5 by 2; /* range of 5, increment by 1*/
                            DO SOCIALD = IFN(&SocialDistancing<.1,0,&SocialDistancing.-.1) to &SocialDistancing.+.1 by .1; 
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
                                DO R0 = IFN((BETA / GAMMA * &Population.)-2<2,0,(BETA / GAMMA * &Population.)-2) to (BETA / GAMMA * &Population.)+2 by .25; /* range of 2, increment by .1*/
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

			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; performance nthreads=4 bypriority=1 partpriority=1; %END;
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
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
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
                            from TMODEL_SEIR_SIM
                            group by Date, ModelType, ScenarioIndex
                        ) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                drop table TMODEL_SEIR_SIM;
            QUIT;
			PROC APPEND base=work.MODEL_FINAL data=TMODEL_SEIR; run;
			PROC SQL; drop table TMODEL_SEIR; drop table DINIT; QUIT;
			
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
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;

			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='TMODEL - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Approach With Uncertainty Bounds";
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
	/*PROC TMODEL SIR APPROACH*/
		/* these are the calculations for variables used from above:
			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 AND &HAVE_SASETS = YES %THEN %DO;
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation"); 
					DO TIME = 0 TO &N_DAYS.; 
						S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
						E_N = &E.;
						I_N = &I. / &DiagnosedRate.;
						R_N = &InitRecovered.;
						R0  = &R_T.;
						OUTPUT; 
					END; 
				RUN;
			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
			%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
				/* PARAMETER SETTINGS */ 
				PARMS N &Population. R0 &R_T. R0_c1 &R_T_Change. R0_c2 &R_T_Change_Two. R0_c3 &R_T_Change_3. R0_c4 &R_T_Change_4.;
				BOUNDS 1 <= R0 <= 13;
				RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0, R0_c3 > 0, R0_c4 > 0;
				GAMMA = &GAMMA.;
				change_0 = (TIME < (&ISOChangeDate. - &DAY_ZERO.));
				change_1 = ((TIME >= (&ISOChangeDate. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));   
				change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));
				change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));
				change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         
				BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N + change_3*R0_c3*GAMMA/N + change_4*R0_c4*GAMMA/N;
				/* DIFFERENTIAL EQUATIONS */ 
				DERT.S_N = -BETA*S_N*I_N; 				
				DERT.I_N = BETA*S_N*I_N - GAMMA*I_N;   
				DERT.R_N = GAMMA*I_N;           
				/* SOLVE THE EQUATIONS */ 
				SOLVE S_N I_N R_N / OUT = TMODEL_SIR; 
			RUN;
			QUIT;

			DATA TMODEL_SIR;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;	
				ModelType="TMODEL - SIR";
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				RETAIN LAG_S LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
					CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
				LAG_S = S_N; 
				E_N = &E.; LAG_E = E_N;  /* placeholder for post-processing of SIR model */
				LAG_I = I_N; 
				LAG_R = R_N; 
				LAG_N = N; 
				SET TMODEL_SIR(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
				N = SUM(S_N, E_N, I_N, R_N);
				SCALE = LAG_N / N;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					Cumulative_sum_fatality + Fatality;
					CUMULATIVE_SUM_MARKET_HOSP + MARKET_HOSP;
					CUMULATIVE_SUM_MARKET_ICU + MARKET_ICU;
					CUMULATIVE_SUM_MARKET_VENT + MARKET_VENT;
					CUMULATIVE_SUM_MARKET_ECMO + MARKET_ECMO;
					CUMULATIVE_SUM_MARKET_DIAL + MARKET_DIAL;
					cumulative_Sum_Market_Fatality + Market_Fatality;
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_MARKET_DIAL));
					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					Deceased_Today = Fatality;
					Total_Deaths = Cumulative_sum_fatality;
					MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
					MARKET_HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
					MARKET_ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
					MARKET_VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
					MARKET_ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
					MARKET_DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
					Market_Deceased_Today = Market_Fatality;
					Market_Total_Deaths = cumulative_Sum_Market_Fatality;
					Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					DATE = &DAY_ZERO. + round(DAY,1);
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP LAG: CUM:;
			RUN;

        /* TMODEL APPROACH FOR SIR - adds SIMULATION APPROACH TO UNCERTAINTY BOUNDS */
			/*DATA FOR PROC TMODEL APPROACHES*/
				DATA DINIT(Label="Initial Conditions of Simulation");  
                    S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
                    E_N = &E.;
                    I_N = &I. / &DiagnosedRate.;
                    R_N = &InitRecovered.;
                    *R0  = &R_T.;
                    /* prevent range below zero on each loop */
                        DO RECOVERYDAYS = IFN(&RecoveryDays<5,0,&RecoveryDays.-5) to &RecoveryDays.+5 by 2; /* range of 5, increment by 1*/
                            DO SOCIALD = IFN(&SocialDistancing<.1,0,&SocialDistancing.-.1) to &SocialDistancing.+.1 by .1; 
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
                                DO R0 = IFN((BETA / GAMMA * &Population.)-2<2,0,(BETA / GAMMA * &Population.)-2) to (BETA / GAMMA * &Population.)+2 by .25; /* range of 2, increment by .1*/
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
				RUN;

			%IF &HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; performance nthreads=4 bypriority=1 partpriority=1; %END;
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
				/* c. inflow from b. - outflow through recovery or death during illness*/
				DERT.I_N = BETA*S_N*I_N - GAMMA*I_N;
				/* d. Recovered and death humans through "promotion" inflow from c.*/
				DERT.R_N = GAMMA*I_N;           
				/* SOLVE THE EQUATIONS */ 
				SOLVE S_N I_N R_N / TIME=TIME OUT = TMODEL_SIR_SIM; 
                by RECOVERYDAYS SOCIALD R0;
			RUN;
			QUIT;

            /* round time to integers - precision */
            proc sql;
                create table TMODEL_SIR_SIM as
                    select S_N as SE, RECOVERYDAYS, SOCIALD, R0, round(Time,1) as Time
                    from TMODEL_SIR_SIM
                    order by RECOVERYDAYS, SOCIALD, R0, Time
                ;
            quit;

            /* use a skeleton from the normal post-processing to processes every scenario.
                by statement used for separating scenarios - order by in sql above prepares this
                note that lag function used in conditional logic can be very tricky.
                The code below has logic to override the lag at the start of each by group.
            */
			DATA TMODEL_SIR_SIM;
				FORMAT ModelType $30. DATE date9. Scenarioname $30. ScenarioNameUnique $100.;
				ModelType="TMODEL - SIR";
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				RETAIN counter CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET TMODEL_SIR_SIM(RENAME=(TIME=DAY));
                by RECOVERYDAYS SOCIALD R0;
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
                KEEP ModelType ScenarioIndex DATE HOSPITAL_OCCUPANCY ICU_OCCUPANCY VENT_OCCUPANCY ECMO_OCCUPANCY DIAL_OCCUPANCY RECOVERYDAYS SOCIALD R0;
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
				where ModelType='TMODEL - SIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SIR Approach";
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
				where ModelType='TMODEL - SIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SIR Approach With Uncertainty Bounds";
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
	/* DATA STEP APPROACH FOR SEIR */
		/* these are the calculations for variables used from above:
			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 %THEN %DO;
			DATA DS_SEIR;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;		
				ModelType="DS - SEIR";
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				byinc = 0.1;
				DO DAY = 0 TO &N_DAYS. by byinc;
					IF DAY = 0 THEN DO;
						S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
						E_N = &E.;
						I_N = &I. / &DiagnosedRate.;
						R_N = &InitRecovered.;
						BETA = &BETA.;
						N = SUM(S_N, E_N, I_N, R_N);
					END;
					ELSE DO;
						BETA = LAG_BETA * (1 - &BETA_DECAY.);
						S_N = LAG_S - (BETA * LAG_S * LAG_I)*byinc;
						E_N = LAG_E + (BETA * LAG_S * LAG_I - &SIGMA. * LAG_E)*byinc;
						I_N = LAG_I + (&SIGMA. * LAG_E - &GAMMA. * LAG_I)*byinc;
						R_N = LAG_R + (&GAMMA. * LAG_I)*byinc;
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
					IF date = &ISOChangeDate. THEN BETA = &BETAChange.;
					ELSE IF date = &ISOChangeDateTwo. THEN BETA = &BETAChangeTwo.;
					ELSE IF date = &ISOChangeDate3. THEN BETA = &BETAChange3.;
					ELSE IF date = &ISOChangeDate4. THEN BETA = &BETAChange4.;
					LAG_BETA = BETA;
					IF abs(DAY - round(DAY,1)) < byinc/10 THEN DO;
						DATE = &DAY_ZERO. + round(DAY,1); /* brought forward from post-processing: examine location impact on ISOChangeDate* */
						OUTPUT;
					END;
				END;
				DROP LAG: BETA byinc;
			RUN;

			DATA DS_SEIR;
				SET DS_SEIR;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					Cumulative_sum_fatality + Fatality;
					CUMULATIVE_SUM_MARKET_HOSP + MARKET_HOSP;
					CUMULATIVE_SUM_MARKET_ICU + MARKET_ICU;
					CUMULATIVE_SUM_MARKET_VENT + MARKET_VENT;
					CUMULATIVE_SUM_MARKET_ECMO + MARKET_ECMO;
					CUMULATIVE_SUM_MARKET_DIAL + MARKET_DIAL;
					cumulative_Sum_Market_Fatality + Market_Fatality;
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_MARKET_DIAL));
					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					Deceased_Today = Fatality;
					Total_Deaths = Cumulative_sum_fatality;
					MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
					MARKET_HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
					MARKET_ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
					MARKET_VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
					MARKET_ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
					MARKET_DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
					Market_Deceased_Today = Market_Fatality;
					Market_Total_Deaths = cumulative_Sum_Market_Fatality;
					Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					DATE = &DAY_ZERO. + round(DAY,1);
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP CUM:;
			RUN;

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
		%END;

	/* DATA STEP APPROACH FOR SIR */
		/* these are the calculations for variablez used from above:
			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 %THEN %DO;
			DATA DS_SIR;
				FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;		
				ModelType="DS - SIR";
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				byinc = 0.1;
				DO DAY = 0 TO &N_DAYS. by byinc;
					IF DAY = 0 THEN DO;
						S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
						I_N = &I./&DiagnosedRate.;
						R_N = &InitRecovered.;
						BETA = &BETA.;
						N = SUM(S_N, I_N, R_N);
					END;
					ELSE DO;
						BETA = LAG_BETA * (1- &BETA_DECAY.);
						S_N = LAG_S - (BETA * LAG_S * LAG_I)*byinc;
						I_N = LAG_I + (BETA * LAG_S * LAG_I - &GAMMA. * LAG_I)*byinc;
						R_N = LAG_R + (&GAMMA. * LAG_I)*byinc;
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
					ELSE IF date = &ISOChangeDate3. THEN BETA = &BETAChange3.;
					ELSE IF date = &ISOChangeDate4. THEN BETA = &BETAChange4.;
					LAG_BETA = BETA;
					IF abs(DAY - round(DAY,1)) < byinc/10 THEN DO;
						DATE = &DAY_ZERO. + round(DAY,1); /* brought forward from post-processing: examine location impact on ISOChangeDate* */
						OUTPUT;
					END;
				END;
				DROP LAG: BETA byinc;
			RUN;

			DATA DS_SIR;
				SET DS_SIR;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					Cumulative_sum_fatality + Fatality;
					CUMULATIVE_SUM_MARKET_HOSP + MARKET_HOSP;
					CUMULATIVE_SUM_MARKET_ICU + MARKET_ICU;
					CUMULATIVE_SUM_MARKET_VENT + MARKET_VENT;
					CUMULATIVE_SUM_MARKET_ECMO + MARKET_ECMO;
					CUMULATIVE_SUM_MARKET_DIAL + MARKET_DIAL;
					cumulative_Sum_Market_Fatality + Market_Fatality;
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_MARKET_DIAL));
					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					Deceased_Today = Fatality;
					Total_Deaths = Cumulative_sum_fatality;
					MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
					MARKET_HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
					MARKET_ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
					MARKET_VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
					MARKET_ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
					MARKET_DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
					Market_Deceased_Today = Market_Fatality;
					Market_Total_Deaths = cumulative_Sum_Market_Fatality;
					Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					DATE = &DAY_ZERO. + round(DAY,1);
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
				/* END: Common Post-Processing Across each Model Type and Approach */
				DROP CUM:;
			RUN;

			PROC APPEND base=work.MODEL_FINAL data=DS_SIR NOWARN FORCE; run;
			PROC SQL; drop table DS_SIR; QUIT;

		%END;

		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='DS - SIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - Data Step SIR Approach";
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
		%END;

	/* PROC TMODEL SEIR APPROACH - WITH OHIO FIT INTERVENE */
		/* these are the calculations for variables used from above:
			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);
		*/
		/* If this is a new scenario then run it */
    	%IF &ScenarioExist = 0 AND &HAVE_SASETS = YES %THEN %DO;

			/* START DOWNLOAD FIT_INPUT - only if STORE.FIT_INPUT does not have data for yesterday */
				/* the file appears to be updated throughout the day but partial data for today could cause issues with fit */
				%IF %sysfunc(exist(STORE.FIT_INPUT)) %THEN %DO;
					PROC SQL NOPRINT; 
						SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.FIT_INPUT;
						SELECT MAX(DATE) into :LATEST_CASE FROM STORE.FIT_INPUT; 
					QUIT;
				%END;
				%ELSE %DO;
					%LET LATEST_CASE=0;
				%END;
					%IF &ScenarioSource. = BATCH %THEN %DO;
						%IF &LATEST_CASE. < %eval(%sysfunc(today())-2) %THEN %DO;
							FILENAME OHIO URL "https://coronavirus.ohio.gov/static/COVIDSummaryData.csv";
							OPTION VALIDVARNAME=V7;
							PROC IMPORT file=OHIO OUT=WORK.FIT_IMPORT DBMS=CSV REPLACE;
								GETNAMES=YES;
								DATAROW=2;
								GUESSINGROWS=20000000;
							RUN; 
							/* check to make sure column 1 is county and not VAR1 - sometime the URL is pulled quickly and this gets mislabeled*/
								%let dsid=%sysfunc(open(WORK.FIT_IMPORT));
								%let countnum=%sysfunc(varnum(&dsid.,var1));
								%let rc=%sysfunc(close(&dsid.));
								%IF &countnum. > 0 %THEN %DO;
									data WORK.FIT_IMPORT; set WORK.FIT_IMPORT; rename VAR1=COUNTY; run;
								%END;
							/* Prepare Ohio Data For Model - add rows for missing days (had no activity) */
								PROC SQL NOPRINT;
									CREATE TABLE WORK.FIT_INPUT AS 
										SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
										FROM WORK.FIT_IMPORT
										WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
											'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
											'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
										GROUP BY CALCULATED DATE
										ORDER BY CALCULATED DATE;
									SELECT MIN(DATE) INTO :FIRST_CASE FROM WORK.FIT_INPUT;
									SELECT MAX(DATE) INTO :LATEST_CASE FROM WORK.FIT_INPUT;
								QUIT;

								DATA ALLDATES;
									FORMAT DATE DATE9.;
									DO DATE = &FIRST_CASE. TO &LATEST_CASE.;
										TIME = DATE - &FIRST_CASE. + 1;
										OUTPUT;
									END;
								RUN;

								DATA STORE.FIT_INPUT;
									MERGE ALLDATES WORK.FIT_INPUT;
									BY DATE;
									CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
								RUN;

								PROC SQL NOPRINT;
									drop table ALLDATES;
									drop table WORK.FIT_INPUT;
								QUIT; 
						%END;
					%END;
            /* END DOWNLOAD FIT_INPUT **/
			/* Fit Model with Proc (t)Model (SAS/ETS) */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA = STORE.FIT_INPUT OUTMODEL=SEIRMOD_I NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA = STORE.FIT_INPUT OUTMODEL=SEIRMOD_I NOPRINT; %END;
					/* Parameters of interest */
					PARMS R0 &R_T. I0 &I. RI -1 DI &ISOChangeDate.;
					BOUNDS 1 <= R0 <= 13;
					RESTRICT RI + R0 > 0;
					/* Fixed values */
					N = &Population.;
					INF = &RecoveryDays.;
					SIGMA = &SIGMA.;
					STEP = CDF('NORMAL',DATE, DI, 1);
					/* Differential equations */
					GAMMA = 1 / INF;
					BETA = (R0 + RI*STEP) * GAMMA / N;
					/* Differential equations */
					/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
					DERT.S_N = -BETA * S_N * I_N;
					/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
					DERT.E_N = BETA * S_N * I_N - SIGMA * E_N;
					/* c. inflow from b. - outflow through recovery or death during illness*/
					DERT.I_N = SIGMA * E_N - GAMMA * I_N;
					/* d. Recovered and death humans through "promotion" inflow from c.*/
					DERT.R_N = GAMMA * I_N;
					CUMULATIVE_CASE_COUNT = I_N + R_N;
					/* Fit the data */
					FIT CUMULATIVE_CASE_COUNT INIT=(S_N=&Population. E_N=0 I_N=I0 R_N=0) / TIME=TIME DYNAMIC OUTPREDICT OUTACTUAL OUT=FIT_PRED LTEBOUND=1E-10 OUTEST=FIT_PARMS
						%IF &HAVE_V151. = YES %THEN %DO; OPTIMIZER=ORMP(OPTTOL=1E-5) %END;;
					OUTVARS S_N E_N I_N R_N;
				QUIT;

			/* Prepare output: fit data and parameter data */
				DATA FIT_PRED;
					SET FIT_PRED;
					LABEL CUMULATIVE_CASE_COUNT='Cumulative Incidence';
					FORMAT ModelType $30. DATE DATE9.; 
					DATE = &FIRST_CASE. + TIME - 1;
					ModelType="TMODEL - SEIR - FIT";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				run;
				DATA FIT_PARMS;
					SET FIT_PARMS;
					FORMAT ModelType $30.; 
					ModelType="TMODEL - SEIR - FIT";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
				run;

			/*Capture basline R0, date of Intervention effect, R0 after intervention*/
				PROC SQL NOPRINT;
					SELECT R0 INTO :R0_FIT FROM FIT_PARMS;
					SELECT "'"||PUT(DI,DATE9.)||"'"||"D" INTO :CURVEBEND1 FROM FIT_PARMS;
					SELECT SUM(R0,RI) INTO :R0_BEND_FIT FROM FIT_PARMS;
				QUIT;

			/*Calculate observed social distancing (and other interventions) percentage*/
				%LET SOC_DIST_FIT = %SYSEVALF(1 - &R0_BEND_FIT / &R0_FIT);

			/* DATA FOR PROC TMODEL APPROACHES */
				DATA DINIT(Label="Initial Conditions of Simulation"); 
					FORMAT DATE DATE9.; 
					DO TIME = 0 TO &N_DAYS.; 
						S_N = &Population. - (&I. / &DiagnosedRate.) - &InitRecovered.;
						E_N = &E.;
						I_N = &I. / &DiagnosedRate.;
						R_N = &InitRecovered.;
						R0  = &R_T.;
						DATE = &DAY_ZERO. + TIME;
						OUTPUT; 
					END; 
				RUN;

			/* Create SEIR Projections based R0 and first social distancing change from model fit above, plus additional change points */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA=DINIT NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA=DINIT NOPRINT; %END;
					/* PARAMETER SETTINGS */ 
					PARMS N &Population. R0 &R0_FIT. R0_c1 &R0_BEND_FIT. R0_c2 &R_T_Change_Two. R0_c3 &R_T_Change_3. R0_c4 &R_T_Change_4.; 
					BOUNDS 1 <= R0 <= 13;
					RESTRICT R0 > 0, R0_c1 > 0, R0_c2 > 0, R0_c3 > 0, R0_c4 > 0;
					GAMMA = &GAMMA.;
					SIGMA = &SIGMA.;
					change_0 = (TIME < (&CURVEBEND1. - &DAY_ZERO.));
					change_1 = ((TIME >= (&CURVEBEND1. - &DAY_ZERO.)) & (TIME < (&ISOChangeDateTwo. - &DAY_ZERO.)));  
					change_2 = ((TIME >= (&ISOChangeDateTwo. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate3. - &DAY_ZERO.)));
					change_3 = ((TIME >= (&ISOChangeDate3. - &DAY_ZERO.)) & (TIME < (&ISOChangeDate4. - &DAY_ZERO.)));
					change_4 = (TIME >= (&ISOChangeDate4. - &DAY_ZERO.)); 	         
					BETA = change_0*R0*GAMMA/N + change_1*R0_c1*GAMMA/N + change_2*R0_c2*GAMMA/N + change_3*R0_c3*GAMMA/N + change_4*R0_c4*GAMMA/N;
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
					SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR_FIT_I;
				RUN;
				QUIT;

				DATA TMODEL_SEIR_FIT_I;
					FORMAT ModelType $30. DATE ADMIT_DATE DATE9. Scenarioname $30. ScenarioNameUnique $100.;
					ModelType="TMODEL - SEIR - FIT";
					ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
					RETAIN LAG_S LAG_I LAG_R LAG_N CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL Cumulative_sum_fatality
						CUMULATIVE_SUM_MARKET_HOSP CUMULATIVE_SUM_MARKET_ICU CUMULATIVE_SUM_MARKET_VENT CUMULATIVE_SUM_MARKET_ECMO CUMULATIVE_SUM_MARKET_DIAL cumulative_Sum_Market_Fatality;
					LAG_S = S_N; 
					LAG_E = E_N; 
					LAG_I = I_N; 
					LAG_R = R_N; 
					LAG_N = N; 
					SET TMODEL_SEIR_FIT_I(RENAME=(TIME=DAY) DROP=_ERRORS_ _MODE_ _TYPE_);
					N = SUM(S_N, E_N, I_N, R_N);
					SCALE = LAG_N / N;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					Cumulative_sum_fatality + Fatality;
					CUMULATIVE_SUM_MARKET_HOSP + MARKET_HOSP;
					CUMULATIVE_SUM_MARKET_ICU + MARKET_ICU;
					CUMULATIVE_SUM_MARKET_VENT + MARKET_VENT;
					CUMULATIVE_SUM_MARKET_ECMO + MARKET_ECMO;
					CUMULATIVE_SUM_MARKET_DIAL + MARKET_DIAL;
					cumulative_Sum_Market_Fatality + Market_Fatality;
					CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;
					CUMMARKETADMITLAG=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_MARKET_HOSP));
					CUMMARKETICULAG=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_MARKET_ICU));
					CUMMARKETVENTLAG=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_MARKET_VENT));
					CUMMARKETECMOLAG=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_MARKET_ECMO));
					CUMMARKETDIALLAG=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_MARKET_DIAL));
					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					Deceased_Today = Fatality;
					Total_Deaths = Cumulative_sum_fatality;
					MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
					MARKET_HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_HOSP-CUMMARKETADMITLAG,1);
					MARKET_ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ICU-CUMMARKETICULAG,1);
					MARKET_VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_VENT-CUMMARKETVENTLAG,1);
					MARKET_ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_ECMO-CUMMARKETECMOLAG,1);
					MARKET_DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_MARKET_DIAL-CUMMARKETDIALLAG,1);	
					Market_Deceased_Today = Market_Fatality;
					Market_Total_Deaths = cumulative_Sum_Market_Fatality;
					Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					DATE = &DAY_ZERO. + round(DAY,1);
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
				/* END: Common Post-Processing Across each Model Type and Approach */
					DROP LAG: CUM: ;
				RUN;

				PROC APPEND base=work.MODEL_FINAL data=TMODEL_SEIR_FIT_I NOWARN FORCE; run;
				PROC SQL; 
					drop table TMODEL_SEIR_FIT_I;
					drop table DINIT;
					drop table SEIRMOD_I;
				QUIT;

		%END;

		%IF &PLOTS. = YES AND &HAVE_SASETS = YES %THEN %DO;

			%IF &ScenarioExist ~= 0 %THEN %DO;
				/* this is only needed to define macro varibles if the fit is being recalled.  
					If it is being run above these will already be defined */
					/*Capture basline R0, date of Intervention effect, R0 after intervention*/
						PROC SQL NOPRINT;
							SELECT R0 INTO :R0_FIT FROM FIT_PARMS;
							SELECT "'"||PUT(DI,DATE9.)||"'"||"D" INTO :CURVEBEND1 FROM FIT_PARMS;
							SELECT SUM(R0,RI) INTO :R0_BEND_FIT FROM FIT_PARMS;
						QUIT;

					/*Calculate observed social distancing (and other interventions) percentage*/
						%LET SOC_DIST_FIT = %SYSEVALF(1 - &R0_BEND_FIT / &R0_FIT);
			%END;

			/* Plot Fit of Actual v. Predicted */
			PROC SGPLOT DATA=work.FIT_PRED;
				WHERE _TYPE_  NE 'RESIDUAL' and ModelType='TMODEL - SEIR - FIT' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Actual v. Predicted Infections in Region";
				TITLE2 "Initial R0: %SYSFUNC(round(&R0_FIT.,.01))";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
				SERIES X=DATE Y=CUMULATIVE_CASE_COUNT / LINEATTRS=(THICKNESS=2) GROUP=_TYPE_  MARKERS NAME="cases";
				FORMAT CUMULATIVE_CASE_COUNT COMMA10.;
			RUN;
			TITLE;TITLE2;TITLE3;

			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='TMODEL - SEIR - FIT' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach";
				TITLE2 "Scenario: &Scenario., Initial Observed R0: %SYSFUNC(round(&R0_FIT.,.01))";
				TITLE3 "Adjusted Observed R0 after %sysfunc(INPUTN(&CURVEBEND1., date10.), date9.): %SYSFUNC(round(&R0_BEND_FIT.,.01)) with Observed Social Distancing of %SYSFUNC(round(%SYSEVALF(&SOC_DIST_FIT.*100)))%";
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
		%END;

    %IF &PLOTS. = YES %THEN %DO;
        /* if multiple models for a single scenarioIndex then plot them */
        PROC SQL noprint;
            select count(*) into :scenplot from (select distinct ModelType from work.MODEL_FINAL where ScenarioIndex=&ScenarioIndex.);
        QUIT;
        %IF &scenplot > 1 %THEN %DO;
            PROC SGPLOT DATA=work.MODEL_FINAL;
                where ScenarioIndex=&ScenarioIndex.;
                TITLE "Daily Hospital Occupancy - All Approaches";
                TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
                TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
                TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
				TITLE5 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate3., date10.), date9.): %SYSFUNC(round(&R_T_Change_3.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange3.*100)%";
				TITLE6 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate4., date10.), date9.): %SYSFUNC(round(&R_T_Change_4.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange4.*100)%";
                SERIES X=DATE Y=HOSPITAL_OCCUPANCY / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                XAXIS LABEL="Date";
                YAXIS LABEL="Daily Occupancy";
            RUN;
            TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;
        %END;	
    %END;

    /* code to manage output tables in STORE and CAS table management (coming soon) */
        %IF &ScenarioExist = 0 %THEN %DO;

				/*CREATE FLAGS FOR DAYS WITH PEAK VALUES OF DIFFERENT METRICS*/
					PROC SQL;
						CREATE TABLE work.MODEL_FINAL AS
							SELECT MF.*, HOSP.PEAK_HOSPITAL_OCCUPANCY, ICU.PEAK_ICU_OCCUPANCY, VENT.PEAK_VENT_OCCUPANCY, 
								ECMO.PEAK_ECMO_OCCUPANCY, DIAL.PEAK_DIAL_OCCUPANCY, I.PEAK_I_N, FATAL.PEAK_FATALITY
							FROM work.MODEL_FINAL MF
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, HOSPITAL_OCCUPANCY, 1 AS PEAK_HOSPITAL_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING HOSPITAL_OCCUPANCY=MAX(HOSPITAL_OCCUPANCY)
											) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) HOSP
									ON MF.MODELTYPE = HOSP.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = HOSP.SCENARIONAMEUNIQUE
										AND MF.DATE = HOSP.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, ICU_OCCUPANCY, 1 AS PEAK_ICU_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING ICU_OCCUPANCY=MAX(ICU_OCCUPANCY)
											) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) ICU
									ON MF.MODELTYPE = ICU.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = ICU.SCENARIONAMEUNIQUE
										AND MF.DATE = ICU.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, VENT_OCCUPANCY, 1 AS PEAK_VENT_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING VENT_OCCUPANCY=MAX(VENT_OCCUPANCY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) VENT
									ON MF.MODELTYPE = VENT.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = VENT.SCENARIONAMEUNIQUE
										AND MF.DATE = VENT.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, ECMO_OCCUPANCY, 1 AS PEAK_ECMO_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING ECMO_OCCUPANCY=MAX(ECMO_OCCUPANCY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) ECMO
									ON MF.MODELTYPE = ECMO.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = ECMO.SCENARIONAMEUNIQUE
										AND MF.DATE = ECMO.DATE
								LEFT JOIN
									(SELECT * FROM
										(SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, DIAL_OCCUPANCY, 1 AS PEAK_DIAL_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING DIAL_OCCUPANCY=MAX(DIAL_OCCUPANCY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) DIAL
									ON MF.MODELTYPE = DIAL.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = DIAL.SCENARIONAMEUNIQUE
										AND MF.DATE = DIAL.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, I_N, 1 AS PEAK_I_N
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING I_N=MAX(I_N)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) I
									ON MF.MODELTYPE = I.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = I.SCENARIONAMEUNIQUE
										AND MF.DATE = I.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, FATALITY, 1 AS PEAK_FATALITY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING FATALITY=MAX(FATALITY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) FATAL
									ON MF.MODELTYPE = FATAL.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = FATAL.SCENARIONAMEUNIQUE
										AND MF.DATE = FATAL.DATE
							ORDER BY SCENARIONAMEUNIQUE, MODELTYPE, DATE;
					QUIT;
				/* use proc datasets to apply labels to each column of output data table
					except INPUTS which is documented right after the %EasyRun definition
				 */
					PROC DATASETS LIB=WORK NOPRINT;
						MODIFY MODEL_FINAL;
							LABEL
								ADMIT_DATE = "Date of Admission"
								DATE = "Date of Infection"
								DAY = "Day of Pandemic"
								HOSP = "New Hospitalized Patients"
								HOSPITAL_OCCUPANCY = "Current Hospitalized Census"
								MARKET_HOSP = "New Region Hospitalized Patients"
								MARKET_HOSPITAL_OCCUPANCY = "Current Region Hospitalized Census"
								ICU = "New Hospital ICU Patients"
								ICU_OCCUPANCY = "Current Hospital ICU Census"
								MARKET_ICU = "New Region ICU Patients"
								MARKET_ICU_OCCUPANCY = "Current Region ICU Census"
								MedSurgOccupancy = "Current Hospital Medical and Surgical Census (non-ICU)"
								Market_MedSurg_Occupancy = "Current Region Medical and Surgical Census (non-ICU)"
								VENT = "New Hospital Ventilator Patients"
								VENT_OCCUPANCY = "Current Hospital Ventilator Patients"
								MARKET_VENT = "New Region Ventilator Patients"
								MARKET_VENT_OCCUPANCY = "Current Region Ventilator Patients"
								DIAL = "New Hospital Dialysis Patients"
								DIAL_OCCUPANCY = "Current Hospital Dialysis Patients"
								MARKET_DIAL = "New Region Dialysis Patients"
								MARKET_DIAL_OCCUPANCY = "Current Region Dialysis Patients"
								ECMO = "New Hospital ECMO Patients"
								ECMO_OCCUPANCY = "Current Hospital ECMO Patients"
								MARKET_ECMO = "New Region ECMO Patients"
								MARKET_ECMO_OCCUPANCY = "Current Region ECMO Patients"
								Deceased_Today = "New Hospital Mortality"
								Fatality = "New Hospital Mortality"
								Total_Deaths = "Cumulative Hospital Mortality"
								Market_Deceased_Today = "New Region Mortality"
								Market_Fatality = "New Region Mortality"
								Market_Total_Deaths = "Cumulative Region Mortality"
								N = "Region Population"
								S_N = "Current Susceptible Population"
								E_N = "Current Exposed Population"
								I_N = "Current Infected Population"
								R_N = "Current Recovered Population"
								NEWINFECTED = "New Infected Population"
								ModelType = "Model Type Used to Generate Scenario"
								SCALE = "Ratio of Previous Day Population to Current Day Population"
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								Scenarioname = "Scenario Name"
								LOWER_HOSPITAL_OCCUPANCY="Lower Bound: Current Hospitalized Census"
								LOWER_ICU_OCCUPANCY="Lower Bound: Current Hospital ICU Census"
								LOWER_VENT_OCCUPANCY="Lower Bound: Current Hospital Ventilator Patients"
								LOWER_ECMO_OCCUPANCY="Lower Bound: Current Hospital ECMO Patients"
								LOWER_DIAL_OCCUPANCY="Lower Bound: Current Hospital Dialysis Patients"
								UPPER_HOSPITAL_OCCUPANCY="Upper Bound: Current Hospitalized Census"
								UPPER_ICU_OCCUPANCY="Upper Bound: Current Hospital ICU Census"
								UPPER_VENT_OCCUPANCY="Upper Bound: Current Hospital Ventilator Patients"
								UPPER_ECMO_OCCUPANCY="Upper Bound: Current Hospital ECMO Patients"
								UPPER_DIAL_OCCUPANCY="Upper Bound: Current Hospital Dialysis Patients"
								PEAK_HOSPITAL_OCCUPANCY = "Day Peak Hospital Occupancy First Occurs"
								PEAK_ICU_OCCUPANCY = "Day Peak ICU Occupancy First Occurs"
								PEAK_VENT_OCCUPANCY = "Day Peak Ventilator Patients First Occurs"
								PEAK_ECMO_OCCUPANCY = "Day Peak ECMO Patients First Occurs"
								PEAK_DIAL_OCCUPANCY = "Day Peak Dialysis Patients First Occurs"
								PEAK_I_N = "Day Peak Current Infected Population First Occurs"
								PEAK_FATALITY = "Day Peak New Hospital Mortality First Occurs"
								;
							MODIFY SCENARIOS;
							LABEL
								scope = "Source Macro for variable"
								name = "Name of the macro variable"
								offset = "Offset for long character macro variables (>200 characters)"
								value = "The value of macro variable name"
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								Stage = "INPUT for input variables - MODEL for all variables"
								;
							MODIFY INPUTS;
							LABEL
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								;
							MODIFY FIT_PRED;
							LABEL
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								;
							MODIFY FIT_PARMS;
							LABEL
								ScenarioIndex = "Scenario ID: Order"
								ScenarioSource = "Scenario ID: Source (BATCH or UI)"
								ScenarioUser = "Scenario ID: User who created Scenario"
								ScenarioNameUnique = "Unique Scenario Name"
								;
					RUN;
					QUIT;

                %IF &ScenarioSource = BATCH %THEN %DO;
                
                    PROC APPEND base=store.MODEL_FINAL data=work.MODEL_FINAL NOWARN FORCE; run;
                    PROC APPEND base=store.SCENARIOS data=work.SCENARIOS; run;
                    PROC APPEND base=store.INPUTS data=work.INPUTS; run;
                    PROC APPEND base=store.FIT_PRED data=work.FIT_PRED; run;
                    PROC APPEND base=store.FIT_PARMS data=work.FIT_PARMS; run;

                    PROC SQL;
                        drop table work.MODEL_FINAL;
                        drop table work.SCENARIOS;
                        drop table work.INPUTS;
                        drop table work.FIT_PRED;
                        drop table work.FIT_PARMS;
                    QUIT;

                %END;

        %END;
        /*%ELSE %IF &PLOTS. = YES %THEN %DO;*/
        %ELSE %DO;
            %IF &ScenarioSource = BATCH %THEN %DO;
                PROC SQL; 
                    drop table work.MODEL_FINAL;
                    drop table work.SCENARIOS;
                    drop table work.INPUTS; 
                    drop table work.FIT_PRED;
                    drop table work.FIT_PARMS;
                QUIT;
            %END;
        %END;
%mend;


