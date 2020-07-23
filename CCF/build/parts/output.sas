    /* code to manage output tables in STORE and CAS table management (coming soon) */
        %IF &ScenarioExist = 0 %THEN %DO;

X_IMPORT: peak_flags2.sas

X_IMPORT: data_dictionary.sas

C_IMPORT: CCF_post.sas
D_IMPORT: CCF_post.sas

                %IF &ScenarioSource = BATCH or &ScenarioSource = BOEMSKA %THEN %DO;
                
                    PROC APPEND base=store.MODEL_FINAL data=work.MODEL_FINAL NOWARN FORCE; run;
                    PROC APPEND base=store.SCENARIOS data=work.SCENARIOS; run;
                    PROC APPEND base=store.INPUTS data=work.INPUTS; run;
P_IMPORT: fit_recall_append.sas
D_IMPORT: fit_recall_append.sas
T_IMPORT: fit_recall_append.sas
U_IMPORT: fit_recall_append.sas


                    PROC SQL;
                        drop table work.MODEL_FINAL;
                        drop table work.SCENARIOS;
                        drop table work.INPUTS;
P_IMPORT: fit_recall_drop.sas
D_IMPORT: fit_recall_drop.sas
T_IMPORT: fit_recall_drop.sas
U_IMPORT: fit_recall_drop.sas

                    QUIT;

                %END;

        %END;
        /*%ELSE %IF &PLOTS. = YES %THEN %DO;*/
        %ELSE %DO;
            %IF &ScenarioSource = BATCH or &ScenarioSource = BOEMSKA %THEN %DO;
                PROC SQL; 
                    drop table work.MODEL_FINAL;
                    drop table work.SCENARIOS;
                    drop table work.INPUTS; 
P_IMPORT: fit_recall_drop.sas
D_IMPORT: fit_recall_drop.sas
T_IMPORT: fit_recall_drop.sas
U_IMPORT: fit_recall_drop.sas
B_IMPORT: fit_recall_drop.sas

B_IMPORT: fit_recall_boemska.sas

                QUIT;
            %END;
        %END;