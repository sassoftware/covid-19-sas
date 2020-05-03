proc sql noprint;
	select name into :varlist separated by ', '
		from dictionary.columns
		where UPCASE(LIBNAME)="STORE" and upcase(memname)="MODEL_FINAL" and upcase(name) ne 'EVENTY_MULTIPLIER';
	create table temp2 as
		select * from
			(select &varlist from STORE.MODEL_FINAL) m1
			left join
			(
				select t1.ScenarioNameUnique, t1.ModelType, t1.Date,
						round(t1.EventY_Multiplier * t2.HOSPITAL_OCCUPANCY,1) as EventY_HOSPITAL_OCCUPANCY,
						round(t1.EventY_Multiplier * t3.ICU_OCCUPANCY,1) as EventY_ICU_OCCUPANCY,
						round(t1.EventY_Multiplier * t4.DIAL_OCCUPANCY,1) as EventY_DIAL_OCCUPANCY,
						round(t1.EventY_Multiplier * t5.ECMO_OCCUPANCY,1) as EventY_ECMO_OCCUPANCY,
						round(t1.EventY_Multiplier * t6.VENT_OCCUPANCY,1) as EventY_VENT_OCCUPANCY
				from
					(select ScenarioNameUnique, ModelType, Date, EventY_Multiplier from STORE.MODEL_FINAL) t1
					left join
					(select ScenarioNameUnique, ModelType, HOSPITAL_OCCUPANCY from store.Model_FINAL where PEAK_HOSPITAL_OCCUPANCY) t2
					on t1.ScenarioNameUnique=t2.ScenarioNameUnique and t1.ModelType=t2.ModelType
					left join
					(select ScenarioNameUnique, ModelType, ICU_OCCUPANCY from store.Model_FINAL where PEAK_ICU_OCCUPANCY) t3
					on t1.ScenarioNameUnique=t3.ScenarioNameUnique and t1.ModelType=t3.ModelType
					left join
					(select ScenarioNameUnique, ModelType, DIAL_OCCUPANCY from store.Model_FINAL where PEAK_DIAL_OCCUPANCY) t4
					on t1.ScenarioNameUnique=t4.ScenarioNameUnique and t1.ModelType=t4.ModelType
					left join
					(select ScenarioNameUnique, ModelType, ECMO_OCCUPANCY from store.Model_FINAL where PEAK_ECMO_OCCUPANCY) t5
					on t1.ScenarioNameUnique=t5.ScenarioNameUnique and t1.ModelType=t5.ModelType
					left join
					(select ScenarioNameUnique, ModelType, VENT_OCCUPANCY from store.Model_FINAL where PEAK_VENT_OCCUPANCY) t6
					on t1.ScenarioNameUnique=t6.ScenarioNameUnique and t1.ModelType=t6.ModelType
			) m2
		on m1.ScenarioNameUnique=m2.ScenarioNameUnique and m1.ModelType=m2.ModelType and m1.DATE=m2.DATE
	;
quit;




%macro test();

proc sql noprint;
select name into :varlist separated by ', '
	from dictionary.columns
	where UPCASE(LIBNAME)="STORE" and upcase(memname)="MODEL_FINAL" and upcase(name) ne 'EVENTY_MULTIPLIER';
create table test as select &varlist from store.MODEL_FINAL;
quit;

%mend;
%test;