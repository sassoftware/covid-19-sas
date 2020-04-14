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

%PUT &ScenarioExist.; 