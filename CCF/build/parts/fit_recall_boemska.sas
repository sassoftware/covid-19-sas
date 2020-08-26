            data work.ds_seir;
                set &PULLLIB..MODEL_FINAL;
                where ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall." and ModelType = "SEIR with Data Step"; 
            run;


            data work.ds_sir;
                set &PULLLIB..MODEL_FINAL;
                where  ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall." and ModelType = "SIR with Data Step"; 
            run;

            data work.tmodel_seir;
                set &PULLLIB..MODEL_FINAL;
                where ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall." and ModelType = "SEIR with PROC (T)MODEL"; 
            run;


            data work.tmodel_sir;
                set &PULLLIB..MODEL_FINAL;
                where  ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall." and ModelType = "SIR with PROC (T)MODEL"; 
            run;

            data work.tmodel_seir_fit_i;
                set &PULLLIB..MODEL_FINAL;
                where  ScenarioIndex=&ScenarioIndex_recall. and ScenarioSource="&ScenarioSource_recall." and ScenarioUser="&ScenarioUser_recall." and ModelType = "SEIR with PROC (T)MODEL-Fit R0"; 
            run;