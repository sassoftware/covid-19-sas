				/*CREATE FLAGS FOR DAYS WITH PEAK VALUES OF DIFFERENT METRICS*/
					PROC SQL noprint;
						CREATE TABLE work.MODEL_FINAL AS
							SELECT MF.*, HOSP.PEAK_HOSPITAL_OCCUPANCY, ICU.PEAK_ICU_OCCUPANCY, VENT.PEAK_VENT_OCCUPANCY, 
								ECMO.PEAK_ECMO_OCCUPANCY, DIAL.PEAK_DIAL_OCCUPANCY, I.PEAK_I_N, FATAL.PEAK_FATALITY
							FROM work.MODEL_FINAL MF
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, HOSPITAL_OCCUPANCY, 1 AS PEAK_HOSPITAL_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING HOSPITAL_OCCUPANCY=MAX(HOSPITAL_OCCUPANCY)
											) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) HOSP
									ON MF.MODELTYPE = HOSP.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = HOSP.SCENARIONAMEUNIQUE
										AND MF.DATE = HOSP.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, ICU_OCCUPANCY, 1 AS PEAK_ICU_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING ICU_OCCUPANCY=MAX(ICU_OCCUPANCY)
											) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) ICU
									ON MF.MODELTYPE = ICU.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = ICU.SCENARIONAMEUNIQUE
										AND MF.DATE = ICU.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, VENT_OCCUPANCY, 1 AS PEAK_VENT_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING VENT_OCCUPANCY=MAX(VENT_OCCUPANCY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) VENT
									ON MF.MODELTYPE = VENT.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = VENT.SCENARIONAMEUNIQUE
										AND MF.DATE = VENT.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, ECMO_OCCUPANCY, 1 AS PEAK_ECMO_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING ECMO_OCCUPANCY=MAX(ECMO_OCCUPANCY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) ECMO
									ON MF.MODELTYPE = ECMO.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = ECMO.SCENARIONAMEUNIQUE
										AND MF.DATE = ECMO.DATE
								LEFT JOIN
									(SELECT * FROM
										(SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, DIAL_OCCUPANCY, 1 AS PEAK_DIAL_OCCUPANCY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING DIAL_OCCUPANCY=MAX(DIAL_OCCUPANCY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) DIAL
									ON MF.MODELTYPE = DIAL.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = DIAL.SCENARIONAMEUNIQUE
										AND MF.DATE = DIAL.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, I_N, 1 AS PEAK_I_N
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING I_N=MAX(I_N)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) I
									ON MF.MODELTYPE = I.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = I.SCENARIONAMEUNIQUE
										AND MF.DATE = I.DATE
								LEFT JOIN
									(SELECT *
										FROM (SELECT MODELTYPE, SCENARIONAMEUNIQUE, DATE, FATALITY, 1 AS PEAK_FATALITY
											FROM work.MODEL_FINAL
											GROUP BY 1, 2
											HAVING FATALITY=MAX(FATALITY)
										) 
										GROUP BY MODELTYPE, SCENARIONAMEUNIQUE
										HAVING DATE=MIN(DATE)
									) FATAL
									ON MF.MODELTYPE = FATAL.MODELTYPE
										AND MF.SCENARIONAMEUNIQUE = FATAL.SCENARIONAMEUNIQUE
										AND MF.DATE = FATAL.DATE
							ORDER BY SCENARIONAMEUNIQUE, MODELTYPE, DATE;

							/* add EVENTY columns for ploting labels in ISOChangeEvent */
							select name into :varlist separated by ', '
								from dictionary.columns
								where UPCASE(LIBNAME)="WORK" and upcase(memname)="MODEL_FINAL" and upcase(name) ne 'EVENTY_MULTIPLIER';
							create table work.MODEL_FINAL as
								select * from
									(select &varlist from work.MODEL_FINAL) m1
									left join
									(
										select t1.ScenarioNameUnique, t1.ModelType, t1.Date,
												round(t1.EventY_Multiplier * t2.HOSPITAL_OCCUPANCY,1) as EventY_HOSPITAL_OCCUPANCY,
												round(t1.EventY_Multiplier * t3.ICU_OCCUPANCY,1) as EventY_ICU_OCCUPANCY,
												round(t1.EventY_Multiplier * t4.DIAL_OCCUPANCY,1) as EventY_DIAL_OCCUPANCY,
												round(t1.EventY_Multiplier * t5.ECMO_OCCUPANCY,1) as EventY_ECMO_OCCUPANCY,
												round(t1.EventY_Multiplier * t6.VENT_OCCUPANCY,1) as EventY_VENT_OCCUPANCY
										from
											(select ScenarioNameUnique, ModelType, Date, EventY_Multiplier from work.MODEL_FINAL) t1
											left join
											(select ScenarioNameUnique, ModelType, HOSPITAL_OCCUPANCY from work.Model_FINAL where PEAK_HOSPITAL_OCCUPANCY) t2
											on t1.ScenarioNameUnique=t2.ScenarioNameUnique and t1.ModelType=t2.ModelType
											left join
											(select ScenarioNameUnique, ModelType, ICU_OCCUPANCY from work.Model_FINAL where PEAK_ICU_OCCUPANCY) t3
											on t1.ScenarioNameUnique=t3.ScenarioNameUnique and t1.ModelType=t3.ModelType
											left join
											(select ScenarioNameUnique, ModelType, DIAL_OCCUPANCY from work.Model_FINAL where PEAK_DIAL_OCCUPANCY) t4
											on t1.ScenarioNameUnique=t4.ScenarioNameUnique and t1.ModelType=t4.ModelType
											left join
											(select ScenarioNameUnique, ModelType, ECMO_OCCUPANCY from work.Model_FINAL where PEAK_ECMO_OCCUPANCY) t5
											on t1.ScenarioNameUnique=t5.ScenarioNameUnique and t1.ModelType=t5.ModelType
											left join
											(select ScenarioNameUnique, ModelType, VENT_OCCUPANCY from work.Model_FINAL where PEAK_VENT_OCCUPANCY) t6
											on t1.ScenarioNameUnique=t6.ScenarioNameUnique and t1.ModelType=t6.ModelType
									) m2
								on m1.ScenarioNameUnique=m2.ScenarioNameUnique and m1.ModelType=m2.ModelType and m1.DATE=m2.DATE
							;
					QUIT;