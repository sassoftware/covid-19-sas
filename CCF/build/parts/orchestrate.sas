C_IMPORT: CCF_pre.sas
D_IMPORT: CCF_pre.sas

%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,
                SocialDistancing,ISOChangeDate,ISOChangeEvent,ISOChangeWindow,SocialDistancingChange,
                MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate,
                plots=no,N_DAYS=365,DiagnosedRate=1.0,E=0,SIGMA=3,DAY_ZERO='13MAR2020'd,
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
            ISOChangeDate               $200.    
            ISOChangeEvent              $200.
            ISOChangeWindow             $50.
            SocialDistancingChange      $50.     
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
            ECMO_RATE                   BEST12.
            DIAL_RATE                   BEST12.
            HOSP_LOS                    $100.
            ICU_LOS                     $100.
            VENT_LOS                    $100.
            ECMO_LOS                    $100.
            DIAL_LOS                    $100.
        ;
        LABEL
            Scenario                    =   "Scenario Name"
            IncubationPeriod            =   "Average Days between Infection and Hospitalization"
            InitRecovered               =   "Number of Recovered (Immune) Patients on Day 0"
            RecoveryDays                =   "Average Days Infectious"
            doublingtime                =   "Baseline Infection Doubling Time (No Social Distancing)"
            Population                  =   "Regional Population"
            KnownAdmits                 =   "Number of Admitted Patients in Hospital of Interest on Day 0"
            SocialDistancing            =   "Initial Social Distancing (% Reduction from Normal)"
            ISOChangeDate               =   "Dates of Change in Social Distancing"
            ISOChangeEvent              =   "Event label associated with ISOChangeDate"
            ISOChangeWindow             =   "Number of Days to rollout Social Distancing Change"
            SocialDistancingChange      =   "Social Distancing Change (% Reduction from Normal)"
            MarketSharePercent          =   "Anticipated Share (%) of Regional Hospitalized Patients"
            Admission_Rate              =   "Percentage of Infected Patients Requiring Hospitalization"
            ICUPercent                  =   "Percentage of Hospitalized Patients Requiring ICU"
            VentPErcent                 =   "Percentage of Hospitalized Patients Requiring Ventilators"
            FatalityRate                =   "Percentage of Hospitalized Patients who will Die"
            plots                       =   "Display Plots (Yes/No)"
            N_DAYS                      =   "Number of Days to Project"
            DiagnosedRate               =   "Hospitalization Rate Reduction (%) for Underdiagnosis"
            E                           =   "Number of Exposed Patients on Day 0"
            SIGMA                       =   "Days Exposed before Infected"
            DAY_ZERO                    =   "Date of the First COVID-19 Case"
            ECMO_RATE                   =   "Percentage of Hospitalized Patients Requiring ECMO"
            DIAL_RATE                   =   "Percentage of Hospitalized Patients Requiring Dialysis"
            HOSP_LOS                    =   "Hospital Length of Stay"
            ICU_LOS                     =   "ICU Length of Stay"
            VENT_LOS                    =   "Ventilator Length of Stay"
            ECMO_LOS                    =   "ECMO Length of Stay"
            DIAL_LOS                    =   "Dialysis Length of Stay"
        ;
        Scenario                    =   "&Scenario.";
        IncubationPeriod            =   &IncubationPeriod.;
        InitRecovered               =   &InitRecovered.;
        RecoveryDays                =   &RecoveryDays.;
        doublingtime                =   &doublingtime.;
        Population                  =   &Population.;
        KnownAdmits                 =   &KnownAdmits.;
        SocialDistancing            =   &SocialDistancing.;
        ISOChangeDate               =   "&ISOChangeDate.";
        ISOChangeEvent              =   "&ISOChangeEvent.";
        ISOChangeWindow             =   "&ISOChangeWindow.";
        SocialDistancingChange      =   "&SocialDistancingChange.";
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
        ECMO_RATE                   =   &ECMO_RATE.;
        DIAL_RATE                   =   &DIAL_RATE.;
        HOSP_LOS                    =   "&HOSP_LOS.";
        ICU_LOS                     =   "&ICU_LOS.";
        VENT_LOS                    =   "&VENT_LOS.";
        ECMO_LOS                    =   "&ECMO_LOS.";
        DIAL_LOS                    =   "&DIAL_LOS.";
    RUN;

X_IMPORT: scenario_setup.sas

X_IMPORT: models.sas

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
                TITLE3 "&sdchangetitle.";
                SERIES X=DATE Y=HOSPITAL_OCCUPANCY / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                XAXIS LABEL="Date";
                YAXIS LABEL="Daily Occupancy";
            RUN;
            TITLE; TITLE2; TITLE3;

            PROC SGPANEL DATA=work.MODEL_FINAL;
                where ScenarioIndex=&ScenarioIndex.;
				PANELBY MODELTYPE / NOVARNAME;
                TITLE "BETA Parameter Over Time - All Approaches";
                TITLE2 "&sdchangetitle.";
                SERIES X=DATE Y=BETA / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                COLAXIS LABEL="Date" GRID;
                ROWAXIS LABEL="BETA Parameter" GRID;
                %IF &ISOChangeLoop > 0 %THEN %DO;
                    REFLINE %DO j=1 %TO &ISOChangeLoop; &&ISOChangeDate&j %END; / axis=x ;
                %END;
            RUN;
            TITLE; TITLE2;

            PROC SGPANEL DATA=work.MODEL_FINAL;
                where ScenarioIndex=&ScenarioIndex.;
				PANELBY MODELTYPE / NOVARNAME;
                TITLE "Social Distancing Input Over Time - All Approaches";
                TITLE2 "&sdchangetitle.";
                SERIES X=DATE Y=SocialDistancing / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                COLAXIS LABEL="Date" GRID;
                ROWAXIS LABEL="Social Distancing" GRID;
                %IF &ISOChangeLoop > 0 %THEN %DO;
                    REFLINE %DO j=1 %TO &ISOChangeLoop; &&ISOChangeDate&j %END; / axis=x ;
                %END;
            RUN;
            TITLE; TITLE2;

        %END;	
    %END;

X_IMPORT: output.sas

%mend;
