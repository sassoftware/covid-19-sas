# covid
Covid tool development

An open collaboration between the Cleveland Clinic and SAS Institute.

# Notes
- The current locked version of the project is in COVID_19.sas.
- Progress towards the next locked version is in the /progress folder
- the COVID_19.sas file is built from modular parts in the /build/public folder and then copied here

# What This Code Does
This code takes a set of input parameters and uses them in infectious disease models (SIR & SEIR).  Model output is used to calculate useful metrics for each day of an epidemic, such as the number of hospitalizations.  

# Getting Started
- Download COVID_19.sas to your SAS environment
    - Also download the run_scenario.csv file for an example submission file to run many scenarios in batch
- Edit line 10 to a local directory you want to save datasets with model output and scenario information to
- If you do not have SAS/ETS then edit line 16 to 'NO'
    - This option causes the SIR/SEIR models to run with a SAS Data Step version only
    - If you are unsure then you can run 'PROC PRODUCT_STATUS; run;' in SAS and view the log for this information
- If you have the latest analytical release of SAS, 15.1, then set line 17 to YES
    - This option swaps out PROC MODEL for PROC TMODEL
    - If you are unsure then you can run 'PROC PRODUCT_STATUS; run;' in SAS and view the log for this information
- Make calls to the macro %EasyRun.  Examples scenarios are at the end of the file.
    - The last parameter for the macro calls is plots=YES.  This triggers basic SGPLOT output to visually review.
- Submit many scenarios in batch by using an input file.  An example file, run_scenarios.csv is provided. Each row of this file will feed individual calls to the %EasyRun macro.
- All model output for each call to %EasyRun saves in the dataset STORE.MODEL_FINAL
- All of the parameters that lead to the results in STORE.MODEL_FINAL save in STORE.SCENARIOS.  The variable SCENARIOINDEX links these two files.

# Input & Output Definitions
- INPUT:
    - The description of the input parameters for the %EasyCall Macro follow the macro definition in COVID_19.sas around line 20
- OUTPUT:
    - The model dataset in STORE.MODEL_FINAL has descriptive labels for each column.  The labels can be found in the COVID_19.sas file around line 740 also.
    - The scenario parameters are stored in STORE.SCENARIOS which has labels for each column.  The labels can be found in the COVID_19.sas file around line 788 also.

# Important Note on Output Files
- STORE.MODEL_FINAL stores each scenario and each model type with 1 row per day. Make sure you are viewing the results for a single scenario and single model type by filter by the columns: 
    - ScenarioNameUnique
    - ModelType

# Notes on Model Types
This code computes SIR and SEIR models with different methods and different parameterizations, as described in the following. 

The output file, MODEL_FINAL, uses the column ModelType to differentiate output from each of the following setups:
- ModelType = 'DS - SIR'
    - Fits a SIR model with Data Step
    - Initial values of &SocialDistancing contribute to BETA and then &ISOChangeDate used to step Beta down using &SocialDistancingChange at the specified date.  Similarly, &ISOChangeDateTwo and &SocialDistancingChangeTwo are and additional step down.
    - An internal parameter, &BETA_DECAY, is used to adjust BETA each day.  It is currently set to 0.
- ModelType = 'DS - SEIR'
    - Fits an SEIR model with Data Step
    - Initial values of &SocialDistancing contribute to BETA and then &ISOChangeDate used to step Beta down using &SocialDistancingChange at the specified date.  Similarly, &ISOChangeDateTwo and &SocialDistancingChangeTwo are and additional step down.
    - An internal parameter, &BETA_DECAY, is used to adjust BETA each day.  It is currently set to 0.
- ModelType = 'TMODEL - SEIR'
    - Fits an SEIR model with PROC (T)MODEL 
    - The BETA parameter incorporates different R0 parameters for each phase as defined by: before &ISOChangeDate, starting on &ISOChangeDateTwo, the period between these two
- ModelType = 'TMODEL - SIR'
    - Fits an SEIR model with PROC (T)MODEL 
    - The BETA parameter incorporates different R0 parameters for each phase as defined by: before &ISOChangeDate, starting on &ISOChangeDateTwo, the period between these two
- ModelType = 'TMODEL - SEIR - OHIO FIT'
    - This is a prototype for using a data feed of daily case counts from a geographical region.  In this prototypes case it is a region of the state of Ohio in the United States.
    - Fits and SEIR model with PROC (T)MODEL 
    - Uses input data to fit cumulative cases by day
    - The fitted model is used to solve the specification of the SEIR model.  This does not yet incorporate a change in BETA due to changes in Social Distancing.

In the next few days, the model specification will be arranged into parts: the core model, specification of R0 over the time period, using a data feed as demonstrated in the prototype ModelType = 'TMODEL - SEIR - OHIO FIT.'

# Disclaimer
These models are only as good as their inputs. Input values for this type of model are very dynamic and may need to be evaluated across wide ranges and reevaluated as the epidemic progresses.  This work is currently defaulting to values for the population studied in the Cleveland Clinic and SAS collaboration.  You need to evaluate each parameter for your population of interest.

SAS and Cleveland Clinic are not responsible for any misuse of these techniques.
