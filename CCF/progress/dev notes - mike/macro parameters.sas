
/* keyword and positional parameters */
%macro test(a,b,c=4);
	%put &a. &b. &c.;
%mend;

/* just keyword */
%test(1,2);
/* positional requires variable name */
*%test(1,2,3);
/* keyword and positional */
%test(1,2,c=3);
/* keyword with variable name */
%test(a=1,b=2,c=3);
/* keyword order switched with variable name */
%test(b=1,a=2,c=3);

/* macro example without defined inputs */
%macro temp / parmbuff;
	%put &syspbuff;
%mend;
%temp(a,b,c);

/* macro example without defined and undefined inputs */
%macro temp(a,b,c=4) / parmbuff;
	%put &syspbuff;
	%put &a &b &c &d;
%mend;
%temp(1,2,c=3,d=4);



/* macro example with no defined inputs 
	uses parmbuff which stores all inputs in &syspbuff
	this example has two levels of delimitting to show use case of variable and array like variables
*/
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

