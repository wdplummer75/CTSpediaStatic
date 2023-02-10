* Macro npar1way combines output from the univvariate macro with p-values for Kruskal-Wallis or Mann-Whitney tests and organizes the
  the output in a concise format.

  Inputs: 
		DSName = input SAS data set
		GroupVar = two or more level numeric or alphanumeric grouping variable.  Observations with missing values on 
					  this variable are deleted.
      Vars = list of numeric variables for analysis.  Shortcut lists OK.
      ByVars = options By variables.  Missing values on By variables define legitimate groups.  
      VarName = Y requests the name of each variable to appear in the output (default = Y)
      Label = Y requests the label for each dependent variable to appear in the output (default = N)
	   Dec = integer controls the number of decimal places shown in all output statistics except N and the P-Value. 
            (default = 3)
		Print = Y/N for printed output (default = Y)
		Out = output SAS data set.   Use NPar1wayPrint macro to print these data sets.

	Last modified: April, 2, 2008;

filename chkvar URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckVar.sas";
%include chkvar;
filename univar URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/Univariate.sas";
%include univar;
filename varlist URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/Varlist.sas";
%include varlist;
filename words URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;

* Macro FirstDot generates list of not(first.byvar) and not(first.byvar) and...;
%Macro KWFirstDot(NBy,ByVars);
   %do i = 1 %to &NBy;
      %Let OneBy = %scan(&ByVars,&i);
      not%str( )First%str(.)&OneBy%str( )
      %if &i < &NBy %then %do; and %end;
   %end;
%mend KWFirstDot;


%macro NPar1way(dsname=,GroupVar=,Vars=,ByVars=,Print=Y,VarName=Y,Label=N,Dec=3,Out=);

	%Local AnyKW AnyMW BadVar DSLabel GroupFmt GroupType I K NVars NBy OrigLongList Var Varlist;
	%Global _Error _LongList;

	%varlist(VLDsname=&dsname,ShortList=&Vars)						* This creates global macro variable _LongList;	
	%Let Vars = %str( )%upcase(%cmpres(&_LongList))%str( );
	%Let OrigLongList = &_LongList;
	
	%Let ByVars = %str( )%upcase(%cmpres(&Byvars))%str( );
	%Let Label = %upcase(&Label);
	%Let NVars = %words(&Vars);
	%Let NBy = %words(&Byvars);
	%Let VarName = %upcase(&varname);
	%Let Label = %upcase(&Label);
	%Let Print = %upcase(&Print);

	* Check that grouping variable, all dependent and by variables are in the data set;
	%Let Varlist = %upcase(%cmpres(&GroupVar%str( )&Vars%str( )&ByVars));
	%CheckVar(CVDSName=&DSName,CVVars=&Varlist,Message=Y)
	%if &_Error = 1 %then GoTo ExitNPar1way;
   
	* Check for alpha variables in the dependent list;
	%do K = 1 %to &NVars;
		%Let Var = %scan(&Vars,&K);
		data _null_;
		   set &dsname (obs = 1);
			Type = VType(&Var);
			if Type NE 'N' then
				do;
					Call Symput('BadVar',1);
					put '   ';
					put "Error: Variable &Var is a character variable.";
					put '   ';
				end;
		run;
		%if &BadVar = 1 %then %goto ExitNPar1way;
	%end;

	* Check that either Print = Y or there is an output data set;
	%if &Print ne Y and &out= %then
		%do;
			%put;
			%put Error: Print = N and no output data set specified.;
			%put;
			%goto ExitNPar1way;
		%end;

	* Create a a series of macro variables _DV1,_DV2,...,_DV&NVars that will be 1 if that variable is a date variable
	  otherwise 0.;
	data _null_;
  		set &dsname (obs = 1);
		%do i = 1 %to &NVars;
			%Let ThisVar = %scan(&Vars,&i);
			Fmt = VFormatN(&ThisVar);
			Call Symput("_DV&I",0);
			if Fmt in('DATE','NENGO','DDMMYY','JULIAN','MMDDYY','YYMMDD','WEEKDATE','WEEKDATX','WORDDATE','WORDDATX') then Call Symput("_DV&I",1);
		%end;
	run;
		
	* Store grouping variable type in GroupType and format in GroupFmt;
	data _null_;
	   set &dsname (obs = 1);
		Call Symput('GroupType',Vtype(&GroupVar));
		Call Symput('GroupFmt',VFormat(&GroupVar));
	run;

	proc format; value _nblnk . = ' ' other = [10.];
					 value _meanblnk . = ' ' other = [10.&Dec];
					 value _pfmt . = ' ' low-.00995 = [pvalue6.4] .00995-.0995 = [6.3] .0995-1 = [6.2];

	%if &GroupType = N %then
		%do;
			value _gpfmt . = ' ' other = [&GroupFmt];
		%end;
   run;

   * Delete missing values of grouping variables.  Allow by groups based on missing values;
   data _use;
      set &dsname;
		if missing(&GroupVar) then delete;		* missing function works for both alpha and numeric;
   run;

   proc sort data = _use; by &ByVars &GroupVar;
	%Univariate(dsname=_use,Vars=&OrigLongList,ByVars=&ByVars &GroupVar,Print=N,out=_utemp)

	ods listing close;
	* Cycle through the dependent variables doing one at a time and saving the P-value.  NPar1way is
	invoked one variable at a time otherwise one degenerate variable aborts all analyses.;
	proc datasets nolist; delete _allnpar; quit;
	%Let AnyKW = 0;											 * A value of 1 indicates at least one var had 3+ levels;
	%Let AnyMW = 0;											 * A value of 1 indicates at least one var had 2 levels;
	%do i = 1 %to &NVars; 
	   %Let Var = %Scan(&OrigLongList,&i);
		proc datasets nolist; delete _Wilcoxon _wil2; quit;
		proc npar1way wilcoxon data = _use; class &GroupVar; var &Var; by &ByVars;		* ok even if no by variables;
			output out = _wilcoxon;
      run;
		%if %sysfunc(exist(_wilcoxon)) %then
			%do;
				data _wil2 (Keep = Variable Prob_Wil &ByVars);
				   set _wilcoxon;
					Length Variable $ 32;
					Variable = upcase(_Var_);
					if p2_wil = . then 
						do;
							Prob_Wil = P_KW;
							Call Symput('AnyKW',1);
						end;
					else 
						do;
							Prob_Wil = p2_wil;
							Call Symput('AnyMW',1);
						end;
				run;
				proc append base = _allnpar data = _wil2 force;
				run;
			%end;
	%end;
		
	data _allnpar;
	   set _allnpar;
		Prob_WilAlpha = left(put(Prob_Wil,_pfmt.));
		%if &AnyKW = 0 and &AnyMW = 1 %then
			%do;
				label Prob_Wil = 'Mann-Whitney P-Value';
				label Prob_WilAlpha = 'Mann-Whitney P-Value';
			%end;
		%if &AnyKW = 1 and &AnyMW = 0 %then
			%do;
				label Prob_Wil = 'Kruskal-Wallis P-Value';
				label Prob_WilAlpha = 'Kruskal-Wallis P-Value';
			%end;
		%if &AnyKW = &AnyMW %then
			%do;
				Label Prob_Wil = 'Mann-Whitney/Kruskal-Wallis P-Value';
				Label Prob_WilAlpha = 'Mann-Whitney/Kruskal-Wallis P-Value';
			%end;
	run;

   data _utemp;
      set _utemp; by &ByVars &GroupVar;
		if first.&GroupVar then Order = 0;
		Order = Order + 1;
		retain order;
		Length Variable $ 32;
      Variable = upcase(Variable);
   run;

	proc sort data = _utemp; by &ByVars Variable &GroupVar;

   proc sort data = _allnpar; by &ByVars Variable;
   
   data _all;
      merge _utemp _allnpar (in = haskw); by &ByVars Variable;
		if haskw = 0 then do; Prob_Wil = .; end;
		if not first.Variable 
		%if &ByVars ne %then
		   %do;
			   and %kwfirstdot(&Nby,&ByVars)
			%end;
		then 
			do; 
				prob_wil = .; 
				prob_wilAlpha = '';
				label = ''; 
				Variable = '';
			end;
   run;
	proc sort data = _all; by &Byvars order &GroupVar;
	
	%if &out ne %then
		%do;
			%Let DSLabel = DSN=&dsname,GV=&GroupVar,Dec=&Dec;
			%if %Length(&DsLabel) > 256 %then
				%do;
					%put;
					%put WARNING: Length of output data set label > 256.  NPar1wayPrint may not function correctly.;
					%put;
				%end;
			data &out (Type = 'NP1' Label = "&DSLabel");
			   set _all;
			run;
		%end;
	data _all;
	   set _all; by &Byvars order &GroupVar;
		output;
		if last.order then
		   do;
				N = .; Mean = .; Median = .; SD = .; MedianLowerCL = .; MedianUpperCL = .; Min = .; Max = .;
				Prob_WilAlpha = ''; Label = ''; Variable = '';
				MeanAlpha = ''; SDAlpha = ''; MedianAlpha = ''; MedianLowerCLAlpha = ''; MedianUpperCLAlpha = '';
				MinAlpha = ''; MaxAlpha = '';
				%if &GroupType = N %then
					%do;
						&GroupVar = .;
					%end;
				%else
					%do;
						&GroupVar = '';
					%end;
				output;
			end;
	run;
	%if &Print = Y %then
		%do;
		   ods listing;
			proc print data = _all noobs uniform label; var N MeanAlpha SDAlpha MedianAlpha MedianLowerCLAlpha MedianUpperCLAlpha MinAlpha MaxAlpha Prob_WilAlpha; id
			%if &Varname = Y %then %do; Variable %end;
			%if &Label = Y %then %do; Label %end;
			&GroupVar;
			format N _nblnk. 
			%if &GroupType = N %then %do;	&GroupVar _gpfmt. %end;
			;
			%if &ByVars ne %then
			   %do;
				   by &ByVars;
				%end;
		   run;
		%end;
	%ExitNPar1way:
	proc datasets nolist; delete _all _allnpar _kw  _use _utemp _wt; quit; 

%mend npar1way;
