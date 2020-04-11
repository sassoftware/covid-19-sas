
/* Scenarios can be run in batch by specifying them in a sas dataset.
    In the example below, this dataset is created by reading scenarios from an csv file: run_scenarios.csv
    An example run_scenarios.csv file is provided with this code.

	IMPORTANT NOTES: 
		The example run_scenarios.csv file has columns for all the positional macro variables.  
		There are even more keyword parameters available.
			These need to be set for your population.
			They can be reviewed within the %EasyRun macro at the very top.
		THEN:
			you can set fixed values for the keyword parameters in the %EasyRun definition call
			OR
			you can add columns for the keyword parameters to this input file

	You could also use other files as input sources.  For example, with an excel file you could use libname XLSX.
*/
%macro run_scenarios(ds);
	/* import file */
	PROC IMPORT DATAFILE="&homedir./&ds."
		DBMS=CSV
		OUT=run_scenarios
		REPLACE;
		GETNAMES=YES;
	RUN;
	/* extract column names into space delimited string stored in macro variable &names */
	PROC SQL noprint;
		select name into :names separated by ' '
	  		from dictionary.columns
	  		where memname = 'RUN_SCENARIOS';
		select name into :dnames separated by ' '
	  		from dictionary.columns
	  		where memname = 'RUN_SCENARIOS' and substr(format,1,4)='DATE';
	QUIT;
	/* change date variables to character and of the form 'ddmmmyyyy'd */
	%DO i = 1 %TO %sysfunc(countw(&dnames.));
		%LET dname = %scan(&dnames,&i);
		data run_scenarios(drop=x);
			set run_scenarios(rename=(&dname.=x));
			&dname.="'"||put(x,date9.)||"'d";
		run;
	%END;
	/* build a call to %EasyRun for each row in run_scenarios */
	%GLOBAL cexecute;
	%DO i=1 %TO %sysfunc(countw(&names.));
		%LET next_name = %scan(&names, &i);
		%IF &i = 1 %THEN %DO;
			%LET cexecute = "&next_name.=",&next_name.; 
		%END;
		%ELSE %DO;
			%LET cexecute = &cexecute ,", &next_name.=",&next_name;
		%END;
	%END;
%mend;

%run_scenarios(run_scenarios.csv);
	/* use the &cexecute variable and the run_scenario dataset to run all the scenarios with call execute */
	data _null_;
		set run_scenarios;
		call execute(cats('%nrstr(%EasyRun(',&cexecute.,'));'));
	run;