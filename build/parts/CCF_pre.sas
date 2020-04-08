/* the following is specific to CCF coding and included prior to the %EasyRun Macro */
	libname DL_RA teradata server=tdprod1 database=DL_RiskAnalytics;
	libname DL_COV teradata server=tdprod1 database=DL_COVID;
	libname CovData '/sas/data/ccf_preprod/finance/sas/EA_COVID_19/CovidData';
	proc datasets lib=work kill;run;quit;

	proc sql; 
	connect to teradata(Server=tdprod1);
	create table CovData.PullRealCovid as select * from connection to teradata 

	(
	Select COVID_RESULT_V.*, DEP_STATE from DL_COVID.COVID_RESULT_V
	LEFT JOIN (SELECT DISTINCT COVID_FACT_V.patient_identifier,COVID_FACT_V.DEP_STATE from DL_COVID.COVID_FACT_V) dep_st
	on dep_st.patient_identifier = COVID_RESULT_V.patient_identifier
	WHERE COVIDYN = 'YES' and DEP_STATE='OH'and discharge_Cat in ('Inpatient','Discharged To Home');
	)

	;quit;
	PROC SQL;
	CREATE TABLE CovData.PullRealAdmitCovid AS 
	SELECT /* AdmitDate */
				(datepart(t1.HSP_ADMIT_DTTM)) FORMAT=Date9. AS AdmitDate, 
			/* COUNT_DISTINCT_of_patient_identi */
				(COUNT(DISTINCT(t1.patient_identifier))) AS TrueDailyAdmits, 
			/* SumICUNum_1 */
				(SUM(input(t1.ICU, 3.))) AS SumICUNum_1, 
			/* SumICUNum */
				(SUM(case when t1.ICU='YES' then 1
				else case when t1.ICU='1' then 1 else 0
				end end)) AS SumICUNum
		FROM CovData.PULLREALCOVID t1
		GROUP BY (CALCULATED AdmitDate);
	QUIT;
	PROC SQL;
	CREATE TABLE CovData.RealCovid_DischargeDt AS 
	SELECT /* COUNT_of_patient_identifier */
				(COUNT(t1.patient_identifier)) AS TrueDailyDischarges, 
			/* DischargDate */
				(datepart(t1.HSP_DISCH_DTTM)) FORMAT=Date9. AS DischargDate, 
			/* SUMICUDISCHARGE */
				(SUM(Case when t1.DISCHARGEICUYN ='YES' then 1
				else case when t1.DISCHARGEICUYN ='1' then 1
				else 0
				end end)) AS SUMICUDISCHARGE
		FROM CovData.PULLREALCOVID t1
		WHERE (CALCULATED DischargDate) NOT = .
		GROUP BY (CALCULATED DischargDate);
	QUIT;
