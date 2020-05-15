
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
	/* proc import changes ISOChangeDate to a date format and only pulls first date in list - switch to manual data step with infile
	PROC IMPORT DATAFILE="&homedir./&ds."
		DBMS=CSV
		OUT=run_scenarios
		REPLACE;
		GETNAMES=YES;
	RUN;
	*/
	/* manual data step import with infile - note this will miss new columns added to the run_scenarios.csv unless it is updated */
	data WORK.RUN_SCENARIOS;
		infile "&homedir./run_scenarios.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
		informat scenario $25. ;
		informat IncubationPeriod best32. ;
		informat InitRecovered best32. ;
		informat RecoveryDays best32. ;
		informat doublingtime best32. ;
		informat KnownAdmits best32. ;
		informat Population best32. ;
		informat SocialDistancing best32. ;
		informat MarketSharePercent best32. ;
		informat Admission_Rate best32. ;
		informat ICUPercent best32. ;
		informat VentPErcent best32. ;
		informat ISOChangeDate $200. ;
		informat ISOChangeEvent $200. ;
		informat ISOChangeWindow $50. ;
		informat SocialDistancingChange $50. ;
		informat FatalityRate best32. ;
		informat plots $3. ;
		format scenario $25. ;
		format IncubationPeriod best12. ;
		format InitRecovered best12. ;
		format RecoveryDays best12. ;
		format doublingtime best12. ;
		format KnownAdmits best12. ;
		format Population best12. ;
		format SocialDistancing best12. ;
		format MarketSharePercent best12. ;
		format Admission_Rate best12. ;
		format ICUPercent best12. ;
		format VentPErcent best12. ;
		format ISOChangeDate $200. ;
		format ISOChangeEvent $200. ;
		format ISOChangeWindow $50. ;
		format SocialDistancingChange $50. ;
		format FatalityRate best12. ;
		format plots $3. ;
		input
					scenario  $
					IncubationPeriod
					InitRecovered
					RecoveryDays
					doublingtime
					KnownAdmits
					Population
					SocialDistancing
					MarketSharePercent
					Admission_Rate
					ICUPercent
					VentPErcent
					ISOChangeDate $
					ISOChangeEvent $
					ISOChangeWindow $
					SocialDistancingChange  $
					FatalityRate
					plots  $
		;
	run;
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
	%IF %SYMEXIST(dnames) %THEN %DO i = 1 %TO %sysfunc(countw(&dnames.));
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


