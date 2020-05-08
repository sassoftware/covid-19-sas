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
				/* update the fit source (STORE.FIT_INPUT) if outdated */
					%IF &ScenarioSource. = BATCH AND &LATEST_CASE. < %eval(%sysfunc(today())-2) %THEN %DO;

/* START: STORE.FIT_INPUT READ */

X_IMPORT: fit_input_ohio.sas
 
/* END: STORE.FIT_INPUT READ */

					%END;
            /* END DOWNLOAD FIT_INPUT **/