			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%IF &SIGMA. <= 0 %THEN %LET SIGMA = 0.00000001;
					%LET SIGMAINV = %SYSEVALF(1 / &SIGMA.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);

				%IF %sysevalf(%superq(SocialDistancingChange)=,boolean)=0 %THEN %DO;
					%LET sdchangetitle=Adjust R0 (Date / Event / R0 / Social Distancing Shift):;
					%LET ISOChangeLoop = %SYSFUNC(countw(&SocialDistancingChange.,:));
					%DO j = 1 %TO &ISOChangeLoop;
						%LET SocialDistancingChange&j = %scan(&SocialDistancingChange.,&j,:);
						%LET ISOChangeDate&j = %scan(&ISOChangeDate.,&j,:);
						%LET ISOChangeEvent&j = %scan(&ISOChangeEvent.,&j,:);
						%LET ISOChangeWindow&j = %scan(&ISOChangeWindow.,&j,:);

						%LET BETAChange&j = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * ((&&SocialDistancingChange&j)/&&ISOChangeWindow&j));
						%IF &j = 1 %THEN %LET R_T_Change&j = %SYSEVALF(&R_T - &&BETAChange&j / &GAMMA. * &Population.);
						%ELSE %DO;
							%LET j2=%eval(&j-1);
							%LET R_T_Change&j = %SYSEVALF(&&R_T_Change&j2 - &&BETAChange&j / &GAMMA. * &Population.);
						%END;

						%LET sdchangetitle = &sdchangetitle. (%sysfunc(INPUTN(&&ISOChangeDate&j., date10.), date9.) / &&ISOChangeEvent&j / %SYSFUNC(round(&&R_T_Change&j,.01)) / %SYSEVALF(&&SocialDistancingChange&j.*100)%);
					%END; 
				%END;
				%ELSE %DO;
					%LET sdchangetitle=No Adjustment to R0 over time;
					%LET ISOChangeLoop = 0;
				%END;
				