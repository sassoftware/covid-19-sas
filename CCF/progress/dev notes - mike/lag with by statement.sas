data temp;
	do a=1 to 3;

		do i=1 to 10;
			output;
		end;
	end;
run;

%let goal=3;

data temp;
	set temp;
	retain count;
	by a;
	x=lag&goal.(i);
	if first.a then do;
		count=1;
	end;
	else do;
		count+1;
	end;
	if count<=&goal. then do;
		x=.;
	end;
	put a i x;
run;







data temp;
	do a=1 to 3;
		do i=1 to 10;
			b=lag(i);
			c=lag(lag(i));
			d=lag2(i);
			output;
			put a i b c d;
		end;
	end;
run;	








%macro test(m,s);

	data test;
		newinfected=100; /* pretend 100 new patients per day for this code experiment */
		do day = 1 to 10;
			output;
		end;
	run;

	data test;
		set test;
		call streaminit(2019);
		array census_los{0:40} _temporary_;

			/* decrease all census by 1 day */
			if day > 1 then do;
				do i = 0 to 39;
					census_los{i}=census_los{i+1};
				end;
				census_los{40}=0;
			end;

			/* todays new admits */
				hosp=newinfected;

			/* LOS counts for HOSP patients for today added to census_los */
				do i = 1 to hosp;
					temp=round(rand('NORMAL',&m,&s),1);
					if temp<0 then temp=0;
					else if temp>40 then temp=40;
					census_los{temp}+1;
				end;
				HOSPITAL_OCCUPANCY = sum(of census_los{*});

			/* quick view of iterations by day */
				put "newinfected / day / hosp / hospital_occupancy";
				put newinfected day hosp hospital_occupancy;
				do i = 0 to 40;
					if i=0 then do; put "days_left / count"; end;
					if census_los{i} then do; put i census_los{i}; end;
				end;

		drop i temp;
	run;

%mend;

%test(10,2);






















