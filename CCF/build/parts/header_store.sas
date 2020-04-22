/* directory path for files: COVID_19.sas (this file), libname store */
    %let homedir = /Local_Files/covid-19-sas/ccf;

/* the storage location for the MODEL_FINAL table and other output tables - when &ScenarioSource=BATCH */
    libname store "&homedir.";