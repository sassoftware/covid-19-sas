DATA PARMS_TRANSP;
     FORMAT Scenario ScenarioName $30.;
     LABEL
           Scenario              = "Scenario"
           ScenarioIndex         = "Scenario Index"
           ScenarioName          = "Scenario Name"
           IncubationPeriod      = "Incubation Period"
           InitRecovered         = "Initial Recovered"
           RecoveryDays          = "Recovery Days"
           DoublingTime          = "Doubling Time (days)"
           KnownAdmits           = "Known Admits"
           KnownCOVID                 = "Known COVID"
           Population                 = "Population"
           SocialDistancing      = "Social Distancing"
           MarketSharePercent    = "Hospital Market Share (%)"
           AdmissionRate         = "Admission Rate (%)"
           ICUPercent                 = "ICU (% total infections)"
           VentPercent           = "Ventilated (% total infections)";
 
     Scenario = "&Scenario";
     ScenarioIndex = &ScenarioIndex;
     ScenarioName="&Scenario._&ScenarioIndex";
     IncubationPeriod = &IncubationPeriod;
     InitRecovered = &InitRecovered;
     RecoveryDays = &RecoveryDays;
     DoublingTime = &DoublingTime;
     Population = &Population;
     KnownAdmits = &KnownAdmits;
     KnownCOVID = &KnownCOVID;
     SocialDistancing = &SocialDistancing;
     MarketSharePercent = &MarketSharePercent;
     AdmissionRate = &AdmissionRate;
     ICUPercent = &ICUPercent;
     VentPercent = &VentPercent;
RUN;






        data input; set RUN_SCENARIOS; stop; run;
        DATA _NULL_;
            set sashelp.vmacro(where=(scope='EASYRUN'));
            call symput('mname',trim(name));
            call execute(cats('data input; set input; ',"&mname.=",&&mname.,'; run;'));
        RUN;