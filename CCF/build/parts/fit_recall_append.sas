                    %IF &HAVE_SASETS = YES AND %SYMEXIST(ISOChangeDate1) %THEN %DO;
                        PROC APPEND base=store.FIT_PRED data=work.FIT_PRED; run;
                        PROC APPEND base=store.FIT_PARMS data=work.FIT_PARMS; run;
                    %END;