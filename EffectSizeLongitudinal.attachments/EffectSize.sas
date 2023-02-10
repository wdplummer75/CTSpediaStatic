* EffectSize macro computes the average effect sizes on the longitudinal data structure.
  The macro compares the group means between two treatment conditions w/o adjusting for 
  baseline values and covariates.

  The macro parameters are:

   DSName         = name of SAS data set
   ID			  = name of the variable for object ID
   Outcome        = name of outcome variable.  This variable is case-sensitive. the input 
					variable must match the variable name in the dataset exactly 
   TimeSeq        = name of the time sequence variable. if the data is not longitudinal, leave 
					it blank 
   Treatment      = name of the variable to specify two cohorts
   CovariateNum   = name of the continuous covariates
   CovariateClass = name of the catigorical covariates 
   AdjustTimeBase = Y/N
					Y: adjust for the value of outcome variable at TimeSeq = 0
					   when AdjustTimeBase = Y, the value of timeseq >=0
					N: do not adjust for the value of outcome variable at time 0
					   when AdjustTimeBase = N, the value of timeseq >=0
;

%macro EffectSize(DSName=,
					ID=,
					Outcome=,
					TimeSeq=,
					Treatment=,
					CovariateNum=,
					CovariateClass=,
					AdjustTimeBase=Y);

%Let Treatment = %upcase(%cmpres(&Treatment));
%Let TimeSeq=%upcase(&TimeSeq);

ods listing close;

%if &TimeSeq>0 %then 
%do;
	proc sort data=&DSName;
		by &ID &TimeSeq; 
	run;

	data data1;
		set &DSName;
		by &ID &TimeSeq; 
		retain _bas;
		if first.&ID then _bas=.;
		if &TimeSeq=0 then _bas=&Outcome;
		if &TimeSeq>0 then output;
	run;

	proc freq data=data1;
		tables &TimeSeq / out=_counts;
	run;

	data _null_;
	    set _counts nobs = last;
		call symput('NObs',Last);
	run;


	proc datasets nolist; delete _alles; quit;
	%do i = 1 %to &NObs;
		data _counts;
			set _counts;
			if _n_=&i then call symput('ttime',&TimeSeq);
		run;
		%if &AdjustTimeBase=Y %then 
		%do;
			proc glm data=data1;
				where &TimeSeq = &ttime;
				class &CovariateClass &Treatment;
				model &Outcome = &Treatment &CovariateNum &CovariateClass _bas ;
				lsmeans &Treatment;
				means &Treatment;
				ods output OverallANOVA=_oa;
				ods output LSMeans=_ls;
				ods output Means=_means;
				ods output ModelANOVA=_manova;
			quit;
		%end;
		%else
		%do;
			proc glm data=data1;
				where &TimeSeq = &ttime;
				class &CovariateClass &Treatment;
				model &Outcome = &Treatment &CovariateNum &CovariateClass;
				lsmeans &Treatment;
				means &Treatment;
				ods output OverallANOVA=_oa;
				ods output LSMeans=_ls;
				ods output Means=_means;
				ods output ModelANOVA=_manova;
			quit;
		%end;

		data _final;
			set _manova;
			keep Source ProbF;
			if upcase(Source)=upcase("&Treatment");
		run;


		data _null_;
			set _oa;
			if Source='Error' then call symput('ms',ms);		
		run;

		data _null_;
			set _manova;
			if HypothesisType=3 then call symput('probf',ProbF);		
		run;

		data _merge;
			merge _ls _means;
			by Effect;
		run;

		proc transpose data=_merge out=_merge1;
		run;

		%let lsm=LSMean;
		%Let outcomels = &outcome&lsm;


		data _null_;
			set _merge1;
			if upcase(_name_)=upcase("&outcomels") then 
				do;
					call symput('u1',col1);
					call symput('u2',col2);
				end;
			if _name_='N' then
				do;
					call symput('n1',col1);
					call symput('n2',col2);
				end;
		run;

		data _final1;
			set _final (obs=1);
			Time=&ttime;
			ES=abs(&u1-&u2)/sqrt(&ms);
			LCI=ES-1.96*sqrt(1/&n1+1/&n2);
			UCI=ES+1.96*sqrt(1/&n1+1/&n2);
			ProbF=&probf;
		run;

		proc append base = _alles data = _final1 force; run;
	%end;

	proc means data=_alles noprint;
		output out=_mES;
	run;
	data _null_;
		set _mES;
		if _stat_='MEAN' then 
		do;
			call symput('mES',ES);
			call symput('mLCI',LCI);
			call symput('mUCI',UCI);
			call symput('mProbF',ProbF);
		end;
	run;

	data _final1;
		set _final1;
		Source='Average';
		ES=&mES;
		Time=.;
		LCI=&mLCI; 
		UCI=&mUCI; 
		ProbF=&mProbF;
	run;
	proc append base = _alles data = _final1 force; run;
%end;
%else 
%do;
	proc glm data=&DSName;
		class &CovariateClass &Treatment;
		model &Outcome = &Treatment &CovariateNum &CovariateClass;
		lsmeans &Treatment;
		means &Treatment;
		ods output OverallANOVA=_oa;
		ods output LSMeans=_ls;
		ods output Means=_means;
		ods output ModelANOVA=_manova;
	quit;

	data _final;
		set _manova;
		keep Source ProbF;
		if Source="&Treatment";
	run;


	data _null_;
		set _oa;
		if Source='Error' then call symput('ms',ms);		
	run;

	data _null_;
		set _manova;
		if HypothesisType=3 then call symput('probf',ProbF);		
	run;

	data _merge;
		merge _ls _means;
		by Effect;
	run;

	proc transpose data=_merge out=_merge1;
	run;

	%let lsm=LSMean;
	%Let outcomels = &outcome&lsm;

	data _null_;
		set _merge1;
		if upcase(_name_)=upcase("&outcomels") then 
			do;
				call symput('u1',col1);
				call symput('u2',col2);
			end;
		if _name_='N' then
			do;
				call symput('n1',col1);
				call symput('n2',col2);
			end;
	run;

	data _alles;
		set _final (obs=1);
		ES=abs(&u1-&u2)/sqrt(&ms);
		LCI=ES-1.96*sqrt(1/&n1+1/&n2);
		UCI=ES+1.96*sqrt(1/&n1+1/&n2);
		ProbF=&probf;
	run;

%end;


proc datasets nolist; 
	delete _counts _ls _manova _means _merge _merge1 _oa _final _final1 _mES;
quit;

%mend EffectSize;

