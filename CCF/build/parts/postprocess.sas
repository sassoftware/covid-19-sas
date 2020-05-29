				/* START: Common Post-Processing Across each Model Type and Approach */

					RT = BETA / GAMMA * &Population.;

					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
						IF counter < &IncubationPeriod THEN NEWINFECTED = .;
						IF NEWINFECTED < 0 THEN NEWINFECTED=0;

					HOSP = CEIL(NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.);
					ICU = CEIL(NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.);
					VENT = CEIL(NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.);
					ECMO = CEIL(NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.);
					DIAL = CEIL(NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.);
					
					Fatality = CEIL(NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.);
						Cumulative_sum_fatality + Fatality;
						Deceased_Today = Fatality;
						Total_Deaths = Cumulative_sum_fatality;
					
					MARKET_HOSP = CEIL(NEWINFECTED * &HOSP_RATE.);
					MARKET_ICU = CEIL(NEWINFECTED * &ICU_RATE. * &HOSP_RATE.);
					MARKET_VENT = CEIL(NEWINFECTED * &VENT_RATE. * &HOSP_RATE.);
					MARKET_ECMO = CEIL(NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.);
					MARKET_DIAL = CEIL(NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.);
					
					Market_Fatality = CEIL(NEWINFECTED * &FatalityRate. * &HOSP_RATE.);
						cumulative_Sum_Market_Fatality + Market_Fatality;
						Market_Deceased_Today = Market_Fatality;
						Market_Total_Deaths = cumulative_Sum_Market_Fatality;

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
							%END;

					/* setup drivers for OCCUPANCY variable calculations in this code */
						%LET varlist = HOSP ICU VENT ECMO DIAL MARKET_HOSP MARKET_ICU MARKET_VENT MARKET_ECMO MARKET_DIAL;

					/* *_OCCUPANCY variable calculations */
						call streaminit(2019); /* may need to move to main data step code = as long as it appears before rand function it works correctly */						
						%DO j = 1 %TO %sysfunc(countw(&varlist));
							/* get largest possible LOS for current variable - stored in setup LOS above (increase by 1 in case rates dont sum to exactly 1 */
							%LET maxlos = %eval(%sysfunc(cat(&,%scan(&varlist,&j),_LOS_MAX)) + 1);
							/* arrays to hold an retain the distribution of LOS for hospital census */
								array %scan(&varlist,&j)_los{1:&maxlos} _TEMPORARY_;
							/* at the start of each day reduce the LOS for each patient by 1 day */
								do k = 1 to &maxlos;
									if day = 0 then do;
										%scan(&varlist,&j)_los{k}=0;
									end;
									else do;
										if k < &maxlos then do;
											%scan(&varlist,&j)_los{k} = %scan(&varlist,&j)_los{k+1};
										end;
										else do;
											%scan(&varlist,&j)_los{k} = 0;
										end;
									end;
								end;
							/* distribute todays new admissions by LOS */
								do k = 1 to round(%scan(&varlist,&j),1);
									/*temp = %sysfunc(cat(&,%scan(&varlist,&j),_LOS));*/
									temp = rand('TABLED',%sysfunc(cat(&,%scan(&varlist,&j),_LOS_TABLE)));
									if temp<0 then temp=0;
									else if temp>&maxlos then temp=&maxlos;
									/* if stay (>=1) then put them in the LOS array */
									if temp>0 then %scan(&varlist,&j)_los{temp}+1;
								end;
								/* set the output variables equal to total census for current value of Day */
									%scan(&varlist,&j)_OCCUPANCY = sum(of %scan(&varlist,&j)_los{*});
						%END;
							/* correct name of hospital occupancy to expected output */
								rename HOSP_OCCUPANCY=HOSPITAL_OCCUPANCY MARKET_HOSP_OCCUPANCY=MARKET_HOSPITAL_OCCUPANCY;
							/* derived Occupancy values - calculated from renamed variables so remember to use old name (*hosp) which persist until data is written */
								MedSurgOccupancy=Hosp_Occupancy-ICU_Occupancy;
								Market_MEdSurg_Occupancy=Market_Hosp_Occupancy-MArket_ICU_Occupancy;
					
					/* date variables */
						DATE = &DAY_ZERO. + round(DAY,1);
						ADMIT_DATE = SUM(DATE, &IncubationPeriod.);
					
					/* ISOChangeEvent variable */
						FORMAT ISOChangeEvent $30.;
						%IF %sysevalf(%superq(ISOChangeDate)=,boolean)=0 %THEN %DO;
							%DO j = 1 %TO %SYSFUNC(countw(&ISOChangeDate.,:)); 
								IF DATE = &&ISOChangeDate&j THEN DO;
									ISOChangeEvent = "&&ISOChangeEvent&j";
									/* the values in EventY_Multiplier will get multiplied by Peak values later in the code */
									EventY_Multiplier = 1.1+MOD(&j,2)/10;
								END;
							%END;
						%END;
						%ELSE %DO;
							ISOChangeEvent = '';
							EventY_Multiplier = .;
						%END;

					/* clean up */
						drop k temp;

				/* END: Common Post-Processing Across each Model Type and Approach */
