/* 
This creates an HTML file from the output of (possibly multiple calls of) the Logistic macro.
Hyperlinks to explanations of column headings and some rows are given, making the file suitable
for providing to clients and collaborators who might otherwise have trouble understanding the
output without explanations.
This was modeled on the LogisticPrint macro.
*/

%macro LogisticHtml(dsname=,Space=Y,results=, filename=,mytitle =);

	proc datasets nolist; delete _check _expand; quit; 

	%Local BadData FreqPctPresent PQuadPresent PType3Present;

	%let modelurl=http://ctspedia.org/do/view/CTSpedia/ModelNumber;
	%let Variableurl=http://ctspedia.org/do/view/CTSpedia/VariableColumn;
	%let Valueurl=http://ctspedia.org/do/view/CTSpedia/ValueColumn;
	%let freqpcturl=http://ctspedia.org/do/view/CTSpedia/CountsInOutput;
	%let ORAlphaurl= http://ctspedia.org/do/view/CTSpedia/OddsRatio;
	%let CLAlphaurl= http://ctspedia.org/do/view/CTSpedia/ConfidenceIntervals;
	%let Pvalphaurl= http://ctspedia.org/do/view/CTSpedia/PValues;
	%let PQuadAlphaurl= http://ctspedia.org/do/view/CTSpedia/QuadraticPvalue;
	%let P3Alphaurl=http://ctspedia.org/do/view/CTSpedia/Type3Pvalue;
	 %let RescaledPredurl=http://ctspedia.org/do/view/CTSpedia/RescaledPredictors;
	%let LogisticOutcomeurl=http://ctspedia.org/do/view/CTSpedia/LogisticOutcome;
	%let logLRurl=http://ctspedia.org/do/view/CTSpedia/LogLikelihood;
	%let HRTesturl=http://ctspedia.org/do/view/CTSpedia/HosmerLemeshowTest;	

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
	%if &BadData = 1 %then %goto ExitLogisticHtml;

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
	data _expand ;
		set &dsname; by model orderbetween;
		if not(first.model) then model = .;
		%if &OneOutcome = 0 %then
			%do;
				%if &Include = F %then %do; label FreqPct = '# Outcome = 1/# subgroup'; %end;
				%if &Include = P %then %do; label FreqPct = '% Outcome = 1'; %end;
				%if &Include = FP %then %do; label FreqPct ='# Outcome = 1/*# subgroup*(% Outcome = 1)'; %end;
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

	data _expand2;
		set _expand;
		if orderbetween<3000 and variable='' and ProbChiSq=. then delete;
	run; 
	data _expand3;
		set _expand2 end=EOF;
		lines+1;
		if lines>16 then do;
			pagen+1;
			lines=0;
		end;
		page=pagen+1;
		if EOF then call symput('totalpages',left(put(page,3.)));
		label page='page #';
	run; 

	ods listing;
	proc format; value _missint . = ' ' other = [3.];
	ods listing close;
	ods html file="&results\&filename..html" style=sasweb;
	title "&mytitle";
	
	proc report data=_expand3  nowindows headline split='*' 
		style(header)=[font_weight=bold just=center  background=white];
		column page Model Variable value %if &FreqPctPresent = 1 %then %do; FreqPct %end; OddsRatioAlpha LowerCLAlpha UpperCLAlpha ProbChiSqAlpha %if &PQuadPresent = 1 %then %do; PQuadAlpha %end;
		%if &PType3Present = 1 %then %do; P3Alpha %end; ;
		define page/order order=internal  noprint ;
		define model/analysis format= _missint. style(column)={just=center }  style(header)=[just=center foreground=blue cellwidth= 1 in url="&modelurl"];
		define  Variable/display style(header)=[ cellwidth= 2 in url="&Variableurl"];
		define  Value/display  style(header)=[foreground=blue cellwidth= 2.5 in url="&Valueurl"];
		define OddsRatioAlpha/ display " Odds * Ratio " style(column)={just=center  cellwidth= 1 in} style(header)=[ foreground=blue cellwidth= 1 in  url="&ORAlphaurl"];
		define LowerCLAlpha/display  " Lower * 95% CI " style(column)={just=center  cellwidth= 1 in} style(header)=[ foreground=blue cellwidth= 1 in url="&CLAlphaurl"];
		define UpperCLAlpha/display " Upper * 95% CI " style(column)={just=center  cellwidth= 1 in} style(header)=[foreground=blue cellwidth= 1 in   url="&CLAlphaurl"];
		define ProbChiSqAlpha/display style(column)={just=center  cellwidth= 1 in} style(header)=[ cellwidth= 1 in   url="&Pvalphaurl"];
		%if &FreqPctPresent = 1 %then %do; 
				define freqpct/display  style(column)={just=center } style(header)=[cellwidth=2 in url="&freqpcturl"];
		%end;
	
		%if &PQuadPresent = 1 %then %do; 	
			define PQuadAlpha/display 'Quadratic*P-Value' style(column)={just=center  cellwidth= 1 in} style(header)=[cellwidth= 1 in  url="&PQuadAlphaurl"];
			compute PQuadAlpha;
				if ''< PQuadAlpha< '0.05' or index(P3Alpha,'<')>0 then 
					call define(_col_, "style", "style=[font_weight=bold background=red]");
			endcomp;
			%end;
		%if &PType3Present = 1 %then %do; 
			define P3Alpha/display 'Type 3*P-Value' style(column)={just=center  cellwidth= 1 in} style(header)=[cellwidth= 1 in  url="&P3Alphaurl"];
			compute P3Alpha;
				if ''< P3Alpha< '0.05' or index(P3Alpha,'<')>0 then call define(_col_, "style", "style=[font_weight=bold background=pink]");
			endcomp;
		%end;
		compute Variable ;
		 	href="&RescaledPredurl";
			href2="&LogisticOutcomeurl";
			href3="&logLRurl";
			href4="&HRTesturl";
			if index(variable,'(per 10 units)')>0 then  call define(_col_, "URLP", href);
			if index(variable, 'Outcome')>0 then call define(_col_,"URLP", href2);
			if index(variable,'-2 Log L')>0 then call define(_col_,"URLP", href3);
			if index(variable,'H-L Test')>0 then call define(_col_,"URLP", href4);
	    endcomp;
		compute ProbChiSqAlpha;
			if (''< ProbChiSqAlpha< '0.05' or index(ProbChiSqAlpha,'<')>0) and index(variable,'H-L Test')>0 
					then do;
					call define(_col_, "style", "style=[font_weight=bold background=red]");
			end;
			if (''< ProbChiSqAlpha< '0.05' or index(ProbChiSqAlpha,'<')>0) and index(variable,'H-L Test')=0 then do;
					call define('OddsRatioAlpha', "style", "style=[font_weight=bold background=pink]");
					call define('LowerCLAlpha', "style", "style=[font_weight=bold background=pink]");
					call define('UpperCLAlpha', "style", "style=[font_weight=bold background=pink]");
					call define('ProbChiSqAlpha', "style", "style=[font_weight=bold background=pink]");
			end;	

		endcomp;				
		break after page /suppress page;
		compute before _page_/right;
			_page+1;			
			line   _page ;
		endcomp;
		compute after _page_/left;
			line "Pink cells indicate effects with p<0.05"; 
			line "Red cells indicate evidence for violations of model assumptions.";
		endcomp;
	run; 
	ods html close;
	ods listing;
	%ExitLogisticHtml:

%mend LogisticHtml;

