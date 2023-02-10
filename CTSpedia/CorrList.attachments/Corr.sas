* Macro corr is a rewrite of the corrlist macro with a number of enhancements:
		Variable lists can be crossed (as in the current corrlist) or paired.
      The second variable list can be omitted to generate all non-redundant pairs of the first list.
      Output can be sorted by variable name (as in the current corrlist) or according to the
         list order or by absolute Pearson or Spearman value.
      Listwise or pairwise deleting of missing values.
      Error handling is improved.

  Note that the names of the variables in the output file have been changed from the old corrlist
  macro. They are IVar, JVar, N (as before), CorrP, LowerCLP, UpperCLP, PValueP and four analogous
  varibles ending in S for the Spearman.
         
  Parameters:
  		DSName = data set name
		IVar = 1st variable list   (cannot be empty)
		JVar = 2nd variable list	(can be empty)
		Pairs = X crossed, all IVar variables paired with all JVar variables , the default
            = P paired, 1st IVar variable paired with 1st JVar variable, etc.  This option
                 requires the two lists to have the same number of variables.  This option
                 is ignored if JVar list is empty.
		Missing = L listwise deletion of missing values
              = P pairwise deletion of missing values
                default = P
		ByVars = any By variables
		Print = Y/N (default=Y)
		Out = output data set
		Label = Y/N to label printed output (default=Y)
		Sort = A for alpha sort if IVar, then JVar within IVar
			  = O for original order, each IVar paired with all JVar 
			  = P for sorting by descending absolute Pearson correlation
			  = S for sorting by descending absolute Spearman correlation
				 (default=O)
	The macros called by corr are CheckVar, Varlist, and Words.;	

%Let MacroDir = L:\BCU Macros\Macros;
%include "&MacroDir\CheckVar.sas";
%include "&MacroDir\Varlist.sas";
%include "&MacroDir\Words.sas";

%macro corr(DSName=,IVar=,JVar=,Pairs=X,Missing=P,ByVars=,Print=Y,Out=,Label=Y,Sort=O);

	%Local BadVar I J JVarEmpty K LastVar LongList NBy NCorr NIVar NIJVar NJVar NOrigBy OneBy ThisList Var Varlist;
	%Varlist(VLDsname=&dsname,ShortList=&IVar);
	%Let IVar = %str( )%upcase(%cmpres(&_LongList))%str( );
	%Varlist(VLDsname=&Dsname,ShortList=&JVar);
	%Let JVar = %str( )%upcase(%cmpres(&_LongList))%str( );
	%Let ByVars = %str( )%upcase(%cmpres(&Byvars))%str( );
	%Let Pairs = %upcase(&Pairs);
	%Let Missing = %upcase(&Missing);
	%Let Print = %upcase(&Print);
	%Let Label = %upcase(&Label);
	%Let Sort = %upcase(&Sort);
	
	%Let NIVar = %words(&IVar);
	%Let NJVar = %words(&JVar);
	%Let NOrigBy = %words(&Byvars);
	%Let NIJVar = %eval(&NIVar + &NJVar);

	%if &Out= and &Print=N %then
		%do;
			%put;
			%put Error: No output file and Print = N.;
			%put;
			%goto ExitCorr;
		%end;

	* Check that all IVar, JVar and By variables are in the data set;
	%Let Varlist = %upcase(%cmpres(&IVar%str( )&JVar%str( )&ByVars));
	%CheckVar(CVDSName=&DSName,CVVars=&Varlist,Message=Y)
	%if &_Error =1 %then %Goto ExitCorr;
   
	* Check for alpha variables in the IVar, JVar lists;
	%Let Varlist = %upcase(%cmpres(&IVar%str( )&JVar%str( )));
	%do J = 1 %to &NIJVar;
		%Let Var = %scan(&Varlist,&J);
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
		%if &BadVar = 1 %then %goto ExitCorr;
	%end;
	
	* If JVar is not empty and Pairs = P, then check that lists are the same length;
	%if &NJVar > 0 and &Pairs = P %then
		%do;
			%if &NIVar ne &NJVar %then
				%do;
					%put;
					%put Error: Variable lists must be the same length when requesting pairing of IVar and JVar lists.;
					%put;
					%Goto ExitCorr;
				%end;
		%end;
	
	* If JVar is empty, then set a flag to remember this and copy IVar to JVar;
	%Let JVarEmpty = 0;
	%if &NJVar = 0 %then
		%do;
			%Let JVarEmpty = 1;
			%Let JVar = &IVar;
			%Let NJVar = &NIVar;
		%end;

   * If no by vars, set up one phony by var for consistency;
	%if &NOrigBy = 0 %then
		%do;
			%Let NBy = 1; 
			%Let ByVars = _phonyby;
		%end;
	%else %Let NBy = &NOrigBy;
				
	* Eliminate observations with missing data on any By variables;
	data _nomiss;
	   set &DSName;
		%if &NOrigBy > 0 %then
			%do I = 1 %to &NBy;
				%Let Var = %scan(&ByVars,&I);
				if missing(&Var) then delete;
			%end;
		%else
			%do;
				_PhonyBy = 1;
			%end;
	run;
				
	* Sort the file;
	proc sort data = _nomiss; by &byvars; 

	* Create the correlations;
	ods listing close;
	proc corr data = _nomiss spearman pearson
	%if &Missing = L %then %do; nomiss %end;
	;
		var &Ivar; with &jvar; by &byvars;
		ods output PearsonCorr = _pearson;
		ods output SpearmanCorr = _Spearman;
	run;

	* If Missing = L or if a by group has no missing data then the ods output data sets do not contain Ns.
	  For this reason we make a separate pass through the data to tally the ns and store them in a data
	  set which we can merge with the correlations.;

	%Let NCorr = %trim(%eval(&NIVar * &NJvar));
	data _ns (Keep = &Byvars IVar JVar N);
	   set _nomiss; by &byvars;
		Length IVar JVar $ 32;
		array _a1 {*} N1-N&NCorr;
		array _a2 {*} &IVar;
		array _a3 {*} &JVar;
		if
		%do i = 1 %to &NBy;
         %Let OneBy = %scan(&ByVars,&i);
         First%str(.)&OneBy
         %if &i < &NBy %then %do; or %end;
      %end;
		then do i = 1 to &NCorr; _a1{i} = 0; end;
		retain N1-N&NCorr;
		%if &Missing = P %then
			%do;
				k = 0;
				do i = 1 to &NIVar;
				   do j = 1 to &NJVar;
					   k = k + 1;
						if not(missing(_a2{i})) and not(missing(_a3{j})) then _a1{k} = _a1{k} + 1;
					end;
				end;
			%end;
		%else
			%do;
				%Let ThisList =;
				%do i = 1 %to &NIVar;
					%Let ThisList = &ThisList %scan(&IVar,&i)%str(,);
				%end;	
				%do i = 1 %to &NJVar;
					%if &i < &NJVar %then
						%do;
							%Let ThisList = &ThisList %scan(&JVar,&i)%str(,);
						%end;
					%else
						%do;
							%Let ThisList = &ThisList %scan(&JVar,&i);
						%end;
				%end;
				if nmiss(of &ThisList) = 0 then
					do i = 1 to &NCorr;
					   _a1{i} = _a1{i} + 1;
					end;
			%end;
		if
		%do i = 1 %to &NBy;
		   %Let OneBy = %scan(&ByVars,&i);
			Last%str(.)&OneBy
			%if &i < &NBy %then %do; or %end;
		%end;
		then 
			do;												* Arrange the data so there is one obs per corr per by group;
				k = 0;
				do i = 1 to &NIVar;
					IVar = VName(_a2{i});
				   do j = 1 to &NJvar;
						JVar = VName(_a3{j});
					   k = k + 1;
						N = _a1{k};
						output;
					end;
				end;
			end;
	run;
	proc sort data = _ns; by &byvars IVar JVar;
	
	* Arrange the Pearson and Spearman data sets to one observation per correlation;
	%Let LastVar = P%scan(&IVar,&NIVar); 
	data _pearson2 (Keep = IVar JVar CorrP PValueP AbsCorrP OrigOrder &Byvars);
	   set _pearson;
		Length IVar JVar $ 32;
		array _a1 {*} &IVar -- &LastVar;
		OrigOrder = _n_ - &NJVar;
		do j = 1 to &NIVar;
		   JVar = Variable;
			IVar = VName(_a1{j});
			CorrP = _a1{j};
			AbsCorrP = abs(CorrP);
			PValueP = _a1{j + &NIVar};
			OrigOrder = OrigOrder + &NJVar;
			output;
		end;
	run;
	proc sort data = _pearson2; by &byvars ivar jvar;

	data _spearman2 (Keep = IVar JVar CorrS PValueS AbsCorrS &ByVars);
		set _spearman;
		Length IVar JVar $ 32;
		array _a1 {*} &IVar -- &LastVar;
		do j = 1 to &NIVar;
		   JVar = Variable;
			IVar = VName(_a1{j});
			CorrS = _a1{j};
			AbsCorrS = abs(CorrS);
			PValueS = _a1{j + &NIVar};
			output;
		end;
	run;
	proc sort data = _spearman2; by &byvars ivar jvar;

	* Merge Pearson, Spearman and N data sets and compute confidence intervals;
	data _both (drop = x);
	   merge _Pearson2 _Spearman2 _ns; by &byvars ivar jvar;
		if N > 2 and CorrP not in(-1,1) then X = 0.5 * Log((1 + CorrP) / (1 - CorrP));
		if N > 3 then
			do;
				LowerCLP = tanh(X - 1.96 / (N - 3)**.5);
				UpperCLP = tanh(X + 1.96 / (N - 3)**.5);
			end;
		if N > 2 and CorrS not in(-1,1) then X = 0.5 * Log((1 + CorrS) / (1 - CorrS));
		if N > 3 then
			do;
				LowerCLS = tanh(X - 1.96 / (N - 3)**.5);
				UpperCLS = tanh(X + 1.96 / (N - 3)**.5);
			end;
	run;
   
	* If JVar list not empty and Pairs = P then eliminated unwanted correlations;
	%if &JVarEmpty = 0 and &Pairs = P %then
		%do;
			data _both2;
				set _both; by &byvars;
				%do i = 1 %to &NIVar;
				   if upcase(IVar) = "%upcase(%scan(&IVar,&i))" and upcase(JVar) = "%upcase(%scan(&JVar,&i))" then output;
				%end;
			run;
		%end;

	* If JVar list is empty then eliminate redundant correlations;
	%if &JVarEmpty = 1 %then
		%do;
			data _both2 (drop = i j);
			   set _both; by &byvars;
				if
      		%do i = 1 %to &NBy;
         		%Let OneBy = %scan(&ByVars,&i);
         		First%str(.)&OneBy
         		%if &i < &NBy %then %do; or %end;
      		%end;
				then do; i = 1; j = 0; end;
				retain i j;
				j = j + 1;
				if j > &NIvar then do; j = 1; i = i + 1; end;
				if i < j then output;
			run;
		%end;

	* If JVar list is not empty and Pairs = X then copy _both to _both2;
	%if &JVarEmpty = 0 and &Pairs = X %then
		%do;
			data _both2;
			   set _both;
			run;
		%end;
		
	* Sort _both2 as requested;
	proc sort data = _both2; by &byvars
	%if &Sort = O %then %do; OrigOrder %end;
	%if &Sort = A %then %do; IVar JVar %end;
	%if &Sort = P %then %do; descending AbsCorrP %end;
	%if &Sort = S %then %do; descendind AbsCorrS %end;
	;
	* Add labels and create formatted p-values; 
	proc format; value _pfmt . = ' ' low-.00995 = [pvalue6.4] .00995-.0995 = [6.3] .0995-1 = [6.2];
	data _both2;
	   set _both2 (drop = AbsCorrP AbsCorrS OrigOrder);
		PValuePAlpha = left(put(PValueP,_pfmt.));
		PValueSAlpha = left(put(PValueS,_pfmt.));
		format CorrP LowerCLP UpperCLP CorrS LowerCLS UpperCLS 5.3;
		label	CorrP	= 'Pearson Correlation'
				PValueP	= 'Pearson P-Value'
				PValuePAlpha = 'Pearson P-Value'
				LowerCLP	= 'Pearson 95% CI Lower'
				UpperCLP	= 'Pearson 95% CI Upper'
				CorrS = 'Spearman Rank Correlation'
				PValueS = 'Spearman P-Value'
				PValueSAlpha = 'Spearman P-Value'
				LowerCLS	= 'Spearman 95% CI Lower'
				UpperCLS	= 'Spearman 95% CI Upper';
		%if &NOrigBy = 0 %then %do; drop _phonyby; %end;
	run;
	
	%if &Print = Y %then
		%do;
			ods listing;
			proc print data = _both2 noobs uniform
			%if &Label = Y %then %do; label %end;
			;
			var n CorrP LowerCLP UpperCLP PValuePAlpha CorrS LowerCLS UpperCLS PValueSAlpha;
			id ivar jvar;
			%if &NOrigBy > 0 %then %do; by &byvars; %end;
			run;
		%end;
	%if &out ne %then
		%do;
			data &out;
			   set _both2;
			run;
		%end;
	
	%ExitCorr:
	%if &JVarEmpty = 1 %then %Let JVar =;
	%if &NOrigBy = 0 %then %Let ByVars =;
	
	proc datasets nolist; delete _both _both2 _nomiss _ns _Pearson _Pearson2 _Spearman _Spearman2; quit; 

%mend corr;
