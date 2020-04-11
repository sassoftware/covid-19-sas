				/*CREATE FLAGS FOR DAYS WITH PEAK VALUES OF DIFFERENT METRICS*/
					PROC SQL;
						CREATE TABLE WORK.MODEL_FINAL AS
							SELECT *,
								CASE when HOSPITAL_OCCUPANCY = max(HOSPITAL_OCCUPANCY) then 1 else 0 END as PEAK_HOSPITAL_OCCUPANCY LABEL="Peak Value: Current Hospitalized Census",
								CASE when ICU_OCCUPANCY = max(ICU_OCCUPANCY) then 1 else 0 END as PEAK_ICU_OCCUPANCY LABEL="Peak Value: Current Hospital ICU Census",
								CASE when VENT_OCCUPANCY = max(VENT_OCCUPANCY) then 1 else 0 END as PEAK_VENT_OCCUPANCY LABEL="Peak Value: Current Hospital Ventilator Patients",
								CASE when ECMO_OCCUPANCY = max(ECMO_OCCUPANCY) then 1 else 0 END as PEAK_ECMO_OCCUPANCY LABEL="Peak Value: Current Hospital ECMO Patients",
								CASE when DIAL_OCCUPANCY = max(DIAL_OCCUPANCY) then 1 else 0 END as PEAK_DIAL_OCCUPANCY LABEL="Peak Value: Current Hospital Dialysis Patients",
								CASE when I_N = max(I_N) then 1 else 0 END as PEAK_I_N LABEL="Peak Value: Current Infected Population",
								CASE when FATALITY = max(FATALITY) then 1 else 0 END as PEAK_FATALITY LABEL="Peak Value: New Hospital Mortality"
							FROM WORK.MODEL_FINAL
							GROUP BY SCENARIONAMEUNIQUE, MODELTYPE
							ORDER BY SCENARIONAMEUNIQUE, MODELTYPE, DATE
						;
					QUIT;