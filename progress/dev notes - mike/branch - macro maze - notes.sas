NOTES ON TRACING VARIBLES BEFORE CHANGE:

Can’t make a masterpiece if you don’t make a mess….

GOALS
    - Get this code on a public site dynamically running scenarios
    - User to trust and ramp up on the code from GitHub
    - We have worked with users and seen the first questions people have are
        - what is it doing
        - how to I adapt it to my situation

Branch: Macro Maze (move this to readme.md under /build) DONE
    - [X] Trace Macro Variables from input to model
    - [X] Remove renaming and duplication
    - [X] Move hardcoded macro variables to macro keyword parameters
        - [X] Edit the creation of STORE.SCENARIOS to account for new position of parameter creation
        - [X] Add new variables to STORE.INPUTS with labels
    - [X] Move calculations near models for ease of review
        - [X] copy to model as a comment using Build.py
    - [X] Tidy the model specifications
        - [X] make equations easy to read and use parentheses 
    - [X] update &DAY_ZERO - input format changed to match other input dates, usage changed to reflex this in TMODEL models and post processing.sas
    - [X] Plots = yes or YES - not case sensitive
        - [X] do not include plots variable in scenario evaluation.  If the scenario was run before with a different plots= value then it is not a new scenario.
    - [X] update readme.md in main repo
          - [X] add Markdown table to readme.md with all inputs described
    - [X] update readme.md in /build
    - [X] notes in code near %EasyRun calls and the run_scenarios.csv input to point out keyword parameters are available and need adjustment for populations
    - [X] PROC COMPARE on STORE.MODEL_FINAL from master branch and macro-maze branch

COMMIT 1: Macro Variable Remap
- carried all macro varibles that were hardcoded to the %EasyRun macro as keyword variables with default values
- removed macro variable renaming and preserved the names on %EasyRun macro
- Collapsed all calculated macro variables to single variables
- put a commented out copy of the calcualted macro variable sat the top of each model method for make model easier to trace and read
- Update STORE.INPUTS and STORE.SCENARIOS to reflect these changes
- NO IMPACT on STORE.MODEL_FINAL

COMMIT 2: Cleanup
- Updated creation of STORE.SCENARIOS and STORE.INPUTS to account for new macro variable layout
- Updated labels in STORE.INPUTS for new keyword macro variable additions
- Included comments at the top of each model section with a copy of the calcualted macro variable to aide in model review
- Tidyed up the model specifications to account for new varaible layout
- made the plots= input variable more flexible: case does not matter
    - remove plots= input varaible from the scenario evaluation to prevent creating a new scenario due to plots= value changing
- added notes near example %EasyRun calls and the input file run_scenarios.csv to point out new keyword parameters available for more flexibility to users scenario 

COMMIT 3: Documentation of Inputs
- updated readme.md in main repository
- added a table of inputs with descriptions in readme.md in main repository 

COMMIT 4: Verification of Results and Finalize Documentation
- updated reame.md in /build with release notes for this branch: macro-maze
- Use PROC COMPARE to compare STORE.MODEL_FINAL from master branch and macro-maze branch to ensure all results are identical after these changes 
    - code: proc compare data=temp.model_final_old compare=temp.model_final_new criterion=.001; run; quit;
    - results: Number of Observations with Some Compared Variables Unequal: 0. 


harcoded value to add to easyrun:
	used in models:
		&N_DAYS=365
		&DiagnosedRate=1.0 (this replaces &DIAGNOSED_RATE hardcoded below)
		&E=0
		&SIGMA=0.90
		&DAY_ZERO='13MAR2020'd
		&BETA_DECAY = 0.00
	used in postprocessing:
		&ECMO_RATE=0.03
		&DIAL_RATE=0.05
		&HOSP_LOS=7
		&ICU_LOS=9
		&VENT_LOS=10
		&ECMO_LOS=6
		&DIAL_LOS=11


Example macro call:
%EASYRUN inputs:
    scenario=Scenario_DrS_00_20_run_1,
    IncubationPeriod=0,
    InitRecovered=0,
    RecoveryDays=14,
    doublingtime=5,
    KnownAdmits=10,
    KnownCOVID=46,
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
    FatalityRate=0,
    plots=YES	

Adjustments in parameters.sas:

Postprocessing.sas uses:
    - &IncubationPeriod (%EasyRun)
    - &MARKET_SHARE (parameters.sas)
        - &MarketSharePercent (%EasyRun)
    - &Fatality_rate (parameters.sas)
        - &FatalityRate (%EasyRun)
    - &HOSP_RATE (parameters.sas)
        - %SYSEVALF(&ADMISSION_RATE*&DIAGNOSED_RATE)
            - &ADMISSION_RATE (parameters.sas)
                - &Admission_Rate (%EasyRun)
            - &DIAGNOSED_RATE (parameters.sas)
                - hardcoded
    - &ICU_RATE (parameters.sas)
        - %SYSEVALF(&ICUPercent.*&DIAGNOSED_RATE)
            - &ICUPercent (%EasyRun)
            - &DIAGNOSED_RATE (parameters.sas)
                - hardcoded
    - &VENT_RATE (parameters.sas)
        - %SYSEVALF(&VentPErcent.*&DIAGNOSED_RATE)
            - &VentPErcent (%EasyRun)
            - &DIAGNOSED_RATE (parameters.sas)
                - hardcoded
    - &ECMO_RATE (parameters.sas)
        - hardcoded
    - &DIAL_RATE (parameters.sas)
        - hardcoded
    - &HOSP_LOS (parameters.sas)
        - hardcoded
    - &ICU_LOS (parameters.sas)
        - hardcoded
    - &VENT_LOS (parameters.sas)
        - hardcoded
    - &ECMO_LOS (parameters.sas)
        - hardcoded
    - &DIAL_LOS (parameters.sas)
        - hardcoded
    - %DAYS_TO_HOSP (parameters.sas)
        - &IncubationPeriod (%EasyRun)

DS SIR uses:
    - &Scenario (%EasyRun)
    - &N_DAYS (parameters.sas)
        - hardcoded
    - &S (parameters.sas)
        - &S_DEFAULT (parameters.sas)
            - &Population (%EasyRun)
    - &I (parameters.sas)
        - %SYSEVALF(&INITIAL_INFECTIONS / &DETECTION_PROB) (parameters.sas)
            - &INITIAL_INFECTIONS (parameters.sas)
                - &KNOWN_INFECTIONS (parameters.sas)
                    - &KnownCOVID. (%EasyRun)
            - &DETECTION_PROB (parameters.sas)
                - %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS) (parameters.sas)
                    - &INITIAL_INFECTIONS (parameters.sas)
                        - &KNOWN_INFECTIONS (parameters.sas)
                            - &KnownCOVID. (%EasyRun)
                    - &TOTAL_INFECTIONS (parameters.sas)
                        - %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE)
                            - &CURRENT_HOSP (parameters.sas)
                                - &KNOWN_CASES (parameters.sas)
                                    - &KnownAdmits (%EasyRun)
                            - &MARKET_SHARE (parameters.sas)
                                - &MarketSharePercent. (%EasyRun)
                            - &HOSP_RATE (parameters.sas)
                                - %SYSEVALF(&ADMISSION_RATE*&DIAGNOSED_RATE)
                                    - &ADMISSION_RATE (parameters.sas)
                                        - &Admission_Rate (%EasyRun)
                                    - &DIAGNOSED_RATE (parameters.sas)
                                        - hardcoded
    - &R (parameters.sas)
        - &InitRecovered (%EasyRun)
    - &DIAGNOSED_RATE (parameters.sas)
        - hardcoded
    - &BETA (parameters.sas)
        - %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE)) (parameters.sas)
            - &INTRINSIC_GROWTH_RATE (parameters.sas)
                - %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1) (parameters.sas)
                    - &DOUBLING_TIME (parameters.sas)
                        - &doublingtime (%EasyRun)
            - &GAMMA (parameters.sas)
                - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                    - &RECOVERY_DAYS (parameters.sas)
                        - &RecoveryDays (%EasyRun)
            - &S (parameters.sas)
                - &S_DEFAULT (parameters.sas)
                    - &Population (%EasyRun)
            - &RELATIVE_CONTACT_RATE (parameters.sas)
                - &SocialDistancing (%EasyRun)
    - &GAMMA (parameters.sas)
        - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
            - &RECOVERY_DAYS (parameters.sas)
                - &RecoveryDays (%EasyRun)
    - &ISO_Change_Date (parameters.sas)
        - &ISOChangeDate (&EasyRun)
    - &BETA_Change (parameters.sas)
        - %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change)) (parameters.sas)
            - &INTRINSIC_GROWTH_RATE (parameters.sas)
                - %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1) (parameters.sas)
                    - &DOUBLING_TIME (parameters.sas)
                        - &doublingtime (%EasyRun)
            - &S (parameters.sas)
                - &S_DEFAULT (parameters.sas)
                    - &Population (%EasyRun)
            - &RELATIVE_CONTACT_RATE_Change (parameters.sas)
                - &SocialDistancingChange (%EasyRun)
    - &ISO_Change_Date_Two (parameters.sas)
        - &ISOChangeDateTwo (%EasyRun)
    - &BETA_CHANGE_Two (parameters.sas)
        - %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_Two)) (parameters.sas)
            - &INTRINSIC_GROWTH_RATE (parameters.sas)
                - %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1) (parameters.sas)
                    - &DOUBLING_TIME (parameters.sas)
                        - &doublingtime (%EasyRun)
            - &GAMMA (parameters.sas)
                - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                    - &RECOVERY_DAYS (parameters.sas)
                        - &RecoveryDays (%EasyRun)
            - &S (parameters.sas)
                - &S_DEFAULT (parameters.sas)
                    - &Population (%EasyRun)
            - &RELATIVE_CONTACT_RATE_Change_Two (parameters.sas)
                - &SocialDistancingChangeTwo (%EasyRun)
    - &BETA_DECAY (parameters.sas)
        - hardcoded

DS SEIR also Uses:
    - &E (parameters.sas)
        - hardcoded
    - &DAY_ZERO (parameters.sas)
        - hardcoded
    - &R_T (parameters.sas)
        - %SYSEVALF(&BETA / &GAMMA * &S) (parameters.sas)
            - &BETA (parameters.sas)
                - %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE)) (parameters.sas)
                    - &INTRINSIC_GROWTH_RATE (parameters.sas)
                        - %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1) (parameters.sas)
                            - &DOUBLING_TIME (parameters.sas)
                                - &doublingtime (%EasyRun)
                    - &GAMMA (parameters.sas)
                        - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                            - &RECOVERY_DAYS (parameters.sas)
                                - &RecoveryDays (%EasyRun)
                    - &S (parameters.sas)
                        - &S_DEFAULT (parameters.sas)
                            - &Population (%EasyRun)
                    - &RELATIVE_CONTACT_RATE (parameters.sas)
                        - &SocialDistancing (%EasyRun)
            - &GAMMA (parameters.sas)
                - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                    - &RECOVERY_DAYS (parameters.sas)
                        - &RecoveryDays (%EasyRun)
            - &S (parameters.sas)
                - &S_DEFAULT (parameters.sas)
                    - &Population (%EasyRun)
    - &R_T_Change (parameters.sas)
        - %SYSEVALF(&BETA_Change / &GAMMA * &S) (parameters.sas)
            - &BETA_Change (parameters.sas)
                - %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change)) (parameters.sas)
                    - &INTRINSIC_GROWTH_RATE (parameters.sas)
                        - %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1) (parameters.sas)
                            - &DOUBLING_TIME (parameters.sas)
                                - &doublingtime (%EasyRun)
                    - &S (parameters.sas)
                        - &S_DEFAULT (parameters.sas)
                            - &Population (%EasyRun)
                    - &RELATIVE_CONTACT_RATE_Change (parameters.sas)
                        - &SocialDistancing (%EasyRun)
            - &GAMMA (parameters.sas)
                - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                    - &RECOVERY_DAYS (parameters.sas)
                        - &RecoveryDays (%EasyRun)
            - &S (parameters.sas)
                - &S_DEFAULT (parameters.sas)
                    - &Population (%EasyRun)
    - &R_T_Change_Two (parameters.sas)
        - %SYSEVALF(&BETA_Change_Two / &GAMMA * &S) (parameters.sas)
            - &BETA_Change_Two
                - %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_Two)) (parameters.sas)
                    - &INTRINSIC_GROWTH_RATE (parameters.sas)
                        - %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1) (parameters.sas)
                            - &DOUBLING_TIME (parameters.sas)
                                - &doublingtime (%EasyRun)
                    - &GAMMA (parameters.sas)
                        - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                            - &RECOVERY_DAYS (parameters.sas)
                                - &RecoveryDays (%EasyRun)
                    - &S (parameters.sas)
                        - &S_DEFAULT (parameters.sas)
                            - &Population (%EasyRun)
                    - &RELATIVE_CONTACT_RATE_Change_Two (parameters.sas)
                        - &SocialDistancingChangeTwo (%EasyRun)
            - &GAMMA (parameters.sas)
                - %SYSEVALF(1/&RECOVERY_DAYS) (parameters.sas)
                    - &RECOVERY_DAYS (parameters.sas)
                        - &RecoveryDays (%EasyRun)
            - &S (parameters.sas)
                - &S_DEFAULT (parameters.sas)
                    - &Population (%EasyRun)
    - &SIGMA (parameters.sas)
        - hardcoded


NOTES ON THE PROCESS of creating new parameters.sas:

/* some of the CCF calcualtion have compound expressions without parentheses - check on the order of operations */
/* Order of operations information: basically - * and / are handled left-to-right after parentheses
	https://documentation.sas.com/?docsetId=lrcon&docsetTarget=p00iah2thp63bmn1lt20esag14lh.htm&docsetVersion=9.4&locale=en#n112j4kvyu5tw8n10tcc8qey5xqu
*/
%LET a=16; %LET b=8; %LET c=2;
%LET try1 = %SYSEVALF(16 / 8 / 2);
%LET try2 = %SYSEVALF(&a. / &b. / &c.);
%PUT "&try1.  and  &try2.";
/* results is: 1 for both */


PRE CHANGE parameters.sas:
			/* Translate CCF code macro (%EASYRUN) inputs to variables used in this code 
				these variables come in from the macro call above
				this section show the name mapping to how they are used in this code
			*/
			/*%LET scenario=BASE_Scenario_one;*/
			/*%LET IncubationPeriod=0;*/ /* Used with this name */
			/*%LET InitRecovered=0;*/ /* R */
			/*%LET RecoveryDays=14;*/ /* RECOVERY_DAYS */
			/*%LET doublingtime=5;*/ /* DOUBLING_TIME */
			/*%LET KnownAdmits=10;*/ /* KNOWN_CASES */
			/*%LET KnownCOVID=46;*/ /* KNOWN_INFECTIONS */
			/*%LET Population=4390484;*/ /* S_DEFAULT */
			/*%LET SocialDistancing=0.0;*/ /* RELATIVE_CONTACT_RATE */
			/*%LET MarketSharePercent=0.29;*/ /* MARKET_SHARE */
			/*%LET Admission_Rate=0.075;*/ /* same name below */
			/*%LET ICUPercent=0.25;*/ /* used in ICU_RATE */
			/*%LET VentPErcent=0.125;*/ /* used in VENT_RATE */
			/*%LET FatalityRate=;*/ /* Fatality_rate */


			/* Dynamic Variables across Scenario Runs */
			/*Number of people in region of interest, assumed to be well mixed and independent of other populations*/
			%LET S_DEFAULT = &Population.;
			/*Number of known COVID-19 patients in the region at Day 0, not used in S(E)IR calculations*/
			%LET KNOWN_INFECTIONS = &KnownCOVID.;
			/*Number of COVID-19 patients at hospital of interest at Day 0, used to calculate the assumed number of Day 0 Infections*/
			%LET KNOWN_CASES = &KnownAdmits.;
			/*Doubling time before social distancing (days)*/
			%LET DOUBLING_TIME = &doublingtime.;
			/*Initial Number of Exposed (infected but not yet infectious)*/
			%LET E = 0;
			/*Initial number of Recovered patients, assumed to have immunity to future infection*/
			%LET R = &InitRecovered.;
			/*Number of days a patient is considered infectious (the amount of time it takes to recover or die)*/
			%LET RECOVERY_DAYS = &RecoveryDays.;
			/*Baseline Social distancing (% reduction in social contact)*/
			%LET RELATIVE_CONTACT_RATE = &SocialDistancing.;
			/*Anticipated share (%) of hospitalized COVID-19 patients in region that will be admitted to hospital of interest*/
			%LET MARKET_SHARE = &MarketSharePercent.;
			/*Percentage of Infected patients in the region who will be hospitalized*/
			%LET ADMISSION_RATE= &Admission_Rate.;
			/*factor to adjust %admission to make sense multiplied by Total I*/
			%LET DIAGNOSED_RATE=1.0; 
			/*Percentage of hospitalized patients who will require ICU*/
			%LET ICU_RATE = %SYSEVALF(&ICUPercent.*&DIAGNOSED_RATE);
			/*Percentage of hospitalized patients who will require Ventilators*/
			%LET VENT_RATE = %SYSEVALF(&VentPErcent.*&DIAGNOSED_RATE);
			/*Percentage of hospitalized patients who will die*/
			%Let Fatality_rate = &fatalityrate;
			/*Number of days by which to offset hospitalization from infection, effectively shifting utilization curves to the right*/
			%LET DAYS_TO_HOSP = &IncubationPeriod.;
			/*Date of first change from baseline in social distancing parameter*/
			%Let ISO_Change_Date = &ISOChangeDate.;
			/*Second value of social distancing (% reduction in social contact compared to normal activity)*/
			%LET RELATIVE_CONTACT_RATE_Change = &SocialDistancingChange.;
			/*Date of second change in social distancing parameter*/
			%Let ISO_Change_Date_Two = &ISOChangeDateTwo.;
			/*Third value of social distancing (% reduction in social contact compared to normal activity)*/
			%LET RELATIVE_CONTACT_RATE_Change_Two = &SocialDistancingChangeTwo.;


			/*Parameters assumed to be constant across scenarios*/
			/*Currently Hospitalized COVID-19 Patients*/
			%LET CURRENT_HOSP = &KNOWN_CASES;
			/*Hospitalization %(total infections)*/
			%LET HOSP_RATE = %SYSEVALF(&ADMISSION_RATE*&DIAGNOSED_RATE);
			/*Average Hospital Length of Stay*/
			%LET HOSP_LOS = 7;
			/*Average ICU Length of Stay*/
			%LET ICU_LOS = 9;
			/*Average Vent Length of Stay*/
			%LET VENT_LOS = 10;
			/*default percent of total admissions that need ECMO*/
			%LET ECMO_RATE=0.03; 
			%LET ECMO_LOS=6;
			/*default percent of admissions that need Dialysis*/
			%LET DIAL_RATE=0.05;
			%LET DIAL_LOS=11;
			/*rate of latent individuals Exposed transported to the infectious stage each time period*/
			%LET SIGMA = 0.90;
			/*Days to project*/
			%LET N_DAYS = 365;
			/*Factor (%) used for daily reduction of Beta*/
			%LET BETA_DECAY = 0.00;
			/*Date of first COVID-19 Case*/
			%LET DAY_ZERO = 13MAR2020;


			/*Parameters derived from other inputs*/
			/*Regional Population*/
			%LET S = &S_DEFAULT;
			/*Currently Known Regional Infections (only used to compute detection rate - does not change projections*/
			%LET INITIAL_INFECTIONS = &KNOWN_INFECTIONS;
			/*Extrapolated number of Infections in the Region at Day 0*/
			%LET TOTAL_INFECTIONS = %SYSEVALF(&CURRENT_HOSP / &MARKET_SHARE / &HOSP_RATE);
			%LET DETECTION_PROB = %SYSEVALF(&INITIAL_INFECTIONS / &TOTAL_INFECTIONS);
			/*Number of Infections in the Region at Day 0 - Equal to TOTAL_INFECTIONS*/
			%LET I = %SYSEVALF(&INITIAL_INFECTIONS / &DETECTION_PROB);
			%LET INTRINSIC_GROWTH_RATE = %SYSEVALF(2 ** (1 / &DOUBLING_TIME) - 1);
			%LET GAMMA = %SYSEVALF(1/&RECOVERY_DAYS);
			%LET BETA = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE));
			%LET BETA_Change = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change));
			%LET BETA_Change_Two = %SYSEVALF((&INTRINSIC_GROWTH_RATE + &GAMMA) / &S * (1-&RELATIVE_CONTACT_RATE_Change_Two));
			/* R_T is R_0 after distancing */
			%LET R_T = %SYSEVALF(&BETA / &GAMMA * &S);
			%LET R_T_Change = %SYSEVALF(&BETA_Change / &GAMMA * &S);
			%LET R_T_Change_Two = %SYSEVALF(&BETA_Change_Two / &GAMMA * &S);
			%LET R_NAUGHT = %SYSEVALF(&R_T / (1-&RELATIVE_CONTACT_RATE));
			/*doubling time after distancing*/
			%LET DOUBLING_TIME_T = %SYSEVALF(1/%SYSFUNC(LOG2(&BETA*&S - &GAMMA + 1)));
