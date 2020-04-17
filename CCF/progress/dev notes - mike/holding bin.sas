            /* compute and merge the lower and upper  columns with results from model in work.MODEL_FINAL on ScenarioIndex and ModelType */
            PROC SQL NOPRINT;
                /* union of Model_FINAL without current modeltype AND model_FINAL for current modelType joined with LOWER and UPPER columns  */
                select name into: vars separated by ', ' from dictionary.columns where libname='WORK' and memname='MODEL_FINAL' and substr(name,1,5) not in ('UPPER','LOWER');
                create table work.MODEL_FINAL as
                    select * from work.MODEL_FINAL where ModelType~='TMODEL - SIR'
                    union
                    (select * from
                        (select &vars. from work.MODEL_FINAL where ModelType='TMODEL - SIR') B 
                        left join
                        (select min(HOSPITAL_OCCUPANCY) as LOWER_HOSPITAL_OCCUPANCY label="Lower Bound: Current Hospitalized Census", 
                                min(ICU_OCCUPANCY) as LOWER_ICU_OCCUPANCY label="Lower Bound: Current Hospital ICU Census", 
                                min(VENT_OCCUPANCY) as LOWER_VENT_OCCUPANCY label="Lower Bound: Current Hospital Ventilator Patients", 
                                min(ECMO_OCCUPANCY) as LOWER_ECMO_OCCUPANCY label="Lower Bound: Current Hospital Patients", 
                                min(DIAL_OCCUPANCY) as LOWER_DIAL_OCCUPANCY label="Lower Bound: Current Hospital Patients",
                                max(HOSPITAL_OCCUPANCY) as UPPER_HOSPITAL_OCCUPANCY label="Upper Bound: Current Hospitalized Census", 
                                max(ICU_OCCUPANCY) as UPPER_ICU_OCCUPANCY label="Upper Bound: Current Hospital ICU Census", 
                                max(VENT_OCCUPANCY) as UPPER_VENT_OCCUPANCY label="Upper Bound: Current Hospital Ventilator Patients", 
                                max(ECMO_OCCUPANCY) as UPPER_ECMO_OCCUPANCY label="Upper Bound: Current Hospital Patients", 
                                max(DIAL_OCCUPANCY) as UPPER_DIAL_OCCUPANCY label="Upper Bound: Current Hospital Patients",
                                Date, ModelType, ScenarioIndex
                            from TMODEL_SIR
                            group by Date, ModelType, ScenarioIndex
                        ) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE)
                    order by ScenarioIndex, ModelType, Date
                ;
            QUIT;

            /* compute and merge the lower and upper  columns with results from model in work.MODEL_FINAL on ScenarioIndex and ModelType */
            PROC SQL;
                create table work.MODEL_FINAL as
                    select * from
                        (select * from work.MODEL_FINAL) B 
                        left join
                        (select min(HOSPITAL_OCCUPANCY) as LOWER_HOSPITAL_OCCUPANCY label="Lower Bound: Current Hospitalized Census", 
                                min(ICU_OCCUPANCY) as LOWER_ICU_OCCUPANCY label="Lower Bound: Current Hospital ICU Census", 
                                min(VENT_OCCUPANCY) as LOWER_VENT_OCCUPANCY label="Lower Bound: Current Hospital Ventilator Patients", 
                                min(ECMO_OCCUPANCY) as LOWER_ECMO_OCCUPANCY label="Lower Bound: Current Hospital Patients", 
                                min(DIAL_OCCUPANCY) as LOWER_DIAL_OCCUPANCY label="Lower Bound: Current Hospital Patients",
                                max(HOSPITAL_OCCUPANCY) as UPPER_HOSPITAL_OCCUPANCY label="Upper Bound: Current Hospitalized Census", 
                                max(ICU_OCCUPANCY) as UPPER_ICU_OCCUPANCY label="Upper Bound: Current Hospital ICU Census", 
                                max(VENT_OCCUPANCY) as UPPER_VENT_OCCUPANCY label="Upper Bound: Current Hospital Ventilator Patients", 
                                max(ECMO_OCCUPANCY) as UPPER_ECMO_OCCUPANCY label="Upper Bound: Current Hospital Patients", 
                                max(DIAL_OCCUPANCY) as UPPER_DIAL_OCCUPANCY label="Upper Bound: Current Hospital Patients",
                                Date, ModelType, ScenarioIndex
                            from TMODEL_SEIR
                            group by Date, ModelType, ScenarioIndex
                        ) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                drop table TMODEL_SEIR;
                drop table DINIT;
            QUIT;