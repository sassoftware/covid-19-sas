# Build Code For Different Users Bases
The build.py file in the folder will build code for different user bases.  The public version is created in the /public folder and the CCF version is created in the /ccf folder.  The public version is also copied to the main repository folder.

## /build folder
- orchestrate.sas - build macro %EasyRun
    - IMPORT: ccf_pre
    - IMPORT: parameters.sas
    - IMPORT: scenario_setup.sas
    - IMPORT: model * .sas
        - IMPORT: postprocess.sas (future step)
- driver.sas - call macro %EasyRun
    - IMPORT: header.sas
    - IMPORT: orchestrate.sas
    - IMPORT: CAS_post.sas

# Import Types
- X_IMPORT: import for the CCF and Public versions of the code
- P_IMPORT: import for the public version of the code
- C_IMPORT: import for the CCF version of the code

## Notes on development
Note: CCF only version needed - limited models, some pre/post steps
Note: CAS_post can be expanded to do per run append to both physical and CAS tables rather than replace at end



