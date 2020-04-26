/* directory path for files: COVID_19.sas (this file), libname store */
    %let homedir = /Local_Files/covid-19-sas/ccf;

/* the storage location for the MODEL_FINAL table and other output tables - when &ScenarioSource=BATCH */
    libname store "&homedir.";


CAS;

CASLIB _ALL_ ASSIGN;

	/* ScenarioIndex=1 implies a new MODEL_FINAL is being built, load it to CAS, if already in CAS then drop first */
	PROC CASUTIL;
		DROPTABLE INCASLIB="CASUSER" CASDATA="MODEL_FINAL" QUIET;
		LOAD DATA=store.MODEL_FINAL CASOUT="MODEL_FINAL" OUTCASLIB="CASUSER" PROMOTE;
		
		DROPTABLE INCASLIB="CASUSER" CASDATA="SCENARIOS" QUIET;
		LOAD DATA=store.SCENARIOS CASOUT="SCENARIOS" OUTCASLIB="CASUSER" PROMOTE;

		DROPTABLE INCASLIB="CASUSER" CASDATA="INPUTS" QUIET;
		LOAD DATA=store.INPUTS CASOUT="INPUTS" OUTCASLIB="CASUSER" PROMOTE;
	QUIT;



%IF %SYSFUNC(exist(casuser.scenarios)) %THEN %DO;
	%PUT "It detects caslib tables";
%END;
%ELSE %DO;
	%PUT "Boooooo";
%END;

%LET GlobalCAS=casuser;

PROC SQL noprint; select max(ScenarioIndex) into :ScenarioIndex_Base from store.scenarios; quit;
%PUT &ScenarioIndex_Base;

PROC SQL noprint; select max(ScenarioIndex) into :CScenarioIndex_Base from &GlobalCAS..scenarios; quit;
%PUT &CScenarioIndex_Base;

PROC SQL noprint;
	select max(ScenarioIndex) into :ScenarioIndex_Base from store.scenarios where name='Mike';
quit;
%PUT &ScenarioIndex_Base;
%IF &ScenarioIndex_Base = . %THEN %DO; %LET ScenarioIndex_Base = 0; %END;
%PUT &ScenarioIndex_Base;


PROC SQL noprint;
	select ScenarioIndex into :ScenarioIndex_Base separated by ',' from store.scenarios;
QUIT;
%PUT &ScenarioIndex_Base;

CAS CASAUTO TERMINATE;