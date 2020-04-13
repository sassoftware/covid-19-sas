            proc sql;
                /* reorder data and round(time,1) becasue some time values are not integer? maybe nthreads artifact. */
                create table TMODEL_SEIR as
                    select Sigma, RECOVERYDAYS, SOCIALD, R0, S_N, E_N, I_N, R_N, round(Time,1) as Time
                    from TMODEL_SEIR
                    order by Sigma, RECOVERYDAYS, SOCIALD, R0, Time
                ;
                *create table TMODEL_SEIR_LOWER1 as	
                    select min(I_N) as I_N, min(S_N) as S_N, min(R_N) as R_N, min(E_N) as E_N, Time 
                    from TMODEL_SEIR
                    group by Time
                ;
                *create table TMODEL_SEIR_UPPER1 as	
                    select max(I_N) as I_N, max(S_N) as S_N, max(R_N) as R_N, max(E_N) as E_N, Time 
                    from TMODEL_SEIR
                    group by Time
                ;
                create table TMODEL_SEIR_LOWER1 as
                    select min(sum(S_N,E_N)) as SE, Time
                    from TMODEL_SEIR
                    group by Time
                ;
                create table TMODEL_SEIR_UPPER1 as
                    select max(sum(S_N,E_N)) as SE, Time
                    from TMODEL_SEIR
                    group by Time
                ;
                create table TMODEL_SEIR1 as
                    select sum(S_N,E_N) as SE, Time
                    from TMODEL_SEIR
                    order by Sigma, RECOVERYDAYS, SOCIALD, R0, Time
                ;
            quit;

			DATA TMODEL_SEIR_LOWER2;
				FORMAT ModelType $30. DATE date9.;
				ModelType="TMODEL - SEIR";
				ScenarioIndex=&ScenarioIndex.;
                LABEL   HOSPITAL_OCCUPANCY="Lower: Current Hospitalized Census"
                        ICU_OCCUPANCY="Lower: Current Hospital ICU Census"
                        VENT_OCCUPANCY="Lower: Current Hospital Ventilator Patients"
                        ECMO_OCCUPANCY="Lower: Current Hospital ECMO Patients"
                        DIAL_OCCUPANCY="Lower: Current Hospital Dialysis Patients"
                ;
                RENAME  HOSPITAL_OCCUPANCY=LOWER_HOSPITAL_OCCUPANCY
                        ICU_OCCUPANCY=LOWER_ICU_OCCUPANCY
                        VENT_OCCUPANCY=LOWER_VENT_OCCUPANCY
                        ECMO_OCCUPANCY=LOWER_ECMO_OCCUPANCY
                        DIAL_OCCUPANCY=LOWER_DIAL_OCCUPANCY
                ;
				RETAIN CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET TMODEL_SEIR_LOWER1(RENAME=(TIME=DAY));
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SE),-1*SE));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;

					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					
                    CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;

					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					
                    HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					
					DATE = &DAY_ZERO. + DAY;
				/* END: Common Post-Processing Across each Model Type and Approach */
                KEEP ModelType ScenarioIndex DATE HOSPITAL_OCCUPANCY ICU_OCCUPANCY VENT_OCCUPANCY ECMO_OCCUPANCY DIAL_OCCUPANCY;
			RUN;

			DATA TMODEL_SEIR_UPPER2;
				FORMAT ModelType $30. DATE date9.;
				ModelType="TMODEL - SEIR";
				ScenarioIndex=&ScenarioIndex.;
                LABEL   HOSPITAL_OCCUPANCY="Upper: Current Hospitalized Census"
                        ICU_OCCUPANCY="Upper: Current Hospital ICU Census"
                        VENT_OCCUPANCY="Upper: Current Hospital Ventilator Patients"
                        ECMO_OCCUPANCY="Upper: Current Hospital ECMO Patients"
                        DIAL_OCCUPANCY="Upper: Current Hospital Dialysis Patients"
                ;
                RENAME  HOSPITAL_OCCUPANCY=UPPER_HOSPITAL_OCCUPANCY
                        ICU_OCCUPANCY=UPPER_ICU_OCCUPANCY
                        VENT_OCCUPANCY=UPPER_VENT_OCCUPANCY
                        ECMO_OCCUPANCY=UPPER_ECMO_OCCUPANCY
                        DIAL_OCCUPANCY=UPPER_DIAL_OCCUPANCY
                ;
				RETAIN CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET TMODEL_SEIR_UPPER1(RENAME=(TIME=DAY));
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SE),-1*SE));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;

					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					
                    CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;

					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					
                    HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					
					DATE = &DAY_ZERO. + DAY;
				/* END: Common Post-Processing Across each Model Type and Approach */
                KEEP ModelType ScenarioIndex DATE HOSPITAL_OCCUPANCY ICU_OCCUPANCY VENT_OCCUPANCY ECMO_OCCUPANCY DIAL_OCCUPANCY;
			RUN;

			DATA TMODEL_SEIR2;
				FORMAT ModelType $30. DATE date9.;
				ModelType="TMODEL - SEIR";
				ScenarioIndex=&ScenarioIndex.;
                LABEL   HOSPITAL_OCCUPANCY="Current Hospitalized Census"
                        ICU_OCCUPANCY="Current Hospital ICU Census"
                        VENT_OCCUPANCY="Current Hospital Ventilator Patients"
                        ECMO_OCCUPANCY="Current Hospital ECMO Patients"
                        DIAL_OCCUPANCY="Current Hospital Dialysis Patients"
                ;
				RETAIN CUMULATIVE_SUM_HOSP CUMULATIVE_SUM_ICU CUMULATIVE_SUM_VENT CUMULATIVE_SUM_ECMO CUMULATIVE_SUM_DIAL;
				SET TMODEL_SEIR1(RENAME=(TIME=DAY));
                by Sigma RECOVERYDAYS SOCIALD R0;
				/* START: Common Post-Processing Across each Model Type and Approach */
					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SE),-1*SE));
					IF NEWINFECTED < 0 THEN NEWINFECTED=0;
					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;

					CUMULATIVE_SUM_HOSP + HOSP;
					CUMULATIVE_SUM_ICU + ICU;
					CUMULATIVE_SUM_VENT + VENT;
					CUMULATIVE_SUM_ECMO + ECMO;
					CUMULATIVE_SUM_DIAL + DIAL;
					
                    CUMADMITLAGGED=ROUND(LAG&HOSP_LOS.(CUMULATIVE_SUM_HOSP),1) ;
					CUMICULAGGED=ROUND(LAG&ICU_LOS.(CUMULATIVE_SUM_ICU),1) ;
					CUMVENTLAGGED=ROUND(LAG&VENT_LOS.(CUMULATIVE_SUM_VENT),1) ;
					CUMECMOLAGGED=ROUND(LAG&ECMO_LOS.(CUMULATIVE_SUM_ECMO),1) ;
					CUMDIALLAGGED=ROUND(LAG&DIAL_LOS.(CUMULATIVE_SUM_DIAL),1) ;

					ARRAY FIXINGDOT _NUMERIC_;
					DO OVER FIXINGDOT;
						IF FIXINGDOT=. THEN FIXINGDOT=0;
					END;
					
                    HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
					ICU_OCCUPANCY= ROUND(CUMULATIVE_SUM_ICU-CUMICULAGGED,1);
					VENT_OCCUPANCY= ROUND(CUMULATIVE_SUM_VENT-CUMVENTLAGGED,1);
					ECMO_OCCUPANCY= ROUND(CUMULATIVE_SUM_ECMO-CUMECMOLAGGED,1);
					DIAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_DIAL-CUMDIALLAGGED,1);
					
					DATE = &DAY_ZERO. + DAY;
				/* END: Common Post-Processing Across each Model Type and Approach */
                KEEP ModelType ScenarioIndex DATE HOSPITAL_OCCUPANCY ICU_OCCUPANCY VENT_OCCUPANCY ECMO_OCCUPANCY DIAL_OCCUPANCY;
			RUN;
            PROC SQL;
                create table TMODEL_SEIR3 as
                    select min(HOSPITAL_OCCUPANCY) as LOWER_HOSPITAL_OCCUPANCY, 
                            min(ICU_OCCUPANCY) as LOWER_ICU_OCCUPANCY, 
                            min(VENT_OCCUPANCY) as LOWER_VENT_OCCUPANCY, 
                            min(ECMO_OCCUPANCY) as LOWER_ECMO_OCCUPANCY, 
                            min(DIAL_OCCUPANCY) as LOWER_DIAL_OCCUPANCY,
                            max(HOSPITAL_OCCUPANCY) as UPPER_HOSPITAL_OCCUPANCY, 
                            max(ICU_OCCUPANCY) as UPPER_ICU_OCCUPANCY, 
                            max(VENT_OCCUPANCY) as UPPER_VENT_OCCUPANCY, 
                            max(ECMO_OCCUPANCY) as UPPER_ECMO_OCCUPANCY, 
                            max(DIAL_OCCUPANCY) as UPPER_DIAL_OCCUPANCY,
                            Time 
                    from TMODEL_SEIR2
                    group by Time
                ;
            QUIT;


            /* merge with lower and upper  columns with results from model in work.MODEL_FINAL*/
            PROC SQL;
                *create table work.MODEL_FINAL as
                    select * from
                    ( 
                    select * from work.MODEL_FINAL B
                        left join
                            (select * from work.TMODEL_SEIR_LOWER2) L
                            on B.ModelType=L.ModelType and B.ScenarioIndex=L.ScenarioIndex and B.DATE=L.DATE
                    )
                    left join
                        (select * from work.TMODEL_SEIR_UPPER2) U
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                create table work.MODEL_FINAL as
                    select * from
                        (select * from work.MODEL_FINAL) B 
                        left join
                        (select * from work.TMODEL_SEIR3) U 
                        on B.ModelType=U.ModelType and B.ScenarioIndex=U.ScenarioIndex and B.DATE=U.DATE
                    order by ScenarioIndex, ModelType, Date
                ;
                *drop table TMODEL_SEIR;
                *drop table TMODEL_SEIR_LOWER;
                *drop table TMODEL_SEIR_UPPER;
            QUIT;
            data temp; set work.MODEL_FINAL; where modeltype="TMODEL - SEIR"; run;
        %END;

        %IF &PLOTS. = YES %THEN %DO;
			PROC SGPLOT DATA=work.MODEL_FINAL;
				where ModelType='TMODEL - SEIR' and ScenarioIndex=&ScenarioIndex.;
				TITLE "Daily Occupancy - PROC TMODEL SEIR Approach";
				TITLE2 "Scenario: &Scenario., Initial R0: %SYSFUNC(round(&R_T.,.01)) with Initial Social Distancing of %SYSEVALF(&SocialDistancing.*100)%";
				TITLE3 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate., date10.), date9.): %SYSFUNC(round(&R_T_Change.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange.*100)%";
				TITLE4 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDateTwo., date10.), date9.): %SYSFUNC(round(&R_T_Change_Two.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChangeTwo.*100)%";
				TITLE5 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate3., date10.), date9.): %SYSFUNC(round(&R_T_Change_3.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange3.*100)%";
				TITLE6 "Adjusted R0 after %sysfunc(INPUTN(&ISOChangeDate4., date10.), date9.): %SYSFUNC(round(&R_T_Change_4.,.01)) with Adjusted Social Distancing of %SYSEVALF(&SocialDistancingChange4.*100)%";
				SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
                BAND x=Date lower=LOWER_HOSPITAL_OCCUPANCY upper=UPPER_HOSPITAL_OCCUPANCY;
                *SERIES X=DATE Y=LOWER_HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
                *SERIES X=DATE Y=UPPER_HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=ICU_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=VENT_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=ECMO_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				*SERIES X=DATE Y=DIAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
				XAXIS LABEL="Date";
				YAXIS LABEL="Daily Occupancy";
			RUN;
			TITLE; TITLE2; TITLE3; TITLE4; TITLE5; TITLE6;
        %END;