* EfectSizeMixed macro computes the effect sizes using a linear mixed-effect model.
  The macro compares the group means between two treatment conditions after adjust for 
  baseline values and covariates.

  The macro parameters are:

   MacroDir		  = directory where the macros and results are saved
   DSName         = name of SAS data set
   Outcome        = name of outcome variable.  
   Cluster		  = name of the variable to identify the cluster (e.g. ID, time, etc.)
   Treatment      = name of the variable to specify two cohorts
   NumFix   	  = name of the fixed effect continuous covariates
   ClassFix       = name of the fixed effect catigorical covariates 
   NumRandom   	  = name of the random effect continuous covariates
   ClassRandom    = name of the random effect catigorical covariates
   ResultsFormat  = rtf/html (default = rtf)
					format of the reults file
;
%macro EfectSizeMixed(MacroDir=,
					DSName=,
					Outcome=,
					Cluster=,
					Treatment=,
					NumFix=,
					ClassFix=,
					NumRandom=,
					ClassRandom=,
			   		ResultsFormat=html);

filename words URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;

%Let Treatment = %upcase(%cmpres(&Treatment));
%Let Cluster=%upcase(&Cluster);

* Counting the number of variables put in the Outcome;
%let Nout = %words(&Outcome);

proc datasets nolist; delete _alles; quit;
%do i = 1 %to &Nout;
	%Let Outi = %upcase(%scan(&Outcome,&i,%str( )));
	ods listing close;
	proc mixed data=&DSName covtest;
		class &ClassFix &Treatment &ClassRandom &Cluster;
		model &Outi = &Treatment &NumFix &ClassFix / s;
		random int &NumRandom &ClassRandom / type=un sub=&Cluster;
		lsmeans &Treatment;
		ods output LSMeans=_ls;
		ods output CovParms=_cp;
		ods output SolutionF=_sf;
	quit;

	data _null_;
		set _cp;
		if CovParm='Residual' then do;
			call symput('resvar',Estimate);
			call symput('resstderr',StdErr);
			end;
	run;

/*	data _null_;*/
/*		set _sf;*/
/*		if upcase(Effect)=upcase("&Treatment") and tValue ne . then call symput('Probt',Probt);*/
/*	run;*/
	ods listing close;
	proc means data=&DSName;
		class &Treatment;
		var &Outi;
		ods output Summary=_sum;
	run;

	data _mls;
		merge _ls _sum;
	run;

	proc transpose data=_mls out=_mls;
	run;

	data _null_;
		set _mls;
		if _name_='NObs' then 
			do;
				call symput('n1',col1);
				call symput('n2',col2);
			end;
		if _name_='Estimate' then 
			do;
				call symput('u1',col1);
				call symput('u2',col2);
			end;
		if _label_='Std Dev' then
			do;
				call symput('std1',col1);
				call symput('std2',col2);
			end;
	run;


	data input; 
		md = &u1 - &u2;           * mean diff btw group 1 and group 2; 
		mdvar = (1/&n1) * &std1*&std1 + (1/&n2) * &std2 * &std2; * var for mean diff; 
		resvar = &resvar;     * pooled var from PROC MIXED; 
		resstderr = &resstderr;      * std error for pooled var from PROC MIXED; 
		keep md mdvar resvar resstderr; 
	run; 

	proc iml workspace = 30000; 
		use input; 
		read all into m; 
		xi1          = m[1]; 
		mdvar        = m[2]; 
		xi2          = m[3]; 
		resstderr    = m[4]; 
		df1          = xi2##(-1/2);
		df2          = (-1/2) * xi1 * xi2##(-3/2); 
		df           = df1 // df2; 
		sigmaxi      = j(2,2,0); 
		sigmaxi[1,1] = mdvar; 
		sigmaxi[2,2] = resstderr * resstderr; 

		theta        = xi1 *  xi2##(-1/2);
		sigmatheta   = df` * sigmaxi * df; 

		out          = theta || sigmatheta; 
		*print xi1 mdvar xi2 resstderr theta sigmatheta;  

		create efdata from out;
		append from out;
		close  efdata;
	quit; 
	
	%let s_sq=((&n1-1)*&std1*&std1+(&n2-1)*&std2*&std2)/(&n1-1+&n2-1);

	data final;
		set efdata;
		Variable = "&Outi";
		WithoutI_m = &u1;
		WithoutI_std = &std1;
		Intervention_m = &u2;
		Intervention_std = &std2;
		es=col1;
/*		LCI=es-1.96*sqrt(col2);*/
/*		UCI=es+1.96*sqrt(col2);*/
/*		tvalue=(&u1-&u2)/(&s_sq*(1/&n1+1/&n2));*/
/*		pvalue=&Probt;*/
		drop col1 col2;
		label WithoutI_m='Without Intervention (Mean)'
				WithoutI_std='Without Intervention (STD)'
				Intervention_m = 'With Intervention (Mean)'
				Intervention_std = 'With Intervention (STD)'
				ES = 'Effect Size';
/*				tvalue='t Value'*/
/*		  		LCI = 'Lower 95% CI' */
/*		  		UCI = 'Upper 95% CI' */
/*				pvalue='p value';*/
	run;

	proc append base = _alles data = final force; run;
%end;

ods listing;
%if &ResultsFormat=rtf %then
%do;
	ods rtf file = "&MacroDir.\ResultOutput.rtf";
		
	proc print data=_alles label noobs;
	run;

	ods rtf close;
%end;

%if &ResultsFormat=htm %then
%do;
	ods html file = "&MacroDir.\ResultOutput.htm";
	
	proc print data=_alles label noobs;
	run;

	ods html close;
%end;


proc datasets nolist; 
	delete  _ls _sf _sum _mls _cp _oa final efdata input;
quit;

%mend EfectSizeMixed;

