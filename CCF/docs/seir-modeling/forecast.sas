

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



title 'SEIR Fit Model';
proc tmodel outmodel=seirmod;
   /* Parameters of interest */
   parms R0 &Rho0 i0 1 /*Ri -1*/ di &idate dstd=10;
   bounds 1 <= R0 <= 3;
   /*restrict R0 + Ri > 0; */

   /* fixed values */
   control sigma  &sigma
           tau &tau;

   /* coefficient parameterizations */
   gamma = 1/tau;
   step = cdf('normal',date,di,dstd);
   beta = (R0 - step*R0)*gamma/N;

   /* Differential equations */
   dert.s = - beta*s*v;
   dert.e = beta*s*v - sigma*e;
   dert.v = sigma*e - gamma*v;
   dert.r = gamma*v;
   cases = v + r;

   outvars s v e r;

   /* Fit the Italy data */
   fit cases init=(s=&Nit v=i0 r=0 e=0) / time=date dynamic outpredict outactual out=itpred(rename=v=i)
               covout outest=itprmcov optimizer=ormp(opttol=1e-5) ltebound=1e-10
               data=italy(where=(cases>0));
quit;

data mccov;
   set itprmcov;
   if _name_ ^= "" then do;
      R0 = 0;
      i0 = 0;
      di = 0;
      dstd = 0;
      if  _name_ = "di" then di = 300;
   end;
run;


data s;
   keep _name_ s e v r;
   array endovar[4] s e v r;
   array endonam[4] $ ( "s" "e" "v" "r");
   cov = 0;
   output;
   case = 0;
   do i = 1 to dim(endovar);
      _name_ = endonam[i];
      do j = 1 to dim(endovar);
         if i=j then endovar[j] = cov;
         else endovar[j] = 0;
      end;
      output;
   end;
run;

data itproject;
   drop lastdate cnt sigma tau _type_ _weight_ jul31;
   set itpred(rename=i=v where=(_type_='ACTUAL')) end=last;
   output;
   if last then do;
      lastdate=date;
      call symputx('lastdate',lastdate);
      jul31 = '31jul2020'd - lastdate;
      do cnt=1 to jul31;
         date = lastdate + cnt;
         s = .;
         e = .;
         v = .;
         r = .;
         cases = .;
         output;
      end;
   end;
run;

proc tmodel data=itproject model=seirmod;
   solve s e v r / simulate time=date out=itfore(rename=v=i) 
                 random=25 seed=1 quasi=sobol estdata=mccov sdata=s;
quit;

data itforevar;
   set itfore;
   if date >= &lastdate then do;
      ifore=i;
      if date > &lastdate then i=.;
   end;
   if _rep_ ^= 0 then i = .;

run;

%macro plotsim(state,pre);
   title &state Forecast;
   
   proc sgplot data=&pre.forevar noautolegend;
       series x=date y=i / lineattrs=(thickness=3) name="modeled";
       series x=date y=ifore /  group=_rep_ lineattrs=(pattern=solid thickness=1) name="forecast";
       yaxis min=0;
       format i ifore comma10.;
   run;
   proc sgplot data=&pre.forevar noautolegend;
       series x=date y=i / lineattrs=(thickness=3) name="modeled";
       series x=date y=ifore /  group=_rep_ lineattrs=(pattern=solid thickness=1) name="forecast";
       yaxis min=0 max=30000;
       format i ifore comma10.;
   run;
%mend plotsim;

%plotsim(Italy,it);
   
