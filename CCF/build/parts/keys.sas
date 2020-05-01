				FORMAT ScenarioName $50. ScenarioNameUnique $100. ScenarioSource $10. ScenarioUser $25.;
				ScenarioName="&Scenario.";
				ScenarioIndex=&ScenarioIndex.;
				ScenarioUser="&SYSUSERID.";
				ScenarioSource="&ScenarioSource.";
				ScenarioNameUnique=cats("&Scenario.",' (',ScenarioIndex,'-',"&SYSUSERID.",'-',"&ScenarioSource.",')');
