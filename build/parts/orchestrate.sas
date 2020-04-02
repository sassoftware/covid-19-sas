C_IMPORT: CCF_pre.sas

%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,KnownCOVID,SocialDistancing,ISOChangeDate,SocialDistancingChange,ISOChangeDateTwo,SocialDistancingChangeTwo,MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate,plots=no);
    /* descriptions for the input fields of this macro:
        Scenario - Scenario Name to be stored as a character variable, combined with automatically-generated ScenarioIndex to create a unique ID
        IncubationPeriod - Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right
        InitRecovered - Initial number of Recovered patients, assumed to have immunity to future infection
        RecoveryDays - Number of days a patient is considered infectious (the amount of time it takes to recover or die)
        doublingtime - Baseline Doubling Time without social distancing
        Population - Number of people in region of interest, assumed to be well mixed and independent of other populations
        KnownAdmits - Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections
        KnownCOVID - Number of known COVID-19 patients in the region at Day 0, not used in S(E)IR calculations
        SocialDistancing - Baseline Social distancing (% reduction in social contact compared to normal activity)
        ISOChangeDate - Date of first change from baseline in social distancing parameter
        SocialDistancingChange - Second value of social distancing (% reduction in social contact compared to normal activity)
        ISOChangeDateTwo - Date of second change in social distancing parameter
        SocialDistancingChangeTwo - Third value of social distancing (% reduction in social contact compared to normal activity)
        MarketSharePercent - Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest
        Admission_Rate - Percentage of Infected patients in the region who will be hospitalized
        ICUPercent - Percentage of hospitalized patients who will require ICU
        VentPErcent - Percentage of hospitalized patients who will require Ventilators
        FatalityRate - Percentage of hospitalized patients who will die
        plots - YES/NO display plots in output
    */


X_IMPORT: scenario_setup.sas

    /* If this is a new scenario then run it */
    %IF &ScenarioExist = 0 %THEN %DO;

P_IMPORT: model_proctmodel_seir.sas

P_IMPORT: model_proctmodel_sir.sas

X_IMPORT: model_datastep_sir.sas

P_IMPORT: model_datastep_seir.sas

X_IMPORT: model_proctmodel_seir_Ohio_I_Feed.sas

        %IF &PLOTS. = YES %THEN %DO;
            /* if multiple models for a single scenarioIndex then plot them */
            PROC SQL noprint;
                select count(*) into :scenplot from (select distinct ModelType from store.MODEL_FINAL where ScenarioIndex=&ScenarioIndex.);
            QUIT;
            %IF &scenplot > 1 %THEN %DO;
                PROC SGPLOT DATA=store.MODEL_FINAL;
                    where ScenarioIndex=&ScenarioIndex.;
                    TITLE "Daily Hospital Occupancy - All Approaches";
                    TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing*100)%";
                    TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate, date10.), date9.): %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
                    TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo, date10.), date9.): %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
                    SERIES X=DATE Y=HOSPITAL_OCCUPANCY / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                    XAXIS LABEL="Date";
                    YAXIS LABEL="Daily Occupancy";
                RUN;
                TITLE; TITLE2; TITLE3; TITLE4;
            %END;	
        %END;

    %END;

X_IMPORT: data_dictionary.sas

%mend;
