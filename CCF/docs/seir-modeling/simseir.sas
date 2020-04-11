
ods graphics on;

%let N=50e6;
%let tau=5.1;
%let Rho0=2.5;
%let sigma=.9;
%let start='1mar2020'd;
%let end='1sep2020'd;

data timepts;
   s = &N; e = 0; v = 1; r = 0;
   do date = &start to &end;
      output;
      s = .; e = .; v = .; r = .;
   end;
run;

data s;
   _name_ = "cases";
   cases = 0;
run;

data r0cov;
   length _type_ $ 8 _name_ $ 8;
   _type_ = "OLS";
   _name_ = "";
   R0 = &Rho0;
   output;
   _name_ = "R0";
   R0 = 1;
   output;
run;

data r0tcov;
   length _type_ $ 8 _name_ $ 8;
   _type_ = "OLS";
   _name_ = "";
   R0 = &Rho0;
   tau = &tau;
   output;
   _name_ = "R0";
   R0 = 0.5;  tau = 0;
   output;
   _name_ = "tau";
   R0 = 0;  tau = 2;
   output;
run;

title 'SEIR Monte Carlo simulation';



proc tmodel data=timepts;
   endo s &N e 0 v 1 r 0;
   /* parameters of interest */
   parms R0 &Rho0 tau &tau;

   /* fixed values */
   control N  &N
           sigma  &sigma;

   /* coefficient parameterizations */
   gamma = 1/tau;
   beta = R0*gamma/N;

   /* Differential equations */
   dert.s = - beta*s*v;
   dert.e = beta*s*v - sigma*e;
   dert.v = sigma*e - gamma*v;
   dert.r = gamma*v;

   cases = v + r;

   /* monte carlo simulation; r0 */
   solve cases / time=date outpredict out=mcsimr0(rename=v=i) seed=1
                 random=5 sdata=s estdata=r0cov;
   outvars R0 tau;
   /* monte carlo simulation: r0 and tau */
   solve cases / time=date outpredict out=mcsimr0t(rename=v=i) seed=1
                 random=10 sdata=s estdata=r0tcov;
   outvars R0 tau;
quit;


/* Hundred thousands Fomat */
proc format;
  picture hundthou 0-high = '000.0' (mult=0.00001);
quit;

data mcsimr0;
   set mcsimr0;
   format date date.;
run;

proc print data=mcsimr0(where=(date=&start));
   format s e i r hundthou.;
run;

proc sgplot data=mcsimr0 noautolegend;
   series x =date y=i / group=_rep_ lineattrs=(pattern=solid thickness=2);
   yaxis label='Number of Cases (x100,000)' valuesformat=hundthou.;
   xaxis label='Date';
run;


data mcsimr0t;
   set mcsimr0t;
   format date date.;
run;

proc print data=mcsimr0t(where=(date=&start));
   format s e i r hundthou.;
run;

proc sgplot data=mcsimr0t noautolegend;
   series x =date y=i / group=_rep_ lineattrs=(pattern=solid thickness=2);
   yaxis label='Number of Cases (x100,000)' valuesformat=hundthou.;
   xaxis label='Date';
run;

