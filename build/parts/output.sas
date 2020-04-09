    /* code to manage output tables in STORE and CAS table management (coming soon) */
        %IF &ScenarioExist = 0 %THEN %DO;

C_IMPORT: CCF_post.sas

                PROC APPEND base=store.MODEL_FINAL data=work.MODEL_FINAL NOWARN FORCE; run;

X_IMPORT: CAS_post.sas

                PROC SQL; drop table work.MODEL_FINAL; QUIT;

        %END;
        %ELSE %IF &PLOTS. = YES %THEN %DO;
            PROC SQL; drop table work.MODEL_FINAL; quit;
        %END;
