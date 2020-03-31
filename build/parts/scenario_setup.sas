    /* create an index, ScenarioIndex for this run by incrementing the max value of ScenarioIndex in SCENARIOS dataset */
    %IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
        PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from store.scenarios; quit;
    %END;
    %ELSE %DO; %LET ScenarioIndex_Base = 0; %END;
    /* store all the macro variables that set up this scenario in PARMS dataset */
        DATA PARMS;
            set sashelp.vmacro(where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE') then delete;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
            STAGE='INPUT';
        RUN;

X_IMPORT: parameters.sas

        DATA PARMS;
            set PARMS sashelp.vmacro(in=i where=(scope='EASYRUN'));
            if name in ('SQLEXITCODE','SQLOBS','SQLOOPS','SQLRC','SQLXOBS','SQLXOPENERRS','SCENARIOINDEX_BASE') then delete;
            ScenarioIndex = &ScenarioIndex_Base. + 1;
            if i then STAGE='MODEL';
        RUN;
    /* Check to see if PARMS (this scenario) has already been run before in SCENARIOS dataset */
    %IF %SYSFUNC(exist(store.scenarios)) %THEN %DO;
        PROC SQL noprint;
            /* has this scenario been run before - all the same parameters and value - no more and no less */
            select count(*) into :ScenarioExist from
                (select t1.ScenarioIndex, t2.ScenarioIndex
                    from 
                        (select *, count(*) as cnt 
                            from PARMS
                            where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT')
                            group by ScenarioIndex) t1
                        join
                        (select * from store.SCENARIOS
                            where name not in ('SCENARIO','SCENARIOINDEX_BASE','SCENARIOINDEX','SCENPLOT')) t2
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
        PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex from work.parms; QUIT;
        PROC APPEND base=store.SCENARIOS data=PARMS; run;
    %END;
    PROC SQL; drop table PARMS; QUIT;