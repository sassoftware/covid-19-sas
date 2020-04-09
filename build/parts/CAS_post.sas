			%IF &CAS_LOAD=YES %THEN %DO;

				CAS;

				CASLIB _ALL_ ASSIGN;

				%IF &ScenarioIndex=1 %THEN %DO;

					/* ScenarioIndex=1 implies a new MODEL_FINAL is being built, load it to CAS, if already in CAS then drop first */
					PROC CASUTIL;
						DROPTABLE INCASLIB="CASUSER" CASDATA="MODEL_FINAL" QUIET;
						LOAD DATA=store.MODEL_FINAL CASOUT="MODEL_FINAL" OUTCASLIB="CASUSER" PROMOTE;
					QUIT;

				%END;
				%ELSE %DO;

					/* ScenarioIndex>1 implies new scenario needs to be apended to MODEL_FINAL in CAS */
					PROC CASUTIL;
						LOAD DATA=work.MODEL_FINAL CASOUT="MODEL_FINAL" APPEND;
					QUIT;

				%END;


				CAS CASAUTO TERMINATE;

			%END;
