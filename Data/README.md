# Data sources for COVID-19 reporting

SAS developers and data scientists maintain a [Coronavirus Dashboard Report](https://www.sas.com/covid19) using SAS Visual Analytics.
The dashboard is refreshed daily with new data from several public data sources.  In this folder, the team has shared
the SAS programs that are used to retrieve and prepare this data for reporting.

These data sources include:

* [Novel Coronavirus (COVID-19) Cases](https://github.com/CSSEGISandData/COVID-19), provided by John Hopkins University CSSE. This data source is used widely in many dashboards and reports around the world.
* [Coronavirus (Covid-19) Data in the United States](https://github.com/nytimes/covid-19-data), provided by _The New York Times_. This data contains daily counts for the United States, each state in the US, and each county within the states.

## About these SAS programs

These SAS programs use Base SAS features.  They should work in any modern SAS environment, including SAS 9.4M6 and SAS Viya 3.5.
These programs also work within [SAS University Edition](https://www.sas.com/en_us/software/university-edition.html) and [SAS OnDemand for Academics](https://www.sas.com/en_us/software/on-demand-for-academics.html).

* [import-data-nyt.sas](./import-data-nyt.sas) - This program uses Git functions to fetch CSV files from [https://github.com/nytimes/covid-19-data](https://github.com/nytimes/covid-19-data) and reads the data into SAS data sets.  It creates 3 data sets with data at different levels: US (national), US states, US states with counties.

  You can see examples of the code and some sample visualizations in [the NYT-COVID19-SAS notebook](NYT-COVID19-SAS.ipynb). (This notebook can be added to SAS University Edition, which supports Jupyter Lab.  You can also enable the [SAS kernel for your own SAS environment](https://blogs.sas.com/content/sasdummy/2016/04/24/how-to-run-sas-programs-in-jupyter-notebook/).)
* [import-data-jhu.sas](./import-data-jhu.sas) - This program uses PROC HTTP to fetch the daily CSV files from [https://github.com/CSSEGISandData/COVID-19](https://github.com/CSSEGISandData/COVID-19). It uses PROC IMPORT to read the data a single SAS data set, covering all countries/regions over all of the days with data. Subsequent steps are used to clean/normalize the data for easier reporting. The main outputs include: a data set with all countries and regions/states and daily data with running totals of cases/deaths, and a data set summarized to the country level with "days to double" rate for cases/deaths.

## Credits

Jeff Stander, Pritesh Desai, Falko Schulz, Anand Chitale, and Robert Collins contributed to these SAS scripts. Adapted for GitHub sharing
by Chris Hemedinger.
