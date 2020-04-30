							%IF &HAVE_SASETS = YES AND %SYMEXIST(ISOChangeDate1) %THEN %DO;
								MODIFY FIT_PRED;
								LABEL
									ScenarioIndex = "Scenario ID: Order"
									ScenarioSource = "Scenario ID: Source (BATCH or UI)"
									ScenarioUser = "Scenario ID: User who created Scenario"
									ScenarioNameUnique = "Unique Scenario Name"
									;
								MODIFY FIT_PARMS;
								LABEL
									ScenarioIndex = "Scenario ID: Order"
									ScenarioSource = "Scenario ID: Source (BATCH or UI)"
									ScenarioUser = "Scenario ID: User who created Scenario"
									ScenarioNameUnique = "Unique Scenario Name"
									;
							%END;