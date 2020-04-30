%macro temp (a,b,c);

	data temp; 
		a=&a.;
		b="&b.";
		c="&c.";
		output;
	run;

	%DO j = 1 %TO %SYSFUNC(countw(&c.,:));
		%LET SocialDistancingChange&j = %scan(&c.,&j,:);
		%LET ISOChangeDate&j = %scan(&b.,&j,:);
		%put &&ISOChangeDate&j &&SocialDistancingChange&j;
	%END; 

	%put &j;
	%SYMDEL j;

%mend;
%temp(A,'31MAR2020'd:'06APR2020'd:'20APR2020'd:'01MAY2020'd,0:0.2:0.5:0.3);