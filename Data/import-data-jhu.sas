/* 
   SAS program code to fetch and import the COVID-19 data 
   maintained by John Hopkins University CSSE.

   Data source: https://github.com/CSSEGISandData
   
   Copyright 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
   SPDX-License-Identifier: Apache-2.0

   Output: WORK.covid19_jhu_final, WORK.covid19_jhu_doubling
*/
%macro importSheets(start, end);

  %let start=%sysfunc(inputn(&start,anydtdte9.));
  %if (&end eq '') %then
    %do;
      %let end=%sysfunc(today());
    %end;
  %else
    %do;
      %let end=%sysfunc(inputn(&end,anydtdte9.));
    %end;
  %do i=&start. %to &end.;
    %let date=%sysfunc(putn(&i.,mmddyyd10.));
    filename gdata temp lrecl=2048;

    proc http 
       url="https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_daily_reports/&date..csv"
       method="GET"
       out=gdata;
    run;

    %if &SYS_PROCHTTP_STATUS_CODE. eq 200 %then 
      %do;
        options validvarname=v7;

        proc import datafile=gdata out=work.tmp_day dbms=csv replace;
          getnames=yes;
          datarow=2;
          guessingrows=max;
        run;

        filename gdata;
        %if (%sysfunc(exist(work.tmp_day)) eq 1) %then
          %do;

            data work.tmp_day;
              set work.tmp_day;
              date = input("&date.",mmddyy10.);
              rename lat=latitude long_=longitude;
              rename fips=county_fips;
              rename admin2=county;
              rename country_region=country province_state=state;
            run;

            proc append base=work.ncov_cases data=work.tmp_day force;
            run;

            /* remove temp holding file */
            proc delete data=work.tmp_day; run;
          %end;
      %end;
    %else %put WARNING: No data fetched for &date.;
  %end;
%mend;

/* Create a base data set with proper attributes */
data work.ncov_cases;
  attrib    
    date            length=8      format=date9.   label="Date"
    country         length=$50.   format=$CHAR50. label="Country/Region"
    county          length=$50.   format=$CHAR50. label="County"
    county_fips     length=8      format=best12.  label="County FIPS"
    state           length=$50.   format=$CHAR50. label="Province/State"
    latitude        length=8      format=best12.  label="Latitude"
    longitude       length=8      format=best12.  label="Longitude"
    confirmed       length=8      format=best12.  label="Confirmed"
    recovered       length=8      format=best12.  label="Recovered"
    deaths          length=8      format=best12.  label="Deaths"
    active          length=8      format=best12.  label="Active"
  ;
  call missing(of _all_);
  stop;
run;

/* Populate the data for each day of data from JHU GitHub */
%importSheets(22JAN2020, '');

/* Group some special values (like cruise ships)            */
/* Normalize Country and State names for easier reporting   */
/* Remove City names from State level variable where needed */
proc sql;
	create table work.novel_corona_virus_states as
	select distinct a.date, a.country as country_orig label="Country (Recorded)",
			case 
				when 	trim(lowcase(a.state)) like ("%cruise ship%") 
						or trim(lowcase(a.country)) like ("%cruise ship%") 
						or trim(lowcase(a.state)) like ("%grand princess%")
						or lowcase(a.state) contains "diamond princess"
						or lowcase(a.country) contains "diamond princess"
						or lowcase(a.state) contains "from diamon"
					then "Others / Cruise Ship"
				when a.country in ("Mainland China", "Hong Kong", "Hong Kong SAR", "Macau", "Macao SAR") then "China"
				when compress(a.state) eq "Guam" then "Guam"
				when a.state eq 'Northern Mariana Islands' or country contains "Mariana Islands" then "Northern Mariana Islands"
				when a.state eq 'American Samoa' then "American Samoa"
				when a.state eq 'Puerto Rico' then 'Puerto Rico'
				when a.state contains 'Virgin Islands' then "US Virgin Islands"
				when a.country in ("US") then "United States"
				when a.country in ("UK", "North Ireland", "Channel Islands") then "United Kingdom"
				when a.country in ("Vietnam") then "Viet Nam"
				when a.country in ("Russia") then "Russian Federation"
				when a.country in ("Bolivia") then "Bolivia, Plurinational State of"
				when a.country in ("Brunei") then "Brunei Darussalam"
				when a.country in ("Czechia") then "Czech Republic"
				when a.country in ("Holy See", "Vatican City") then "Vatican City State"
				when a.country in ("Korea, South") then "South Korea"
				when a.country contains "Taiwan" then "Taiwan"
				when a.country in ("North Macedonia") then "Macedonia"
				when a.country contains "Congo" then "Congo"
				when a.country in ("Cote d'Ivoire") then "Ivory Coast"
				when a.country in ("Cabo Verde") then "Cape Verde"
				when a.country in ("Jersey") then "Cape Verde"
				when a.country contains "Ireland" then "Ireland"
				when a.country contains "Moldova" then "Moldova"
				when a.country in ("Republic of Korea") then "South Korea"
				when a.country in ("Saint Vincent and the Grenadines") then "Saint Vincent and Grenadines"
				when a.country in ("St. Martin") then "Saint Martin"
				when a.country in ("Taipei and environs") then "Taiwan"
				when a.country in ("Tanzania") then "Tanzania, United Republic of"
				when a.country contains "Bahamas" then "Bahamas"
				when a.country contains "Gambia" then "Gambia"
				when a.country in ("Timor-Leste", "East Timor") then "Timor Leste"
				when a.country in ("Venezuela") then "Venezuela, Bolivarian Republic of"
				when a.country in ("West Bank and Gaza") then "Israel"
				when a.country in ("occupied Palestinian territory") then "Israel/Palestine"
				when a.country in ("Eswatini") then "Swaziland"
				when a.country in ("Guernsey") then "Bailiwick of Guernsey"
				when a.country in ("Jersey then") then "Bailiwick of Jersey"
				when a.country in ("Iran (Islamic Republic of)") then "Iran"
				when a.country in ("Guinea-Bissau") then "Guinea Bissau"
				else a.country
			end as country,
			case
				when a.country eq "Australia" and a.state in ('External territories','Jervis Bay Territory') then "Other Territories"
				
				when a.country eq "Canada" and compress(scan(a.state,2,",")) in ('ON') then "Ontario"
				when a.country eq "Canada" and compress(scan(a.state,2,",")) in ('QC') then "Quebec"
				when a.country eq "Canada" and compress(scan(a.state,2,",")) in ('Alberta') then "Alberta"

				when calculated country eq "China" and a.state in ('Anhui','Fujian','Gansu','Guangdong','Guizhou','Hainan','Hebei',
					'Heilongjiang','Henan','Hubei','Hunan','Jiangxi','Jiangsu','Jilin','Liaoning',
					'Qinghai','Shaanxi','Shandong','Shanxi','Sichuan','Zhejiang','Yunnan') then trim(left(a.state)) || ' Sheng'
				when calculated country eq "China" and a.state in ('Beijing','Chongqing','Shanghai','Tianjin') then trim(left(a.state)) || ' Shi'
				when calculated country eq "China" and a.state in ('Guangxi') then 'Guangxi Zhuangzu Zizhiqu'
  				when calculated country eq "China" and a.state in ('Ningxia') then 'Ningxia Huizu Zizhiqu'
				when calculated country eq "China" and a.state in ('Xinjiang') then "Xinjiang Weiwu'er Zizhiqu"
				when calculated country eq "China" and a.state eq "Tibet" then "Xizang Zizhiqu"
				when calculated country eq "China" and a.state eq "Macau" then "Aomen Tebie Xingzhengqu"
				when calculated country eq "China" and a.state eq 'Hong Kong' then 'Xianggang Tebie Xingzhengqu'
				when calculated country eq "China" and a.state eq 'Inner Mongolia' then 'Neimenggu Zizhiqu'

				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('AL') then "Alabama"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('AK') then "Alaska"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('AZ') then "Arizona"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('AR') then "Arkansas"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('CA') then "California"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('CO') then "Colorado"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('CT') then "Connecticut"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('DE') then "Delaware"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('DC', 'D.C.') then "District of Columbia"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('FL') then "Florida"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('GA') then "Georgia"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('HI') then "Hawaii"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('ID') then "Idaho"	
				when calculated country eq "United States" and (compress(scan(a.state,2,",")) in ('IL') or a.state eq 'Chicago') then "Illinois"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('IN') then "Indiana"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('IA') then "Iowa"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('KS') then "Kansas"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('KY') then "Kentucky"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('LA') then "Louisiana"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('ME') then "Maine"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MD') then "Maryland"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MA') then "Massachusetts"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MI') then "Michigan"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MN') then "Minnesota"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MS') then "Mississippi"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MO') then "Missouri"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('MT') then "Montana"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NE') then "Nebraska"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NV') then "Nevada"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NH') then "New Hampshire"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NJ') then "New Jersey"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NM') then "New Mexico"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NY') then "New York"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('NC') then "North Carolina"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('ND') then "North Dakota"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('OH') then "Ohio"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('OK') then "Oklahoma"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('OR') then "Oregon"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('PA') then "Pennsylvania"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('RI') then "Rhode Island"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('SC') then "South Carolina"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('SD') then "South Dakota"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('TN') then "Tennessee"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('TX') then "Texas"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('UT') then "Utah"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('VT') then "Vermont"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('VA') then "Virginia"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('WA') then "Washington"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('WV') then "West Virginia"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('WI') then "Wisconsin"	
				when calculated country eq "United States" and compress(scan(a.state,2,",")) in ('WY') then "Wyoming"

				else a.state
			end as state label="Province/State Label",
			sum(a.confirmed) as confirmed label="Confirmed", 
			sum(a.recovered) as recovered label="Recovered", 
			sum(a.deaths) as deaths label="Deaths",
			sum(a.active) as active label="Active",
			avg(a.latitude) as latitude label="Latitude", avg(a.longitude) as longitude label="Longitude"
	from	ncov_cases a
	where	country ne ''
	group by calculated country, state, date;
quit;

/* Calculate lat/long for use in those records where it's missing */
proc sql;
  create table work.country_states as
    select distinct country, state, 
       avg(latitude) as latitude, avg(longitude) as longitude
      from work.novel_corona_virus_states
        where latitude ne . and longitude ne .
          group by country, state
  ;
quit;

/* remerge calculated lat/long with those records where it's missing */
proc sql;
 create table work.covid_withlatlong as
  select 
    t1.date,
    t1.country,
    t1.country_orig,
    t1.state,
     case 
       when t1.latitude is missing then t2.latitude
       else t1.latitude
     end as latitude,
     case 
       when t1.longitude is missing then t2.longitude
       else t1.longitude
     end as longitude,
    t1.confirmed,
    t1.deaths,
    t1.recovered,
    t1.active 
  from work.novel_corona_virus_states t1
   left join work.country_states t2 on 
     (t1.country=t2.country and t1.state=t2.state) 
  order by country, state, date;
quit;

data work.covid19_jhu_final(
  drop=confirmed recovered deaths 
  rename=(confirmed_new=confirmed recovered_new=recovered deaths_new=deaths)
  );
	set work.covid_withlatlong;
    by country state date;

	if (confirmed eq .) then confirmed = 0;
	if (recovered eq .) then recovered = 0;
	if (deaths eq .) then deaths = 0;

	if (first.country or first.state) then do;
		confirmed_total = confirmed;confirmed_new = confirmed;
		recovered_total = recovered;recovered_new = recovered;
		deaths_total = deaths;deaths_new = deaths;
	end; else do;
		confirmed_new = confirmed - confirmed_total;confirmed_total = confirmed;
		recovered_new = recovered - recovered_total;recovered_total = recovered;
		deaths_new = deaths - deaths_total;deaths_total = deaths;
	end;

	label confirmed_new="Confirmed" recovered_new="Recovered" deaths_new="Deaths";
	label confirmed_total="Confirmed (Total)" recovered_total="Recovered (Total)" deaths_total="Deaths (Total)";

	retain confirmed_total recovered_total deaths_total;
run;


/* prep for days since first cases */
proc sql;
	create table work.covid_country as
	select 	country, date, 
			sum(confirmed_total) as confirmed_total, 
			sum(recovered_total) as recovered_total, 
			sum(deaths_total) as deaths_total
	from work.covid19_jhu_final
	group by country, date
	order by country, date;
quit;


data work.covid_country;
	set work.covid_country;
    by country date;

	label days_since_first_case = "Number of days since 1st case / Country";
	label days_since_tenth_case = "Number of days since 10th case / Country";
	label days_since_hundredth_case = "Number of days since 100th case / Country";
	label days_since_first_death = "Number of days since 1st death / Country";
	label days_since_tenth_death = "Number of days since 10th death / Country";
	label days_since_hundredth_death = "Number of days since 100th death / Country";

	if (first.country) then do;
		if (confirmed_total ge 1) then days_since_first_case = 1; else days_since_first_case = 0;
		if (confirmed_total ge 10) then days_since_tenth_case = 1; else days_since_tenth_case = 0;
		if (confirmed_total ge 100) then days_since_hundredth_case = 1; else days_since_hundredth_case = 0;
		if (deaths_total ge 1) then days_since_first_death = 1; else days_since_first_death = 0;
		if (deaths_total ge 10) then days_since_tenth_death = 1; else days_since_tenth_death = 0;
		if (deaths_total ge 100) then days_since_hundredth_death = 1; else days_since_hundredth_death = 0;
	end; else do;
		if (confirmed_total ge 1 or days_since_first_case ne 0) then days_since_first_case = days_since_first_case + 1;
		if (confirmed_total ge 10 or days_since_tenth_case ne 0) then days_since_tenth_case = days_since_tenth_case + 1;
		if (confirmed_total ge 100 or days_since_hundredth_case ne 0) then days_since_hundredth_case = days_since_hundredth_case + 1;
		if (deaths_total ge 1 or days_since_first_death ne 0) then days_since_first_death = days_since_first_death + 1;
		if (deaths_total ge 10 or days_since_tenth_death ne 0) then days_since_tenth_death = days_since_tenth_death + 1;
		if (deaths_total ge 100 or days_since_hundredth_death ne 0) then days_since_hundredth_death = days_since_hundredth_death + 1;
	end;

	retain days_since_first_case days_since_tenth_case days_since_hundredth_case days_since_first_death days_since_tenth_death days_since_hundredth_death;
run;

/* calculate doubling rates */
data work.covid19_jhu_doubling;
	set work.covid_country;
    by country date;

	length confirmed_d2d 8.;label confirmed_d2d="Confirmed (Days to double) / Country";
	length recovered_d2d 8.;label recovered_d2d="Recovered (Days to double) / Country";
	length deaths_d2d 8.;label deaths_d2d="Deaths (Days to double) / Country";

	if (first.country) then do;
		confirmed_dblcnt = confirmed_total;confirmed_dblcnt_days = days_since_first_case;
		recovered_dblcnt = recovered_total;recovered_dblcnt_days = days_since_first_case;
		deaths_dblcnt = deaths_total;deaths_dblcnt_days = days_since_first_case;
	end; else do;
		if (confirmed_total gt 0 and confirmed_total ge (confirmed_dblcnt*2)) then do;
			confirmed_d2d = days_since_first_case - confirmed_dblcnt_days;
			confirmed_dblcnt = confirmed_total;
			confirmed_dblcnt_days = days_since_first_case;
		end; 
		if (recovered_total gt 0 and recovered_total ge (recovered_dblcnt*2)) then do;
			recovered_d2d = days_since_first_case - recovered_dblcnt_days;
			recovered_dblcnt = recovered_total;
			recovered_dblcnt_days = days_since_first_case;
		end; 
		if (deaths_total gt 0 and deaths_total ge (deaths_dblcnt*2)) then do;
			deaths_d2d = days_since_first_case - deaths_dblcnt_days;
			deaths_dblcnt = deaths_total;
			deaths_dblcnt_days = days_since_first_case;
		end; 
	end;
	drop confirmed_dblcnt confirmed_dblcnt_days recovered_dblcnt recovered_dblcnt_days deaths_dblcnt deaths_dblcnt_days;
	retain confirmed_d2d recovered_d2d deaths_d2d confirmed_dblcnt confirmed_dblcnt_days recovered_dblcnt recovered_dblcnt_days deaths_dblcnt deaths_dblcnt_days;
run;

