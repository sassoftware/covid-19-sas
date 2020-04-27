/* User Interface Switches - these are used if you using the code within SAS Visual Analytics UI */
    %LET ScenarioSource = UI;
    %LET CASSource = casuser; 
    /* NOTES: 
        - &ScenarioSource = UI overrides the behavior of the %EasyRun macro
        - &CASSource is the location of the results tables you want the macro to read from in determining if a scenario has been run before: can be a libname or caslib
        - An active CAS session and CASLIB are needed for &CASSource to be available to the %EasyRun macro if you set &CASSource to a caslib
        - At the end of execution all the output tables holding just the current scenario will be in WORK
        - If &ScenarioExist = 0 then the files in WORK contain a new scenario
            - Else, %ScenarioExist > 0, the files in WORK contain a recalled, previously run scenario identified by the columns ScenarioIndex, ScenarioSource, ScenarioUser, ScenarionNameUnique
                - The column Scenario will contain the name entered in the UI as the name is not used in matching previous scenarios
                - these global macro variables will have recalled scenario information in this case (empty when &ScenarioExist=0): &ScenerioIndex_Recall, &ScenarioUser_Recall, &Scenario_Source_Recall, &ScenarioNameUnique_Recall
        - The code assumes that the files it is creating are not in the current SAS workspace.  If there are files with the same name then unexpected behavior will cause issues: appending new data to existing data without warning.
    */