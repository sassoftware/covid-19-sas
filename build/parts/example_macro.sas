/* Test runs of EasyRun macro 
	IMPORTANT NOTES: 
		These example runs have all the positional macro variables.  
		There are even more keyword parameters available.
			These need to be set for your population.
			They can be reviewed within the %EasyRun macro at the very top.
*/
%EasyRun(
scenario=Scenario_DrS_00_20_run_1,
IncubationPeriod=0,
InitRecovered=0,
RecoveryDays=14,
doublingtime=5,
KnownAdmits=10,
Population=4390484,
SocialDistancing=0,
MarketSharePercent=0.29,
Admission_Rate=0.075,
ICUPercent=0.45,
VentPErcent=0.35,
ISOChangeDate='31MAR2020'd,
SocialDistancingChange=0,
ISOChangeDateTwo='06APR2020'd,
SocialDistancingChangeTwo=0.2,
ISOChangeDate3='20APR2020'd,
SocialDistancingChange3=0.5,
ISOChangeDate4='01MAY2020'd,
SocialDistancingChange4=0.3,
FatalityRate=0,
plots=YES	
);
	
%EasyRun(
scenario=Scenario_DrS_00_40_run_1,
IncubationPeriod=0,
InitRecovered=0,
RecoveryDays=14,
doublingtime=5,
KnownAdmits=10,
Population=4390484,
SocialDistancing=0,
MarketSharePercent=0.29,
Admission_Rate=0.075,
ICUPercent=0.45,
VentPErcent=0.35,
ISOChangeDate='31MAR2020'd,
SocialDistancingChange=0,
ISOChangeDateTwo='06APR2020'd,
SocialDistancingChangeTwo=0.4,
ISOChangeDate3='20APR2020'd,
SocialDistancingChange3=0.5,
ISOChangeDate4='01MAY2020'd,
SocialDistancingChange4=0.3,
FatalityRate=0,
plots=YES	
);
	
%EasyRun(
scenario=Scenario_DrS_00_40_run_12,
IncubationPeriod=0,
InitRecovered=0,
RecoveryDays=14,
doublingtime=5,
KnownAdmits=10,
Population=4390484,
SocialDistancing=0,
MarketSharePercent=0.29,
Admission_Rate=0.075,
ICUPercent=0.45,
VentPErcent=0.35,
ISOChangeDate='31MAY2020'd,
SocialDistancingChange=0.25,
ISOChangeDateTwo='06AUG2020'd,
SocialDistancingChangeTwo=0.5,
ISOChangeDate3='20AUG2020'd,
SocialDistancingChange3=0.4,
ISOChangeDate4='01SEP2020'd,
SocialDistancingChange4=0.2,
FatalityRate=0,
plots=YES	
);