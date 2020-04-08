    /* code to manage output tables in STORE and CAS table management (coming soon) */
        %IF &ScenarioExist = 0 %THEN %DO;
            PROC APPEND base=store.MODEL_FINAL data=work.MODEL_FINAL NOWARN FORCE; run;
            PROC SQL; drop table work.MODEL_FINAL; QUIT;

X_IMPORT: CAS_post.sas

        %END;
        %ELSE %IF &PLOTS. = YES %THEN %DO;
            PROC SQL; drop table work.MODEL_FINAL; quit;
        %END;
