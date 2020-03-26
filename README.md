# covid
Covid tool development

An open collaboration between the Cleveland Clinic and SAS Institute.

# Notes
- The current locked version of the project is in COVID_19.sas.
- Progress towards the next locked version is in the /progress folder

# What This Code Does
This code takes a set of input parameters and uses them in infectious disease models (SIR & SEIR).  Model output is used to calculate useful metrics for each day of an epidemic, such as the number of hospitalizations.  

# Getting Started
- Download COVID_19.sas to your SAS environment
- Edit line 4 to a local directory you want to save datasets with model output and scenario information to
- If you do not have SAS/ETS then edit line 15 to 'NO'
    - This option causes only the SIR model to run with a SAS Data Step version
- If you have the latest analytical release of SAS, 15.1, then set line 16 to YES
    - This option swaps out PROC MODEL for PROC TMODEL
- Make calls to the macro %EasyRun.  Examples scenarios are at the end of the file.
    - The last parameter for the macro calls is plots=YES.  This triggers basic SGPLOT output to visually review. 
- All model output for each call to %EasyRun saves in the dataset STORE.MODEL_FINAL
- All of the parameters that lead to the results in STORE.MODEL_FINAL save in STORE.SCENARIOS.  The variable SCENARIOINDEX links these two files.

