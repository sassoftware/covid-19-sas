/* DS METHODS */
%LET N_DAYS = 365;
%LET DIAGNOSED_RATE = 1.0;
%LET S = 4390484;
%LET E = 0;
%LET I = 459.770114942528;
%LET R = 0;
%LET BETA = 5.013728017813E-8;
%LET BETA_DECAY = 0;
%LET SIGMA = 0.90;
%LET GAMMA = 0.07142857142857;
%LET IncubationPeriod = 0;
%LET DAY_ZERO = 13MAR2020;
%LET HOSP_RATE = 0.075;
%LET MARKET_SHARE = .29 ;
%LET HOSP_LOS = 7;

DATA DS_SEIR;
	DO DAY = 0 TO &N_DAYS;
		IF DAY = 0 THEN DO;
			S_N = &S - (&I/&DIAGNOSED_RATE) - &R;
			E_N = &E;
			I_N = &I/&DIAGNOSED_RATE;
			R_N = &R;
			BETA=&BETA;
			N = SUM(S_N, E_N, I_N, R_N);
		END;
		ELSE DO;
			BETA = LAG_BETA * (1- &BETA_DECAY);
			S_N = (-BETA * LAG_S * LAG_I) + LAG_S;
			E_N = (BETA * LAG_S * LAG_I) - &SIGMA * LAG_E + LAG_E;
			I_N = (&SIGMA * LAG_E - &GAMMA * LAG_I) + LAG_I;
			R_N = &GAMMA * LAG_I + LAG_R;
			N = SUM(S_N, E_N, I_N, R_N);
			SCALE = LAG_N / N;
			IF S_N < 0 THEN S_N = 0;
			IF E_N < 0 THEN E_N = 0;
			IF I_N < 0 THEN I_N = 0;
			IF R_N < 0 THEN R_N = 0;
			S_N = SCALE*S_N;
			E_N = SCALE*E_N;
			I_N = SCALE*I_N;
			R_N = SCALE*R_N;
		END;
		LAG_S = S_N;
		LAG_E = E_N;
		LAG_I = I_N;
		LAG_R = R_N;
		LAG_N = N;
		LAG_BETA = BETA;
		NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
		IF NEWINFECTED < 0 THEN NEWINFECTED=0;
        HOSP = NEWINFECTED * &HOSP_RATE * &MARKET_SHARE;
        CUMULATIVE_SUM_HOSP + HOSP;
        CUMADMITLAGGED=ROUND(LAG&HOSP_LOS(CUMULATIVE_SUM_HOSP),1) ;
        HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
        DATE = "&DAY_ZERO"D + DAY;
		OUTPUT;
    END;
RUN;

PROC SGPLOT DATA=DS_SEIR;
    SERIES X=DATE Y=HOSPITAL_OCCUPANCY / LINEATTRS=(THICKNESS=2);
    XAXIS LABEL="Date";
    YAXIS LABEL="Daily Occupancy";
RUN;

DATA DS_SEIR_SIM;
    call streaminit(2019);
    DO SIM = 1 to 100;
        DO DAY = 0 TO &N_DAYS;
            IF DAY = 0 THEN DO;
                S_N = &S - (&I/&DIAGNOSED_RATE) - &R;
                E_N = &E;
                I_N = &I/&DIAGNOSED_RATE;
                R_N = &R;
                BETA=&BETA;
                N = SUM(S_N, E_N, I_N, R_N);
            END;
            ELSE DO;
                BETA = LAG_BETA * (1- &BETA_DECAY);
                RV = RAND('POISson',BETA * LAG_S * LAG_I);
                S_N = (-RV) + LAG_S;
                E_N = (RV) - &SIGMA * LAG_E + LAG_E;
                I_N = (&SIGMA * LAG_E - &GAMMA * LAG_I) + LAG_I;
                R_N = &GAMMA * LAG_I + LAG_R;
                N = SUM(S_N, E_N, I_N, R_N);
                SCALE = LAG_N / N;
                IF S_N < 0 THEN S_N = 0;
                IF E_N < 0 THEN E_N = 0;
                IF I_N < 0 THEN I_N = 0;
                IF R_N < 0 THEN R_N = 0;
                S_N = SCALE*S_N;
                E_N = SCALE*E_N;
                I_N = SCALE*I_N;
                R_N = SCALE*R_N;
            END;
            LAG_S = S_N;
            LAG_E = E_N;
            LAG_I = I_N;
            LAG_R = R_N;
            LAG_N = N;
            LAG_BETA = BETA;

            DATE = "&DAY_ZERO"D + DAY;
            OUTPUT;
        END;
    END;
RUN;
DATA DS_SEIR_SIM;
	SET DS_SEIR_SIM;
            NEWINFECTED=LAG&IncubationPeriod(SUM(LAG(SUM(S_N,E_N)),-1*SUM(S_N,E_N)));
            IF NEWINFECTED < 0 THEN NEWINFECTED=0;
            HOSP = NEWINFECTED * &HOSP_RATE * &MARKET_SHARE;
            CUMULATIVE_SUM_HOSP + HOSP;
            CUMADMITLAGGED=ROUND(LAG&HOSP_LOS(CUMULATIVE_SUM_HOSP),1) ;
            HOSPITAL_OCCUPANCY= ROUND(CUMULATIVE_SUM_HOSP-CUMADMITLAGGED,1);
run;

PROC SGPLOT DATA=DS_SEIR_SIM;
    SERIES X=DATE Y=I_N / LINEATTRS=(THICKNESS=2) GROUP=SIM;
    XAXIS LABEL="Date";
    YAXIS LABEL="Daily Occupancy";
RUN;



/* PHARMASUG SIR METHODS */

data arrepi (keep=t s i r);
    /* Parameter settings */
    N = 1000;
    R0 = 1.4;
    inf = 3;
    gamma = 1/inf;
    beta = R0*gamma/N;
    array s_arr(90);
    array i_arr(90);
    array r_arr(90);
    do t = 1 to 90;
        /* initial conditions */
        if t = 1 then do;
            s_arr(1) = 1000;
            i_arr(1) = 1;
            r_arr(1) = 0;
        end;
        else do;
            s_arr(t) = s_arr(t-1)-beta*s_arr(t-1)*i_arr(t-1);
            i_arr(t) = i_arr(t-1)+beta*s_arr(t-1)*i_arr(t-1)-gamma*i_arr(t-1);
            r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
        end;
        /* output compartments */
        s = s_arr(t);
        i = i_arr(t);
        r = r_arr(t);
        output;
    end;
run;
PROC SGPLOT DATA=arrepi;
    SERIES X=t Y=i / LINEATTRS=(THICKNESS=2);
    XAXIS LABEL="Date";
    YAXIS LABEL="Daily Occupancy";
RUN;

data arrepi2 (keep=t s i r sim);
    call streaminit(2019);
    /* Parameter settings */
    N = 1000;
    R0 = 1.4;
    inf = 3;
    gamma = 1/inf;
    beta = R0*gamma/N;
    array s_arr(90);
    array i_arr(90);
    array r_arr(90);
    do sim = 1 to 100;
	    do t = 1 to 90;
	        /* initial conditions */
	        if t = 1 then do;
	            s_arr(1) = 1000;
	            i_arr(1) = 1;
	            r_arr(1) = 0;
	        end;
	        else do;
	            poicase = rand('POISson', beta*s_arr(t-1)*i_arr(t-1));
				*poicase = ranpoi(0,beta*s_arr(t-1)*i_arr(t-1));
	            s_arr(t) = s_arr(t-1)-poicase;
	            i_arr(t) = i_arr(t-1)+poicase-gamma*i_arr(t-1);
	            r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
	        end;
	        /* output compartments */
	        s = s_arr(t);
	        i = i_arr(t);
	        r = r_arr(t);
	        output;
	    end;
    end;
run;
PROC SGPLOT DATA=arrepi2;
    SERIES X=t Y=i / LINEATTRS=(THICKNESS=2) group=sim;
    XAXIS LABEL="Date";
    YAXIS LABEL="Daily Occupancy";
RUN;


/* PHARMASUG SEIR METHODS */

data arrepi3 (keep=t s e i r);
    /* Parameter settings */
    N = 1000;
    R0 = 1.4;
    lat = 1;
    inf = 3;
    alpha = 1/lat;
    gamma = 1/inf;
    beta = R0*gamma/N;
    array s_arr(90);
    array e_arr(90);
    array i_arr(90);
    array r_arr(90);
    do t = 1 to 90;
        /* initial conditions */
        if t = 1 then do;
            s_arr(1) = 1000;
            e_arr(1) = 1;
            i_arr(1) = 1;
            r_arr(1) = 0;
        end;
        else do;
            *s_arr(t) = s_arr(t-1)-beta*s_arr(t-1)*i_arr(t-1);
            *i_arr(t) = i_arr(t-1)+beta*s_arr(t-1)*i_arr(t-1)-gamma*i_arr(t-1);
            *r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
            s_arr(t) = s_arr(t-1)-beta*s_arr(t-1)*i_arr(t-1);
            e_arr(t) = e_arr(t-1)+beta*s_arr(t-1)*i_arr(t-1)-alpha*e_arr(t-1);
            i_arr(t) = i_arr(t-1)+alpha*e_arr(t-1)-gamma*i_arr(t-1);
            r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
        end;
        /* output compartments */
        s = s_arr(t);
        e = e_arr(t);
        i = i_arr(t);
        r = r_arr(t);
        output;
    end;
run;
PROC SGPLOT DATA=arrepi3;
    SERIES X=t Y=i / LINEATTRS=(THICKNESS=2);
    XAXIS LABEL="Date";
    YAXIS LABEL="Daily Occupancy";
RUN;

data arrepi4 (keep=t s e i r sim);
    call streaminit(2019);
    /* Parameter settings */
    N = 1000;
    R0 = 1.4;
    lat = 1;
    inf = 3;
    alpha = 1/lat;
    gamma = 1/inf;
    beta = R0*gamma/N;
    array s_arr(90);
    array e_arr(90);
    array i_arr(90);
    array r_arr(90);
    do sim = 1 to 100;
        do t = 1 to 90;
            /* initial conditions */
            if t = 1 then do;
                s_arr(1) = 1000;
                e_arr(1) = 1;
                i_arr(1) = 1;
                r_arr(1) = 0;
            end;
            else do;
	            poicase = rand('POISson', beta*s_arr(t-1)*i_arr(t-1));
                s_arr(t) = s_arr(t-1)-poicase;
                e_arr(t) = e_arr(t-1)+poicase-alpha*e_arr(t-1);
                i_arr(t) = i_arr(t-1)+alpha*e_arr(t-1)-gamma*i_arr(t-1);
                r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
            end;
            /* output compartments */
            s = s_arr(t);
            e = e_arr(t);
            i = i_arr(t);
            r = r_arr(t);
            output;
        end;
    end;
run;
PROC SGPLOT DATA=arrepi4;
    SERIES X=t Y=i / LINEATTRS=(THICKNESS=2) group=sim;
    XAXIS LABEL="Date";
    YAXIS LABEL="Daily Occupancy";
RUN;


