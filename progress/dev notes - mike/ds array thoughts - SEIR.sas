/* from paper */
data arrepi (keep=t s e i r);
	/* Parameter settings */
	N = 1000;
	R0 = 2;
	lat = 1; /* latent period */
	inf = 3; /* infectious period */
	alpha = 1/lat;
	gamma = 1/inf;
	beta = R0*gamma/N;

	array s_arr(60);
	array e_arr(60);
	array i_arr(60);
	array r_arr(60);

	do t = 1 to 60;
		/* Initial conditions */
		if t = 1 then do;
			s_arr(1) = 1000;
			e_arr(1) = 1;
			i_arr(1) = 1;
			r_arr(1) = 0;
		end;
		else do;
			s_arr(t) = s_arr(t-1)-beta*s_arr(t-1)*i_arr(t-1);
			e_arr(t) = e_arr(t-1)+beta*s_arr(t-1)*i_arr(t-1)-alpha*e_arr(t-1);
			i_arr(t) = i_arr(t-1)+alpha*e_arr(t-1)-gamma*i_arr(t-1);
			r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
		end;
		/* output the compartments */
		s = s_arr(t);
		e = e_arr(t);
		i = i_arr(t);
		r = r_arr(t);
		output;
	end; 
run;

/* thoughts on noise
	if t=1 then do;
		s_arr(1) = 1000;
		e_arr(1) = 1;
		i_arr(1) = 1;
		r_arr(1) = 0;
	end;
	else do;
		poicase = ranpoi(0, beta*s_arr(t-1)*i_arr(t-1));
		s_arr(t) = s_arr(t-1)-poicase;
		e_arr(t) = e_arr(t-1)+poicase-alpha*e_arr(t-1);
		i_arr(t) = i_arr(t-1)+alpha*e_arr(t-1)-gamma*i_arr(t-1);
		r_arr(t) = r_arr(t-1)+gamma*i_arr(t-1);
	end;
*/

/* CCF DS - sigma here is alpha above */
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

/* CCF TMODEL */
/*DATA FOR PROC TMODEL APPROACHES*/
DATA DINIT(Label="Initial Conditions of Simulation"); 
	S_N = &S. - (&I/&DIAGNOSED_RATE) - &R;
	E_N = &E;
	I_N = &I/&DIAGNOSED_RATE;
	R_N = &R;
	R0  = &R_T;
	DO TIME = 0 TO &N_DAYS; 
		OUTPUT; 
	END; 
RUN;

		%IF HAVE_V151 = YES %THEN %DO; PROC TMODEL DATA = DINIT NOPRINT; %END;
		%ELSE %DO; PROC MODEL DATA = DINIT NOPRINT; %END;
			/* PARAMETER SETTINGS */ 
			PARMS N &S. R0 &R_T. ; 
			GAMMA = &GAMMA.;
			SIGMA = &SIGMA;
			BETA = R0*GAMMA/N;
			/* DIFFERENTIAL EQUATIONS */ 
			/* a. Decrease in healthy susceptible persons through infections: number of encounters of (S,I)*TransmissionProb*/
			DERT.S_N = -BETA*S_N*I_N;
			/* b. inflow from a. -Decrease in Exposed: alpha*e "promotion" inflow from E->I;*/
			DERT.E_N = BETA*S_N*I_N-SIGMA*E_N;
			/* c. inflow from b. - outflow through recovery or death during illness*/
			DERT.I_N = SIGMA*E_N-GAMMA*I_N;
			/* d. Recovered and death humans through "promotion" inflow from c.*/
			DERT.R_N = GAMMA*I_N;           
			/* SOLVE THE EQUATIONS */ 
			SOLVE S_N E_N I_N R_N / OUT = TMODEL_SEIR; 
		RUN;
		QUIT;