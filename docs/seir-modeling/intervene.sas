
/* import JHU world and US data */
/*
%inc preproc_jhu;
%jhuimport(us);
%jhuimport(world);
*/

libname lcl ".";
data jhuus;
   set lcl.jhuus;
run;
data jhuworld;
   set lcl.jhuworld;
run;
libname lcl;

%let Nit=60e6;
%let Nwa=7.5e6;
%let tau=5.1;
%let Rho0=2.5;
%let sigma=.9;
%let idate='15mar2020'd;

data italy;
   set jhuworld(where=(country_region='Italy'));
   N = &Nit;
run;

data washington;
   set jhuus(where=(province_state='Washington'));
   N = &Nwa;
run;

title 'SEIR Fit Intervention Model';



proc tmodel outmodel=seirmod;
   /* Parameters of interest */
   parms R0 &Rho0 i0 1 Ri -1 di &idate;
   bounds 1 <= R0 <= 13;
   restrict R0 + Ri > 0;

   /* fixed values */
   control sigma  &sigma
           tau &tau;

   /* coefficient parameterizations */
   gamma = 1/tau;
   step = cdf('normal',date,di,1);
   beta = (R0 + step*Ri)*gamma/N;

   /* Differential equations */
   dert.s = - beta*s*v;
   dert.e = beta*s*v - sigma*e;
   dert.v = sigma*e - gamma*v;
   dert.r = gamma*v;
   cases = v + r;

   outvars s v e r;

   /* Fit the Italy data */
   fit cases init=(s=&Nit v=i0 r=0 e=0) / time=date dynamic outpredict outactual
               out=itpred(rename=v=i) covout outest=itprmcov optimizer=ormp(opttol=1e-5)
               ltebound=1e-10 data=italy(where=(cases>0));
   /* Fit the Washington data */
   fit cases init=(s=&Nwa v=i0 r=0 e=0) parms=(R0 &Rho0 i0 1 Ri -1 di &idate) / time=date
               dynamic outpredict outactual out=wapred(rename=v=i) covout outest=waprmcov
               outs=cov_error optimizer=ormp(opttol=1e-5) ltebound=1e-10
               data=washington(where=(cases>1));
quit;


%macro plotstateest(state,pre);
   data _null_;
      set &pre.prmcov(where=(_name_=""));
      call symputx('r0est',round(R0,0.01));
      call symputx('i0est',round(i0,0.01));
      call symputx('riest',round(Ri,0.01));
      call symputx('diest',put(di,mmddyy.));
   run;
    
   data &pre.pred;
      set &pre.pred end=last;
      label cases='Cumulative Incidence';
      if last then call symputx("&pre"||"endfit",put(date,mmddyy.));;
   run;
   
   
   /*Plot results*/
   %let tit=&&%sysfunc(cat(&pre,endfit));
   title &state Through &tit;
   title2 "Fit of CumulativeInfections (R0=&r0est i0=&i0est Ri=&riest  di=&diest)";
   
   proc sgplot data=&pre.pred;
       where _type_  ne 'RESIDUAL';
       series x=date y=cases / lineattrs=(thickness=2) group=_type_  markers name="cases";
       format cases comma10.;
   run;
%mend plotstateest;

%plotstateest(Italy,it);
%plotstateest(Washington,wa);

