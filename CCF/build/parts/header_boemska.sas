/*  User Interface Switches
  - BATCH: Default mode 
  - UI: Used when using SAS Visual Analytics
  - BOEMSKA: Used when using the Boemska App 
*/
    %bafGetDatasets; /* get all input tables */
    resetline; /* for error reconciliation */

    %LET ScenarioSource = BOEMSKA;