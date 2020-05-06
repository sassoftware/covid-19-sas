				/* START: Common Post-Processing Across each Model Type and Approach */

					NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
						IF counter < &IncubationPeriod THEN NEWINFECTED = .;
						IF NEWINFECTED < 0 THEN NEWINFECTED=0;

					HOSP = NEWINFECTED * &HOSP_RATE. * &MarketSharePercent.;
					ICU = NEWINFECTED * &ICU_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					VENT = NEWINFECTED * &VENT_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					ECMO = NEWINFECTED * &ECMO_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					DIAL = NEWINFECTED * &DIAL_RATE. * &MarketSharePercent. * &HOSP_RATE.;
					
					Fatality = NEWINFECTED * &FatalityRate * &MarketSharePercent. * &HOSP_RATE.;
						Cumulative_sum_fatality + Fatality;
						Deceased_Today = Fatality;
						Total_Deaths = Cumulative_sum_fatality;
					
					MARKET_HOSP = NEWINFECTED * &HOSP_RATE.;
					MARKET_ICU = NEWINFECTED * &ICU_RATE. * &HOSP_RATE.;
					MARKET_VENT = NEWINFECTED * &VENT_RATE. * &HOSP_RATE.;
					MARKET_ECMO = NEWINFECTED * &ECMO_RATE. * &HOSP_RATE.;
					MARKET_DIAL = NEWINFECTED * &DIAL_RATE. * &HOSP_RATE.;
					
					Market_Fatality = NEWINFECTED * &FatalityRate. * &HOSP_RATE.;
						cumulative_Sum_Market_Fatality + Market_Fatality;
						Market_Deceased_Today = Market_Fatality;
						Market_Total_Deaths = cumulative_Sum_Market_Fatality;

					/* setup LOS variables */	
						%LET los_varlist = HOSP ICU VENT ECMO DIAL;
						%LET los_varlistn = %sysfunc(countw(&los_varlist));
							%DO i = 1 %TO &los_varlistn;
								%LET los_curvar = %scan(&los_varlist,&i)_LOS;
								%LET los_len = %sysfunc(countw(&&&los_curvar,:));
								%IF &los_len > 1 %THEN %DO;
									*%put "unravel delimited list distribution here later";	
								%END;
								%ELSE %DO;
									%LET &los_curvar = &&&los_curvar;
									%LET MARKET_&los_curvar = &&&los_curvar;
									*%put &los_curvar &&&los_curvar &&MARKET_&los_curvar;
									%IF &&&los_curvar = 1 %THEN %LET &los_curvar._table = 1;
									%ELSE %LET &los_curvar._table = 0;
										%DO j = 2 %TO &&&los_curvar;
											%IF &j = &&&los_curvar %THEN %LET &los_curvar._table = &&&los_curvar._table,1;
											%ELSE %LET &los_curvar._table = &&&los_curvar._table,0;
										%END;
									%LET MARKET_&los_curvar._table = &&&los_curvar._table;
									*%put &&&los_curvar._table;	
								%END;
							%END;







						%let maxlos = 40;

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
						call streaminit(2019); /* may need to move to main data step code = as long as it appears before rand function it works correctly */
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
							/* correct name of hospital occupancy to expected output */
								rename HOSP_OCCUPANCY=HOSPITAL_OCCUPANCY MARKET_HOSP_OCCUPANCY=MARKET_HOSPITAL_OCCUPANCY;
							/* derived Occupancy values */
								MedSurgOccupancy=Hospital_Occupancy-ICU_Occupancy;
								Market_MEdSurg_Occupancy=Market_Hospital_Occupancy-MArket_ICU_Occupancy;
					
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
						drop i temp;

				/* END: Common Post-Processing Across each Model Type and Approach */
