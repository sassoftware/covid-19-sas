data temp;
	do a=1 to 3;

		do i=1 to 10;
			output;
		end;
	end;
run;

%let goal=3;

data temp;
	set temp;
	retain count;
	by a;
	x=lag&goal.(i);
	if first.a then do;
		count=1;
	end;
	else do;
		count+1;
	end;
	if count<=&goal. then do;
		x=.;
	end;
	put a i x;
run;