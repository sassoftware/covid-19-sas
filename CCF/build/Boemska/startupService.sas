%bafGetDatasets; /* get all input tables */
resetline; /* for error reconciliation */

/*** START USER WRITTEN CODE ***/

data dataLabels;
    Scenario                    =   "Scenario Name to be stored as a character variable, combined with automatically-generated ScenarioIndex to create a unique ID";
    IncubationPeriod            =   "Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right";
    InitRecovered               =   "Initial number of Recovered patients, assumed to have immunity to future infection";
    RecoveryDays                =   "Number of days a patient is considered infectious (the amount of time it takes to recover or die)";
    doublingtime                =   "Baseline Infection Doubling Time without social distancing";
    Population                  =   "Number of people in region of interest, assumed to be well mixed and independent of other populations";
    KnownAdmits                 =   "Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections";
    SocialDistancing            =   "Baseline Social distancing (% reduction in social contact compared to normal activity)";
    ISOChangeDate               =   "Date of first change from baseline in social distancing parameter";
    SocialDistancingChange      =   "Second value of social distancing (% reduction in social contact compared to normal activity)";
    ISOChangeDateTwo            =   "Date of second change in social distancing parameter";
    SocialDistancingChangeTwo   =   "Third value of social distancing (% reduction in social contact compared to normal activity)";
    ISOChangeDate3              =   "Date of third change in social distancing parameter";
    SocialDistancingChange3     =   "Fourth value of social distancing (% reduction in social contact compared to normal activity)";
    ISOChangeDate4              =   "Date of fourth change in social distancing parameter";
    SocialDistancingChange4     =   "Fifth value of social distancing (% reduction in social contact compared to normal activity)";
    MarketSharePercent          =   "Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest";
    Admission_Rate              =   "Percentage of Infected patients in the region who will be hospitalized";
    ICUPercent                  =   "Percentage of hospitalized patients who will require ICU";
    VentPErcent                 =   "Percentage of hospitalized patients who will require Ventilators";
    FatalityRate                =   "Percentage of hospitalized patients who will die";
    plots                       =   "YES/NO display plots in output";
    N_DAYS                      =   "Number of days to project";
    DiagnosedRate               =   "Factor to adjust admission_rate contributing to via MarketSharePercent I (see calculation for I)";
    E                           =   "Initial Number of Exposed (infected but not yet infectious)";
    SIGMA                       =   "Rate of latent individuals Exposed and transported to the infectious stage during each time period";
    DAY_ZERO                    =   "Date of the first COVID-19 case";
    BETA_DECAY                  =   "Factor (%) used for daily reduction of Beta";
    ECMO_RATE                   =   "Default percent of total admissions that need ECMO";
    DIAL_RATE                   =   "Default percent of admissions that need Dialysis";
    HOSP_LOS                    =   "Average Hospital Length of Stay";
    ICU_LOS                     =   "Average ICU Length of Stay";
    VENT_LOS                    =   "Average Vent Length of Stay";
    ECMO_LOS                    =   "Average ECMO Length of Stay";
    DIAL_LOS                    =   "Average DIAL Length of Stay";
  run;


/*** END USER WRITTEN CODE ***/
* if output data does not exist yet use sample data ;
%macro bafCheckoutputs;
* this if sysfunc exist happens for each outtable ;

* --out table 0-- ;
  %if %sysfunc(exist(dataLabels)) = 0 %then %do;
    data dataLabels;
  length Scenario $80. IncubationPeriod $80. InitRecovered $80. RecoveryDays $80. doublingtime $80. Population $80. KnownAdmits $80. SocialDistancing $80. ISOChangeDate $80. SocialDistancingChange $80. ISOChangeDateTwo $80. SocialDistancingChangeTwo $80. ISOChangeDate3 $80. SocialDistancingChange3 $80. ISOChangeDate4 $80. SocialDistancingChange4 $80. MarketSharePercent $80. Admission_Rate $80. ICUPercent $80. VentPErcent $80. FatalityRate $80. plots $80. N_DAYS $80. DiagnosedRate $80. E $80. SIGMA $80. DAY_ZERO $80. BETA_DECAY $80. ECMO_RATE $80. DIAL_RATE $80. HOSP_LOS $80. ICU_LOS $80. VENT_LOS $80. ECMO_LOS $80. DIAL_LOS $80.;
    run;
  %end;
%mend; 

%bafCheckoutputs;
%bafheader;
    %bafOutDataset(dataLabels, work, dataLabels);
%bafFooter;