* Macro Table1 combines descriptive statistics and p-values in a typical Table 1 format where columns correspond
  to values of a grouping variable (or just one column) and rows correspond to measures or subgroups in the case
  of categorical variables.

  Inputs:
      DSName = input SAS data set
      GroupVar = two or more level numeric or alphanumeric grouping variable.  Observations with missing values on
                 this variable are deleted.  If not present, then statistics are given for all data.
      NumVars = list of numeric variables to be summarized with mean +/- SD or median (min-max). Shortcut lists OK.
      FreqVars = list of numeric or alpha variables to summarized with frequencies and/or percents.  Alpha variable
                 are allowed.  Shortcut lists OK.
      Mean = Y/N  If Y, then continuous variables are summarized with N, mean +/- SD.
      Median = Y/N If Y, then continuous variables are summarized with median (min-max).  If both Mean and Median
             are Y, then there will be two lines of output per continuous variable.
		Total = R or C or N or RC
				 R = generates a column of totals with statistics for both continuous and categorical variables
					  (this option has no effect if GroupVar is blank)
				 C = generates a row of totals for each categorical variable (has no effect on continuous variables)
				 RC = both totals are computed
				 N = no totals are computed (default = C)
	   P = T or W or N or TW  
				 T = p-values for continuous variables based on a pooled variances t-statistic
				 W = p-values for continuous variables based on a Wilcoxon rank-sum statistic
				 TW = both of the above p-values will be shown
				 N = no p-values (default = W)
		       Note that P must be T, W, or TW in order for p-values for categorical variables to be computed (see below).
		Fisher = list of variables in FreqVars for which Fishers exact test should be used.
      KW = list of variables in FreqVars for which a Wilcoxon rank-sum (or Kruskal-Wallis) p-value should be used.
      FreqCell = N or RP or CP or combinations N(RP) or N(CP) or RP(N) or CP(N).  RP = Row percent, CP = column
             percent. (default = N(RP))
	   Missing = Y/N. If Y, then frequencies for categorical variables will include missing values. Default is N.
					 The missing values are not included in the P-value calculation.
                This parameter has no effect on statistics for continuous variables. 
		Print = Y/N for printed output
		Label = N for Name, L for Label, NL for both.  This parameter affects categorical variable labeling only. 
				  Continuous variables always show only the variable label (which is the variable name if there is no
				  label). (default = L) Examples
				 		Label = N			SEX
				 		Label = L			Subject's gender		
				 		Label = NL			SEX (Subject's gender)
				  Note that very long labels make cause problems with the output format.
				
		Out = output data set name to be printed with the Table1Print macro. 
		Out1way = output data set name for data set to be created by npar1way macro (2+ groups) or univariate macro (1 group)
          	    If Print = Y, then this will apply to the npar1way or univariate output also.  If Print = N, then
                this parameter can be used to create a dataset to be printed with npar1wayprint.
	
	Revision date: January 30, 2009;

%Let MacroDir = L:\BCU Macros\Macros;
%include "&MacroDir\Npar1way.sas";

%macro Table1(DSName=,GroupVar=,NumVars=,FreqVars=,Mean=Y,Median=N,Total=C,P=W,Fisher=,KW=,FreqCell=N(RP),Missing=N,Print=Y,Label=L,Out=,Out1way=);

	%Local BadVar Cat1 Cat2 Cat3 Cat4 Cat5 Cat6 Cat7 Cat8 Cat9 Cat10 CatFmt	Fish FisherKW GroupFmt HasChisq HasFisher HasMW
			 I K KWVar NBoth NCat NCells NFisher NFreqVars NGroups NKW NNote NNumVars NVars ThisFreqVar ThisVar Val1 Val2 Val3 Val4
          Val5 Val6 Val7 Val8 Val9 Val10 Var Varlist;
	%Global _Error _LongList;

	%varlist(VLDsname=&dsname,ShortList=&NumVars)                * This creates global macro variable _LongList;
   %Let NumVars = %str( )%upcase(%cmpres(&_LongList))%str( );
	%varlist(VLDsname=&dsname,ShortList=&FreqVars)
	%Let FreqVars = %str( )%upcase(%cmpres(&_LongList))%str( );
	%varlist(VLDsname=&dsname,ShortList=&Fisher)
	%Let Fisher = %str( )%upcase(%cmpres(&_LongList))%str( );
	%varlist(VLDsname=&dsname,ShortList=&KW)
	%Let KW = %str( )%upcase(%cmpres(&_LongList))%str( );
	%Let NNumVars = %words(&NumVars);
	%Let NFreqVars = %words(&FreqVars);
	%Let NFisher = %words(&Fisher);
	%Let NKW = %words(&KW);
   %Let GroupVar = %upcase(&GroupVar);
	%Let Mean = %upcase(&Mean);
	%Let Median = %upcase(&Median);
	%Let Total = %upcase(&Total);
	%Let P = %upcase(&P);
	%Let FreqCell = %upcase(&FreqCell);
	%Let Missing = %upcase(&Missing);
	%Let Print = %upcase(&Print);
	%Let Label = %upcase(&Label);

%Let NVars = %eval(&NNumVars + &NFreqVars);
	%if &NVars = 0 %then
		%do;
			%put;
			%put Error: No continuous or categorical variables have been specified.;
			%put;
			%goto ExitTable1;
		%end;
	* Check that P is legal;
	%if &P ne T and &P ne W and &P ne TW and &P ne WT and &P ne N %then
		%do;
			%put;
			%put Error: The legal choices for P are T, W, TW, or N.;
			%put;
			%goto ExitTable1;
		%end;
	* Check that Total is legal;
	%if &Total ne R and &Total ne C and &Total ne RC and &Total ne N %then
		%do;
			%put;
			%put Error: The legal choices for Total are R, C, RC, or N.;
			%put;
			%goto ExitTable1;
		%end;

	* Check that grouping variable, by variables, all dependent and frequency variables are in the data set;
   %Let Varlist = %upcase(%cmpres(&GroupVar%str( )&NumVars%str( )&FreqVars));
	%CheckVar(CVDSName=&DSName,CVVars=&Varlist,Message=Y);
	%if &_Error = 1 %then %GoTo ExitTable1;

   * Check that there are no alpha variables in the numeric variable list;
	%if &NNumVars > 0 %then
	   %do K = 1 %to &NNumVars;
	      %Let Var = %scan(&NumVars,&K);
	      data _null_;
	         set &dsname (obs = 1);
	         Type = VType(&Var);
	         if Type NE 'N' then
	            do;
	               Call Symput('BadVar',1);
	               put '   ';
	               put "Error: Variable &Var is a character variable and cannot be in the numeric variables list.";
	               put '   ';
	            end;
	      run;
	      %if &BadVar = 1 %then %goto ExitTable1;
	   %end;

	* Check that there are no alpha variables in the KW list;
	%if &NKW > 0 %then
		%do K = 1 %to &NKW;
			%Let Var = %Scan(&KW,&k);
			data _null_;
			   set &dsname (obs = 1);
				Type = VType(&Var);
				if Type NE 'N' then
					do;
						Call Symput('BadVar',1);
						put '    ';
						put "Error: Variable &Var is a character variable and cannot be in the KW variables list.";
						put '    ';
					end;
			run;
			%if &BadVar = 1 %then %goto ExitTable1;
		%end;

	* Check that Mean or Median is Y if NumVars is not empty;
	%if &NNumVars > 0 %then
		%do;
			%if &Mean = N and &Median = N %then
				%do;
					%put;
					%put Error: Numeric variables specified but Mean and Median are both N.;
					%put;
					%goto ExitTable1;
				%end;
		%end;

	* The legal values for FreqCell are N, RP, CP, N(RP), N(CP), RP(N), CP(N).  Check that FreqCell is legal.;
	%if %quote(&FreqCell) ne %then
		%do;
			%if %quote(&FreqCell) ne N and %quote(&FreqCell) ne RP and %quote(&FreqCell) ne CP and %quote(&FreqCell) ne %quote(N(RP)) and %quote(&FreqCell) ne %quote(N(CP)) and
	    		 %quote(&FreqCell) ne %quote(RP(N)) and %quote(&FreqCell) ne %quote(CP(N)) %then
		 			%do;
						%put;
						%put Error: FreqCell specifications incorrect.;
						%put;
						%goto ExitTable1;
					%end;
		%end;

	* Check that any variables in Fisher and KW lists are in FreqVars;
	%Let NBoth = %eval(&NFisher + &NKW);
	%let FisherKW = %str( )%cmpres(&Fisher &KW)%str( );
	%if &NBoth > 0 %then
		%do i = 1 %to &NBoth;
			%Let ThisVar = %scan(&FisherKW,&i);
			%Let ThisVar = %str( )%Left(%trim(&ThisVar))%str( );
			%Let K = %index(&FreqVars,&ThisVar);
			%if &K = 0 %then
				%do;
					%put;
					%put Error: Variable &ThisVar in the Fisher or KW lists must also be in the FreqVars list.;
					%put;
					%goto ExitTable1;
				%end;
			* Check that any KW variables are not also in Fisher list;
			%if &i > &NFisher %then
				%do;
					%Let K = %index(&Fisher,&ThisVar);
					%if &K > 0 %then
						%do;
							%put;
							%put Error: Variable &ThisVar cannot be in both the Fisher and KW lists.;
							%put;
							%goto ExitTable1;
						%end;
				%end;
		%end;

	* Create a a series of macro variables _TabDV1,_TabDV2,...,_TabDV&NNumVars that will be 1 if that numeric variable is a date variable
	  otherwise 0. A variable will be a date variable based on its format.;
	%if &NNumVars > 0 %then
		%do;
			data _null_;
	   		set &dsname (obs = 1);
				%do i = 1 %to &NNumVars;
					%Let ThisVar = %scan(&NumVars,&i);
					Fmt = VFormatN(&ThisVar);
					Call Symput("_TabDV&I",0);
					if Fmt in('DATE','NENGO','DDMMYY','JULIAN','MMDDYY','YYMMDD','WEEKDATE','WEEKDATX','WORDDATE','WORDDATX') then Call Symput("_TabDV&I",1);
				%end;
			run;
		%end;
   * Store grouping variable format in GroupFmt;
	%Let GroupFmt =;
   %if &GroupVar ne %then
      %do;
         data _null_;
            set &dsname (obs = 1);
            Call Symput('GroupFmt',VFormat(&GroupVar));
         run;
      %end;
	%else %Let GroupFmt = 1.;				* when no grouping variable we will have a phony constant variable;
   proc format; value _pfmt . = ' ' low-.00995 = [pvalue6.4] .00995-.0995 = [6.3] .0995-1 = [6.2];
   
   * Delete observations with missing values on the grouping variable;
   data _use;
      set &dsname;
      %if &GroupVar ne %then
         %do;
            if missing(&GroupVar) then delete;     * missing function works for both alpha and numeric;
         %end;
		_Const = 1;												* used as the "grouping variable" if no grouping variable;
   run;
	%if &GroupVar = %then 
		%do; 
			%Let GroupVar = _CONST;
			%Let Total = N;
		%end;

	* Store the possible formatted values of the GroupVar in macro variables Val1, Val2, ....;
	ods listing close;
	proc freq data = _use; tables &GroupVar/out = _GpVarCounts;
	
	data _null_;
	   set _GpVarCounts end = done;
		%if &GroupFmt ne %then
			%do;
				call symput('Val'||left(_n_),put(&GroupVar,&GroupFmt));
			%end;
		%else
			%do;
				call symput('Val'||Left(_n_),&GroupVar);
			%end;
		if done then call symput('NGroups',_n_);
	run;
	%Let NGroups = %trim(&NGroups);

   proc sort data = _use; by &GroupVar;    
	
	%if &NNumVars > 0 %then
		%do;
			%Univariate(dsname=_use,Vars=&NumVars,ByVars=&GroupVar,Print=N,out=_Tabutemp) 
			* Add a variable DV to _Tabutemp that will identify a date variable.;
			data _Tabutemp;
			   set _Tabutemp (drop = _count); by &GroupVar;
				if first.&GroupVar then _count = 0;
				retain _count;
				_count = _count +1;
				DV = input(Left(symget('_TabDV'||left(trim(put(_Count,5.))))),1.);
				Variable = upcase(Variable);
				_order = _n_;
   		run;
			
   		%if &GroupVar ne _CONST %then
      		%do;
					* Get totals across rows;
					%Univariate(dsname=_use,Vars=&NumVars,ByVars=,Print=N,out=_Tabutemp2) 
					data _Tabutemp2;
					   set _tabutemp2 (Keep = Variable Mean Median Min Max SD N
						                rename = (N = TN Mean = TMean Median = TMedian Min = TMin Max = TMax SD = TSD));
						Variable = upcase(Variable);
					run;
					proc sort data = _tabutemp; by variable;
					proc sort data = _tabutemp2; by variable;
					data _tabutemp;
					   merge _tabutemp _tabutemp2; by variable;
					run;
					proc sort data = _tabutemp; by _order;

					* Cycle through the dependent variables doing one at a time and saving the P-value.  NPar1way is
   				invoked one variable at a time otherwise one degenerate variable aborts all analyses.
				   [For now, we do this without regard to value of P.];
         		proc datasets nolist; delete _allnpar; quit;
         		ods listing close;
         		%do i = 1 %to &NNumVars;
            		%Let Var = %Scan(&NumVars,&i);
            		proc datasets nolist; delete _Wt _wilcoxon; quit;
            		proc npar1way wilcoxon data = _use; class &GroupVar; var &Var;   
							output out = _wilcoxon;
            		run;
						%put _user_;
						%if %sysfunc(exist(_wilcoxon)) %then
							%do;
								data _wil2 (Keep = Variable Prob_Wil);
						   		set _Wilcoxon;
									Length Variable $ 32;
									Variable = upcase(_Var_);
									if p2_wil = . then
										do;
											Prob_Wil = P_KW;
										end;
									else
										do;
											Prob_Wil = p2_wil;
										end;
								run;
								proc append base = _allnpar data = _wil2 force;
								run;
							%end;
         		%end;
         		data _allnpar;
            		set _allnpar;
						Length Prob_WilAlpha $ 7;
            		Prob_WilAlpha = trim(left(put(Prob_Wil,_pfmt.)))||Byte(185);
					run;   
					* Get p-values based on pooled variances t-statistic;
               %if &NGroups = 2 %then
						%do;	
							proc datasets nolist; delete _tt; quit;
							proc ttest data = _use; class &GroupVar; var &NumVars; 
								ods output ttests = _tt;
							run;
							data _tt (Keep = Variable Probt ProbtAlpha);
					   		set _tt;
								Length ProbTAlpha $ 7;
            				ProbTAlpha = trim(left(put(Probt,_pfmt.)))||Byte(176);
								Variable = upcase(Variable);
								if Variances = 'Equal';
							run;
						%end;
				%end;
   		* Create a data set of one obs per combination of GroupVar and outcome variable. This data set will be
     		merged with _Tabutemp by GroupVar because _utemp will not have the outcome variable if N = 0;
   		data _counts2;
      		set _GpVarCounts;
      		Length meas $ 32;
      		array _a1 {&NNumvars} &NumVars;
      		do j = 1 to dim(_a1);
         		meas = upcase(vname(_a1{j}));
         		Order = j;
         		Keep meas &GroupVar Order;
         		output;
      		end;
   		run;
   		proc sort data = _counts2; by &GroupVar Order;
   		proc sort data = _Tabutemp; by &GroupVar;
   		data _Tabutemp;
      		set _Tabutemp; by &GroupVar;
      		if first.&GroupVar then Order = 0;
      		retain Order;
      		Order = Order + 1;
   		run;
   		proc sort data = _Tabutemp; by &GroupVar order;
   		data _Tabutemp3 (drop = meas);
      		merge _Tabutemp (in = f1) _counts2; by &GroupVar order;
      		if f1;
      		Length Variable $ 32;
      		Variable = upcase(meas);
   		run;
		
   		proc sort data = _Tabutemp3; by Variable &GroupVar;

   		%if &GroupVar ne _CONST %then
      		%do;
         		proc sort data = _allnpar; by Variable;
					%if &NGroups = 2 %then
						%do;
							proc sort data = _tt; by Variable;
							data _allnpar;
					   		merge _allnpar _tt; by Variable;
						%end;
					run;
      		%end;

   		data _all;
      		%if &GroupVar ne _CONST %then
         		%do;
            		merge _Tabutemp3 _allnpar (in = haskw);
         		%end;
      		%else
         		%do;
            		set _Tabutemp3;
            		haskw = 0;
         		%end;
      		by Variable;
      		if haskw = 0 then do; Prob_Wil = .; end;
      		if not (first.Variable) then
         		do;
            		prob_wil = .;
            		prob_wilAlpha = '';
						Probt = .;
						ProbTAlpha='';
            		label = '';
            		Variable = '';
         		end;
   		run; 
			proc sort data = _all; by order &GroupVar;

   		data _all2(drop = label rename = (Label2 = Label) );
      		set _all (rename = (Variable = Var)); by order;
				Length Label2 $ 80 PValue1 PValue2 $ 7 Variable $ 32 Total $ 60;
      		array _a1 {&NGroups} n1-n&NGroups;
      		array _a2 {&NGroups} mean1-mean&NGroups;
      		array _a3 {&NGroups} sd1-sd&NGroups;
      		array _a4 {&NGroups} min1-min&NGroups;
      		array _a5 {&NGroups} max1-max&NGroups;
      		array _a6 {&NGroups} median1-median&NGroups;
				array _a7 {&NGroups} $ 60 GroupVal1-GroupVal&NGroups;
      		if first.order then 
					do; Count = 0; Variable = Var; PValue1 = Prob_WilAlpha; PValue2 = ProbTAlpha; Label2 = Label; Total = ''; TotN = 0; 
					    %if &P = T %then %do; PValue1 = ProbTAlpha; %end;
					end;
      		Retain Count n1-n&NGroups mean1-mean&NGroups sd1-sd&NGroups min1-min&NGroups max1-max&NGroups median1-median&NGroups Variable
						 PValue1 PValue2 Label2 Total TotN;
      		Count = Count+1;
				TotN = TotN + _a1{Count};
				if Count <= &NGroups then
					do;
		      		_a1{Count} = n;
		      		_a2{Count} = mean;
		      		_a3{Count} = sd;
		      		_a4{Count} = min;
		      		_a5{Count} = max;
		      		_a6{Count} = median;
					end;
				
				* All values have been accumulated for this dependent variable.  Create the output statistics;
      		if last.order then
         		do;
						%if &Mean = Y %then
							%do;
								_nvalid = 0;					* number of valid groups.  If > 1 then pvalue is possible.;
               			do i = 1 to &NGroups;		* Loop over the values of the grouping variable creating composite statistics for each value;
									/* if dv = 0 then	_a7{i} = trim(left(put(_a1{i},10.)))||', '||trim(left(put(_a2{i},10.1)))||' '||Byte(177)||' '||trim(left(put(_a3{i},10.1)));
									   else do; _a2{i} = int(_a2{i}); _a7{i} = trim(left(put(_a1{i},10.)))||', '||Trim(left(put(_a2{i},mmddyy8.)))||' '||Byte(177)||' '||trim(left(put(_a3{i},10.1))); end; */
									if dv = 0 then _a7{i} = trim(left(put(_a2{i},10.1)))||' '||Byte(177)||' '||trim(left(put(_a3{i},10.1)))||' (N='||trim(left(put(_a1{i},10.)))||')';
   									else do; _a2{i} = int(_a2{i}); _a7{i} = trim(left(put(_a1{i},10.)))||', '||Trim(left(put(_a2{i},mmddyy8.)))||' '||Byte(177)||' '||trim(left(put(_a3{i},10.1))); end;
									 if _a1{i} in(.,0) then _a7{i} = ''; else _nvalid = _nvalid + 1;
								end;
								Label Label2 = 'Variable';
								*Label2 = trim(left(Label2))||' (N, Mean '||Byte(177)||' SD)';
								Label2 = trim(left(Label2))||' (Mean '||Byte(177)||' SD (N))';
								%if &Total = R or &Total = RC %then
									%do;
										if dv = 0 then
											/* Total = trim(left(put(TN,10.)))||', '||trim(left(put(TMean,10.1)))||' '||Byte(177)||' '||trim(left(put(TSD,10.1))); */
											Total = trim(left(put(TMean,10.1)))||' '||Byte(177)||' '||trim(left(put(TSD,10.1)))||' (N='||trim(left(put(TN,10.)))||')';
										else
											do; TMean = int(TMean); Total = trim(left(put(TMean,mmddyy8.)))||' '||Byte(177)||' '||trim(left(put(TSD,10.1))); end;
									%end;
								if _nvalid <= 1 then do; PValue1 = ''; PValue2 = ''; end;
								Keep Variable Label2 GroupVal1-GroupVal&NGroups PValue1 PValue2 Total n1-n&NGroups;
								output;
							%end;
						%if &median = Y %then
							%do; 
								_nvalid = 0;
								do i = 1 to &NGroups;
								   if dv = 0 then
										do;
											if _a4{i} < 0 or _a5{i} < 0 then	_a7{i} = trim(left(put(_a6{i},10.1)))||' ('||trim(left(put(_a4{i},10.1)))||' to '||trim(left(put(_a5{i},10.1)))||')';
											else _a7{i} = trim(left(put(_a6{i},10.1)))||' ('||trim(left(put(_a4{i},10.1)))||'-'||trim(left(put(_a5{i},10.1)))||')';
										end;
									   else do; _a6{i} = int(_a6{i}); _a7{i} = trim(left(put(_a6{i},mmddyy8.)))||' ('||trim(left(put(_a4{i},mmddyy8.)))||'-'||trim(left(put(_a5{i},mmddyy8.)))||')'; end;
									if _a1{i} in(.,0) then _a7{i} = ''; 
									%if &Mean = N %then %do; else _nvalid = _nvalid + 1; %end;
								end;
								%if &Mean = N %then %do; if _nvalid <= 1 then do; PValue1 = ''; PValue2 = ''; end; %end;
								Label Label2 = 'Variable';
								%if &Mean = Y %then	%do; Label2 = substr(Label2,1,index(Label2,'(')-1); %end;
								Label2 = trim(left(Label2))||' (Median (min-max))';
								%if &Total = R or &Total = RC %then
									%do;
										if dv = 0 then
											do;
												if TMin < 0 or TMax < 0 then Total = trim(left(put(TMedian,10.1)))||' ('||trim(left(put(TMin,10.1)))||' to '||trim(left(put(TMax,10.1)))||')';
												else Total = trim(left(put(TMedian,10.1)))||' ('||trim(left(put(TMin,10.1)))||'-'||trim(left(put(TMax,10.1)))||')';
											end;
										else do; TMedian = int(TMedian); Total = trim(left(put(TMedian,mmddyy8.)))||' ('||trim(left(put(TMin,mmddyy8.)))||'-'||trim(left(put(TMax,mmddyy8.)))||')'; end;
									%end;
								%if &Mean = Y %then %do; PValue1 = ''; PValue2 = ''; %end;
								output;
							%end;	
						* Write a blank observation;
						do i = 1 to &NGroups;
				   		_a7{i} = '';
						end;
						label2 = '';
						PValue1 = '';
						PValue2 = '';
						Total = '';
						output;
         		end;
			run;
		%end;
	* Process frequency variables one at a time;
	%if &NFreqVars > 0 %then
		%do m = 1 %to &NFreqVars;
			%Let ThisFreqVar = %scan(&FreqVars,&m);
			data _null_;
            set &dsname (obs = 1);
            Call Symput('CatFmt',VFormat(&ThisFreqVar));						* Get the format for this categorical variable;
         run;
			ods listing close;
			proc freq data = _use; tables &ThisFreqVar / out = _counts;		* get all possible values of categorical variable
																								and store than in macro variables cat1, cat2,...;
			run;
			* The data set _counts includes frequencies for missing values of ThisFreqVar.  They will have PERCENT = .;
			%if &Missing = N %then
				%do;
					data _counts;
						set _counts;
						if PERCENT = . then delete;
					run;
				%end;
			* Put the values of the categorical variable into macro variables Cat1, Cat2,...;
			data _null_;
				set _counts end = done;
				%if &CatFmt ne %then
					%do;
						call symput('Cat'||left(_n_),put(&ThisFreqVar,&CatFmt));
					%end;
				%else
					%do;
						call symput('Cat'||Left(_n_),&ThisFreqVar);
					%end;
				if done then call symput('NCat',_n_);
			run;
			%Let NCat = %trim(&NCat);
			* See if ThisFreqVar is in the Fisher list;
			%Let Fish = %index(&Fisher,%str( )&ThisFreqVar%str( ));

			* Now get the frequency table of the categorical variable by the group variable;
			proc freq data = _use; tables &ThisFreqvar * &GroupVar /chisq out = _counts; 
				%if &Fish > 0 %then %do; exact fisher; %end;
				output out = _stats chisq
				%if &Fish > 0 %then %do; fisher %end;
				;
			%Let PChi = '';
			* For some strange reason the %sysfunc(exist(_stats)) does not return 1 for the first categorical variable
			  even though _stats normally exists.  We will temporarily use the number of group values as the test.;
			
			%if &NGroups > 1 %then
				%do;
					* put chi-square or Fisher pvalue into a macro variable;
					data _null_;
						set _stats;
						Length PValue1 $ 7;
						%if &Fish > 0 %then 
							%do; 
							   if XP2_Fish = . then PValue1 = ''; else
								PValue1 = trim(left(put(XP2_Fish,_pfmt.)))||Byte(179);
							%end;
						%else
							%do;
								if P_PChi = . then PValue1 = ''; else
								PValue1 = trim(left(put(P_PChi,_pfmt.)))||Byte(178);
							%end;
						call symput('PChi',PValue1);
					run;
			
				* See if this variable is in the KW list;
				%Let KWVar = %index(&KW,%str( )&ThisFreqVar%str( ));
				* If it is we get the PValue from npar1way;
				%if &KWVar > 0 %then
					%do;
						proc npar1way data = _use; class &groupvar; var &ThisFreqVar;
							output out = _wilcoxon;
						run;
						data _null_;
						   set _wilcoxon;
							Length PValue1 $ 7;
							if p2_wil = . then p = p_kw; else p = p2_wil;
							if p = . then PValue1 = ''; else
							PValue1 = trim(left(put(p,_pfmt.)))||Byte(185);
							Call Symput('PChi',PValue1);
						run;
					%end;
				%end;
		
			* Delete the counts based on missing values if Missing = N;
			%if &Missing = N %then
				%do;
					data _counts;
				   	set _counts;
						if PERCENT = . then delete;
					run;
				%end;

			* The array a1 in the next data step will cover the &NCat rows by &NGroups cols for this categorical variable;
			%Let NCells = %Trim(%eval(&NCat * &NGroups));
			data _freqs;
			   set _counts end = done; 
				Length Test $ 60 PValue1 $ 7 Total $ 20;
				array _a1 {&NCells} n1-n&NCells; 
				array _a2 {&NCat} $ 60 Cat1-Cat&NCat (
				%do i = 1 %to &NCat;
					"&&Cat&i"
				%end;
				);
				array _a3 {&NGroups} $ 60 Val1-Val&NGroups (
				%do i = 1 %to &NGroups;
					"&&Val&i" 
				%end;
				);
				retain n1-n&NCells;
				* initialize ns to 0 because not all may be present in _counts;
				if _n_ = 1 then
					do j = 1 to &NCells;
					   _a1{j} = 0;
					end;
				* Locate the categorical variable value;
				%if &CatFmt ne %then
					%do;
						Test = put(&ThisFreqVar,&CatFmt);
					%end;
				%else
					%do;
						Test = &ThisFreqVar;
					%end;
				do i = 1 to &NCat;
					if Test = _a2{i} then Cat = i;
				end;
				* Locate the grouping variable value;
				%if &GroupFmt ne %then
					%do;
						Test = put(&GroupVar,&GroupFmt);
					%end;
				%else
					%do;
						Test = put(&GroupVar,5.);
					%end;
				do j = 1 to &NGroups;
					 if Test = _a3{j} Then Group = j;
				end;
				k = (Cat-1) * &NGroups + Group;
				_a1{k} = Count;
				* When all observations in _counts have been processed, we can output the table 1 values;
				array _a4 {&NGroups} $ 60 GroupVal1-GroupVal&NGroups;		* These are the values written to Table 1;
				array _a5 {&NGroups} Col1-Col&NGroups;							* Column totals;
				array _a6 {&NCat} Row1-Row&NCat;									* Row totals;
				if done then
					do;
						Length Label $ 50;
						* Write an observation with the variable name and/or label;
						%if &Label = N %then 
							%do;
								Label = vname(&ThisFreqVar);
							%end;
						%if &Label = L %then
							%do;
								Label = vlabel(&ThisFreqVar);
							%end;
						%if &Label = NL %then
							%do;
								if vlabel(&ThisFreqVar) = vname(&ThisFreqVar) then Label = vname(&ThisFreqVar); else
									Label = vname(&ThisFreqVar)||' ('||vlabel(&ThisFreqVar)||')';
							%end;
						do j = 1 to &NGroups;
						   _a4{j} = '';
						end;
						PValue1 = '';
						PValue2 = '';
						Total = '';
						Keep Label GroupVal1-GroupVal&NGroups PValue1 PValue2 Total;
						output;
						TotN = 0;
						* Get the row totals;
						do i = 1 to &NCat;
							_a6{i} = 0;
							do j = 1 to &NGroups;
								l = (i-1)*&NGroups + j;
								_a6{i} = _a6{i} + _a1{l};
								TotN = TotN + _a1{l};
							end;
						end;
						* Get the col totals;
						do j = 1 to &NGroups;
							_a5{j} = 0;
							do i = 1 to &NCat;
								l = (i-1)*&NGroups + j;
								_a5{j} = _a5{j} + _a1{l};
							end;
						end;
						* Create the appropriate output for each row of the categorical variable;
						l = 0;
						do i = 1 to &NCat;
							do j = 1 to &Ngroups;
								l = l + 1;
								%if %quote(&FreqCell) = N %then %do; _a4{j} = trim(Left(put(_a1{l},10.))); %end;
								%if %quote(&FreqCell) = RP %then 
									%do; 
										if _a6{i} > 0 then 
											do; 
												Pct = 100 * _a1{l} / _a6{i}; 
												_a4{j} = trim(left(put(Pct,5.1)))||'%'; 
											end;
										else _a4{j} = '0.0%';
									%end;
								%if %quote(&FreqCell) = CP %then
									%do;
										if _a5{j} > 0 then
											do;
												Pct = 100 * _a1{l} / _a5{j};
												_a4{j} = trim(left(put(Pct,5.1)))||'%';
											end;
										else _a4{j} = '0.0%';
									%end;
								%if %quote(&FreqCell) = %quote(N(RP)) %then 
									%do;
										if _a6{i} > 0 then
											do;
												Pct = 100 * _a1{l} / _a6{i};
												_a4{j} = trim(left(put(_a1{l},10.)))||' ('||trim(left(put(Pct,5.1)))||'%)';
											end;
										else _a4{j} = '0 (0.0%)';
									%end;
								%if %quote(&FreqCell) = %quote(N(CP)) %then
									%do;
										if _a5{j} > 0 then
											do;
												Pct = 100 * _a1{l} / _a5{j};
												_a4{j} = trim(left(Put(_a1{l},10.)))||' ('||trim(left(put(Pct,5.1)))||'%)';
											end;
										else _a4{j} = '0 (0.0%)';
									%end;
								%if %quote(&FreqCell) = %quote(RP(N)) %then
									%do;
										if _a6{i} > 0 then
											do;
												Pct = 100 * _a1{l} / _a6{i};
												_a4{j} = trim(left(put(Pct,5.1)))||'% ('||trim(left(put(_a1{l},10.)))||')';
											end;
										else _a4{j} = '0.0% (0)';
									%end;
								%if %quote(&FreqCell) = %quote(CP(N)) %then
									%do;
										if _a5{j} > 0 then
											do;
												Pct = 100 * _a1{l} / _a5{j};
												_a4{j} = trim(left(put(pct,5.1)))||'% ('||trim(left(put(_a1{l},10.)))||')';
											end;
										else _a4{j} = '0.0% (0)';
									%end;
							end;
							* all items in the row have been created so output the observation;
							PValue1 = '';
							PValue2 = '';
							%if (&P = T or &P = W or &P = TW or &P = WT) and &NGroups > 1 %then
								%do;
									if i = 1 then PValue1 = trim(left("&PChi"));
								%end;
							Label = '   '||left(trim(_a2{i}));
							Pct = 100 * _a6{i} / TotN;
							Total = trim(left(put(_a6{i},10.)))||' ('||trim(left(put(Pct,5.1)))||'%)';
							output;
						end;
						* Output an observation of column totals;
						%if &Total = C or &Total = RC %then
							%do;
								Label = '   Total';
								do j = 1 to &NGroups;
									_a4{j} = trim(left(put(_a5{j},10.)));
								end;
								Total = trim(left(put(TotN,10.)));
								output;
							%end;
						* Write a blank observation;
						do j = 1 to &NGroups;
						   _a4{j} = '';
						end;
						Label = '';
						PValue1 = '';
						PValue2 = '';
						Total = '';
						output;

					end;
			run;
			proc append base = _all2 data = _freqs force; 
			run;
		%end;
	run;
	
	* Get group Ns and put into macro variables;
	proc freq data = _use; tables &GroupVar/out=_getns;
	data _null_;
	   set _getns end = done;
		if _n_ = 1 then TotN = 0;
		Retain TotN;
		TotN = TotN + Count;
		call symput('N'||left(_n_),Count);
		if done then call symput('TotN',TotN);
	run;
	
	data _all3;
	   set _all2 end = done;
		if _n_ = 1 then do; HasT = 0; HasMW = 0; HasChisq = 0; HasFisher = 0; end;
		Retain HasMW HasChisq HasFisher HasT;
		%if &P = T or &P = TW or &P = WT %then
			%do;
				if index(PValue1,Byte(176)) > 0 or Index(PValue2,Byte(176)) > 0 then HasT = 1;
			%end;
		if index(PValue1,Byte(185)) > 0 then HasMW = 1;
		if index(PValue1,Byte(178)) > 0 then HasChisq = 1;
		if index(PValue1,Byte(179)) > 0 then HasFisher = 1;
		array a1 {&NGroups} n1-n&NGroups;
		Label label = 'Variable'
		%if &NGroups = 1 %then
			%do;
				GroupVal1 = "All Data / (N=%trim(&N1))";
			%end;
		%else
			%do;
				%do i = 1 %to &NGroups;
		   		Groupval&i = "&GroupVar = &&val&i /(N=%trim(&&N&i))"
				%end;
				PValue1 = 'P-Value'
				PValue2 = 'P-Value'
				%if &Total = R or &Total = RC %then
					%do;
						Total = "Total (N=%trim(&TotN))"
					%end;
				;
			%end;
		if done then
			do;
				Length Msg0 Msg1 Msg2 Msg3 $ 40;
				Msg0 = Byte(176)||" based on pooled variances t-test";
				%if &NGroups = 2 %then
					%do;
						Msg1 = Byte(185)||" based on Mann-Whitney test";
					%end;
				%if &NGroups > 2 %then
					%do;
						Msg1 = Byte(185)||" based on Kruskal-Wallis test";
					%end;
				Msg2 = Byte(178)||" based on Chi-square test";
				Msg3 = Byte(179)||" based on Fisher's exact test";
				Call Symput('HasT',HasT);
				Call Symput('HasMW',HasMW);
				call Symput('HasChisq',HasChisq);
				Call Symput('HasFisher',HasFisher);
				Call Symput('Msg0',Msg0);
				Call Symput('Msg1',Msg1);
				Call Symput('Msg2',Msg2);
				Call Symput('Msg3',Msg3);
			end;
	run;
	%if &Print = Y %then
		%do;
			ods listing;
			proc print noobs label split = '/' data = _all3 uniform; var GroupVal1-GroupVal&NGroups 
			%if &Total = R or &Total = RC %then %do; Total %end;
			%if &P = T or &P = W or &P = TW or &P = WT %then
				%do;
					%if &NGroups > 1 %then %do; PValue1 %end;
				%end;
			%if &P = TW or &P = WT %then
				%do;
					%if &NGroups > 1 %then %do; PValue2 %end;
				%end;
			;
			id label;
			%Let NNote = 0;
			%if &P = T or &P = W or &P = TW or &P = WT %then
				%do;
					%if &HasT = 1 %then
						%do;
							%Let NNote = %eval(&NNote+1);
							FootNote%trim(&NNote) "&Msg0";
						%end;
					%if &HasMW  = 1 %then 
						%do;
							%Let NNote = %eval(&NNote + 1);
							FootNote%trim(&NNote) "&Msg1";
						%end;
					%if &HasChisq  = 1 %then
						%do;
							%Let NNote = %eval(&NNote+1);
							FootNote%trim(&NNote) "&Msg2";
						%end;
					%if &HasFisher  = 1 %then
						%do;
							%Let NNote = %eval(&NNote+1);
							FootNote%trim(&NNote) "&Msg3";
						%end;
				%end;
			run;
			data _null_;
	  			set _all3 (obs = 1);
				Footnote1 " ";
				Footnote2 " ";
				Footnote3 " ";
				Footnote4 " ";
			run;
		%end;

	%if &Out ne %then
		%do;
			data &out (Type = 'Table1' Label="Groups=%trim(%left(&NGroups)) P=&P" drop = n1 n2 Variable HasT HasMw HasChisq HasFisher Msg0 Msg1 Msg2 Msg3
				%if &Total = N %then %do; Total %end; );
			   set _all3;
			run;
		%end;

	%if &NNumVars > 0 %then
		%do;
			%if &NGroups > 1 %then
				%do;
					* If no print and no npar1way output file, then %npar1way will stop, so give it a dummy file;
					%if &Print = N and &Out1way = %then %Let Out1way = _junk;
					title2 "Descriptive statistics and comparisons by group";
					%NPar1way(dsname=&dsname,GroupVar=&GroupVar,Vars=&NumVars,ByVars=,Print=&Print,VarName=Y,Label=N,Dec=3,Out=&Out1way) 
				%end;
			%else
				%do;
					title2 "Descriptive statistics";
					%Univariate(dsname=&dsname,Vars=&NumVars,Print=&Print,out=&Out1way)
				%end;
		%end;

	%ExitTable1:
   proc datasets nolist; delete _all _all2 _all3 _allnpar _counts _counts2 _freqs _gpvarcounts 
		_stats  _use _tabutemp _tabutemp2 _tabutemp3 _wilcoxon _wil2; quit;  
%mend Table1;
