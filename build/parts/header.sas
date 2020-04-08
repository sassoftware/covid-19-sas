/* SAS Program COVID_19 
Cleveland Clinic and SAS Collaboarion

These models are only as good as their inputs. Input values for this type of model are very dynamic and may need to be evaluated across wide ranges and reevaluated as the epidemic progresses.  This work is currently defaulting to values for the population studied in the Cleveland Clinic and SAS collaboration.  You need to evaluate each parameter for your population of interest.

SAS and Cleveland Clinic are not responsible for any misuse of these techniques.
*/

/* directory path for files: COVID_19.sas (this file), libname store */
%let homedir = /Local_Files/covid;

/* the storage location for the MODEL_FINAL table and the SCENARIOS table */
libname store "&homedir.";

/* Depending on which SAS products you have and which releases you have these options will turn components of this code on/off */
%LET HAVE_SASETS = YES; /* YES implies you have SAS/ETS software, this enable the PROC MODEL methods in this code.  Without this the Data Step SIR model still runs */
%LET HAVE_V151 = NO; /* YES implies you have products verison 15.1 (latest) and switches PROC MODEL to PROC TMODEL for faster execution */
%LET CAS_LOAD = NO; /* YES implies you have SAS Viya and want to keep the output tables of this process managed in a CAS library for use in SAS Viya products (like Visual Analytics for reporting) */
