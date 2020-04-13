/* directory path for files: COVID_19.sas (this file), libname store */
%let homedir = /Local_Files/covid-19-sas/ccf;

/* the storage location for the MODEL_FINAL table and the SCENARIOS table */
libname store "&homedir.";

proc sql;
	drop table store.FIT_PARMS;
drop table store.FIT_PRED;
drop table store.INPUTS;
drop table store.MODEL_FINAL;
drop table store.SCENARIOS;
quit;