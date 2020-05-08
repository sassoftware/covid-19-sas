						/* import data feed from fit_import.csv in libname store */
							PROC IMPORT FILE="&homedir./fit_input.csv" OUT=STORE.FIT_INPUT DBMS=CSV REPLACE;
								GETNAMES = YES;
								DATAROW=2;
								GUESSINGROWS=200;
							RUN; 

							PROC SQL NOPRINT;
								SELECT MIN(DATE) INTO :FIRST_CASE FROM STORE.FIT_INPUT;
								SELECT MAX(DATE) INTO :LATEST_CASE FROM STORE.FIT_INPUT;
							QUIT;

						/* This section, from START: to END:, can be adapted to read case data from your data feed of choice

							If you have data in a database or a sas dataset you can use this section to read it and store it in STORE.FIT_INPUT

							Note: the condition before START: will only run a data refresh when the current source has no data for the last 2 days
						
							for an example of importing data from a source feed check out /examples/fit_import_ohio.sas
								the contents can be used to replace this section of the code from START: to END:
						*/
