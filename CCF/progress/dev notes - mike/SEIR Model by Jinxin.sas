/*Initial Population*/
%let pop0=11;
%let pop=%Sysevalf(&pop0.*1000000);
/*Rho=infection rate*/
%let min_Rho=1;
%let max_Rho=4;
%let stepsize_Rho=0.1;
/*Sigma: rate of latent individuals Exposed transported to the infectious stage each time period*/
%let min_Sigma=.3;
%let max_Sigma=.9;
%let stepsize_Sigma=.1;
/*WeeksOfRecovery*/
%let min_WOR=1;
%let max_WOR=6;
%let stepsize_WOR=1;
/*Initial Population in Each Compartment*/
%let E0=1;* Initial Number of Exposed;
%let I0=2;* Initial Number of Infected;
/*Forecast Lead*/
%let CurrentDate=01DEC2019;
%let ForecastHorizon=700;
data DInit(Label="Initial Coditions of Simulation"); 
    S = &pop.; 
    E = &E0.; 
    I = &I0.; 
    R = 0;
    N = &pop.; 
    Sigma=.9;
    do Sigma=&min_sigma. to &max_sigma. by &stepsize_sigma.;
        do Rho=&min_Rho. to &max_Rho. by &stepsize_Rho.;
            do WOR=&min_WOR. to &max_WOR. by &stepsize_WOR.;
                Gamma=1/(WOR*7);
                Beta = Rho*Gamma/N;
                do time = 1 to &ForecastHorizon; 
                    output; 
                end; 
            end;
        end;
    end;
run;
proc Tmodel data = DInit noprint;
    performance nthreads=4 bypriority=1 partpriority=0;
    /* Differential equations */ 
    dert.S = -Beta*S*I;                                         
    dert.E = Beta*S*I-Sigma*E;  
    dert.I = Sigma*E-Gamma*I;   
    dert.R = Gamma*I;           
    solve S E I R / out = SimEpi;
    by  Sigma Rho WOR;
quit;
libname datalib 'C:\Users\jinxyi\OneDrive - SAS\Covid-19';
proc sql;
    create table datalib.prediction as
        select Sigma,Rho,Gamma,S,E,I,R,Time
        from SimEpi
        order by Sigma,Rho,Gamma,Time;
quit;
data datalib.prediction;
    set datalib.prediction;
    format date date9.;
    date="&CurrentDate"d+time-1;
run;
