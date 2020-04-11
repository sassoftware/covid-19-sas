			* calculated parameters used in model post-processing;
				%LET HOSP_RATE = %SYSEVALF(&Admission_Rate. * &DiagnosedRate.);
				%LET ICU_RATE = %SYSEVALF(&ICUPercent. * &DiagnosedRate.);
				%LET VENT_RATE = %SYSEVALF(&VentPErcent. * &DiagnosedRate.);
			* calculated parameters used in models;
				%LET I = %SYSEVALF(&KnownAdmits. / 
											&MarketSharePercent. / 
												(&Admission_Rate. * &DiagnosedRate.));
				%LET GAMMA = %SYSEVALF(1 / &RecoveryDays.);
				%LET BETA = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancing.));
				%LET BETAChange = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange.));
				%LET BETAChangeTwo = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChangeTwo.));
				%LET BETAChange3 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange3.));
				%LET BETAChange4 = %SYSEVALF(((2 ** (1 / &doublingtime.) - 1) + &GAMMA.) / 
												&Population. * (1 - &SocialDistancingChange4.));
				%LET R_T = %SYSEVALF(&BETA. / &GAMMA. * &Population.);
				%LET R_T_Change = %SYSEVALF(&BETAChange. / &GAMMA. * &Population.);
				%LET R_T_Change_Two = %SYSEVALF(&BETAChangeTwo. / &GAMMA. * &Population.);
				%LET R_T_Change_3 = %SYSEVALF(&BETAChange3. / &GAMMA. * &Population.);
				%LET R_T_Change_4 = %SYSEVALF(&BETAChange4. / &GAMMA. * &Population.);
