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

				%DO j = 1 %TO %SYSFUNC(countw(&SocialDistancingChange.,:));
					%LET SocialDistancingChange&j = %scan(&SocialDistancingChange.,&j,:);
					%LET BETAChange&j = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
											&Population. * (1 - &&SocialDistancingChange&j));
					%LET R_T_Change&j = %SYSEVALF(&&BETAChange&j / &GAMMA. * &Population.);
					%LET ISOChangeDate&j = %scan(&ISOChangeDate.,&j,:);
				%END; 

				%LET sdchangetitle=Adjust R0 (Date / R0 / Social Distancing):;
					%DO j = 1 %TO %SYSFUNC(countw(&SocialDistancingChange.,:));
						%LET sdchangetitle = &sdchangetitle. (%sysfunc(INPUTN(&&ISOChangeDate&j., date10.), date9.) / %SYSFUNC(round(&&R_T_Change&j,.01)) / %SYSEVALF(&&SocialDistancingChange&j.*100)%); 
					%END;
				