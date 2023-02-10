*  Macro univariate is a revision of the univsum macro.  Positional macro parameters have
   been eliminated and p-value formatting has been added.  Note that the variable names
   in the output file (which dated from the days of 8 character limitations) have been 
   changed.  See below.

	Macro parameters are:
	Dsname = name of SAS data set
   Vars = numeric variables to be summarized (short-cut lists ok)
   ByVars = names of any By variable.  Data should be sorted on the By variables before
            calling this macro
	Print = Y/N. If Y, then the Show parameter specifies which statistics are output. 
           Default = Y.
	Label = Y/N.  If Y, then the label option is added to proc print.  This parameter
           is not relevent if Print = N.  Default = Y.
   Show = statistics chosen from the following list separated by blanks.  The statistics
          will be printed in the order specified.
			N			Sample size
			MN			Mean
			SD			Standard deviation
			MNCI		Lower and upper confidence limits for the mean
			Q1			25th percentile
			MD or Q2	50th percentile
			Q3			75th percentile
			MDCI		Lower and upper confidence limits for the median
			MIN		Minimum
			MAX		Maximum
			PW			Wilcoxon signed-ranks p-value
			PT			One sample t p-value
			PN			Normality p-value
			Default statistics are N MN SD MD MDCI MIN MAX.
	ID = VAR will put the variable name in the proc print ID statement
        LAB will put the variable label in the proc print ID statement
		  VAR LAB puts both name and label in the ID statement.  This parameter is not
        relevent if Print = N. Default = VAR.
   Dec = Number of decimals to show in non-integer statistics other than p-values.
         Does not apply to date variable.  Default = 2
	OUT = name of SAS data set containing summary statistics.
			The variables in this data set are:
			Variable					Alpha variable containing variable name
			Label						Alpha variable containing variable label
			N							Sample size
			Mean						Mean
		   MeanAlpha				Mean formatted to Dec decimals
			SD							Standard deviation
			SDAlpha					Standard deviation formatted to Dec decimals
			MeanLowerCL 			Lower confidence limit for mean
         MeanLowerCLAlpha		Lower confidence limit for mean formatted to Dec decimals
			MeanUpperCL				Upper confidence limit for mean
			MeanUpperCLAlpha		Upper confidence limit for mean formatted to Dec decimals
			Q1							25th percentile
			Q1Alpha					25th percentile formatted to Dec decimals
			Median					50th percentile
			MedianAlpha				50th percentile formatted to Dec decimals
			Q3							75th percentile
			Q3Alpha					75th percentile formatted to Dec decimals
			MedianLowerCL			Lower confidence limit for median
			MedianLowerCLAlpha	Lower confidence limit for median formatted to Dec decimals
			MedianUpperCL 			Upper confidence limit for median
			MedianUpperCLAlpha	Upper confidence limit for median formatted to Dec decimals
			PValueW					Wilcoxon signed-ranks p-value
			PValueWAlpha			Wilcoxon signed-ranks p-value formatted
			PValueT					T-test p-value
			PValueTAlpha			T-test p-value formatted
			PValueN					Normality p-value
			PValueNAlpha			Normality p-value formatted
			Any By variables will also be included in the output file.;
filename chkvar URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckVar.sas";
%include chkvar;
filename varlist URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/Varlist.sas";
%include varlist;
filename words URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;

* Macro FirsttDot generates list of first.byvars;
%Macro FirstDot(NBy,ByVars);
	%Local I OneBy;
   %do i = 1 %to &NBy;
      %Let OneBy = %scan(&ByVars,&i);
      First%str(.)&OneBy
      %if &i < &NBy %then %do; or %end;
   %end;
%mend;

%macro Univariate(Dsname=,Vars=,ByVars=,Print=Y,Label=Y,Show=N MN SD MD MDCI MIN MAX,ID=Var,Dec=2,Out=);

	%varlist(VLDsname=&dsname,ShortList=&vars)						* This creates global macro variable _LongList;	
	%Local AllStat BadVar I J K NID NShow NVars NBy Stat ThisID Var Varlist;
	%Global _Error _LongList;

	%Let Vars = %str( )%upcase(%cmpres(&_LongList))%str( );
	%Let ByVars = %str( )%upcase(%cmpres(&Byvars))%str( );
	%Let Print = %upcase(&Print);
	%Let Label = %upcase(&Label);
	%Let Show = %str( )%upcase(%cmpres(&Show))%str( );
	%Let ID = %str( )%upcase(%cmpres(&ID))%str( );
	%Let NVars = %words(&Vars);
	%Let NBy = %words(&Byvars);
	%Let NShow = %words(&Show);
	%Let NID = %words(&ID);
	%if &Out= and &Print=N %then
		%do;
			%put;
			%put Error: No output file and Print = N.;
			%put;
			%goto ExitUnivariate;
		%end;
	%if &Print=Y and &Show= %then
		%do;
			%put;
			%put Error: No statistics have specified with the Show parameter.;
			%put;
			%goto ExitUnivariate;
		%end;

	* Check that all dependent and by variables are in the data set;
	%Let Varlist = %upcase(%cmpres(&Vars%str( )&ByVars));
	%CheckVar(CVDSName=&DSName,CVVars=&Varlist,Message=Y)
	%if &_Error = 1 %then %GoTo ExitUnivariate;
   
	* Check for alpha variables in the dependent list;
	%do J = 1 %to &NVars;
		%Let Var = %scan(&Vars,&J);
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
		%if &BadVar = 1 %then %goto ExitUnivariate;
	%end;
	run;

	* Check that the Show= specifications are legit.;
	%Let AllStat = N MN SD MNCI Q1 MD Q2 Q3 MDCI MIN MAX PW PT PN;
	%Let AllStat = %str( )&AllStat%str( );
	%if &Show ne %then
		%do I = 1 %to &NShow;
		   %Let Stat = %str( )%scan(&Show,&I)%str( );
			%Let K = %index(&AllStat,&Stat);
			%if &K = 0 %then
				%do;
					%put;
					%put Error: The statistic &Stat in the Show specification is not recognized.;
					%put The legal specifications are &allStat;
					%put;
					%goto ExitUnivariate;
				%end;
		%end;

	* Check that the ID= specifications are legit.;
	%if &NID > 0 %then
		%do I = 1 %to &NID;
			%Let ThisID = %str( )%scan(&ID,&I)%str( );
			%Let K = %index(%str( )VAR%str( )LAB%str( ),&ThisID);
			%if &K = 0 %then
				%do;
					%put;
					%put Error: The ID specification &ThisID is not recognized.;
					%put The legal specifications are VAR and/or LAB;
					%put;
					%goto ExitUnivariate;
				%end;
		%end;

	* Check that Dec is between 0 and 7;
	%if &Dec < 0 or &Dec > 7 %then
		%do;
			%put;
			%put Error: The number of decimals must be between 0 and 7.;
			%put;
			%goto ExitUnivariate;
		%end;

	* Create a a series of macro variables _DV1,_DV2,...,_DV&NVars that will be 1 if that numeric variable is a date variable
	  otherwise 0;
	data _null_;
  		set &dsname (obs = 1);
		%do i = 1 %to &NVars;
			%Let ThisVar = %scan(&Vars,&i);
			Fmt = VFormatN(&ThisVar);
			Call Symput("_DV&I",0);
			if Fmt in('DATE','NENGO','DDMMYY','JULIAN','MMDDYY','YYMMDD','WEEKDATE','WEEKDATX','WORDDATE','WORDDATX') then Call Symput("_DV&I",1);
		%end;
	run;

	ods listing close;
  	* Note that SAS allows an empty BY statement;
  	proc univariate data=&Dsname cipctldf;	by &ByVars;	var &Vars;
		output out=_stats Median=Med1-Med&NVars Mean=Mean1-Mean&NVars
	  		Std=Std1-Std&NVars Min=Min1-Min&NVars Max=Max1-Max&NVars
	  		Q1=Q1_1-Q1_&NVars Q3=Q3_1-Q3_&NVars n=N1-N&NVars
	  		Probs=PValueW1-PValueW&NVars Probt=PValueT1-PValueT&NVars
	  		Probn=PValueN1-PValueN&NVars;
			ods output quantiles=_medci;
  	run;

	* Rearrange summary statistics to long form;
  	data _stats2;
		set _stats ; by &ByVars;
		if _n_ = 1 then Order = 0;
		retain Order;
		Length Variable $ 32 ;
		array _a1 {*} &Vars;
		array _a2 {*} N1-N&NVars;
		array _a3 {*} Mean1-Mean&NVars;
		array _a4 {*} Std1-Std&NVars;
		array _a5 {*} Min1-Min&NVars;
		array _a6 {*} Max1-Max&NVars;
		array _a7 {*} Q1_1-Q1_&NVars;
		array _a8 {*} Med1-Med&NVars;
		array _a9 {*} Q3_1-Q3_&NVars;
		array _a10 {*} PValueW1-PValueW&NVars;
		array _a11 {*} PValueT1-PValueT&NVars;
		array _a12 {*} PValueN1-PValueN&NVars;
		Do i = 1 to dim(_a1);
			Variable = VName(_a1{i});
		  	N = _a2{i}; 
			Mean = _a3{i};
			SD = _a4{i};
			MeanLowerCL = .;
			MeanUpperCL = .;
		  	if N > 1 then 
				do;
					MeanLowerCL = Mean - tinv(0.975,N - 1) * SD / sqrt(N);
					MeanUpperCL = Mean + tinv(0.975,N - 1) * sd / sqrt(N);
				end;
			Min = _a5{i};
			Max = _a6{i};
			Q1 = _a7{i}; 
			Median = _a8{i}; 
			Q3 = _a9{i};
			PValueW = _a10{i};
			PValueT = _a11{i};
			PValueN = _a12{i};
			Order = Order + 1;
			keep Variable &ByVars N Mean SD MeanLowerCL MeanUpperCL Q1 Median Q3 Min Max PValueW PValueT PValueN Order;
		  	output;
		end;
  run;

  * Add a variable DV to _stats2 that will identify a date variable.;
	data _stats2;
		set _stats2; by &ByVars;
		%if &NBy > 0 %then 
			%do; if %FirstDot(&NBy,&ByVars) %end;
		%else
			%do; if _n_ = 1 %end;
		then _count = 0;
		retain _count;
		_count = _count +1;
		DV = input(Left(symget('_DV'||left(trim(put(_Count,5.))))),1.);
   run;
	
   proc sort data = _stats2; by &byvars variable;

  * Get variable labels from original data set;
   data _labels;
     set &dsname (obs = 1);
	  Length Variable OrigVarName $ 32 Label $ 80;
	  array _a1 {*} &Vars;
	  do i = 1 to dim(_a1);
	  	  OrigVarName = vname(_a1{i});
	  	  Label = vlabel(_a1{i});
		  Variable = upcase(OrigVarName);
		  Keep Variable Label OrigVarName;
		  output;
		end;
	run;
	proc sort data = _labels; by Variable;
	proc sort data = _stats2; by Variable;

	* add the labels to _stats2;
	data _stats2;
	   merge _stats2 _labels; by Variable;
	run;
	proc sort data = _stats2; by &ByVars Variable;
	  
  * Get the confidence limits for the median for each variable and each by group;
  data _medci (drop = Quantile VarName);
     set _medci (rename = (lcldistfree = MedianLowerCL ucldistfree = MedianUpperCL) keep = VarName lcldistfree ucldistfree Quantile &Byvars);
	  if quantile = '50% Median';
	  Length Variable $ 32;
	  variable = upcase(VarName);
   	*must re-format the CIs to avoid possible format error (code from univsum);
		format MedianLowerCL MedianUpperCL;
	run;
	proc format; value _pfmt . = ' ' low-.00995 = [pvalue6.4] .00995-.0995 = [6.3] .0995-1 = [6.2];
	proc sort data = _medci; by &ByVars Variable;

	data _all (drop = OrigVarName);
	   merge _stats2 _medci; by &ByVars Variable;
		Variable = OrigVarName;
		PValueWAlpha = left(put(PValueW,_pfmt.));
		PValueTAlpha = left(put(PValueT,_pfmt.));
		PValueNAlpha = left(put(PValueN,_pfmt.));
		* round date values to integers;
		array _a1 {10} Mean MeanLowerCL MeanUpperCL Median MedianLowerCL MedianUpperCL Min Max Q1 Q3;
		array _a2 {10} $ 10 MeanAlpha MeanLowerCLAlpha MeanUpperCLAlpha MedianAlpha MedianLowerCLAlpha MedianUpperCLAlpha MinAlpha MaxAlpha Q1Alpha Q3Alpha;
		* Date variables and non-date variables format SD the same;
		%if &Dec = 0 %then
			%do;
				SDAlpha = left(put(sd,10.));
			%end;
		%else
			%do;
				SDAlpha = left(put(sd,10.&Dec));
			%end;
		if SD = . then SDAlpha = '';
		SDAlpha = right(SDAlpha);
		if dv = 1 then
			do j = 1 to 10;
		   	_a1{j} = round(_a1{j});
				_a2{j} = left(put(_a1{j},mmddyy8.));
				if _a1{j} = . then _a2{j} = '';
				_a2{j} = right(_a2{j});
			end;
		else
			do j = 1 to 10;
				%if &Dec = 0 %then 
					%do;
						_a2{j} = left(put(_a1{j},10.));
					%end;
				%else
					%do;
						_a2{j} = left(put(_a1{j},10.&Dec));
					%end;
				if _a1{j} = . then _a2{j} = '';
				_a2{j} = right(_a2{j});
			end;

		label	Variable	= 'Variable'
				Label = 'Label'
				N	= 'N'
				Mean	= 'Mean'
				MeanAlpha = 'Mean'
				SD	= 'SD'
				SDAlpha = 'SD'
				MeanLowerCL	= 'Mean 95% CI Lower'
				MeanLowerCLAlpha = 'Mean 95% CI Lower'
				MeanUpperCL	= 'Mean 95% CI Upper'
				MeanUpperCLAlpha = 'Mean 95% CI Upper'
				Median	= 'Median'
				MedianAlpha = 'Median'
				MedianLowerCL	= 'Median 95% CI Lower'
				MedianLowerCLAlpha = 'Median 95% CI Lower'
				MedianUpperCL	= 'Median 95% CI Upper'
				MedianUpperCLAlpha = 'Median 95% CI Upper'
				Min	= 'Min'
				MinAlpha = 'Min'
				Max	= 'Max'
				MaxAlpha = 'Max'
				Q1	= 'Lower Quartile'
				Q1Alpha = 'Lower Quartile'
				Q3	= 'Upper Quartile'
				Q3Alpha = 'Upper Quartile'
				PValueW	= 'Wilcoxon Signed-Rank P-Value'
				PValueWAlpha = 'Wilcoxon Signed-Rank P-Value'
				PValueT	= 'T-Test P-Value'
				PValueTAlpha = 'T-test P-Value'
				PValueN	= 'P-Value Normality'
				PValueNAlpha = 'P-Value Normality';
	run;
	proc sort data = _all; by Order;
	%if &out ne %then
		%do;
			data &out;
			   set _all (drop = Order);
			run;
		%end;
   
  	run;
	ods listing;
  	%if &Print=Y %then
		%do;
			proc print uniform noobs data=_all
				%if &Label = Y %then %do; label %end;
			;
  			by &ByVars; 
			%if &NID > 0 %then
				%do;
					id 
					%do I = 1 %to &NID;
						%Let ThisID = %scan(&ID,&I);
						%if &ThisID = VAR %then %do; Variable %end;
						%if &ThisID = LAB %then %do; Label %end;
					%end;
					;
				%end;
			var
			%do I = 1 %to &NShow;
				%Let Stat = %str( )%scan(&Show,&I)%str( );
				%if &Stat = %str( )N%Str( ) %then %do; N %end;
				%if &Stat = %str( )MN%str( ) %then %do; MeanAlpha %end;
				%if &Stat = %str( )SD%str( ) %then %do; SDAlpha %end;
				%if &Stat = %str( )MNCI%str( ) %then %do; MeanLowerCLAlpha MeanUpperCLAlpha %end;
				%if &Stat = %str( )Q1%str( ) %then %do; Q1Alpha %end;
				%if &Stat = %str( )MD%str( ) %then %do; MedianAlpha %end;
				%if &Stat = %str( )Q2%str( ) %then %do; MedianAlpha %end;
				%if &Stat = %str( )Q3%str( ) %then %do; Q3Alpha %end;
				%if &Stat = %str( )MDCI%str( ) %then %do; MedianLowerCLAlpha MedianUpperCLAlpha %end;
				%if &Stat = %str( )MIN%str( ) %then %do; MinAlpha %end;
				%if &Stat = %str( )MAX%str( ) %then %do; MaxAlpha %end;
				%if &Stat = %str( )PW%str( ) %then %do; PValueWAlpha %end;
				%if &Stat = %str( )PT%str( ) %then %do; PValueTAlpha %end;
				%if &Stat = %str( )PN%str( ) %then %do; PValueNAlpha %end;
			%end;
			;
			run;
  		%end;
  	   proc datasets nolist; delete _labels _stats _stats2 _medci _all; quit; 
%ExitUnivariate:
%mend univariate;
