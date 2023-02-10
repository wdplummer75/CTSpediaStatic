* ESMacro computes the average effect sizes on the longitudinal data structure.
  The macro compares the group means between two treatment conditions w/o adjusting for 
  baseline values and covariates.

  The macro parameters are:

   MacroDir		  = directory where the macros and results are saved
   DSName         = name of SAS data set
   ID			  = name of the variable for object ID
   Outcome        = name of outcome variable.  This variable is case-sensitive. the input 
					variable must match the variable name in the dataset exactly 
   TimeSeq        = name of the time sequence variable. if the data is not longitudinal, leave 
					it blank 
   Treatment      = name of the variable to specify two cohorts
   CovariateNum   = name of the continuous covariates
   CovariateClass = name of the catigorical covariates 
   AdjustTimeBase = Y/N (default = N)
					Y: adjust for the value of outcome variable at TimeSeq = 0
					   when AdjustTimeBase = Y, the value of timeseq >=0
					N: do not adjust for the value of outcome variable at time 0
					   when AdjustTimeBase = N, the value of timeseq >=0
   ResultsFormat  = rtf/html (default = rtf)
					format of the reults file

The macros called by this macro are %EffectSize, %checkvar, %words;


%macro ESMacro(MacroDir=,
			   DSName=one,
			   ID=ID,
			   Outcome=,
			   TimeSeq=,
			   Treatment=,
			   CovariateNum=,
			   CovariateClass=,
			   AdjustTimeBase=N,
			   ResultsFormat=rtf);



filename words URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;
filename CheckD URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%include CheckD;
filename ES URL "http://ctspedia.org/twiki/pub/CTSpedia/EffectSizeLongitudinalEx/EffectSize.sas";
%include ES;

* Check that the ID, Outcome,TimeSeq, Treatment and all variables in the CovariateNum and CovariateClass
  lists are in the data set;
%Let VarList = %cmpres(&ID%str( )&Outcome%str( )&TimeSeq%str( )&Treatment%str( )&CovariateNum%str( )&CovariateClass);
%if %CheckData(&DSName,Y) %then %Do;


* Check that Outcome is not in the CovariateNum and CovariateClass lists;
%if %index(%upcase(%str( )&CovariateNum%str( )&CovariateClass%str( )),%upcase(&Outcome)) > 0 %then
%do;
	%put;
	%put Error: Outcome variable cannot be in the list of CovariateNum or CovariateClass.;
	%put;
	%goto ExitESMacro;
%end;

* Check that TimeSeq is not in the CovariateNum and CovariateClass lists;
%if %index(%upcase(%str( )&CovariateNum%str( )&CovariateClass%str( )),%upcase(&TimeSeq)) > 0 %then
%do;
	%put;
	%put Error: TimeSeq variable cannot be in the list of  CovariateNum or CovariateClass.;
	%put;
	%goto ExitESMacro;
%end;

* Check that Treatment is not in the CovariateNum and CovariateClass lists;
%if %index(%upcase(%str( )&CovariateNum%str( )&CovariateClass%str( )),%upcase(&Treatment)) > 0 %then
%do;
	%put;
	%put Error: Treatment variable cannot be in the list of  CovariateNum or CovariateClass.;
	%put;
	%goto ExitESMacro;
%end;


%Let NumVars = %cmpres(&Outcome%str( )&CovariateNum);
%let NNum = %words(&NumVars);

* Check that the CovariateClass are not in the NumVars list;
%do i = 1 %to &NNum;
   	%Let TestVar = %scan(&NumVars,&i);
	%Let K = %Index(&CovariateClass,&TestVar);
	%if &K > 0 
	%then
      	%do;
         	%put;
         	%put Error: CovariateClass variables cannot be in the list of CovariateNum.;
         	%put;
         	%goto ExitESMacro;
      	%end;
%end;

* Check that variables in the NumVars list are in fact numeric;
%do i = 1 %to &NNum;
	%Let TestVar = %scan(&NumVars,&i);
	data _null_;
		set &dsname (obs = 1);
		VarType = Vtype(&TestVar);             
		call symput('VarType',VarType);
	run;
	%if &VarType ne N %then
	%do;
		%put;
		%put Error: Variable &TestVar is not numeric.;
		%put;
		%goto ExitESMacro;
	%end;
%end;

* Check that each of these numeric predictors has more than two levels.;
%if &NNum > 0 %then
%do i = 1 %to &NNum;
	%Let ThisVar = %scan(&NumVars,&i);
	proc freq noprint data = &dsname; 
		tables &ThisVar / out=_counts;
	run;
	data _null_;
		set _counts (obs = 1) nobs = last;
		call symput('NObs',Last);
	run;
	%if &NObs <= 2 %then 
	%do; 
		%put;
		%put Error: Continuous variables should have more than two levels.;
		%put;
		%goto ExitESMacro;
	%end;
%end;


%EffectSize(DSName=&DSName,
			ID=&ID,
			Outcome=&Outcome,
			TimeSeq=&TimeSeq,
			Treatment=&Treatment,
			CovariateNum=&CovariateNum,
			CovariateClass=&CovariateClass,
			AdjustTimeBase=&AdjustTimeBase);

ods listing;
%if &ResultsFormat=rtf %then
%do;
	ods rtf file = "&MacroDir.\ResultOutput.rtf";

	proc print data=_alles label noobs;;
		var Source Time ES LCI UCI ProbF;
		label ES = 'Effect Size'
			  Time = 'Time Sequence'
			  ProbF = 'P-Value' 
			  LCI = 'Lower 95% CI' 
			  UCI = 'Upper 95% CI' ;
		title1 "Effect Size of &Treatment";
	run;

	ods rtf close;
%end;

%if &ResultsFormat=htm %then
%do;
	ods html file = "&MacroDir.\ResultOutput.htm";

	proc print data=_alles label noobs;;
		var Source Time ES LCI UCI ProbF;
		label ES = 'Effect Size'
			  Time = 'Time Sequence'
			  ProbF = 'P-Value' 
			  LCI = 'Lower 95% CI' 
			  UCI = 'Upper 95% CI' ;
		title1 "Effect Size of &Treatment";
	run;

	ods html close;
%end;
%end;

%ExitESMacro:
	proc datasets nolist; delete _alles ; quit;
%mend ESMacro;
