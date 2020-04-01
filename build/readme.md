# Build Code For Different Users Bases
The build.py file in the folder will build code for different user bases.  The public version is created in the /public folder and the CCF version is created in the /ccf folder.  The public version is also copied to the main repository folder.

## /build folder
The build.py file uses python to construct .SAS files for different users bases.  The build tree looks like:
- orchestrate.sas - build macro %EasyRun
    - IMPORT: ccf_pre.sas
    - IMPORT: scenario_setup.sas
        - IMPORT: parameters.sas
    - IMPORT: model * .sas
        - IMPORT: postprocess.sas
        - IMPORT: sim_model * .sas (in development)
    - IMPORT: data_dictionary.sas
- driver.sas - call macro %EasyRun
    - IMPORT: header.sas
    - IMPORT: orchestrate.sas
    - IMPORT: CAS_post.sas

### Import Types
- X_IMPORT: import for the CCF and Public versions of the code
- P_IMPORT: import for the public version of the code
- C_IMPORT: import for the CCF version of the code
- T_IMPORT: import for the test version of the code - used to try new features before making available to users (public or ccf)

## Notes on development
Note: CCF only version needed - limited models, some pre/post steps
Note: CAS_post can be expanded to do per run append to both physical and CAS tables rather than replace at end

# branch=Central-Post-Processing (done and pulled):
- [x] Move DINIT table from parameters.sas to model_proctmodel_*.sas files
- [x] Add time change points for social distancing to TMODEL/Model approaches
- [x] Consolidate the post-fitting datastep from all model approaches into postprocess.sas.  The steps still show up in each model approach in the public code but it is managed in a central location: postprocess.sas.
- [x] flag columns in SCENARIOS that are input parameters of %EasyRun - introduced column STAGE with values INPUT (variables coming into macro) and MODEL (variables available at time Models execute)

# Being addressed currently
- [x] Create a data dictionary for the Columns in MODEL_FINAL and SCENARIOS.  Using data_dictionary.sas to create labels for each columns of the two output datasets.
- [x] Add macro input variable descriptions as comment below the macro call
- [ ] Add beta decay parameter to TMODEL/Model approaches - It is in the DS approaches but set to 0 currently
- [ ] introduce stochastic approach to model_datastep_*.sas approaches and use to create bounds for each output parameters - use in postprosessing
    - [ ] introduce stochastic approach to model_proctmodel_*.sas approaches and use to create bounds for output parameters - use in postprocessing



