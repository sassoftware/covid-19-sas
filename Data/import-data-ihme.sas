/* 
   SAS program code to fetch and import the COVID-19 projection estimates 
   created by Institue for Health Metrics and Evaluation (IHME).
   
   Data source: http://www.healthdata.org/covid/data-downloads
   
   Copyright 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
   SPDX-License-Identifier: Apache-2.0
   
   Output: IMHE_IMPORT.sas
*/



/* CHANGE BEFORE RUNNING - File location to save zip files */
%let fileloc = ;

libname final "&fileloc";

options minoperator mindelimiter=',';

%macro IMHE(date1, date2);
	/* Downloads a zip file of data (for a specific date) from the IHME */
	filename inzip "&fileloc&date2..zip";
	%let url = https://ihmecovid19storage.blob.core.windows.net/archive/&date1/ihme-covid19.zip;
	proc http
	url="&url"
	method="GET"
	out=inzip
	;
	run;
	
	/* Reads a CSV from the zip file into a SAS data set */
	filename zipfile zip "&fileloc&date2..zip" member="*/*.csv";
	
	%if &date2 in (Mar25, Mar26, Mar27, Mar29) %then %do;
		data ihme_&date2;
			length location_name $50 date_reported $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 	
					location_name $
					date_reported $	allbed_mean		allbed_lower	allbed_upper	
					ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
					InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
					deaths_upper	admis_mean		admis_lower		admis_upper	
					newICU_mean		newICU_lower	newICU_upper	totdea_mean	
					totdea_lower	totdea_upper	bedover_mean	bedover_lower	
					bedover_upper	icuover_mean	icuover_lower	icuover_upper
					;
			rename date_reported = date_c;
		run;
	%end;
	%else %if &date2 in (Mar30, Mar31) %then %do;
		data ihme_&date2;
			length location_name $50 date_reported $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 
				v1 $	location $
				date_reported $	allbed_mean		allbed_lower	allbed_upper	
				ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
				InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
				deaths_upper	admis_mean		admis_lower		admis_upper	
				newICU_mean		newICU_lower	newICU_upper	totdea_mean	
				totdea_lower	totdea_upper	bedover_mean	bedover_lower	
				bedover_upper	icuover_mean	icuover_lower	icuover_upper
				location_name $
				;
			drop v1 location;
			rename date_reported = date_c;
		run;
	%end;	
	%else %if &date2 in (Apr01, Apr02) %then %do;
		data ihme_&date2;
			length location_name $50 date $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 
				v1 	location $
				date $			allbed_mean		allbed_lower	allbed_upper	
				ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
				InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
				deaths_upper	admis_mean		admis_lower		admis_upper	
				newICU_mean		newICU_lower	newICU_upper	totdea_mean	
				totdea_lower	totdea_upper	bedover_mean	bedover_lower	
				bedover_upper	icuover_mean	icuover_lower	icuover_upper
				location_name $
				;
			drop v1 location;
			rename date = date_c;
		run;
	%end;
	%else %if &date2 in (Apr05, Apr07, Apr08, Apr10, Apr13, Apr17, Apr21, Apr27, Apr28) %then %do;
		*NOTE: Below is the most current file format;
		data ihme_&date2;
			length location_name $50 date $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 
				v1 $	location_name $
				date $			allbed_mean		allbed_lower	allbed_upper	
				ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
				InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
				deaths_upper	admis_mean		admis_lower		admis_upper	
				newICU_mean		newICU_lower	newICU_upper	totdea_mean	
				totdea_lower	totdea_upper	bedover_mean	bedover_lower	
				bedover_upper	icuover_mean	icuover_lower	icuover_upper
				;
			drop v1;
			rename date = date_c;
		run;
	%end;
	
		%else %if &date2 in (Apr22) %then %do;
		*NOTE: Below is the most current file format;
		data ihme_&date2;
			length location_name $50 date $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 
				location_name $
				date $			allbed_mean		allbed_lower	allbed_upper	
				ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
				InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
				deaths_upper	admis_mean		admis_lower		admis_upper	
				newICU_mean		newICU_lower	newICU_upper	totdea_mean	
				totdea_lower	totdea_upper	bedover_mean	bedover_lower	
				bedover_upper	icuover_mean	icuover_lower	icuover_upper
				v1 $
				;
			drop v1;
			rename date = date_c;
		run;
	%end;
	
	%else %if &date2 in (Apr29) %then %do;
		*NOTE: Below is the most current file format;
		data ihme_&date2;
			length location_name $50 date $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 
				v1 $
				location_name $ location_id $
				date $			allbed_mean		allbed_lower	allbed_upper	
				ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
				InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
				deaths_upper	admis_mean		admis_lower		admis_upper	
				newICU_mean		newICU_lower	newICU_upper	totdea_mean	
				totdea_lower	totdea_upper	bedover_mean	bedover_lower	
				bedover_upper	icuover_mean	icuover_lower	icuover_upper
				
				;
			drop v1 location_id;
			rename date = date_c;
		run;
	%end;
	
	*add in Projection_Date variable and create variable labels and formats;
	data ihme_&date2;
		set ihme_&date2;
		Projection_Date_c = "&date2";
		Projection_Date = input("&date1", yymmdd10.);
		Date = input(date_c, yymmdd10.);
		format date date9. Projection_Date date9.;
		label 	Projection_Date = "Date of Projection Release"
				Projection_Date_c = "Date of Projection Release (Char)"
				location_name = "Location Name"
				date = "Date"
				date_c = "Date (Char)"
				allbed_mean = "Mean covid beds needed by day"
				allbed_lower = "Lower uncertainty bound of covid beds needed by day"
				allbed_upper = "Upper uncertainty bound of covid beds needed by day"
				ICUbed_mean = "Mean ICU covid beds needed by day"
				ICUbed_lower = "Lower uncertainty bound of ICU covid beds needed by day"
				ICUbed_upper = "Upper uncertainty bound of ICU covid beds needed by day"
				InvVen_mean = "Mean invasive ventilation needed by day"
				InvVen_lower = "Lower uncertainty bound of invasive ventilation needed by day"
				InvVen_upper = "Upper uncertainty bound of invasive ventilation needed by day"
				deaths_mean = "Mean daily covid deaths"
				deaths_lower = "Lower uncertainty bound of daily covid deaths"
				deaths_upper = "Upper uncertainty bound of daily covid deaths"
				admis_mean = "Mean hospital admissions by day"
				admis_lower = "Lower uncertainty bound of hospital admissions by day"
				admis_upper = "Upper uncertainty bound of hospital admissions by day"
				newICU_mean = "Mean number of new people going to the ICU by day"
				newICU_lower = "Lower uncertainty bound of the number of new people going to the ICU by day"
				newICU_upper = "Upper uncertainty bound of the number of new people going to the ICU by day"
				totdea_mean = "Mean cumulative covid deaths"
				totdea_lower = "Lower uncertainty bound of cumulative covid deaths"
				totdea_upper = "Upper uncertainty bound of cumulative covid deaths"
				bedover_mean = "[covid all beds needed] - ([total bed capacity] - [average all bed usage])"
				bedover_lower = "Lower uncertainty bound of bedover (above)"
				bedover_upper = "Upper uncertainty bound of bedover (above)"
				icuover_mean = "[covid ICU beds needed] - ([total ICU capacity] - [average ICU bed usage])"
				icuover_lower = "Lower uncertainty bound of icuover (above)"
				icuover_upper = "Upper uncertainty bound of icuover (above)"
				;
	run;
%mend IMHE;
%IMHE(2020-03-25, Mar25);
%IMHE(2020-03-26, Mar26);
%IMHE(2020-03-27, Mar27);
%IMHE(2020-03-29, Mar29);
%IMHE(2020-03-30, Mar30);
%IMHE(2020-03-31, Mar31);
%IMHE(2020-04-01, Apr01);
%IMHE(2020-04-02, Apr02);
%IMHE(2020-04-05, Apr05);
%IMHE(2020-04-07, Apr07);
%IMHE(2020-04-08, Apr08);
%IMHE(2020-04-10, Apr10);
%IMHE(2020-04-13, Apr13);
%IMHE(2020-04-17, Apr17);
%IMHE(2020-04-21, Apr21);
%IMHE(2020-04-22, Apr22);
%IMHE(2020-04-27, Apr27);
%IMHE(2020-04-28, Apr28);
%IMHE(2020-04-29, Apr29);

	filename inzip "&fileloc.May04.zip";
	%let url = https://ihmecovid19storage.blob.core.windows.net/archive/2020-05-04/ihme-covid19.zip;
	proc http
	url="&url"
	method="GET"
	out=inzip
	;
	run;
	
	
	/* Reads a CSV from the zip file into a SAS data set */
	filename zipfile zip "&fileloc.May04.zip" member="*\Hospitalization_all_locs.csv";

data ihme_May04;
			length location_name $50 date $10;
			infile zipfile dlm="," dsd firstobs=2;
			input 
				v1 $	location_name $
				date $			allbed_mean		allbed_lower	allbed_upper	
				ICUbed_mean		ICUbed_lower	ICUbed_upper	InvVen_mean	
				InvVen_lower	InvVen_upper	deaths_mean		deaths_lower	
				deaths_upper	admis_mean		admis_lower		admis_upper	
				newICU_mean		newICU_lower	newICU_upper	totdea_mean	
				totdea_lower	totdea_upper	bedover_mean	bedover_lower	
				bedover_upper	icuover_mean	icuover_lower	icuover_upper
				;
			drop v1;
			rename date = date_c;
		run;
		
	
*combine all the data sets;
data final.IHME;
	set IHME_:;
run;
