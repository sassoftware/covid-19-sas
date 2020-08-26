
%if %sysfunc(exist(boemska_ds_seir)) %then %do;
	data ds_seir;
		set boemska_ds_seir;
		datetime=dhms(date,0,0,0);
		drop
			ModelType
			ScenarioName
			ScenarioNameUnique
			ScenarioSource
			ScenarioUser
			ScenarioIndex
			;
	run;
%end;

%if %sysfunc(exist(boemska_ds_sir)) %then %do;
	data ds_sir;
		set boemska_ds_sir;
		datetime=dhms(date,0,0,0);
		drop
			ModelType
			ScenarioName
			ScenarioNameUnique
			ScenarioSource
			ScenarioUser
			ScenarioIndex
			;
	run;
%end;


%if %sysfunc(exist(boemska_tmodel_seir)) %then %do;
	data tmodel_seir;
		set boemska_tmodel_seir;
		datetime=dhms(date,0,0,0);
		drop
			ModelType
			ScenarioName
			ScenarioNameUnique
			ScenarioSource
			ScenarioUser
			ScenarioIndex
			;
	run;
%end;

%if %sysfunc(exist(boemska_tmodel_seir_fit_i)) %then %do;
	data tmodel_seir_fit_i;
		set boemska_tmodel_seir_fit_i;
		datetime=dhms(date,0,0,0);
		drop
			ModelType
			ScenarioName
			ScenarioNameUnique
			ScenarioSource
			ScenarioUser
			ScenarioIndex
			;
	run;
%end;

%if %sysfunc(exist(boemska_tmodel_sir)) %then %do;
	data tmodel_sir;
	set boemska_tmodel_sir;
	datetime=dhms(date,0,0,0);
	drop
		ModelType
		ScenarioName
		ScenarioNameUnique
		ScenarioSource
		ScenarioUser
		ScenarioIndex
		;
	run;
%end;


%macro bafCheckoutputs;
* this if sysfunc exist happens for each outtable ;

* --out table 0-- ;
  %if %sysfunc(exist(ds_seir)) = 0 %then %do;
    data ds_seir;
  length DATE $80. ADMIT_DATE $80. S_N 8. I_N 8. E_N 8. R_N 8. DAY 8. NEWINFECTED 8. HOSP 8. ICU 8. VENT 8. ECMO 8. DIAL 8. Fatality 8. Deceased_Today 8. Total_Deaths 8. MARKET_HOSP 8. MARKET_ICU 8. MARKET_VENT 8. MARKET_ECMO 8. MARKET_DIAL 8. Market_Fatality 8. Market_Deceased_Today 8. Market_Total_Deaths 8. HOSPITAL_OCCUPANCY 8. ICU_OCCUPANCY 8. VENT_OCCUPANCY 8. ECMO_OCCUPANCY 8. DIAL_OCCUPANCY 8. MARKET_HOSPITAL_OCCUPANCY 8. MARKET_ICU_OCCUPANCY 8. MARKET_VENT_OCCUPANCY 8. MARKET_ECMO_OCCUPANCY 8. MARKET_DIAL_OCCUPANCY 8. MedSurgOccupancy 8. Market_MEdSurg_Occupancy 8. ISOChangeEvent $80. LOWER_HOSPITAL_OCCUPANCY 8. LOWER_ICU_OCCUPANCY 8. LOWER_VENT_OCCUPANCY 8. LOWER_ECMO_OCCUPANCY 8. LOWER_DIAL_OCCUPANCY 8. UPPER_HOSPITAL_OCCUPANCY 8. UPPER_ICU_OCCUPANCY 8. UPPER_VENT_OCCUPANCY 8. UPPER_ECMO_OCCUPANCY 8. UPPER_DIAL_OCCUPANCY 8. BETA 8. SocialDistancing 8. N 8. SCALE 8. RT 8. EventY_Multiplier 8. datetime 8.;
    run;
  %end;
* --out table 1-- ;
  %if %sysfunc(exist(ds_sir)) = 0 %then %do;
    data ds_sir;
  length DATE $80. ADMIT_DATE $80. S_N 8. I_N 8. E_N 8. R_N 8. DAY 8. NEWINFECTED 8. HOSP 8. ICU 8. VENT 8. ECMO 8. DIAL 8. Fatality 8. Deceased_Today 8. Total_Deaths 8. MARKET_HOSP 8. MARKET_ICU 8. MARKET_VENT 8. MARKET_ECMO 8. MARKET_DIAL 8. Market_Fatality 8. Market_Deceased_Today 8. Market_Total_Deaths 8. HOSPITAL_OCCUPANCY 8. ICU_OCCUPANCY 8. VENT_OCCUPANCY 8. ECMO_OCCUPANCY 8. DIAL_OCCUPANCY 8. MARKET_HOSPITAL_OCCUPANCY 8. MARKET_ICU_OCCUPANCY 8. MARKET_VENT_OCCUPANCY 8. MARKET_ECMO_OCCUPANCY 8. MARKET_DIAL_OCCUPANCY 8. MedSurgOccupancy 8. Market_MEdSurg_Occupancy 8. ISOChangeEvent $80. LOWER_HOSPITAL_OCCUPANCY 8. LOWER_ICU_OCCUPANCY 8. LOWER_VENT_OCCUPANCY 8. LOWER_ECMO_OCCUPANCY 8. LOWER_DIAL_OCCUPANCY 8. UPPER_HOSPITAL_OCCUPANCY 8. UPPER_ICU_OCCUPANCY 8. UPPER_VENT_OCCUPANCY 8. UPPER_ECMO_OCCUPANCY 8. UPPER_DIAL_OCCUPANCY 8. BETA 8. SocialDistancing 8. N 8. SCALE 8. RT 8. EventY_Multiplier 8. datetime 8.;
    run;
  %end;
* --out table 2-- ;
  %if %sysfunc(exist(tmodel_seir)) = 0 %then %do;
    data tmodel_seir;
  length ModelType $80. DATE $80. ADMIT_DATE $80. ScenarioName $80. ScenarioNameUnique $80. ScenarioSource $80. ScenarioUser $80. ScenarioIndex 8. S_N 8. I_N 8. E_N 8. R_N 8. DAY 8. NEWINFECTED 8. HOSP 8. ICU 8. VENT 8. ECMO 8. DIAL 8. Fatality 8. Deceased_Today 8. Total_Deaths 8. MARKET_HOSP 8. MARKET_ICU 8. MARKET_VENT 8. MARKET_ECMO 8. MARKET_DIAL 8. Market_Fatality 8. Market_Deceased_Today 8. Market_Total_Deaths 8. HOSPITAL_OCCUPANCY 8. ICU_OCCUPANCY 8. VENT_OCCUPANCY 8. ECMO_OCCUPANCY 8. DIAL_OCCUPANCY 8. MARKET_HOSPITAL_OCCUPANCY 8. MARKET_ICU_OCCUPANCY 8. MARKET_VENT_OCCUPANCY 8. MARKET_ECMO_OCCUPANCY 8. MARKET_DIAL_OCCUPANCY 8. MedSurgOccupancy 8. Market_MEdSurg_Occupancy 8. ISOChangeEvent $80. LOWER_HOSPITAL_OCCUPANCY 8. LOWER_ICU_OCCUPANCY 8. LOWER_VENT_OCCUPANCY 8. LOWER_ECMO_OCCUPANCY 8. LOWER_DIAL_OCCUPANCY 8. UPPER_HOSPITAL_OCCUPANCY 8. UPPER_ICU_OCCUPANCY 8. UPPER_VENT_OCCUPANCY 8. UPPER_ECMO_OCCUPANCY 8. UPPER_DIAL_OCCUPANCY 8. SocialDistancing 8. BETA 8. RT 8. EventY_Multiplier 8.;
    run;
  %end;
* --out table 3-- ;
  %if %sysfunc(exist(tmodel_seir_fit_i)) = 0 %then %do;
    data tmodel_seir_fit_i;
  length ModelType $80. DATE $80. ADMIT_DATE $80. ScenarioName $80. ScenarioNameUnique $80. ScenarioSource $80. ScenarioUser $80. ScenarioIndex 8. S_N 8. I_N 8. E_N 8. R_N 8. DAY 8. NEWINFECTED 8. HOSP 8. ICU 8. VENT 8. ECMO 8. DIAL 8. Fatality 8. Deceased_Today 8. Total_Deaths 8. MARKET_HOSP 8. MARKET_ICU 8. MARKET_VENT 8. MARKET_ECMO 8. MARKET_DIAL 8. Market_Fatality 8. Market_Deceased_Today 8. Market_Total_Deaths 8. HOSPITAL_OCCUPANCY 8. ICU_OCCUPANCY 8. VENT_OCCUPANCY 8. ECMO_OCCUPANCY 8. DIAL_OCCUPANCY 8. MARKET_HOSPITAL_OCCUPANCY 8. MARKET_ICU_OCCUPANCY 8. MARKET_VENT_OCCUPANCY 8. MARKET_ECMO_OCCUPANCY 8. MARKET_DIAL_OCCUPANCY 8. MedSurgOccupancy 8. Market_MEdSurg_Occupancy 8. ISOChangeEvent $80. LOWER_HOSPITAL_OCCUPANCY 8. LOWER_ICU_OCCUPANCY 8. LOWER_VENT_OCCUPANCY 8. LOWER_ECMO_OCCUPANCY 8. LOWER_DIAL_OCCUPANCY 8. UPPER_HOSPITAL_OCCUPANCY 8. UPPER_ICU_OCCUPANCY 8. UPPER_VENT_OCCUPANCY 8. UPPER_ECMO_OCCUPANCY 8. UPPER_DIAL_OCCUPANCY 8. SocialDistancing 8. BETA 8. RT 8. EventY_Multiplier 8.;
    run;
  %end;
* --out table 4-- ;
  %if %sysfunc(exist(tmodel_sir)) = 0 %then %do;
    data tmodel_sir;
  length DATE $80. ADMIT_DATE $80. S_N 8. I_N 8. E_N 8. R_N 8. DAY 8. NEWINFECTED 8. HOSP 8. ICU 8. VENT 8. ECMO 8. DIAL 8. Fatality 8. Deceased_Today 8. Total_Deaths 8. MARKET_HOSP 8. MARKET_ICU 8. MARKET_VENT 8. MARKET_ECMO 8. MARKET_DIAL 8. Market_Fatality 8. Market_Deceased_Today 8. Market_Total_Deaths 8. HOSPITAL_OCCUPANCY 8. ICU_OCCUPANCY 8. VENT_OCCUPANCY 8. ECMO_OCCUPANCY 8. DIAL_OCCUPANCY 8. MARKET_HOSPITAL_OCCUPANCY 8. MARKET_ICU_OCCUPANCY 8. MARKET_VENT_OCCUPANCY 8. MARKET_ECMO_OCCUPANCY 8. MARKET_DIAL_OCCUPANCY 8. MedSurgOccupancy 8. Market_MEdSurg_Occupancy 8. ISOChangeEvent $80. LOWER_HOSPITAL_OCCUPANCY 8. LOWER_ICU_OCCUPANCY 8. LOWER_VENT_OCCUPANCY 8. LOWER_ECMO_OCCUPANCY 8. LOWER_DIAL_OCCUPANCY 8. UPPER_HOSPITAL_OCCUPANCY 8. UPPER_ICU_OCCUPANCY 8. UPPER_VENT_OCCUPANCY 8. UPPER_ECMO_OCCUPANCY 8. UPPER_DIAL_OCCUPANCY 8. SocialDistancing 8. BETA 8. RT 8. EventY_Multiplier 8.;
    run;
  %end;
%mend; %bafCheckoutputs;
%bafheader;
    %bafOutDataset(ds_seir, work, ds_seir, h54skeys=nokeys);
    %bafOutDataset(ds_sir, work, ds_sir, h54skeys=nokeys);
    %bafOutDataset(tmodel_seir, work, tmodel_seir, h54skeys=nokeys);
    %bafOutDataset(tmodel_seir_fit_i, work, tmodel_seir_fit_i, h54skeys=nokeys);
    %bafOutDataset(tmodel_sir, work, tmodel_sir, h54skeys=nokeys);
%bafFooter;