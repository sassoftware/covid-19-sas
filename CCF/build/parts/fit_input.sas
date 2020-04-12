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
					%IF &LATEST_CASE. < %eval(%sysfunc(today())-2) %THEN %DO;
						FILENAME OHIO URL "https://coronavirus.ohio.gov/static/COVIDSummaryData.csv";
						OPTION VALIDVARNAME=V7;
						PROC IMPORT file=OHIO OUT=WORK.OHIO_SUMMARY DBMS=CSV REPLACE;
							GETNAMES=YES;
							DATAROW=2;
							GUESSINGROWS=20000000;
						RUN; 
						/* check to make sure column 1 is county and not VAR1 - sometime the URL is pulled quickly and this gets mislabeled*/
							%let dsid=%sysfunc(open(WORK.OHIO_SUMMARY));
							%let countnum=%sysfunc(varnum(&dsid.,var1));
							%let rc=%sysfunc(close(&dsid.));
							%IF &countnum. > 0 %THEN %DO;
								data WORK.OHIO_SUMMARY; set WORK.OHIO_SUMMARY; rename VAR1=COUNTY; run;
							%END;
						/* Prepare Ohio Data For Model - add rows for missing days (had no activity) */
							PROC SQL NOPRINT;
								CREATE TABLE STORE.FIT_INPUT AS 
									SELECT INPUT(ONSET_DATE,ANYDTDTE9.) AS DATE FORMAT=DATE9., SUM(INPUT(CASE_COUNT,COMMA5.)) AS NEW_CASE_COUNT
									FROM WORK.OHIO_SUMMARY
									WHERE STRIP(UPCASE(COUNTY)) IN ('ASHLAND','ASHTABULA','CARROLL','COLUMBIANA','CRAWFORD',
										'CUYAHOGA','ERIE','GEAUGA','HOLMES','HURON','LAKE','LORAIN','MAHONING','MEDINA',
										'PORTAGE','RICHLAND','STARK','SUMMIT','TRUMBULL','TUSCARAWAS','WAYNE')
									GROUP BY CALCULATED DATE
									ORDER BY CALCULATED DATE;
								SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.FIT_INPUT;
								SELECT MAX(DATE) INTO :LATEST_CASE FROM STORE.FIT_INPUT;
								DROP TABLE WORK.OHIO_SUMMARY;
							QUIT;

							DATA ALLDATES;
								FORMAT DATE DATE9.;
								DO DATE = &FIRST_CASE. TO &LATEST_CASE.;
									TIME = DATE - &FIRST_CASE. + 1;
									OUTPUT;
								END;
							RUN;

							DATA STORE.FIT_INPUT;
								MERGE ALLDATES STORE.FIT_INPUT;
								BY DATE;
								CUMULATIVE_CASE_COUNT + NEW_CASE_COUNT;
							RUN;

							PROC SQL NOPRINT;
								drop table ALLDATES;
							QUIT; 
					%END;
            /* END DOWNLOAD FIT_INPUT **/