
data d;
   do date = '1feb2020'd to '1jun2020'd;
	   s = .;
		e = .;
		i = .;
		r = .;
		output;
	end;
run;

proc tmodel data=d;
   dependent s 1e6 e 0 i 1 r 0 ;
	/* fixed values */
	control N 1e6 R0 3 sigma 0.9  tau 5.1;
   gamma = 1/tau;
   beta = R0*gamma/N;

   /* Differential equations */
   dert.s = - beta*s*i;
   dert.e = beta*s*i - sigma*e;
   dert.i = sigma*e - gamma*i;
   dert.r = gamma*i;

	solve / time=date out=tm;
quit;


data ds;
   keep date s e i r;
   retain s 1e6 e 0 i 1 r 0 ls le li lr;
	ls = s; le = e; li = i; lr = r;
	N=1e6;  R0=3; sigma=0.9;  tau=5.1;
   gamma = 1/tau;
   beta = R0*gamma/N;
	retain h 0.1;
   do date = '1feb2020'd to '1jun2020'd by h;
	   if abs(date - round(date,1)) < 0.01 then output;

      s + (- beta*ls*i)*h;
	   e + (beta*ls*li - sigma*le)*h;
	   i + (sigma*le - gamma*li)*h;
	   r + (gamma*li)*h;
	   
   	ls = s; le = e; li = i; lr = r;
	end;
run;


data tvsd;
   merge tm(rename=i=ti) ds(rename=i=di);
	by date;
run;


proc sgplot data=tvsd;
   series x=date y=ti / lineattrs=(thickness=3);
   series x=date y=di / lineattrs=(thickness=3);
	format ti di comma10.;
	format date date9.;
run;


