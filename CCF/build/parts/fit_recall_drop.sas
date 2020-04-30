                        %IF &HAVE_SASETS = YES AND %SYMEXIST(ISOChangeDate1) %THEN %DO;
                            drop table work.FIT_PRED;
                            drop table work.FIT_PARMS;
                        %END;