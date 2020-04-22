/* SAS Program COVID_19 
Cleveland Clinic and SAS Collaboarion

These models are only as good as their inputs. 
Input values for this type of model are very dynamic and may need to be evaluated across wide ranges and reevaluated as the epidemic progresses.  
This work is currently defaulting to values for the population studied in the Cleveland Clinic and SAS collaboration.
You need to evaluate each parameter for your population of interest.
*/

P_IMPORT: header_store.sas
C_IMPORT: header_store.sas
D_IMPORT: header_store.sas
T_IMPORT: header_store.sas
U_IMPORT: header_store.sas


/* Depending on which SAS products you have and which releases you have these options will turn components of this code on/off */
    %LET HAVE_SASETS = YES; /* YES implies you have SAS/ETS software, this enable the PROC MODEL methods in this code.  Without this the Data Step SIR model still runs */
    %LET HAVE_V151 = NO; /* YES implies you have products verison 15.1 (latest) and switches PROC MODEL to PROC TMODEL for faster execution */

P_IMPORT: header_batch.sas
C_IMPORT: header_batch.sas
D_IMPORT: header_batch.sas
T_IMPORT: header_batch.sas
U_IMPORT: header_ui.sas
V_IMPORT: header_ui_public.sas