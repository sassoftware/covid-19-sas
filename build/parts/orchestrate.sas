C_IMPORT: CCF_pre.sas

%macro EasyRun(Scenario,IncubationPeriod,InitRecovered,RecoveryDays,doublingtime,Population,KnownAdmits,KnownCOVID,SocialDistancing,ISOChangeDate,SocialDistancingChange,ISOChangeDateTwo,SocialDistancingChangeTwo,MarketSharePercent,Admission_Rate,ICUPercent,VentPErcent,FatalityRate,plots=no);

X_IMPORT: parameters.sas

X_IMPORT: scenario_setup.sas

    /* If this is a new scenario then run it */
    %IF &ScenarioExist = 0 %THEN %DO;

P_IMPORT: model_proctmodel_seir.sas

P_IMPORT: model_proctmodel_sir.sas

X_IMPORT: model_datastep_sir.sas

P_IMPORT: model_datastep_seir.sas

        PROC SQL; drop table DINIT; QUIT;

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
                    TITLE3 "Adjusted R0 after &ISOChangeDate: %SYSFUNC(round(&R_T_Change,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange*100)%";
                    TITLE4 "Adjusted R0 after &ISOChangeDateTwo: %SYSFUNC(round(&R_T_Change_Two,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo*100)%";
                    SERIES X=DATE Y=HOSPITAL_OCCUPANCY / GROUP=MODELTYPE LINEATTRS=(THICKNESS=2);
                    XAXIS LABEL="Date";
                    YAXIS LABEL="Daily Occupancy";
                RUN;
                TITLE; TITLE2; TITLE3; TITLE4;
            %END;	
        %END;

    %END;

%mend;