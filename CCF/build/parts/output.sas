    /* code to manage output tables in STORE and CAS table management (coming soon) */
        %IF &ScenarioExist = 0 %THEN %DO;

X_IMPORT: peak_flags2.sas

C_IMPORT: CCF_post.sas
D_IMPORT: CCF_post.sas

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