* Macro RegMacro invokes SAS proc reg and organizes the output.  It has the features for automatic 
  creation of dummy variables for the qualitative variables and/or quadratic variables.
  The macro parameters are:

   DSName       = name of SAS data set
   Dir			= directory the macro saved.
   ID			= name of unique id for each observation.
   Outcome      = name of outcome variable.  This variable is assumed to be quantitative and the model predicts the
                  linear relationship between outcome and a set of independent predictors.
   PredictNum   = list of numeric predictor variables.
   PredictClass = qualitative variables with reference level.  
   ClassRef     = reference value used to creat the dummy variable for the corresponding PredictClass. If no reference is specified, 
				  a dot (.) must be input as a place holder and the highest value of the variable will be served as reference level.
   Format		= formats of the variables with the same order in PredictClass. if no format defined for the corresponding
				  qualitattive variable, a dot (.) must be input as a place holder.
   Diagnostic   = Linear, ResidQuantile or N (default=N)
				  N      = No diagnostic procedure is performed.
				  Linear = creating and testing quadratic terms.
				  ResidQuantile = No plot but calculate the average squared studentized residual within each 10-percentile.
   Plot         = Multiple, Residual,  QQ, or N (default=N)
				  N        = No plot will be generated.
				  Residual = Plot of residual vs. predicted value.
				  QQ       = Q-Q plot.
				  Multiple = multiple plots.
   Outdata      = name of output SAS data set containing reg estimates, p-values, leverages, Cook's distances etc.
   Outfile      = file name for the output results
   Demographics = Y/N (default = N) If Y, 
				  frequencies and percentages are displayed with qualitative variable values
				  means and standard deviations are displayed with quantitative variable values

The macros called by this macro are %words, %checkvar, %DummyVar, and %residsqr;


%macro RegMacro(DSName=,
				Dir=,
				ID=,
				Outcome=,
				PredictNum=,
				PredictClass=,
				ClassRef=,
				Format=,
				Diagnostic=N,
				Plot=N,
				Outdata=,
				Outfile=,
				Demographics=N);


filename words URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;
filename chkvar URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckVar.sas";
%include chkvar;
filename residsqr URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/residsqr.sas";
%include residsqr;
filename RefDummy URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/RefDummy.sas";
%include RefDummy;

%Local AFormat BadOutcome ClassVariables Flag Has0 Has1 I K L MaxAfter MaxBefore NClass NPred NQuart
          NNumVars NumVars NNumVars2 NObs NumVars2 Status TempVars TestVar ThisVar Var VarList VarName VarType;

	%Global  _ClassVar _ClassVariables _Error _Model dummyvar; 

   *Make sure just one leading and trailing blank and replace multiple blanks with single blanks in all lists.
    Convert all text to uppercase;
   %Let PredictNum = %str( )%upcase(%cmpres(&PredictNum))%str( );
   %Let PredictClass = %str( )%upcase(%cmpres(&PredictClass))%str( );
   %Let NNum = %words(&PredictNum);
   %Let NClass = %words(&PredictClass);
   %Let Demographics = %upcase(&Demographics);
   %Let Diagnostic = %upcase(&Diagnostic);
   %Let Plot = %upcase(&Plot);

   %Let ClassVariables = &PredictClass;
   %Let NClass = %words(&ClassVariables);

   * Check that the id, outcome and all variables in the PredictNum and ClassVariables lists are in the data set;
   %Let VarList = %upcase(%cmpres(&ID%str( )&Outcome%str( )&PredictNum%str( )&ClassVariables));
	%CheckVar(CVDsname=&DSName,CVVars=&Varlist);
	%if &_Error = 1 %then %goto ExitRegMacro;

	* Check that outcome is not in the PredictNum and ClassVariables lists;
   %if %index(%upcase(%str( )&PredictNum%str( )&ClassVariables%str( )),%str( )%upcase(&Outcome)%str( )) > 0 %then
      %do;
         %put;
         %put Error: Outcome variable cannot be in the list of predictors.;
         %put;
         %goto ExitRegMacro;
      %end;

   * Check that the ClassVariables are not in the PredictNum list;
   %do i = 1 %to &NNum;
   		%Let TestVar = %scan(&PredictNum,&i);
		%Let K = %Index(&ClassVariables,%str( )&TestVar%str( ));
		%if &K > 0 
		%then
      		%do;
         		%put;
         		%put Error: PredictNum variables cannot be in the list of PredictClass.;
         		%put;
         		%goto ExitRegMacro;
      		%end;
   %end;

   * Check that variables in the PredictNum list are in fact numeric;
   %do i = 1 %to &NNum;
      %Let TestVar = %scan(&PredictNum,&i);
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
            %goto ExitRegMacro;
          %end;
    %end;

	* Remove observations with any missing value in the outcome or predictors;

	data nomissing;
		set &DSName;
		if missing(&Outcome) then delete;
	run;

	%do i=1 %to &NNum; 
		%Let TestVar=%scan(&PredictNum,&i);
		data nomissing;
			set nomissing;
			if missing(&TestVar) then delete;
		run;
	%end;
	%do i=1 %to &NClass; 
		%Let TestVar=%scan(&PredictClass,&i);
		data nomissing;
			set nomissing;
			if missing(&TestVar)>0 then delete;
		run;
	%end;


   * Create dummy variables for the PredictClass and create a new list of predictors that contains 
		all the PredictNum and DummyVar;
   %Let Predictors=&PredictNum;
   %if &NClass > 0 %then
		%do;
			%RefDummy(DumDsname=nomissing,Outcome=&Outcome,ClassVars=&PredictClass,Ref_level=&ClassRef,
						format=&Format,Outset1=_efficdummy,Outset2=dropdummy);
			%let DummyVars=&dummyvar;
			%let Predictors = %upcase(%cmpres(&PredictNum &DummyVars));
		%end;  
   %Let NPred = %words(&Predictors);

   * Now fit the basic model without quadratic terms;
   ods listing close;
   proc reg data = _efficdummy;
 		model &Outcome = &Predictors / vif clb collin;
	  	output Out = _basic CookD = _Cookd H = _Leverage P = _yhat R = _residual Student = _studresid;
		ods output ParameterEstimates = _pe;
		ods output FitStatistics = _fs;
   	run;

   * Create squared variables for all variables in PredictNum;
   %if NNum > 0 and &Diagnostic = %upcase(Linear) %then
      %do;
         data _efficdummy;
            set _efficdummy;
            %do i = 1 %to &NNum;
               %Let ThisVar = %scan(&PredictNum,&i);
               _&ThisVar.2 = &ThisVar * &ThisVar;
            %end;
         run;
      %end;

	%if &NNum>0 %then 
	%do;
         proc datasets nolist; delete _allquad; quit;
		%if %upcase(&Diagnostic) = %upcase(Linear) %then
		%do;
			ods listing close;
			%do i = 1 %to &NNum;
				%Let ThisVar = %scan(&PredictNum,&i);
				proc reg data = _efficdummy;
  					model &Outcome = &Predictors _&ThisVar.2;
					ods output ParameterEstimates = _peQuad;
				run;

				data _oneline;
					Length Var $ 32 Value $ 32;
            		set _peQuad (rename = (Probt = PQuad));
            		if Variable = "_&ThisVar.2" then
            		do;
               			Var = "&ThisVar";
						Value = Var; 
               			Keep Var PQuad;
               			output;
            		end;
         		run;
				proc append base = _allquad data = _oneline force;
            	run;
			%end;
			data _pe1;
				Length Var $ 32 Value $ 32;
				set _pe (keep = Variable Estimate StdErr Probt VarianceInflation LowerCL UpperCL Label
						 rename = (Variable = Var));
				Var = upcase(Var);
				Value = Var;
				*if Var = 'INTERCEPT' then delete;
			run;
			proc sort data =  _pe1; by Var; run;
			proc sort data = _allquad; by Var; run;
            data _pe2;
                merge _pe1 _allquad; 
				by Var;
            run;
		%end;
		%else
		%do;
		data _pe2;
			set _pe (keep = Variable Estimate StdErr Probt VarianceInflation LowerCL UpperCL Label
					 rename = (Variable = Var));
			Var = upcase(Var);
			Value = Var;
			*if Var = 'INTERCEPT' then delete;
		run;
		%end;
	%end;
	%else
	%do;
		data _pe2;
			set _pe (keep = Variable Estimate StdErr Probt VarianceInflation LowerCL UpperCL Label
					 rename = (Variable = Var));
			Var = upcase(Var);
			Value = Var;
			*if Var = 'INTERCEPT' then delete;
		run;
	%end;
 
%if &NClass > 0 %then
	%do;
         proc datasets nolist; delete _allquad; quit;
		 %let DummyVars0=&dummyvar;
		 %let _ndum=%words(&DummyVars0);
		 %do i=1 %to &_ndum;
		 	%let ThisVar = %scan(&DummyVars0,&i);
			data _oneline;
				Length Var $ 32 Value $ 32 value1 $ 32;
            	Var = "%upcase(&ThisVar)";
         	run;
			proc append base = _allquad data = _oneline force;
            run;
		 %end;
		 proc sort data =  _pe2; by Var; run;
		 proc sort data = _allquad; by Var; run;
         data _pe3;
                merge _pe2 _allquad; 
				by Var;
            run;

		data _pe3;
			set _pe3;
			K = index(label," ")-1;	
			if value=" " then do;
			value=upcase(substr(label, 1, K)) ; 
			value1=substr(label, K+1) ;
			end;
			drop K;
		run;
	%end;


* Find class variables with more than 2 levels;

%if &NClass > 0 %then
      %do;
 			%Let ClassVarList = %upcase(%cmpres(&ClassVariables));
			%let _multilevelclass=;
			%let _multiref=;
			%let _multifmt=;
            %do i = 1 %to &NClass;
               %Let ThisVar = %scan(&ClassVarList,&i); 
			   ods listing close;
			   proc freq data=nomissing;
			   		tables &ThisVar /out=_temp;
				run;
				%let dsid=%sysfunc(open(_temp));
				%let Nlevel=%sysfunc(attrn(&dsid,nobs));
				%let rc=%sysfunc(close(&dsid));
				%if &Nlevel > 2 %then %let _multilevelclass=%cmpres(&_multilevelclass%str( )&ThisVar);
            %end;
      %end;
%let Nmultilevel=%words(&_multilevelclass);
%if &Nmultilevel>0 %then 
	%do;
         proc datasets nolist; delete _allquad; quit;
		 ods listing close;
		 proc glm data=nomissing;
			class &ClassVariables;
			model &Outcome=&PredictNum &ClassVariables/ss3;
			ods output ModelANOVA=_Manova;
		  quit;
			%do i = 1 %to &Nmultilevel ;
				%Let ThisVar = %scan(&_multilevelclass,&i);
				data _Manova1;
					set _Manova (rename = (ProbF = Type3P));
					if upcase(Source)=upcase("&ThisVar") then call symput('Type3P',Type3P);
				run;

				data dropdummy;
					set dropdummy; 
            		if variable = "%upcase(&ThisVar)" then
            		do;      
               			Type3P = &Type3p;
            		end;
         		run;
			%end;
		%end;
	
	ods listing close;

	data cont;
		set _efficdummy;
		keep &PredictNum;
	run; 

	proc contents data=cont ;
		ods output Variables=_varcont;
	run;
	
	data cont;
		set _varcont;
		type1='NUMERIC';
	run;

	data cate;
		set _efficdummy;
		keep &ClassVarList;
	run;

	proc contents data=cate ;
		ods output Variables=_varcate;
	run;

	data cate;
		set _varcate;
		type1='CLASS';
	run;

	data _var;
		set cont cate;
		Variable=upcase(Variable);
		keep Variable Label type1;
	run;

	proc sort data=_var;
		by Variable;
	run;

ods rtf file = "&dir.&outfile..rtf";

	%if %upcase(&Plot) = %upcase(QQ) %then
	%do;
		ods graphics on;
		ods select QQplot;
		proc reg data = _efficdummy plots(unpackpanels);
		      Linear:model &Outcome = &Predictors; 
   		run;
		ods graphics off;
	%end;

	%if &Plot = %upcase(Residual) %then
	%do;
		ods graphics on;
		ods select RStudentByPredicted;
		ods select ResidualByPredicted;
		proc reg data = _efficdummy plots(unpackpanels);
		      Linear:model &Outcome = &Predictors; 
   		run;
		ods graphics off;
	%end;

	%if &Plot = %upcase(Multiple) %then
	%do;
		ods graphics on; 
		ods select DiagnosticsPanel;
		proc reg data = _efficdummy plots;
		      Linear:model &Outcome = &Predictors; 
   		run;
		ods graphics off;
	%end;

	ods listing;
   * Calculate the average squared studentized residual within each 10-percentile.;
   %if &Diagnostic = %upcase(ResidQuantile) %then 
   		%do;
			%residsqr(RSDsname=_basic,endp=&Outcome,p=_yhat,student=_studresid,Outset=_quantile10average);
		%end;


	* find the observation with the biggest Cook distance.;

	proc sort data=_basic;
		by descending _Cookd;
	run;

	data _biggestcook;
		set _basic;
		if _N_=1 then output;
	run;

	title "Observation with the largest Cooks Distance."; 
	proc print data=_biggestcook label noobs;		
	run;

	* find the observation with the biggest Leverage.;
	proc sort data=_basic;
		by descending _Leverage;
	run;

	data _biggestleverage;
		set _basic;
		if _N_=1 then output;
	run;

	title 'Observation with the largest Leverage.'; 
	proc print data=_biggestleverage label noobs;
	run;
	

	data &outdata;
		set _basic;
	run;
	
	%if &Demographics = Y %then 
	%do;
		ods listing;
		* Create freq table for the class variables;
		title 'Demographic Characteristics'; 
		proc freq data = nomissing;
			tables &ClassVariables;
		run;

		* proc means for the numeric variables;
		proc means data = nomissing;
			var &PredictNum;
		run;
	%end;

	
	data _pe3;
		set _pe3(rename=(value=Variable));
	run;

	data _pe4;
		set _pe3 dropdummy;
		if Variable='INTERCEPT' then _ninter=1;
		else _ninter=9;
	run;

	proc sort data=_pe4;
		by _ninter Variable;
	run;


	ods select NObs;
	proc reg data = _efficdummy;
	      Linear:model &Outcome = &Predictors; 
   	run;

	%if &Nmultilevel>0 %then 
	%do;
		*ods listing;
		proc print data = _pe4 label noobs;
			%if &Diagnostic = %upcase(Linear) %then
			%do;
			var Variable value1 Estimate StdErr Probt LowerCL UpperCL 
					VarianceInflation PQuad Type3P; 
			label value1 = 'Values'
				  Probt = 'P-Value' 
				  VarianceInflation = 'VIF' 
				  LowerCL = 'Lower 95% CI' 
				  UpperCL = 'Upper 95% CI' 
				  PQuad = 'Quadratic P-Value'
				  Type3P = 'Type 3 P-Value';
			%end;
			%else %do;
			var Variable value1 Estimate StdErr Probt LowerCL UpperCL 
					VarianceInflation Type3P; 
			label value1 = 'Values' 
				  Probt = 'P-Value' 
				  VarianceInflation = 'VIF' 
				  LowerCL = 'Lower 95% CI' 
				  UpperCL = 'Upper 95% CI'
				  Type3P = 'Type 3 P-Value';
			%end;

			title Linear Regression Results for Dependent Variable (&Outcome);
		run;
	%end;
	%else %do; 
		*ods listing;
		proc print data = _pe4 label noobs;
			%if &Diagnostic = %upcase(Linear) %then
			%do;
			var Variable value1 Estimate StdErr Probt LowerCL UpperCL 
					VarianceInflation PQuad; 
			label value1 = 'Values'
				  Probt = 'P-Value' 
				  VarianceInflation = 'VIF' 
				  LowerCL = 'Lower 95% CI' 
				  UpperCL = 'Upper 95% CI' 
				  PQuad = 'Quadratic P-Value';
			%end;
			%else %do;
			var Variable value1 Estimate StdErr Probt LowerCL UpperCL 
					VarianceInflation; 
			label value1 = 'Values' 
				  Probt = 'P-Value' 
				  VarianceInflation = 'VIF' 
				  LowerCL = 'Lower 95% CI' 
				  UpperCL = 'Upper 95% CI';
			%end;

			title Linear Regression Results for Dependent Variable (&Outcome);
		run;
	%end;
		
ods rtf close;



	%ExitRegMacro:
	proc datasets nolist; delete _allquad _basic _biggestcook _biggestleverage _cats_ _counts 
		  _efficdummy	_fs _oneline _pe _pe1 _pe2 _pe3 _pe4 _manova1 _manova _pequad _quantile10average _test2
		_type3pe _temp _effic cate  cont _var _varcate _varcont dropdummy ;
	quit;
   %mend RegMacro;
