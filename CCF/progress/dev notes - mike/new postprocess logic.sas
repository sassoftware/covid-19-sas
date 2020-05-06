%macro test(HOSP_LOS,ICU_LOS,VENT_LOS,ECMO_LOS,DIAL_LOS);
					/* setup LOS variables */	
						%LET los_varlist = HOSP ICU VENT ECMO DIAL;
						%LET los_varlistn = %sysfunc(countw(&los_varlist));
							%DO i = 1 %TO &los_varlistn;
								%LET los_curvar = %scan(&los_varlist,&i)_LOS;
								%LET los_len = %sysfunc(countw(&&&los_curvar,:));
								%IF &los_len > 1 %THEN %DO;
%put "unravel delimited list distribution here later";	
								%END;
								%ELSE %DO;
									%LET &los_curvar = &&&los_curvar;
									%LET MARKET_&los_curvar = &&&los_curvar;
%put &los_curvar &&&los_curvar &&MARKET_&los_curvar;
									%IF &&&los_curvar = 1 %THEN %LET &los_curvar._table = 1;
									%ELSE %LET &los_curvar._table = 0;
										%DO j = 2 %TO &&&los_curvar;
											%IF &j = &&&los_curvar %THEN %LET &los_curvar._table = &&&los_curvar._table,1;
											%ELSE %LET &los_curvar._table = &&&los_curvar._table,0;
										%END;
									%LET MARKET_&los_curvar._table = &&&los_curvar._table;
%put &&&los_curvar._table;	
								%END;
							%END;



data test; 
do day = 0 to 50;
output;
end;
run;

data test; set test;
						%let maxlos = 40;
HOSP=10;
ICU=10;
ECMO=10;
VENT=10;
DIAL=10;
MARKET_HOSP=10;
MARKET_ICU=10;
MARKET_ECMO=10;
MARKET_VENT=10;
MARKET_DIAL=10;
					/* setup drivers for this code */
						%LET varlist = HOSP ICU VENT ECMO DIAL MARKET_HOSP MARKET_ICU MARKET_VENT MARKET_ECMO MARKET_DIAL;
						%LET varlistn = %sysfunc(countw(&varlist));

					/* arrays to hold an retain the distribution of LOS for hospital census */	
						%DO i = 1 %TO &varlistn;
							array %scan(&varlist,&i)_los{0:&maxlos} _TEMPORARY_;
						%END;

					/* at the start of each day reduce the LOS for each patient by 1 day */
						%DO i = 1 %TO &varlistn;
							do i = 0 to &maxlos;
								if day = 0 then do;
									%scan(&varlist,&i)_los{i}=0;
								end;
								else do;
									if i < &maxlos then do;
										%scan(&varlist,&i)_los{i} = %scan(&varlist,&i)_los{i+1};
									end;
									else do;
										%scan(&varlist,&i)_los{i} = 0;
									end;
								end;
							end;
						%END;

					/* distribute todays new admissions by LOS */
						call streaminit(2019); /* may need to move to main data step code */
						%DO i = 1 %TO &varlistn;
							do i = 1 to round(%scan(&varlist,&i),1);
								*temp = %sysfunc(cat(&,%scan(&varlist,&i),_LOS));
								temp = rand('TABLED',%sysfunc(cat(&,%scan(&varlist,&i),_LOS_table)));
								if temp<0 then temp=0;
								else if temp>&maxlos then temp=&maxlos;
								%scan(&varlist,&i)_los{temp}+1;
							end;
							/* set the output variables equal to total census for current value of Day */
							%scan(&varlist,&i)_OCCUPANCY = sum(of %scan(&varlist,&i)_los{*});
						%END;
run;


%mend;
%test(1,8,12,16,20);





/* test placement of call streaminit */

data temp;
call streaminit(1234);
do a = 1 to 5;
x=rand('UNIFORM');
put x;
end;
run;


data temp;
do a = 1 to 5;
call streaminit(1234);
x=rand('UNIFORM');
put x;
end;
run;

