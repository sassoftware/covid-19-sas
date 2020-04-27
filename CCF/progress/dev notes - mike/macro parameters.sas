

%macro test(a,b,c=4);
	%put &a. &b. &c.;
%mend;

%test(1,2);
*%test(1,2,3);
%test(1,2,c=3);
%test(a=1,b=2,c=3);
%test(b=1,a=2,c=3);



%macro temp / parmbuff;
	%put &syspbuff;

	%do i  = 1 %to %sysfunc(countw(&syspbuff.)); /* ( and , are default delimiters */
		%put %scan(&syspbuff,&i);
	%end;

	%do i  = 1 %to %sysfunc(countw(&syspbuff.)); /* ( and , are default delimiters */
		%let cw = %scan(&syspbuff.,&i);
		%do j = 1 %to %sysfunc(countw(&cw.,':'));
			%put %scan(&cw,&j,':');
		%end; 
	%end;

%mend;

%temp(a1:a2:a3,b1:b2,c);



