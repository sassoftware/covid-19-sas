
/* aggregate US state data from counties */
/*
%inc preproc_jhu;
%jhuimport(us);
*/

libname lcl ".";
data jhuus;
   set lcl.jhuus;
run;
libname lcl;

%let N=10e6;
%let tau=5.1;
%let Rho0=2.5;
%let sigma=.9;
%let enddate='28mar2020'd;

title 'SEIR Fit Model';



proc tmodel outmodel=seirmod;
   /* Parameters of interest */
   parms R0 &Rho0 i0 1;
   bounds 1 <= R0 <= 13;

   /* fixed values */
   control N  &N
           sigma  &sigma
           tau &tau;

   /* coefficient parameterizations */
   gamma = 1/tau;
   beta = R0*gamma/N;

   /* Differential equations */
   dert.s = - beta*s*v;
   dert.e = beta*s*v - sigma*e;
   dert.v = sigma*e - gamma*v;
   dert.r = gamma*v;
   cases = v + r;

   outvars s v e r;

   /* Fit the NC data */
   fit cases init=(s=&N v=i0 r=0 e=0) / time=date dynamic outpredict outactual
               out=ncpred(rename=v=i) covout outest=ncprmcov optimizer=ormp(opttol=1e-5)
               ltebound=1e-10 data=jhuus(where=(Province_State="North Carolina"
               and cases>0 and date < &enddate));
   /* Fit the OH data */
   fit cases init=(s=&N v=i0 r=0 e=0) parms=(R0 &Rho0 i0 1) / time=date dynamic
               outpredict outactual out=ohpred(rename=v=i) covout outest=ohprmcov
               outs=cov_error optimizer=ormp(opttol=1e-5) ltebound=1e-10 data=jhuus(where=
               (Province_State="Ohio" and cases>0 and date < &enddate));
quit;

%macro plotstateest(state,pre);
   data _null_;
      set &pre.prmcov(where=(_name_=""));
      call symputx('r0est',round(R0,0.01));
      call symputx('i0est',round(i0,0.01));
      call symputx('endfit',put(&enddate,mmddyy.));
   run;
    
   data &pre.pred;
      set &pre.pred;
      label cases='Cumulative Incidence';
   run;
   
   
   /*Plot results*/
   title &state Until &endfit;
   title2 "Fit of CumulativeInfections (R0=&r0est i0=&i0est)";
   
   proc sgplot data=&pre.pred;
       where _type_  ne 'RESIDUAL';
       series x=date y=cases / lineattrs=(thickness=2) group=_type_  markers name="cases";
       format cases comma10.;
   run;
%mend plotstateest;

%plotstateest(North Carolina,nc);
%plotstateest(Ohio,oh);



