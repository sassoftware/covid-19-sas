/*SAS Studio program COVID_19*/
/*%STPBegin;*/

/*need to add: Shift to the right based on X days input (for delay in admission)*/
/* ICU step down (this would be x% of ICU LOS is ICU and the rest is added to )  */
/*Basic parameter input for 'Non Covid beds occupied'  */
/*Mild/Severe/Critical  */
%let homedir = /sas/data/ccf_preprod/finance/sas/EA_COVID_19/COVID_Scenarios;
libname store "&homedir.";
/* Depending on which SAS products you have and which releases you have these options will turn components of this code on/off */
%LET HAVE_SASETS = NO; /* YES implies you have SAS/ETS software, this enable the PROC MODEL methods in this code.  Without this the Data Step SIR model still runs */
%LET HAVE_V151 = NO; /* YES implies you have products verison 15.1 (latest) and switches PROC MODEL to PROC TMODEL for faster execution */
%LET CAS_LOAD = NO; /* YES implies you have SAS Viya and want to keep the output tables of this process managed in a CAS library for use in SAS Viya products (like Visual Analytics for reporting) */

/* the following is specific to CCF coding and included prior to the %EasyRun Macro */
	libname DL_RA teradata server=tdprod1 database=DL_RiskAnalytics;
	libname DL_COV teradata server=tdprod1 database=DL_COVID;
	libname CovData '/sas/data/ccf_preprod/finance/sas/EA_COVID_19/CovidData';
	proc datasets lib=work kill;run;quit;

	proc sql; 
	connect to teradata(Server=tdprod1);
	create table CovData.PullRealCovid as select * from connection to teradata 

	(
	Select COVID_RESULT_V.*, DEP_STATE from DL_COVID.COVID_RESULT_V
	LEFT JOIN (SELECT DISTINCT COVID_FACT_V.patient_identifier,COVID_FACT_V.DEP_STATE from DL_COVID.COVID_FACT_V) dep_st
	on dep_st.patient_identifier = COVID_RESULT_V.patient_identifier
	WHERE COVIDYN = 'YES' and DEP_STATE='OH'and discharge_Cat in ('Inpatient','Discharged To Home');
	)

	;quit;
	PROC SQL;
	CREATE TABLE CovData.PullRealAdmitCovid AS 
	SELECT /* AdmitDate */
				(datepart(t1.HSP_ADMIT_DTTM)) FORMAT=Date9. AS AdmitDate, 
			/* COUNT_DISTINCT_of_patient_identi */
				(COUNT(DISTINCT(t1.patient_identifier))) AS TrueDailyAdmits, 
			/* SumICUNum_1 */
				(SUM(input(t1.ICU, 3.))) AS SumICUNum_1, 
			/* SumICUNum */
				(SUM(case when t1.ICU='YES' then 1
				else case when t1.ICU='1' then 1 else 0
				end end)) AS SumICUNum
		FROM CovData.PULLREALCOVID t1
		GROUP BY (CALCULATED AdmitDate);
	QUIT;
	PROC SQL;
	CREATE TABLE CovData.RealCovid_DischargeDt AS 
	SELECT /* COUNT_of_patient_identifier */
				(COUNT(t1.patient_identifier)) AS TrueDailyDischarges, 
			/* DischargDate */
				(datepart(t1.HSP_DISCH_DTTM)) FORMAT=Date9. AS DischargDate, 
			/* SUMICUDISCHARGE */
				(SUM(Case when t1.DISCHARGEICUYN ='YES' then 1
				else case when t1.DISCHARGEICUYN ='1' then 1
				else 0
				end end)) AS SUMICUDISCHARGE
		FROM CovData.PULLREALCOVID t1
		WHERE (CALCULATED DischargDate) NOT = .
		GROUP BY (CALCULATED DischargDate);
	QUIT;

%macro EasyRun(Scenario,GeographyInput,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,
                SocialDistancing,
                ISOChangeDate,SocialDistancingChange,
                ISOChangeDateTwo,SocialDistancingChangeTwo,
                ISOChangeDate3,SocialDistancingChange3,
                ISOChangeDate4,SocialDistancingChange4,
                
                BETADecayChangeDate5,BETADecayChange5,
                BETADecayChangeDate6,BETADecayChange6,
                BETADecayChangeDate7,BETADecayChange7,
                BETADecayChangeDate8,BETADecayChange8,
                BETADecayChangeDate9,BETADecayChange9,
                BETADecayChangeDate10,BETADecayChange10,
                
                MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate,
                plots=no,N_DAYS=365,DiagnosedRate=1.0,E=0,SIGMA=1,DAY_ZERO='13MAR2020'd,BETA_DECAY=0.0,
                ECMO_RATE=0.03,DIAL_RATE=0.05,HOSP_LOS=7,ICU_LOS=9,VENT_LOS=10,ECMO_LOS=6,DIAL_LOS=11);

    DATA INPUTS;
        FORMAT
            Scenario                    $300.   
            GeographyInput				$100.
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
            
            BETADecayChangeDate5        DATE9.    
            BETADecayChange5     		BEST12.
            BETDecayChangeDate6         DATE9.    
            BETADecayChange6    		BEST12.
            BETADecayChangeDate7        DATE9.    
           	BETADecayChange7     		BEST12.
            BETADecayChangeDate8        DATE9.    
            BETADecaygChange8     		BEST12.
           	BETADecayChangeDate9        DATE9.    
           	BETADecayChange9     		BEST12.
            BETADecayChangeDate10       DATE9.    
           	BETADecayChange10    		BEST12.
            
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
            GeographyInput				=	"Geographical region"
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
            
            BETADecayChangeDate5              =   "Date of fourth change in social distancing parameter"
            BETADecayChange5     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            BETADecayChangeDate6              =   "Date of fourth change in social distancing parameter"
            BETADecayChange6     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            BETADecayChangeDate7              =   "Date of fourth change in social distancing parameter"
            BETADecayChange7     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            BETADecayChangeDate8              =   "Date of fourth change in social distancing parameter"
            BETADecayChange8     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            BETADecayChangeDate9              =   "Date of fourth change in social distancing parameter"
            BETADecayChange9     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            BETADecayChangeDate10              =   "Date of fourth change in social distancing parameter"
            BETADecayChange10     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)"
            
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
        GeographyInput				=	"&GeographyInput";
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
        
        BETADecayChangeDate5              =   &BETADecayChangeDate5.;
        BETADecayChange5     =   &BETADecayChange5.;
        BETADecayChangeDate6              =   &BETADecayChangeDate6.;
        BETADecayChange6     =   &BETADecayChange6.;
        BETADecayChangeDate7              =   &BETADecayChangeDate7.;
        BETADecayChange7     =   &BETADecayChange7.;
        BETADecayChangeDate8              =   &BETADecayChangeDate8.;
        BETADecayChange8     =   &BETADecayChange8.;
        BETADecayChangeDate9              =   &BETADecayChangeDate9.;
        BETADecayChange9     =   &BETADecayChange9.;
        BETADecayChangeDate10             =   &BETADecayChangeDate10.;
        BETADecayChange10    =   &BETADecayChange10.;
        
        
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

    /* create an index, ScenarioIndex for this run by incrementing the max value of ScenarioIndex in SCENARIOS dataset */
        %IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
            PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from store.scenarios; quit;
        %END;
        %ELSE %DO; %LET ScenarioIndex_Base = 0; %END;
    /* store all the macro variables that set up this scenario in SCENARIOS dataset */
        DATA SCENARIOS;
            set sashelp.vmacro(where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE') then delete;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
            STAGE='INPUT';
        RUN;
        DATA INPUTS; 
            set INPUTS;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
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
/* 	THIS WILL CALCULATE BETA CHANAGE with 1% SD CHANGE				 */
				%LET BetaIncrement= %SYSEVALF((((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / &Population. *(1 - .01))
				- (((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / &Population. *(1 - 0)));
				%put &betaincrement;								
												
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
				
/* 				%LET R_T_Change_5 = %SYSEVALF(&BETAChange5. / &GAMMA. * &Population.); */
/* 				%LET R_T_Change_6 = %SYSEVALF(&BETAChange6. / &GAMMA. * &Population.); */
/* 				%LET R_T_Change_7 = %SYSEVALF(&BETAChange7. / &GAMMA. * &Population.); */
/* 				%LET R_T_Change_8 = %SYSEVALF(&BETAChange8. / &GAMMA. * &Population.); */
/* 				%LET R_T_Change_9 = %SYSEVALF(&BETAChange9. / &GAMMA. * &Population.); */
/* 				%LET R_T_Change_10 = %SYSEVALF(&BETAChange10. / &GAMMA. * &Population.); */
/* 				 */

        DATA SCENARIOS;
            set SCENARIOS sashelp.vmacro(in=i where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE') then delete;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
            if i then STAGE='MODEL';
        RUN;
    /* Check to see if SCENARIOS (this scenario) has already been run before in SCENARIOS dataset */
        %IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
            PROC SQL noprint;
                /* has this scenario been run before - all the same parameters and value - no more and no less */
                select count(*) into :ScenarioExist from
                    (select t1.ScenarioIndex, t2.ScenarioIndex
                        from 
                            (select *, count(*) as cnt 
                                from work.SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT','PLOTS')
                                group by ScenarioIndex) t1
                            join
                            (select * from store.SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT','PLOTS')) t2
                            on t1.name=t2.name and t1.value=t2.value and t1.STAGE=t2.STAGE
                        group by t1.ScenarioIndex, t2.ScenarioIndex, t1.cnt
                        having count(*) = t1.cnt)
                ; 
            QUIT;
        %END; 
        %ELSE %DO; 
            %LET ScenarioExist = 0;
        %END;
        %IF &ScenarioExist = 0 %THEN %DO;
            PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex from work.SCENARIOS; QUIT;
        %END;
        %ELSE %IF &PLOTS. = YES %THEN %DO;
            /* what was the last ScenarioIndex value that matched the requested scenario - store that in ScenarioIndex */
            PROC SQL noprint; /* can this be combined with the similar code above that counts matching scenarios? */
				select max(t2.ScenarioIndex) into :ScenarioIndex from
                    (select t1.ScenarioIndex, t2.ScenarioIndex
                        from 
                            (select *, count(*) as cnt 
                                from work.SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT','PLOTS')
                                group by ScenarioIndex) t1
                            join
                            (select * from store.SCENARIOS
                                where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT','PLOTS')) t2
                            on t1.name=t2.name and t1.value=t2.value and t1.STAGE=t2.STAGE
                        group by t1.ScenarioIndex, t2.ScenarioIndex, t1.cnt
                        having count(*) = t1.cnt)
                ;
            QUIT;
            /* pull the current scenario data to work for plots below */
            data work.MODEL_FINAL; set STORE.MODEL_FINAL; where ScenarioIndex=&ScenarioIndex.; run;
        %END;
        
    /* Prepare to create request plots from input parameter plots= */
        %IF %UPCASE(&plots.) = YES %THEN %DO; %LET plots = YES; %END;
        %ELSE %DO; %LET plots = NO; %END;



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
				FORMAT ModelType $30. Scenarioname $300. Date ADMIT_DATE DATE9.;		
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
					
						Beta_Decay = 0;
						if (&BETADecayChangeDate5.<date<intnx('day',&BETADecayChangeDate5.,15)) then Beta_Decay = &BETADecayChange5.;
						else if (&BETADecayChangeDate6.<date<intnx('day',&BETADecayChangeDate6.,15)) then Beta_Decay =&BETADecayChange6.;
						else if (&BETADecaychangedate7.<date<intnx('day',&BETADecaychangedate7.,15)) THEN Beta_Decay = &BETADecayChange7.;
						else if (&BETADecayChangeDate8.<date<intnx('day',&BETADecayChangeDate8.,15)) then Beta_Decay =&BETADecayChange8.;
						else if (&BETADecayChangeDate9.<date<intnx('day',&BETADecayChangeDate9.,15)) then Beta_Decay =&BETADecayChange9.;
						else if (&BETADecayChangeDate10.<date<intnx('day',&BETADecayChangeDate10.,15)) then Beta_Decay =&BETADecayChange10.;
						else Beta_Decay = 0;
/* 						if date > &BETADecaychangedate5. THEN Beta_Decay = &BETADecayChange5.; */
/* 						if date > &BETADecayChangeDate6. then Beta_Decay =&BETADecayChange6.; */
/* 						if date > &BETADecaychangedate7. THEN Beta_Decay = &BETADecayChange7.; */
/* 						if date > &BETADecayChangeDate8. then Beta_Decay =&BETADecayChange8.; */
/* 						if date > &BETADecayChangeDate9. then Beta_Decay =&BETADecayChange9.; */
/* 						if date > &BETADecayChangeDate10. then Beta_Decay =&BETADecayChange10.; */
						BETA = LAG_BETA - (Beta_Decay*.00248575/14)/&Population.;/*.00248575*/
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
					ELSE IF date = &ISOChangeDate3. THEN BETA = &BETAChange3.;
					ELSE IF date = &ISOChangeDate4. THEN BETA = &BETAChange4.;
					
/* 					ELSE IF date = &BETADecayChangeDate5. THEN BETA = &BETADecayChange5.; */
/* 					ELSE IF date = &BETADecayChangeDate6. THEN BETA = &BETADecayChange6.; */
/* 					ELSE IF date = &BETADecayChangeDate7. THEN BETA = &BETADecayChange7.; */
/* 					ELSE IF date = &BETADecayChangeDate8. THEN BETA = &BETADecayChange8.; */
/* 					ELSE IF date = &BETADecayChangeDate9. THEN BETA = &BETADecayChange9.; */
/* 					ELSE IF date = &BETADecayChangeDate10. THEN BETA = &BETADecayChange10.; */
					
					
					
					LAG_BETA = BETA;
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
					Date = &DAY_ZERO. + DAY;
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);

/* CumSumTrueAdmits + TrueDailyAdmits; */
/* CumSumTrueDischarges + TrueDailyDischarges; */
/* CumSumICU + SumICUNum; */
/* CumSumICUDischarge + SumICUNum_Discharge; */


/* True_CCF_Occupancy=CumSumTrueAdmits-CumSumTrueDischarges; */

/* TrueCCF_ICU_Occupancy=CumSumICU-CumSumICUDischarge; */
/*day logic for tableau views*/
/* if date>(today()-3) then Hospital_Occupancy_PP=Hospital_Occupancy; else Hospital_Occupancy_PP=.; */
/* if date>(today()-3) then ICU_Occupancy_PP=ICU_Occupancy; else ICU_Occupancy_PP=.; */
/* if date>(today()-3) then Vent_Occupancy_PP=Vent_Occupancy; else Vent_Occupancy_PP=.; */
/* if date>(today()-3) then ECMO_Occupancy_PP=ECMO_Occupancy; else ECMO_Occupancy_PP=.; */
/* if date>(today()-3) then DIAL_Occupancy_PP=DIAL_Occupancy; else DIAL_Occupancy_PP=.; */

/* if date>today() then True_CCF_Occupancy=.; */
/* if date>today() then TrueCCF_ICU_Occupancy=.; */

INPUT_Geography="&GeographyInput";

INPUT_Recovery_Time				=&RecoveryDays;
INPUT_Doubling_Time				=&doublingtime;
INPUT_Starting_Admits			=&KnownAdmits;

INPUT_Population				=&Population;
INPUT_Social_DistancingCombo	="&SocialDistancing"||"/"||"&SocialDistancingChange"||"/"||"&SocialDistancingChangeTwo"||"/"||"&SocialDistancingChange3"||"/"||"&SocialDistancingChange4";
INPUT_Social_Distancing_Date	=Put(&day_Zero,date9.) ||" - "|| put(&ISOChangeDate,date9.) ||" - "|| put(&ISOChangeDatetwo,date9.) ||" - "|| put(&ISOChangeDate3,date9.) ||" - "|| put(&ISOChangeDate4,date9.);
INPUT_Market_Share				=&MarketSharePercent;
INPUT_Admit_Percent_of_Infected	=&Admission_Rate;
INPUT_ICU_Percent_of_Admits		=&ICU_RATE;
INPUT_Vent_Percent_of_Admits	=&Vent_Rate;
/*paste overarching scenario variables*/
INPUT_Mortality_RateInput		=&FatalityRate;

INPUT_Length_of_Stay			=&HOSP_LOS; 
INPUT_ICU_LOS					=&ICU_LOS; 
INPUT_Vent_LOS					=&VENT_LOS; 
INPUT_Ecmo_Percent_of_Admits	=&ecmo_Rate; 
INPUT_Ecmo_LOS_Input			=&ecmo_los;
INPUT_Dialysis_PErcent			=&Dial_Rate; 
INPUT_Dialysis_LOS				=&Dial_LOS;
INPUT_Time_Zero					="&day_Zero"d;
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
						ScenarioIndex = "Unique Scenario ID"
						ScenarionNameUnique = "Unique Scenario Name"
						Scenarioname = "Scenario Name"
						;
				/* END: Common Post-Processing Across each Model Type and Approach */
					OUTPUT;
				END;
				DROP LAG: BETA CUM: ;
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


	/* PROC TMODEL SEIR APPROACH - WITH OHIO FIT */
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
			/*DOWNLOAD CSV - only if STORE.OHIO_SUMMARY does not have data for yesterday */
				/* the file appears to be updated throughout the day but partial data for today could cause issues with fit */
				%IF %sysfunc(exist(STORE.OHIO_SUMMARY)) %THEN %DO;
					PROC SQL NOPRINT; 
						SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.OHIO_SUMMARY;
						SELECT MAX(DATE) into :LATEST_CASE FROM STORE.OHIO_SUMMARY; 
					QUIT;
				%END;
				%ELSE %DO;
					%LET LATEST_CASE=0;
				%END;
					%IF &LATEST_CASE. < %eval(%sysfunc(today())-2) %THEN %DO;
						FILENAME OHIO URL "https://coronavirus.ohio.gov/static/COVIDSummaryData.csv";
						OPTION VALIDVARNAME=V7;
						PROC IMPORT file=OHIO OUT=WORK.OHIO_SUMMARY DBMS=CSV REPLACE;
							GETNAMES=YES;
							DATAROW=2;
							GUESSINGROWS=20000000;
						RUN; 
						/* check to make sure column 1 is county and not VAR1 - sometime the URL is pulled quickly and this gets mislabeled*/
							%let dsid=%sysfunc(open(WORK.OHIO_SUMMARY));
							%let countnum=%sysfunc(varnum(&dsid.,var1));
							%let rc=%sysfunc(close(&dsid.));
							%IF &countnum. > 0 %THEN %DO;
								data WORK.OHIO_SUMMARY; set WORK.OHIO_SUMMARY; rename VAR1=COUNTY; run;
							%END;
						/* Prepare Ohio Data For Model - add rows for missing days (had no activity) */
							PROC SQL NOPRINT;
								CREATE TABLE STORE.OHIO_SUMMARY AS 
									SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
									FROM WORK.OHIO_SUMMARY
									WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
										'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
										'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
									GROUP BY CALCULATED DATE
									ORDER BY CALCULATED DATE;
								SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.OHIO_SUMMARY;
								SELECT MAX(DATE) INTO :LATEST_CASE FROM STORE.OHIO_SUMMARY;
								DROP TABLE WORK.OHIO_SUMMARY;
							QUIT;

							DATA ALLDATES;
								FORMAT DATE DATE9.;
								DO DATE = &FIRST_CASE. TO &LATEST_CASE.;
									TIME = DATE - &FIRST_CASE. + 1;
									OUTPUT;
								END;
							RUN;

							DATA STORE.OHIO_SUMMARY;
								MERGE ALLDATES STORE.OHIO_SUMMARY;
								BY DATE;
								CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
							RUN;

							PROC SQL NOPRINT;
								drop table ALLDATES;
							QUIT; 
					%END;

			/* Fit Model with Proc (t)Model (SAS/ETS) */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA = STORE.OHIO_SUMMARY OUTMODEL=SEIRMOD NOPRINT; %END;
					/* Parameters of interest */
					PARMS R0 &R_T. I0 &I.;
					BOUNDS 1 <= R0 <= 13;
					/* Fixed values */
					N = &Population.;
					INF = &RecoveryDays.;
					SIGMA = &SIGMA.;
					/* Differential equations */
					GAMMA = 1 / INF;
					BETA = R0 * GAMMA / N;
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
					FIT CUMULATIVE_CASE_COUNT INIT=(S_N=&Population. E_N=0 I_N=I0 R_N=0) / TIME=TIME DYNAMIC OUTPREDICT OUTACTUAL OUT=EPIPRED LTEBOUND=1E-10
						%IF &HAVE_V151. = YES %THEN %DO; OPTIMIZER=ORMP(OPTTOL=1E-5) %END;;
					OUTVARS S_N E_N I_N R_N;
				QUIT;

				%IF &PLOTS. = YES %THEN %DO;
					/* Plot Fit of Actual v. Predicted */
					DATA EPIPRED;
						SET EPIPRED;
						LABEL CUMULATIVE_CASE_COUNT='Cumulative Incidence';
						FORMAT DATE DATE9.; 
						DATE = &FIRST_CASE. + TIME -1;
					run;
					PROC SGPLOT DATA=EPIPRED;
						WHERE _TYPE_  NE 'RESIDUAL';
						TITLE "Actual v. Predicted Infections in Region";
						SERIES X=DATE Y=CUMULATIVE_CASE_COUNT / LINEATTRS=(THICKNESS=2) GROUP=_TYPE_  MARKERS NAME="cases";
						FORMAT CUMULATIVE_CASE_COUNT COMMA10.;
					RUN;
					TITLE;
				%END;

			/* DATA FOR PROC TMODEL APPROACHES */
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

			/* Create SEIR Projections based on model fit above */
				%IF &HAVE_V151. = YES %THEN %DO; PROC TMODEL DATA=DINIT MODEL=SEIRMOD NOPRINT; %END;
				%ELSE %DO; PROC MODEL DATA=DINIT MODEL=SEIRMOD NOPRINT; %END;
					SOLVE CUMULATIVE_CASE_COUNT / TIME=TIME OUT=TMODEL_SEIR_FIT;
				QUIT;

				DATA TMODEL_SEIR_FIT;
					FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;
					ModelType="TMODEL - SEIR - OHIO FIT";
					ScenarioName="&Scenario.";
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
					DATE = &DAY_ZERO. + DAY;
					ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
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
						ScenarioIndex = "Unique Scenario ID"
						ScenarionNameUnique = "Unique Scenario Name"
						Scenarioname = "Scenario Name"
						;
				/* END: Common Post-Processing Across each Model Type and Approach */
					DROP LAG: CUM: ;
				RUN;

				PROC APPEND base=work.MODEL_FINAL data=TMODEL_SEIR_FIT NOWARN FORCE; run;
				PROC SQL; 
					drop table TMODEL_SEIR_FIT;
					drop table DINIT;
					drop table EPIPRED;
					drop table SEIRMOD;
				QUIT;

		%END;

		%IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='TMODEL - SEIR - OHIO FIT' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Fit Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2;
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

            /* CCF specific post-processing of MODEL_FINAL */
            /*pull real COVID admits and ICU*/
                proc sql; 
                    create table work.MODEL_FINAL as select t1.*,t2.TrueDailyAdmits, t2.SumICUNum
                        from work.MODEL_FINAL t1 left join CovData.PullRealAdmitCovid t2 on (t1.Date=t2.AdmitDate);
                    create table work.MODEL_FINAL as select t1.*,t2.TrueDailyDischarges, t2.SumICUDISCHARGE as SumICUNum_Discharge
                        from work.MODEL_FINAL t1 left join CovData.RealCovid_DischargeDt t2 on (t1.Date=t2.DischargDate);
                quit;

                data work.MODEL_FINAL;
                    set work.MODEL_FINAL;
                    *format Scenarioname $550.;
                    format INPUT_Social_DistancingCombo $190.;
                    *ScenarioName="&Scenario";
                    CumSumTrueAdmits + TrueDailyAdmits;
                    CumSumTrueDischarges + TrueDailyDischarges;
                    CumSumICU + SumICUNum;
                    CumSumICUDischarge + SumICUNum_Discharge;


                    True_CCF_Occupancy=CumSumTrueAdmits-CumSumTrueDischarges;

                    TrueCCF_ICU_Occupancy=CumSumICU-CumSumICUDischarge;
                    /*day logic for tableau views*/
                    if date>(today()-3) then Hospital_Occupancy_PP=Hospital_Occupancy; else Hospital_Occupancy_PP=.;
                    if date>(today()-3) then ICU_Occupancy_PP=ICU_Occupancy; else ICU_Occupancy_PP=.;
                    if date>(today()-3) then Vent_Occupancy_PP=Vent_Occupancy; else Vent_Occupancy_PP=.;
                    if date>(today()-3) then ECMO_Occupancy_PP=ECMO_Occupancy; else ECMO_Occupancy_PP=.;
                    if date>(today()-3) then DIAL_Occupancy_PP=DIAL_Occupancy; else DIAL_Occupancy_PP=.;

                    if date>today() then True_CCF_Occupancy=.;
                    if date>today() then TrueCCF_ICU_Occupancy=.;

                    /*
                        INPUT_Geography="&GeographyInput";

                        INPUT_Recovery_Time				=&RecoveryDays;
                        INPUT_Doubling_Time				=&doublingtime;
                        INPUT_Starting_Admits			=&KnownAdmits;

                        INPUT_Population				=&Population;
                        INPUT_Social_DistancingCombo	="&SocialDistancing"||"/"||"&SocialDistancingChange"||"/"||"&SocialDistancingChangeTwo"||"/"||"&SocialDistancingChange3"||"/"||"&SocialDistancingChange4";
                        INPUT_Social_Distancing_Date	=Put(&dayZero,date9.) ||" - "|| put(&iso_change_date,date9.) ||" - "|| put(&iso_change_date_two,date9.) ||" - "|| put(&iso_change_date_3,date9.) ||" - "|| put(&iso_change_date_4,date9.);
                        INPUT_Market_Share				=&MarketSharePercent;
                        INPUT_Admit_Percent_of_Infected	=&Admission_Rate;
                        INPUT_ICU_Percent_of_Admits		=&ICUPercent;
                        INPUT_Vent_Percent_of_Admits	=&VentPErcent;
                    */
                    /*paste overarching scenario variables*/
                    /*
                        INPUT_Mortality_RateInput		=&DeathRt;

                        INPUT_Length_of_Stay			=&LOS; 
                        INPUT_ICU_LOS					=&ICULOS; 
                        INPUT_Vent_LOS					=&VENTLOS; 
                        INPUT_Ecmo_Percent_of_Admits	=&ecmoPercent; 
                        INPUT_Ecmo_LOS_Input			=&ecmolos;
                        INPUT_Dialysis_PErcent			=&DialysisPercent; 
                        INPUT_Dialysis_LOS				=&DialysisLOS;
                        INPUT_Time_Zero					=&day_Zero;
                    */
                run;

                PROC APPEND base=store.MODEL_FINAL data=work.MODEL_FINAL NOWARN FORCE; run;
                PROC APPEND base=store.SCENARIOS data=work.SCENARIOS; run;
                PROC APPEND base=store.INPUTS data=work.INPUTS; run;

			%IF &CAS_LOAD=YES %THEN %DO;

options CASHOST=casctrl1.ccf.org CASPORT=5570;
				CAS;

				CASLIB _ALL_ ASSIGN;

				%IF &ScenarioIndex=1 %THEN %DO;
/*BROMLEY - MAY need to comment this out or connect to cas differently*/
					/* ScenarioIndex=1 implies a new MODEL_FINAL is being built, load it to CAS, if already in CAS then drop first */
					PROC CASUTIL;
						DROPTABLE INCASLIB="CASUSER" CASDATA="MODEL_FINAL" QUIET;
						LOAD DATA=store.MODEL_FINAL CASOUT="MODEL_FINAL" OUTCASLIB="CASUSER" PROMOTE;
						
						DROPTABLE INCASLIB="CASUSER" CASDATA="SCENARIOS" QUIET;
						LOAD DATA=store.SCENARIOS CASOUT="SCENARIOS" OUTCASLIB="CASUSER" PROMOTE;

						DROPTABLE INCASLIB="CASUSER" CASDATA="INPUTS" QUIET;
						LOAD DATA=store.INPUTS CASOUT="INPUTS" OUTCASLIB="CASUSER" PROMOTE;
					QUIT;

				%END;
				%ELSE %DO;

					/* ScenarioIndex>1 implies new scenario needs to be apended to MODEL_FINAL in CAS */
					PROC CASUTIL;
						LOAD DATA=work.MODEL_FINAL CASOUT="MODEL_FINAL" APPEND;
						
						LOAD DATA=work.SCENARIOS CASOUT="SCENARIOS" APPEND;
						
						LOAD DATA=work.INPUTS CASOUT="INPUTS" APPEND;
					QUIT;

				%END;


				CAS CASAUTO TERMINATE;

			%END;

                PROC SQL;
                    drop table work.MODEL_FINAL;
                    drop table work.SCENARIOS;
                    drop table work.INPUTS;
                QUIT;

        %END;
        %ELSE %IF &PLOTS. = YES %THEN %DO;
            PROC SQL; 
                drop table work.MODEL_FINAL; 
            QUIT;
        %END;

%mend;

/* Test runs of EasyRun macro 
	IMPORTANT NOTES: 
		These example runs have all the positional macro variables.  
		There are even more keyword parameters available.
			These need to be set for your population.
			They can be reviewed within the %EasyRun macro at the very top.
*/


/* Scenarios can be run in batch by specifying them in a sas dataset.
    In the example below, this dataset is created by reading scenarios from an csv file: run_scenarios.csv
    An example run_scenarios.csv file is provided with this code.

	IMPORTANT NOTES: 
		The example run_scenarios.csv file has columns for all the positional macro variables.  
		There are even more keyword parameters available.
			These need to be set for your population.
			They can be reviewed within the %EasyRun macro at the very top.
		THEN:
			you can set fixed values for the keyword parameters in the %EasyRun definition call
			OR
			you can add columns for the keyword parameters to this input file

	You could also use other files as input sources.  For example, with an excel file you could use libname XLSX.
*/
%macro run_scenarios(ds);
	/* import file */
	PROC IMPORT DATAFILE="&homedir./&ds."
		DBMS=CSV
		OUT=run_scenarios
		REPLACE;
		GETNAMES=YES;
	RUN;
	/* extract column names into space delimited string stored in macro variable &names */
	PROC SQL noprint;
		select name into :names separated by ' '
	  		from dictionary.columns
	  		where memname = 'RUN_SCENARIOS';
		select name into :dnames separated by ' '
	  		from dictionary.columns
	  		where memname = 'RUN_SCENARIOS' and substr(format,1,4)='DATE';
	QUIT;
	/* change date variables to character and of the form 'ddmmmyyyy'd */
	%DO i = 1 %TO %sysfunc(countw(&dnames.));
		%LET dname = %scan(&dnames,&i);
		data run_scenarios(drop=x);
			set run_scenarios(rename=(&dname.=x));
			&dname.="'"||put(x,date9.)||"'d";
		run;
	%END;
	/* build a call to %EasyRun for each row in run_scenarios */
	%GLOBAL cexecute;
	%DO i=1 %TO %sysfunc(countw(&names.));
		%LET next_name = %scan(&names, &i);
		%IF &i = 1 %THEN %DO;
			%LET cexecute = "&next_name.=",&next_name.; 
		%END;
		%ELSE %DO;
			%LET cexecute = &cexecute ,", &next_name.=",&next_name;
		%END;
	%END;
%mend;
