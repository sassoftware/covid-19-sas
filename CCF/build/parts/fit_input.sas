			/* START DOWNLOAD FIT_INPUT - only if STORE.FIT_INPUT does not have data for yesterday */
				/* the file appears to be updated throughout the day but partial data for today could cause issues with fit */
				%IF %sysfunc(exist(STORE.FIT_INPUT)) %THEN %DO;
					PROC SQL NOPRINT; 
						SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.FIT_INPUT;
						SELECT MAX(DATE) into :LATEST_CASE FROM STORE.FIT_INPUT; 
					QUIT;
				%END;
				%ELSE %DO;
					%LET LATEST_CASE=0;
				%END;
					%IF &ScenarioSource. = BATCH %THEN %DO;
						%IF &LATEST_CASE. < %eval(%sysfunc(today())-2) %THEN %DO;
							FILENAME OHIO URL "https://coronavirus.ohio.gov/static/COVIDSummaryData.csv";
							OPTION VALIDVARNAME=V7;
							PROC IMPORT file=OHIO OUT=WORK.FIT_IMPORT DBMS=CSV REPLACE;
								GETNAMES=YES;
								DATAROW=2;
								GUESSINGROWS=20000000;
							RUN; 
							/* check to make sure column 1 is county and not VAR1 - sometime the URL is pulled quickly and this gets mislabeled*/
								%let dsid=%sysfunc(open(WORK.FIT_IMPORT));
								%let countnum=%sysfunc(varnum(&dsid.,var1));
								%let rc=%sysfunc(close(&dsid.));
								%IF &countnum. > 0 %THEN %DO;
									data WORK.FIT_IMPORT; set WORK.FIT_IMPORT; rename VAR1=COUNTY; run;
								%END;
							/* Prepare Ohio Data For Model - add rows for missing days (had no activity) */
								PROC SQL NOPRINT;
									CREATE TABLE WORK.FIT_INPUT AS 
										SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
										FROM WORK.FIT_IMPORT
										WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
											'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
											'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
										GROUP BY CALCULATED DATE
										ORDER BY CALCULATED DATE;
									SELECT MIN(DATE) INTO :FIRST_CASE FROM WORK.FIT_INPUT;
									SELECT MAX(DATE) INTO :LATEST_CASE FROM WORK.FIT_INPUT;
								QUIT;

								DATA ALLDATES;
									FORMAT DATE DATE9.;
									DO DATE = &FIRST_CASE. TO &LATEST_CASE.;
										TIME = DATE - &FIRST_CASE. + 1;
										OUTPUT;
									END;
								RUN;

								DATA STORE.FIT_INPUT;
									MERGE ALLDATES WORK.FIT_INPUT;
									BY DATE;
									CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
								RUN;

								PROC SQL NOPRINT;
									drop table ALLDATES;
									drop table WORK.FIT_INPUT;
								QUIT; 
						%END;
					%END;
            /* END DOWNLOAD FIT_INPUT **/