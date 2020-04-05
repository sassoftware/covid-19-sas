# Build Code For Different Users Bases
The build.py file in the folder will build code for different user bases.  The public version is created in the /public folder and the CCF version is created in the /ccf folder.  The public version is also copied to the main repository folder.

## /build folder
The build.py file uses python to construct .SAS files for different users bases.  The parts used for building are included in the /parts folder.  The build tree looks like:
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
The build process has logic for the following types of imports.  
- X_IMPORT: import for the CCF and Public versions of the code
- P_IMPORT: import for the public version of the code
- C_IMPORT: import for the CCF version of the code
- T_IMPORT: import for the test version of the code - used to try new features before making available to users (public or ccf)
The logic setup recursively calls parts while honoring a hierarchy of inclusion: 
- Once a C_IMPORT part is called, all further import types are only written to C_IMPORT destinations
- Once a P_IMPORT part is called, all further import types are only written to P_IMPORT and X_IMPORT destinations
- Once a T_IMPORT part is called, all further import type sare only written to T_IMPORT destinations

# branch=Central-Post-Processing (done and pulled):
- [X] Move DINIT table from parameters.sas to model_proctmodel_*.sas files
- [X] Add time change points for social distancing to TMODEL/Model approaches
- [X] Consolidate the post-fitting datastep from all model approaches into postprocess.sas.  The steps still show up in each model approach in the public code but it is managed in a central location: postprocess.sas.
- [X] flag columns in SCENARIOS that are input parameters of %EasyRun - introduced column STAGE with values INPUT (variables coming into macro) and MODEL (variables available at time Models execute)

# branch=Macro-Maze (done and pulled)


# Being addressed currently
- [X] Create a data dictionary for the Columns in MODEL_FINAL and SCENARIOS.  Using data_dictionary.sas to create labels for each columns of the two output datasets.
- [X] Add macro input variable descriptions as comment below the macro call
- [ ] Add beta decay parameter to TMODEL/Model approaches - It is in the DS approaches but set to 0 currently
- [ ] introduce stochastic approach to model_proctmodel_*.sas approaches and use to create bounds for output parameters - use in postprocessing
- [ ] Fix macro variable formating
    - [ ] underscore or camelCase



