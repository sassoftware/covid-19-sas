    /* code to manage output tables in STORE and CAS table management (coming soon) */
        %IF &ScenarioExist = 0 %THEN %DO;

X_IMPORT: peak_flags.sas

C_IMPORT: CCF_post.sas

                PROC APPEND base=store.MODEL_FINAL data=work.MODEL_FINAL NOWARN FORCE; run;
                PROC APPEND base=store.SCENARIOS data=work.SCENARIOS; run;
                PROC APPEND base=store.INPUTS data=work.INPUTS; run;

X_IMPORT: CAS_post.sas

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