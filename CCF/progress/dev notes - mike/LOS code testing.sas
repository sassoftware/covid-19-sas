/* this is an isolated test of the LOS code found in postprocessing.sas */
%macro test();


/* expected inputs */
%LET HOSP_LOS = 0:0:0:1;
%LET ICU_LOS = 5|.5:6|.5;
%LET VENT_LOS = 7;
%LET ECMO_LOS = 1|1;
%LET DIAL_LOS = 8|1;

/* code from postprocessing.sas */

					/* setup LOS macro variables - create *_LOS_TABLE string for rand('TABLED') call in _OCCUPANCY variable calculations */	
						%LET los_varlist = HOSP ICU VENT ECMO DIAL;
							%DO j = 1 %TO %sysfunc(countw(&los_varlist));
								/* pick a variable from &los_varlist to work on and add _LOS as suffix to name */
									%LET los_curvar = %scan(&los_varlist,&j)_LOS;
								/* store the number of days entered in &los_len */
									%LET los_len = %sysfunc(countw(&&&los_curvar,:));
								/* detect day|rate pairs and reconstruct &&&los_curvar as a : delimited list of rates for each day */
									%IF %sysfunc(countw(&&&los_curvar,|)) > 1 %THEN %DO;
										/* iterate over input pairs - assuming they are in order */
											%DO d = 1 %TO &los_len;
												/* caputure the starting day for this pair */
													%IF &d > 1 %THEN %LET d_day_start = %eval(&d_day+1);
													%ELSE %LET d_day_start = 1;
												/* extract the current value for day and rate */
													%LET d_day = %scan(%scan(&&&los_curvar,&d,:),1,|);
													%LET d_rate = %scan(%scan(&&&los_curvar,&d,:),2,|);
												/* iterate up to the day from the pair - fill in missing days with 0 rate */
													%DO e = &d_day_start %TO &d_day;
														/* initialize the string of rates on day 1 */
															%IF &e = 1 %THEN %DO;
																%IF &e < &d_day %THEN %LET out_str = 0;
																%ELSE %LET out_str = &d_rate;
															%END;
														/* increment the string of rates on day > 1 */
															%ELSE %DO;
																%IF &e < &d_day %THEN %LET out_str =  &out_str:0;
																%ELSE %LET out_str = &out_str:&d_rate;
															%END;
													%END;
											%END;
											/* update &los_curvar with the new string of rates */
												%let &los_curvar = %sysfunc(compress(&out_str));
											/* update &los_len to the length of the new unravled string */
												%let los_len = %sysfunc(countw(&&&los_curvar,:));
									%END;
								/* the user input a range or rates for LOS = 1, 2, ... */
								%IF &los_len > 1 %THEN %DO;
									/* initialize the *_LOS_TABLE macro variable with the day 1 rate */
										%LET &los_curvar._TABLE = %scan(&&&los_curvar,1,:);
									/* for each day from 2 to the last entered append the days rate with comma delimiter */
										%DO k = 2 %TO &los_len;
											%LET &los_curvar._TABLE = &&&los_curvar._TABLE,%scan(&&&los_curvar,&k,:);
										%END;
									/* The MARKET_ variables for LOS_TABLE are equal to the *_LOS_TABLE created above */
										%LET MARKET_&los_curvar._TABLE = &&&los_curvar._TABLE;
									/* store the number of days in *LOS_MAX and MARKET_*_LOS_MAX */
										%LET &los_curvar._MAX = &los_len;
										%LET MARKET_&los_curvar._MAX = &los_len;
								%END;
								/* the user input an integer value for LOS */
								%ELSE %DO;
									%LET MARKET_&los_curvar = &&&los_curvar;
									%IF &&&los_curvar = 1 %THEN %LET &los_curvar._TABLE = 1;
									%ELSE %LET &los_curvar._TABLE = 0;
										%DO k = 2 %TO &&&los_curvar;
											%IF &k = &&&los_curvar %THEN %LET &los_curvar._TABLE = &&&los_curvar._TABLE,1;
											%ELSE %LET &los_curvar._TABLE = &&&los_curvar._TABLE,0;
										%END;
									%LET MARKET_&los_curvar._TABLE = &&&los_curvar._TABLE;
									%LET &los_curvar._MAX = &&&los_curvar;
									%LET MARKET_&los_curvar._MAX = &&&los_curvar;
								%END;
								 /* %put &los_curvar &&&los_curvar &&&los_curvar._MAX &&&los_curvar._TABLE; */
%put &los_curvar &&&los_curvar._TABLE;
							%END;

%mend;
%test();

