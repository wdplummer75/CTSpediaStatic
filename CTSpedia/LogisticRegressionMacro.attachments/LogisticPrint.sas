* Macro LogisticPrint is designed to print an output data set created by the logistic macro.
  This data set may contain multiple models.  If all values of PQuad, PType3 or FreqPct are missing (for example, if 
  Quad=N was used in the logistic call or if there are no 3+ level categorical variables), then
  these columns are not printed.  If the models involve more than one outcome variable, the label for the
  Frequency/Percent column is generic and By group identifiers are used to identify the outcome variable.  Note that
  in these cases the form of the Frequency/Percent column label (F or P or FP) is taken from the first model, so
  all models should use the same Include option.

  The macro parameters are:

		Dsname = name of data set created by logistic macro
		Space = Y/N.  If Y, then a space is inserted after each variable.  Spaces are always inserted after
				  each model  (Default = Y);

%macro LogisticPrint(dsname=,Space=Y);

	%Local BadData FreqPctPresent PQuadPresent PType3Present;

	%Let Space = %upcase(&Space);
	* Check that data set is the right type;
	%Let BadData = 0;
	proc contents noprint data = &dsname out = _check; run;
	data _null_;
	   set _check (obs = 1);
		if typemem ne 'LOGISTIC' then
			do;
				put;
				put "Error: Dataset &dsname was not created by the logistic macro.";
				put;
				call Symput('BadData',1);
			end;
	run;
	%if &BadData = 1 %then %goto ExitLogisticPrint;

	* Look for any non-missing values for PQuad, PType3, or FreqPct. Also look for multiple outcomes.;
	data _null_;
	   set &dsname end = done;
		if _n_ = 1 then do; PQuadPresent = 0; PType3Present = 0; FreqPctPresent = 0; SaveOutcome = Dependent; OneOutcome = 1; end;
		retain PQuadPresent PType3Present FreqPctPresent SaveOutcome;
		if PQuad ne . then PQuadPresent = 1;
		if PType3 ne . then PType3Present = 1;
		if FreqPct ne '' then FreqPctPresent = 1;
		if Dependent ne SaveOutcome then OneOutcome = 0;
		if done then
			do;
				Call Symput('PQuadPresent',PQuadPresent);
				call Symput('PType3Present',PType3Present);
				Call Symput('FreqPctPresent',FreqPctPresent);
				Call Symput('OneOutcome',OneOutcome);
			end;
	run;
	* Figure out whether Include was F, P or FP based on the label for FreqPct.  While we can deal with
	  multiple outcome variables, we will assume that the choice of F, P, or FP is the same for all
	  outcome variables.;
	data _null_;
	   set &dsname (obs = 1);
		Length Test $ 200 Include $ 2;
		Test = vLabel(FreqPct);
		HasF = 0; 
		HasP = 0;
		if index(Test,'/') > 0 then HasF = 1;
		if index(Test,'%') > 0 then HasP = 1;
		if HasF = 1 and HasP = 0 then Include = 'F';
		if HasF = 0 and HasP = 1 then Include = 'P';
		if HasF = 1 and HasP = 1 then Include = 'FP';
		call symput('Include',Include);
	run;

	
	* Add blank observations between variables and between models;
	proc sort data = &dsname; by model orderbetween orderwithin;
	data _expand;
		set &dsname; by model orderbetween;
		if not(first.model) then model = .;
		%if &OneOutcome = 0 %then
			%do;
				%if &Include = F %then %do; label FreqPct = '# Outcome = 1/# subgroup'; %end;
				%if &Include = P %then %do; label FreqPct = '% Outcome = 1'; %end;
				%if &Include = FP %then %do; label FreqPct ='# Outcome = 1/# subgroup(% Outcome = 1)'; %end;
			%end;				
		output;
		%if &Space = Y %then
			%do;
				if last.model or (last.OrderBetween and not(last.model)) then
			%end;
		%else
			%do;
				if last.model then
			%end;
			do;
				OddsRatioAlpha = '';
				LowerCLAlpha = '';
				UpperCLAlpha = '';
				ProbChisqAlpha = '';
				PQuadAlpha = '';
				P3Alpha = '';
				FreqPct = '';
				Variable = '';
				Value = '';
				Model = .;
				output;
			end;
	run;

	ods listing;
	proc format; value _missint . = ' ' other = [3.];
	proc print data = _expand label uniform; var OddsRatioAlpha LowerCLAlpha UpperCLAlpha ProbChiSqAlpha
	%if &PQuadPresent = 1 %then %do; PQuadAlpha %end;
	%if &PType3Present = 1 %then %do; P3Alpha %end;
	;
   id Model Variable Value 
	%if &FreqPctPresent = 1 %then %do; FreqPct %end;
	; format model _missint.;
	%if &OneOutcome = 0 %then %do; by Dependent notsorted; %end;
	run;
	%ExitLogisticPrint:
	proc datasets nolist; delete _check _expand; quit; 

%mend LogisticPrint;
