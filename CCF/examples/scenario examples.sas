/* this example illustrates potential projects where social distancing is relaxed and then reinstated */
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
ISOChangeDate='27MAR2020'd:'01MAY2020'd:'01JUL2020'd:'01SEP2020'd:'01NOV2020'd,
ISOChangeEvent=Change 1:Change 2:Change 3:Change 4:Change 5,
SocialDistancingChange=0.7:0.5:0.7:0.5:0.7,
FatalityRate=0,
plots=YES,
DAY_ZERO='01MAR2020'd	
);