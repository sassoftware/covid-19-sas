# COVID-19 Epidemiological Scenario and Critcial Resource Utilization Prediction Program

This is a collaboration space for SAS and others to understand, model, and mitigate COVID-19 through analytics. The projects here include:

* [SIR & SEIR Modeling (with Cleveland Clinic)](#sir--seir-modeling-with-cleveland-clinic)
* [Data sources for COVID-19 reporting](#data-sources-for-covid-19-reporting)

To use the work in these projects, a SAS environment is required.  Refer to the documentation for each project to learn more about the SAS system requirements.

This project is also the engine for an interactive visual interface available at https://www.sas.com/en_us/trials/software/epidemiological-scenario-analysis/form.html  The web-based interface does not require a local SAS environment.

## SIR & SEIR Modeling (with Cleveland Clinic)

This first entry is a collaboration between the Cleveland Clinic and SAS Institute. Explore [the /CCF folder](./CCF)
for code and documentation about the model implementation.

### Outputs from sample scenarios

Among other outputs, these analyses will create diagnostic visuals for each modeled scenario.

| All Approaches | Fitting Approaches |
:-------------------------:|:-------------------------:
![](./CCF/images/example-0.png)  |  ![](./CCF/images/example-1.png)
![](./CCF/images/example-4.png)  |  ![](./CCF/images/example-2.png)
![](./CCF/images/example-3.png)  |  ![](./CCF/images/example-5.png)

## Data sources for COVID-19 reporting

SAS developers and data scientists maintain a [Coronavirus Dashboard Report](https://www.sas.com/covid19) using SAS Visual Analytics.
The dashboard is refreshed daily with new data from several public data sources.  [In the /Data folder](./Data), the team has shared
the SAS programs that are used to retrieve and prepare this data for reporting.

## Preferred Reference for Citation
Cleveland Clinic and SAS COVID-19 Development Team. Developer Documentation [Internet]. 2020. Available from: https://github.com/sassoftware/covid-19-sas
