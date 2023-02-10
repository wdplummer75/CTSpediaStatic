* Macro logistic invokes SAS proc logistic and organizes the output.  It has options for automatic creation of quartile
  variables and/or quadratic variables.
  The macro parameters are:

   DSName       = name of SAS data set
   Outcome      = name of outcome variable.  This variable is assumed to be coded 0, 1 and the model predicts the
                  probability of a 1 outcome.
   Predictors   = list of predictor variables. This list should include class variables and variables to be 'quartiled.'
				      Interaction variables may be included in which case the predictor list should be quoted, e.g.
				      Predictors = %quote(Age Gender Age*Gender).  Note: all variables appearing in interaction terms
				      should also appear as main effects. 
   Classvar     = classification variables with reference level.  Use %quote function.  For example,
                  Classvar=%quote(Gender(ref='Male')Race(ref='Asian'))  Gender and Race could be numeric variables with
                  formatted values of Male or Asian or they could be alphanumeric variables with string values of 'Male'
                  and 'Asian'.  Do not include variables for which quartiles are to be generated.
   Quartiles    = list of numeric variables which should be entered into the model as class variables with four quartile
                  levels. Variables in this list will not be included in the model as linear predictors.
   Quad         = Y/N for creating and testing quadratic terms (default = Y)
   Out          = name of output SAS data set containing logistic estimates, p-values, etc.
   Print        = Y/N (default = N)
   Include      = F,P,FP,or N
                  F = frequencies of outcome variable are displayed for each class variable value, e.g., Sex Female 31/100
                  P = percentages are displayed with class variable values, e.g., Sex Female 31.0%
                  FP = frequencies and percentages are displayed with class variable values, e.g., Sex Female  31/100 (31.0%).
                  N = no frequencies or percentages are displayed with class variable values (default = FP)
   Obs          = Y/N  If Y, then the number of observations in each outcome group and the total are displayed. (default = Y)
   LL           = Y/N  If Y, then -2log(likelihood) is displayed. (default = N)
   HL           = Y/N  If Y, then the Hosmer-Lemeshow p-value is displayed along with the number of groups of estimates
                  (default = N).

Special features:
   The macro will automatically test a quadratic term for numeric (non-class) predictors with more than two values.
   The macro will automatically output odds ratios that have been rescaled until the units > 1/10 of the IQR.

The macros called by this macro are %words, %checkvar, %univariate, and %quartiles.  The global macro _Model
is incremented by one with each call to the logistic macro.  The model number is printed and/or saved to the output file.
To reset the model counter to start at one, use the command: [percent sign]Let _Model = 0;

filename words URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;
filename chkvar URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckVar.sas";
%include chkvar;
filename quart URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/quartiles.sas";
%include quart;
filename univar URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/Univariate.sas";
%include univar;


%macro logistic(DSName=,Outcome=,Predictors=,ClassVar=,Quartiles=,Quad=Y,Out=,Print=N,Include=FP,Obs=Y,LL=N,HL=N);

   %Local AFormat BadOutcome ClassVariables Flag Has0 Has1 I J K L MaxAfter MaxBefore NAst NClass NextVar NInt NPred NQuart
          NNumVars NumVars NNumVars2 NObs NumVars2 Status TempVars TestVar ThisVar Unique Var VarList VarName VarType ;

   %Global  _ClassVar _ClassVariables _Error _Model;

   *Make sure just one leading and trailing blank and replace multiple blanks with single blanks in all lists.
    Convert all text to uppercase;
   %Let Predictors = %str( )%upcase(%cmpres(&Predictors))%str( );
   %Let Quartiles = %str( )%upcase(%cmpres(&Quartiles))%str( );
   %Let NQuart = %words(&Quartiles);
   %Let Include = %upcase(&Include);
   %Let LL = %upcase(&LL);
   %Let HL = %upcase(&HL);
   %Let Print = %upcase(&Print);
   %Let Quad = %upcase(&Quad);
   %Let Obs = %upcase(&Obs);

	* Look for interactions and make sure asterisks have one blank on each side;
	%Let TempVars = &Predictors;
	%Let Predictors = ;
	%Let NAst = 0;											* number of asterisks in predictor list;
	%do %while(%index(&TempVars,%str(*)) > 0);
		%Let K = %index(&TempVars,%str(*));
		%Let NAst = %eval(&NAst + 1);
		%Let Predictors = &Predictors %substr(&TempVars,1,%eval(&K-1))%str( )%str(*)%str( );
		%Let TempVars = %substr(&TempVars,%eval(&K+1));
	%end;
	%Let Predictors = &Predictors &TempVars;
	%Let Predictors = %str( )%cmpres(&Predictors)%str( );
	%Let NPred = %words(&Predictors);						* This will count 3 predictors for Age * Sex;

   *Create a list of class variable names in ClassVariables;
   %Let ClassVariables =;
   %Let TempVars = %upcase(&ClassVar)%str( );   * Make a copy that can be modified. Then remove reference values spece.;
   %do %while(%index(&TempVars,%str(%()) > 0);
      %Let K = %index(&TempVars,%str(%());
      %Let L = %index(&TempVars,%str(%)));
      %if &L = 0 %then
         %do;
            %put;
            %put Error: Unbalanced parens in classvar parameter.;
            %put;
            %goto ExitLogistic;
         %end;
      %else
         %do;
            %Let TempVars = %substr(&TempVars,1,%eval(&K-1))%str( )%substr(&TempVars,%eval(&L+1));
            %Let TempVars = %cmpres(&TempVars)%str( );
         %end;
   %end;
   %Let Flag = 0;                         * Flag = 1 indicates we have all the class variables;
   %Let TempVars = %cmpres(&TempVars)%str( );
	
   %do %while(&Flag = 0);
      %Let K = %Index(&TempVars,%str( ));    * look for a blank;
      %if &K = 0 or &K > %length(&TempVars) %then
         %do;
            %Let Flag = 1;
         %end;
      %else
         %do;
				%if &K > 1 %then
					%do;
        		%Let VarName = %substr(&TempVars,1,%eval(&K-1));
        		%Let ClassVariables = &ClassVariables%str( )&VarName;
					%end;
            %Let K = %eval(&K+1);
            %if &K <= %length(&TempVars) %then
               %do;
                  %Let TempVars = %substr(&TempVars,&K);  * Delete this portion of TempVars;
                  %Let TempVars = %cmpres(&TempVars)%str( );
               %end;
            %else %Let TempVars=;
         %end;

   %end;
   %Let ClassVariables = %str( )%cmpres(&ClassVariables)%str( );
   %Let NClass = %words(&ClassVariables);

	* Create a list of unique variable names in the predictor list;
	%Let Unique =;
	%do i = 1 %to &NPred;
		%Let ThisVar = %scan(&Predictors,&i);
		%Let K = %index(&Unique,%str( )&ThisVar%str( ));
		%if &K = 0 %then
			%do;
				%Let Unique = &Unique%str( )&ThisVar%str( );
			%end;
	%end;
   * Check that the outcome and all variables in the predictor list are in the data set;
   %Let VarList = %upcase(%cmpres(&Outcome%str( )&unique));
   %CheckVar(CVDsname=&DSName,CVVars=&Varlist,Message=Y);
   %if &_Error = 1 %then %goto ExitLogistic;

   * Check that outcome is not in the predictor list;
   %if %index(%str( )%upcase(&Predictors)%str( ),%str( )%upcase(&Outcome)%str( )) > 0 %then
      %do;
         %put;
         %put Error: Outcome variable cannot be in the list of predictors.;
         %put;
         %goto ExitLogistic;
      %end;

   * Check that variables in the ClassVariables and Quartiles lists are all in the Predictor list;
   %Let VarList = %str( )%cmpres(&ClassVariables &Quartiles)%str( );
   %do i = 1 %to %words(&Varlist);
      %Let TestVar = %scan(&Varlist,&i);
      %Let K= %Index(&Predictors,%str( )&TestVar%str( ));
      %if &K = 0 %then
         %do;
            %put;
            %put Error: Variable &TestVar is not in the list of predictors.;
            %put;
            %goto ExitLogistic;
         %end;
   %end;

   * Check that variables in the predictor list that are not in ClassVariables are in fact numeric. 
	  Variables in main effects and interaction terms will be checked more than once, but that is ok;
   %do i = 1 %to %eval(&NPred - &NAst);
      %Let TestVar = %scan(&Predictors,&i);	
	   %Let K = %Index(&ClassVariables,%str( )&TestVar%str( ));
      %if &K = 0 %then
         %do;
            data _null_;
               set &dsname (obs = 1);
               VarType = Vtype(&TestVar);
               call symput('VarType',VarType);
            run;
            %if &VarType ne N %then
               %do;
                  %put;
                  %put Error: Variable &TestVar is not numeric and is not in the list of class variables.;
                  %put;
                  %goto ExitLogistic;
               %end;
         %end;
    %end;
	
   * Create a a series of macro variables _LogDV1,_LogDV2,...,_LogDV&NPred that will be 1 if that numeric variable is a date variable
     otherwise 0.;
   data _null_;
      set &dsname (obs = 1);
      %do i = 1 %to %eval(&NPred - &NAst);
         %Let ThisVar = %scan(&Predictors,&i);
         Fmt = VFormatN(&ThisVar);
			Call Symput("_LogDV&I",0);
         if Fmt in('DATE','NENGO','DDMMYY','JULIAN','MMDDYY','YYMMDD','WEEKDATE','WEEKDATX','WORDDATE','WORDDATX') then Call Symput("_LogDV&I",1);
      %end;
   run;
		
   * Create dataset _nomiss that eliminates all observations with any missing data on the predictors or the outcome.
     Also check that the outcome variable has only values of 0 and 1 (and at least one of each).;
   data _nomiss;
      set &dsname (Keep = &Outcome &Unique) end = done;       * Keep only the needed variables for efficiency;
      if _n_ = 1 then
         do;
            _Outcome0 = 0;
            _Outcome1 = 0;
            _BadOutcome = 0;
         end;
      retain _Outcome0 _Outcome1 _BadOutcome;
      AnyMissing = 0;
      if missing(&Outcome) then AnyMissing = 1;          * Missing() returns 1 if either a character or numeric var is missing;
      %do i = 1 %to %eval(&NPred - &NAst);
         %Let ThisVar = %scan(&Predictors,&i);
         if missing(&ThisVar) then AnyMissing = 1;
      %end;
      if AnyMissing Then Delete;
      if &Outcome = 0 then _Outcome0 = _Outcome0 + 1;
      if &Outcome = 1 then _Outcome1 = _Outcome1 + 1;
      if &Outcome ne 0 and &Outcome ne 1 then _BadOutcome = 1;
      if done then
         do;
            call symput('BadOutcome',_BadOutcome);
            call symput('Has0',_Outcome0);
            call symput('Has1',_Outcome1);
         end;
   run;
   %if &BadOutcome = 1 %then
      %do;
         %put;
         %put Error: Outcome variable &Outcome has nonmissing values other than 0 and 1;
         %put
         %goto ExitLogistic;
      %end;
   %if &Has0 = 0 %then
      %do;
         %put;
         %put Error: Outcome variable &Outcome has no zeros;
         %put;
         %goto ExitLogistic;
      %end;
   %if &Has1 = 0 %then
      %do;
         %put;
         %put Error: Outcome variable &Outcome has no ones;
         %put;
         %goto ExitLogistic;
      %end;
	
   * Create a list of numeric predictors that are not class or quartile variables;
   %Let VarList = %str( )%cmpres(&ClassVariables &Quartiles)%str( );
   %Let NumVars =;
   %do i = 1 %to %words(&unique);
      %Let ThisVar = %scan(&unique,&i);
      %Let K = %Index(&VarList,%str( )&ThisVar%str( ));
      %if &K = 0 %then
         %do;
            %Let NumVars = &NumVars%str( )&ThisVar;
         %end;
   %end;
   %Let NumVars = %str( )%cmpres(&NumVars)%str( );
   %Let NNumVars = %words(&NumVars);

   * Check that each of these numeric predictors has more than two levels.
     Put numeric variables with more than two levels into &NumVars2;
   %Let NumVars2 =;
   %if &NNumVars > 0 %then
      %do i = 1 %to &NNumVars;
         %Let ThisVar = %scan(&NumVars,&i);
         proc freq noprint data = _nomiss; tables &ThisVar/out=_counts;
         run;
         data _null_;
            set _counts (obs = 1) nobs = last;
            call symput('NObs',Last);
         run;
         %if &NObs > 2 %then %Let NumVars2 = &Numvars2%str( )&ThisVar;
      %end;
   %Let NumVars2 = %str( )%cmpres(&NumVars2)%str( );
   %Let NNumVars2 = %words(&NumVars2);

   * Create squared variables for all variables in NumVars2;
   %if NNumVars2 > 0 and &Quad = Y %then
      %do;
         data _nomiss;
            set _nomiss;
            %do i = 1 %to &NNumVars2;
               %Let ThisVar = %scan(&NumVars2,&i);
               _&ThisVar.2 = &ThisVar * &ThisVar;
            %end;
         run;
      %end;

   * Create quartile variables and add them to the classvar and classvariables lists;
   %if &NQuart > 0 %then
      %do;
         %Let _ClassVar = &ClassVar;
         %Let _ClassVariables = &ClassVariables;
         %Quartiles(QDsname=_nomiss,QVars=&Quartiles)
         %Let ClassVar =&_ClassVar;
         %Let ClassVariables = &_ClassVariables;
      %end;

   %Let NClass = %eval(&NClass + &NQuart);

   * Now fit the basic model without quadratic terms;
   ods listing close;
   proc logistic data = _nomiss order = internal descending;
      %if %length(&ClassVar)> 0 %then %do; class &classvar/param=ref order=internal desc; %end;
      model &Outcome = &Predictors/lackfit;
      ods output ConvergenceStatus = _cs;
      ods output FitStatistics = _fs;
      ods output LackFitChiSq = _hl;
      ods output ParameterEstimates = _pe;
      %if %length(&Classvar) > 0 %then %do; ods output Type3 = _t3; %end;
      ods output ResponseProfile = _rp;
   run;
	
   data _null_;
      set _cs;
      call symput('Status',Status);
   run;

   * Get frequencies and percentages for class variables.  Do this even if Include = N so that we get the reference levels.;
   %if &NClass > 0 %then
      %do;
         proc datasets nolist; delete _allcounts; quit;
         %do i = 1 %to &NClass;
            %Let ThisVar = %scan(&ClassVariables,&i);
            proc freq data = _nomiss noprint; tables &ThisVar * &Outcome/out = _counts;
            proc sort data = _counts; by &ThisVar &Outcome;
            data _null_;
               set _Counts (obs = 1);
               Call symput('AFormat',VFormat(&ThisVar));
            run;
            data _counts2;       * reduce _counts to one obs per value of thisvar;
               set _counts (drop = percent); by &ThisVar;
               if first.&ThisVar then Total = 0;
               retain Total;
               Total = Total + count;
               if last.&ThisVar then
                  do;
                     Length Var $ 32 ClassVal0 $ 50 ;
                     Var = "&ThisVar";
                     ClassVal0 = Trim(Left(Put(&ThisVar,&AFormat)));
                     Freq = count;
                     if &Outcome = 0 then Freq = 0;                  * if last value of &This var is 0 then no events;
                     if Total > 0 then Percent = 100 * Freq / Total;
                     Keep Var ClassVal0 Freq Percent Total;
                     output;
                  end;
            run;
            proc append base = _allcounts data = _counts2;
            run;
         %end;
         * Remember the order in _allcounts;
         data _allcounts;
            set _allcounts;
            Order = _n_;
         run;
         data _pe;               * remember original order of variables;
           set _pe;
           Length PrevVar $ 32;
           if _n_ = 1 then OrderBetween = 0;
           Retain OrderBetween PrevVar;
           if _n_ = 1 or Variable ne PrevVar then OrderBetween = OrderBetween + 1;
           PrevVar = Variable;
           Length Var $ 32;
           Var = upcase(Variable);
         run;
         proc sort data = _pe; by var classval0;
         proc sort data = _allcounts; by var classval0;
         data _pe2 (drop = PrevVar);
            merge _pe _allcounts; by var classval0;
         run;
         proc sort data = _pe2; by Order;
         data _pe3 (drop = Order);
            set _pe2;
            Length FreqPct $ 40;
            if Freq ne . then
               do;
                  %if &Include = F %then %do; FreqPct = trim(left(put(Freq,8.)))||'/'||trim(left(put(total,8.))); %end;
                  %if &Include = P %then %do; FreqPct = Trim(left(put(percent,5.1)))||'%'; %end;
                  %if &Include = FP %then %do; FreqPct = trim(left(put(Freq,8.)))||'/'||trim(left(put(total,8.)))||' ('||trim(left(put(percent,5.1)))||'%)'; %end;
						if index(Variable,'*') > 0 then FreqPct = '';
               end;
         run;
			ods listing close;
         * If there are numeric predictors, then use FreqPct to hold the overall proportion (%) of events;
         %if &NNumVars > 0 %then
            %do;
               data _null_;
                  set _rp;
                  Length FreqPct $ 40;
                  if _n_ = 1 then Freq = Count;
                  retain Freq;
                  if _n_ = 2 then
                     do;
                        Percent = 100 * Freq / (Count + freq);
                        %if &Include = F %then %do; FreqPct = trim(left(put(Freq,8.)))||'/'||(left(put(count+Freq,8.))); %end;
                        %if &Include = P %then %do; FreqPct = trim(left(put(Percent,5.1)))||'%'; %end;
                        %if &Include = FP %then %do; FreqPct = trim(left(Put(Freq,8.)))||'/'||trim(left(put(count+freq,8.)))||' ('||trim(left(put(percent,5.1)))||'%)'; %end;
                        call symput('Overall',FreqPct);
						   end;
               run;
					
               data _pe3;
                  set _pe3;
                  if FreqPct = '' and Var ne 'INTERCEPT' and index(var,'*') = 0 then FreqPct = "&Overall";    * must be a numeric variable if freqpct is blank;
               run;

            %end;
			
         * Create an order within each variable so the levels can later be sorted properly;
         proc sort data = _pe3; by Var;
         data _pe3;
            set _pe3; by Var;
            if first.Var then OrderWithin = 0;
            OrderWithin = OrderWithin + 1;
            Retain OrderWithin;
         run;
         proc sort data = _pe3; by var descending OrderBetween;
         data _pe3 (drop = SaveOrderBetween SaveVariable);
            set _pe3; by var;
            Length SaveVariable $ 32;
            if first.var then do; SaveOrderBetween = OrderBetween; SaveVariable = Variable; end;
            retain SaveOrderBetween SaveVariable;
            if OrderBetween = . then OrderBetween = SaveOrderBetween;
            if Variable = '' then Variable = SaveVariable;
            if df = . then df = 1;        * must be the reference category;
         run;
      %end;
   %else
      %do;
         data _pe3;
            set _pe;
            Length Var $ 32 FreqPct $ 40;
            FreqPct = '';
            Var = upcase(Variable);
            OrderBetween = _n_;
            OrderWithin = 1;
         run;
      %end;
	
   * For numeric non-quartile variables, add quadratic term to model to get p-value for quadratic trend;
   %if &NNumVars2 > 0 %then
      %do;
         %if &Quad = Y %then
            %do;
               proc datasets nolist; delete _allquad; quit;
               %do i = 1 %to &NNumVars2;
                  %Let ThisVar = %scan(&NumVars2,&i);
                  proc logistic data = _nomiss order = internal descending;
                     %if %length(&ClassVar)> 0 %then %do; class &ClassVar/param=ref; %end;
                     model &Outcome = &Predictors _&ThisVar.2;
                     ods output ParameterEstimates = _pe_;
                  run;
                  data _oneline;
                     set _pe_ (rename = (ProbChisq = PQuad));
                     Length Var $ 32;
                     if Variable = "_&ThisVar.2" then
                        do;
                           Var = "&ThisVar";          * so we can merge back into _pe3;
                           Keep Var PQuad;
                           output;
                        end;
                  run;
                  proc append base = _allquad data = _oneline force;
                  run;
               %end;
               proc sort data = _allquad; by var;
               proc sort data = _pe3; by var;
            %end;
         %univariate(dsname=_nomiss,vars=&NumVars2,Print=N,out=_irq)   * get q1 and q3 for possible rescalings;
         data _irq (Keep = Var IRQ);
            set _irq (keep = Variable q1 q3 rename = (Variable = Var));
            Var = upcase(var);
            IRQ = q3 - q1;
         run;
         proc sort data = _irq; by var;
			data _pe3;
			   merge _pe3 _irq; by var;
				if OrderBetween > 1 then IsDate = input(Left(symget('_LogDV'||left(trim(put(OrderBetween-1,5.))))),1.);
			run;
         %if &Quad = Y %then
            %do;
               data _pe3;
                  merge _pe3 _allquad; by var;
               run;
            %end;
         proc sort data = _pe3; by OrderBetween OrderWithin;
         data _pe4;
            set _pe3 (rename = (Variable = OldVar));
            Length Variable $ 50;
            Variable = OldVar;
            Unit = 1;
            output;
            Count = 0;
            if IRQ ne . then
               do;
                  Length BaseVar $ 32;
                  BaseVar = Variable;
                  do while(Unit < .1 * IRQ and Count < 2);
                     Count = Count + 1;
							if IsDate = 0 then
								do;
                     		Unit = 10 * Unit;
                     		Estimate = 10 * Estimate;
                     		StdErr = 10 * StdErr;
									Variable = trim(left(BaseVar))||' (per '||trim(left(put(Unit,8.)))||' units)';
								end;
							else
								do;
									if Unit = 1 then NewUnit = 30;
									if Unit = 30 then NewUnit = 365;
									if Unit = 365 then NewUnit = 3650;
									Unit = NewUnit;
									Estimate = Unit * Estimate;
									StdErr = Unit * StdErr;
									if Unit = 30 then Variable = trim(left(BaseVar))||' (per month)';
									if Unit = 365 then Variable = trim(left(BaseVar))||' (per year)';
									if Unit = 3650 then Variable = trim(left(BaseVar))||' (per decade)';
								end;
                     ProbChiSq = .;
                     %if &Quad = Y %then %do; PQuad = .; %end;
                     OrderWithin = OrderWithin + 0.1;

                     FreqPct = '';
                     output;
                  end;

                  Unit = 1;
                  do while (Unit > 10 * IRQ and Count < 2);
                     Count = Count + 1;
                     Unit = Unit / 10;
                     Estimate = Estimate / 10;
                     StdErr = StdErr / 10;
                     ProbChiSq = .;
                     %if &Quad = Y %then %do; PQuad = .; %end;
                     OrderWithin = OrderWithin + 0.1;
                     Variable = trim(Left(BaseVar))||' (per '||trim(left(put(Unit,10.2)))||' units)';
                     FreqPct = '';
                     output;
                  end;

               end;

      %end;
   %else
      %do;
         data _pe4;
            set _pe3 (rename = (Variable = OldVar));
            Length Variable $ 50;
            Variable = OldVar;
            Unit = .;
         run;
      %end;
   * Merge in Type 3 p-values.  Convert Estimates to Odds Ratios;
   %if %length(&ClassVar) > 0 %then
      %do;
         data _t3;
            set _t3 (rename = (Effect = OldVar ProbChisq = PType3 DF = DF3));
         run;
         proc sort data = _t3; by OldVar;
         proc sort data = _pe4; by OldVar;
         data _pe4 (drop = DF3);
            merge _pe4 _t3; by OldVar;
            if not(first.OldVar) or df3 = 1 then PType3 = .;
            OddsRatio = .;
            LowerCL = .;
            UpperCL = .;
            if Estimate = . then OddsRatio = 1; else
               do;
                  if Estimate <25 then OddsRatio = exp(Estimate);
                  X1 = Estimate - 1.96 * StdErr;
                  X2 = Estimate + 1.96 * StdErr;
                  if StdErr ne . then
                     do;
                        if X1 < 25 then LowerCL = exp(X1);
                        if X2 < 25 then UpperCL = exp(X2);
                     end;
               end;
            if Percent in(0,100) then ProbChiSq = .;
            ;
         run;
      %end;
   %else
      %do;
         data _pe4;
            set _pe4;
            OddsRatio = .;
            LowerCL = .;
            UpperCL = .;
            if Estimate = . then OddsRatio = 1; else
               do;
                  if Estimate < 25 then OddsRatio = exp(Estimate);
                  X1 = Estimate - 1.96 * StdErr;
                  X2 = Estimate + 1.96 * StdErr;
                  if StdErr ne . then
                     do;
                        if X1 < 25 then LowerCL = exp(X1);
                        if X2 < 25 then UpperCL = exp(X2);
                     end;
               end;
         run;
      %end;

   * Add, # observations, -2log likelood and Hosmer-Lemeshow statistics;
   data _extra1;
      set _rp;
      Length Variable $ 32 Pre $ 3;
      Variable = "Outcome";
      if _n_ = 1 then Pre = '(+)'; else Pre = '(-)';
      ClassVal0 =Pre||"&outcome "||outcome||'='||left(trim(put(count,10.)));
      OrderBetween = 1000;
      OrderWithin = _n_;
      Keep Variable ClassVal0 OrderBetween OrderWithin;
   run;

   data _extra2;
      set _fs;
      Length Variable $ 32;
      if Criterion = '-2 Log L' then
         do;
            Variable = Criterion;
            ClassVal0 = left(trim(Put(InterceptAndCovariates,10.3)));
            OrderBetween = 2000;
            OrderWithin = 1;
            Keep Variable ClassVal0 OrderBetween OrderWithin;
            output;
         end;
   run;

   data _extra3;
      set _hl;
      Length Variable $ 32;
      Variable = 'H-L Test';
      If df = 0 then ClassVal0 = '< 3 groups'; else ClassVal0 = Trim(Left(Put(df+2,3.)))||' groups';
      OrderBetween = 3000;
      OrderWithin = 1;
      Keep Variable ClassVal0 Probchisq OrderBetween OrderWithin;
   run;

   %if &Status ne 0 %then
      %do;
         data _extra4;
            Length Variable  $ 32;
            Variable = 'Convergence problems';
            ClassVal0 = "Status = %trim(&Status)";
            OrderBetween = 4000;
            OrderWithin = 1;
         run;
      %end;

   data _pe4;
      set
      %if &Obs = Y %then %do; _extra1 %end;
      %if &LL = Y %then %do; _extra2 %end;
      %if &HL = Y %then %do; _extra3 %end;
      %if &Status ne 0 %then %do; _extra4 %end;
      _pe4 ;

   run;

   %if %symexist(_Model) = 1 %then
      %do;
         %Let _Model = %eval(&_Model + 1);
      %end;
   %else
      %do;
         %Let _Model = 1;
      %end;
   proc sort data = _pe4; by OrderBetween OrderWithin;

   proc format; value _pfmt . = ' ' low-.00995 = [pvalue6.4] .00995-.0995 = [6.3] .0995-1 = [6.2];
                value _orfmt . = ' ' low-2 = [6.2] 2-20 = [6.1] 20-high = [6.0];
                value _missint . = ' ' other = [3.];
   data _pe5 (drop = pre post);
      set _pe4 end = done; by OrderBetween;
      if _n_ = 1 then do; MaxBefore = 0; MaxAfter = 0; end;       * find max digits before, after slash so freq could be aligned;
      retain MaxBefore MaxAfter;
      Length ProbChiSqAlpha P3Alpha PQuadAlpha $ 6;
      ProbChiSqAlpha = left(put(ProbChiSq,_pfmt.));
      %if &NClass = 0 %then %do; PType3 = .; *Length ClassVal0 $ 40; %end;
      P3Alpha = left(Put(PType3,_pfmt.));
      %if &NNumVars = 0 or &Quad ne Y %then %do; PQuad = .; %end;
      PQuadALpha = left(put(PQuad,_pfmt.));
      if OrderBetween = 2 and OrderWithin = 1 then Model = &_Model;
      %if (&Include = F or &Include = FP) %then
         %do;
            K = index(FreqPct,'/');
            if K > 0 then
               do;
                  Pre = K-1;
                  L = index(Substr(FreqPct,K+1),' ');
                  If L > 0 then Post = L - 1; else Post = 0;
                  If Pre > MaxBefore then MaxBefore = Pre;
                  if Post > MaxAfter then MaxAfter = Post;
               end;
            %end;
      label ProbChiSqAlpha = 'P-Value'
            ProbChiSq = 'P-Value'
            PType3 = 'Type 3 P-Value'
            P3Alpha = 'Type 3 P-Value'
            PQuad = 'Quadratic P-Value'
            PQuadAlpha = 'Quadratic P-Value'
            ClassVal0 = 'Value'
            LowerCL = 'Lower 95% CI'
            UpperCL = 'Upper 95% CI'
            %if &Include = FP %then %do;  FreqPct = "# &outcome/# subgroup (% &outcome)" %end;
            %if &Include = F  %then %do;  FreqPct = "# &outcome/# subgroup" %end;
            %if &Include = P  %then %do;  FreqPct = "% &outcome" %end;
            ;
      output;
      if last.OrderBetween then
         do;
            Variable = '';
            ProbChiSqAlpha = '';
            P3Alpha = '';
            PQuadAlpha = '';
            FreqPct = '';
            OddsRatio = .;
            LowerCL = .;
            UpperCL = .;
            ClassVal0 = '';
            Model = .;
            output;
         end;
      if done then
         do;
            call Symput('MaxBefore',MaxBefore);
            call Symput('MaxAfter',MaxAfter);
         end;
   run;

   %if (&Include = F or &Include = FP) %then
      %do;
         data _pe5 (drop = K L M MaxBefore MaxAfter);
            set _pe5;
            K = index(FreqPct,'/');
            if K > 0 then
               do;
                  FreqPct = Repeat(' ',&MaxBefore-K+1)||FreqPct;
                  %if &Include = FP %then
                     %do;
                        K = index(FreqPct,'/');
                        L = index(Substr(FreqPct,K+1),' ');
                        M = index(Substr(FreqPct,K+1),'(');
                        if L > 0 then FreqPct = Substr(FreqPct,1,K+L-1)||Repeat(' ',&MaxAfter-L+1)||Substr(FreqPct,M+K);
                     %end;
               end;
         run;
      %end;

   data _pe5;
      set _pe5;
      OddsRatioAlpha = left(put(OddsRatio,_orfmt.));
      UpperCLAlpha = left(put(UpperCL,_orfmt.));
      LowerCLAlpha = left(Put(LowerCL,_orfmt.));
      label OddsRatioAlpha = 'Odds Ratio'
            UpperCLAlpha = 'Upper 95% CI'
            LowerCLAlpha = 'Lower 95% CI';
      if Variable = 'Intercept' then delete;
   run;

   %if &Print = Y %then
      %do;
         ods listing;
         proc print data = _pe5 noobs label uniform; var
          OddsRatioAlpha LowerCLAlpha UpperCLAlpha ProbChiSqAlpha
         %if &NNumVars2 > 0 and &Quad = Y %then %do; PQuadAlpha %end;
         %if &NClass > 0 %then %do; P3Alpha %end;
         ;
         id Model variable
         %if &Obs = Y or &HL = Y or &LL = Y or %length(&ClassVar) > 0 %then %do; classval0 %end;
         %if (&Include = F or &Include = P or &Include = FP) and %Length(&ClassVar) > 0 %then %do; FreqPct %end;
         ;
         format Model _missint.;
         run;
      %end;

   %if &out ne %then
      %do;
         data &out (Type = 'Logistic' drop = OldVar BaseVar Var IRQ Count X1 X2 ClassVal0);
            set _pe5;
            Length Value $ 40;
            %if &NClass > 0 or &Obs = Y or &HL = Y or &LL = Y %then %do; Value = ClassVal0; %end;
            if Variable = '' then delete;
            %if &NNumVars = 0 %then %do; PQuad = .; %end;
            %if &NClass = 0 %then %do; FreqPct = ''; Total = .; Freq = .; Percent = .; PType3 = .; %end;
            Status = &Status;
            Model = &_Model;
            Length VarType $ 20 Dependent $ 32;
            Dependent = "&Outcome";
            if Variable in('Outcome','-2 Log L','H-L GOF','Convergence problems') then VarType = Variable; else   VarType = 'Logistic Model';
         run;
      %end;

   %ExitLogistic:
   proc datasets nolist; delete _allcounts _allquad  _counts _counts2 _cs  _extra1 _extra2 _extra3 _extra4
   _fs _hl _irq  _nomiss  _oneline _pe _pe_ _pe2 _pe3 _pe4 _pe5 _pe5  _rp _test _t3; quit;  

%mend logistic;
