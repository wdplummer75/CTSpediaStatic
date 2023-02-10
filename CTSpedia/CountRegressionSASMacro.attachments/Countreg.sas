*
   DSName       = name of SAS data set
   Dir			= directory the macro saved.
   ID			= name of unique id for each observation.
   Outcome      = name of outcome variable.  This variable is assumed to be quantitative and the model predicts the
                  linear relationship between outcome and a set of independent predictors.
   PredictNum   = list of numeric predictor variables.
   PredictClass = qualitative variables with reference level.  
   Format		= formats of the variables with the same order in PredictClass. if no format defined for the corresponding
				  qualitattive variable, a dot (.) must be input as a place holder.
   ScaleCutpoint= cutpoint for scale to be considered overdispersion
   AlternateMod = GEE, NB, or ZIP
   OutForm      = HTML or RTF, Format of output file;

%macro Countreg(DSName=,
				Dir=,
				ID=,
				Outcome=,
				PredictNum=,
				PredictClass=,
				Format=,
				ScaleCutpoint=,
				AlternateMod=GEE,
				OutForm=);

filename words URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;

%let NClass=%words(&PredictClass);
%let ClassVar=;
%Let VarFmat=;

%do i=1 %to &NClass; 
	%let ThisVar = %qscan(&PredictClass,&i,%str( ));
	%Let K = %index(&ThisVar,%str(%()); 
	%if &K>0 %then %Let ThisVar = %substr(&ThisVar,1,%eval(&K-1));
	%Let ClassVar = %cmpres(&ClassVar &ThisVar);

	%Let ThisFmt = %qscan(&Format,&i,%str( ));
	%if &ThisFmt=. %then %do; %end;
	%else %do;	
		%Let VarFmat=&VarFmat%str( )&ThisVar%str( )&ThisFmt;
	%end;
%end;

ods listing close;

proc reg data=&DSName;
	model  &Outcome = &PredictNum / vif;
	ods output ParameterEstimates=_pevif;
quit;

data _pevif;
	set _pevif;
	keep Variable VarianceInflation; 
	rename Variable=Parameter;
	if 	Parameter="Intercept" then delete;
run;

proc genmod data=&DSName;
	class &PredictClass /PARAM=EFFECT;
    model &Outcome = &PredictNum &ClassVar / dist=poi link=log scale=D type3;  
	ods output ParameterEstimates=_ped;
	%if %words(&VarFmat)>0 %then format &VarFmat; ;
run;

data _null_;
	set _ped;
	if DF=0 then call symput("OverDisp_d",Estimate);
run; 

proc genmod data=&DSName;
	class &PredictClass /PARAM=EFFECT;
    model &Outcome = &PredictNum &ClassVar / dist=poi link=log scale=P type3;  
	ods output ParameterEstimates=_pep;
	%if %words(&VarFmat)>0 %then format &VarFmat; ;
run;

data _null_;
	set _pep;
	if DF=0 then call symput("OverDisp_p",Estimate);
run; 


proc genmod data=&DSName;
	class &PredictClass /PARAM=EFFECT;
    model &Outcome = &PredictNum &ClassVar / dist=poi link=log type3;  
	ods output ParameterEstimates=_pe Type3=_t3;
	%if %words(&VarFmat)>0 %then format &VarFmat; ;
run;


proc sort data=_pe;
	by Parameter;
run;
proc sort data=_pevif;
	by Parameter;
run;
data _pe;
	merge _pe _pevif;
	by Parameter;
run;

%if (&OverDisp_d > &ScaleCutpoint) or (&OverDisp_p > &ScaleCutpoint) %then
%do; 
	%if %upcase(&AlternateMod)=GEE %then
	%do; 
		%if %words(&id)>0 %then
		%do;   
			proc genmod data=&DSName;
				class &ID &PredictClass /PARAM=EFFECT;
			    model &Outcome = &PredictNum &ClassVar/ dist=poi link=log type3; 
				repeated subject=&ID;
				ods output GEEEmpPEst=_altmod  Type3=_alt3;
				%if %words(&VarFmat)>0 %then format &VarFmat; ;
			run;
		%end;
		%else 
		%do;
			%put;
	        %put Error: ID variable must be specified when AlternateMod=GEE;
	        %put;
	        %goto ExitCountreg;
		%end;
	%end;

	%if %upcase(&AlternateMod)=NB %then
	%do; 
		proc genmod data=&DSName;
			class &PredictClass /PARAM=EFFECT;
		    model &Outcome = &PredictNum &ClassVar / dist=nb link=log type3; 
			ods output ParameterEstimates=_altmod Type3=_alt3;
			%if %words(&VarFmat)>0 %then format &VarFmat; ;
		run;
	%end;

	%if %upcase(&AlternateMod)=ZIP %then
	%do;
		proc genmod data=&DSName;
			class &PredictClass /PARAM=EFFECT;
		    model &Outcome = &PredictNum &ClassVar / dist=zip type3;
			ZEROMODEL &PredictNum &ClassVar;  
			ods output ZeroParameterEstimates=_altmod Type3=_alt3;;
			%if %words(&VarFmat)>0 %then format &VarFmat;;	
		run;
	%end;

	data  _altmod;
		set _altmod;
		rename Parm=Parameter;
	run;
	proc sort data=_altmod;
		by Parameter;
	run;
	data _altmod;
		merge _altmod _pevif;
		by Parameter;
	run;
%end;

ods listing; 

%if %upcase(&OutForm)=HTML %then %do; ods html; %end; 
%if %upcase(&OutForm)=RTF %then %do; ods rtf file = "&dir.\CountregOuput.rtf";	%end;

title1 Analysis Of Maximum Likelihood Parameter Estimates (Distribution=Poisson); 
title2 NOTE: The scale parameter was held fixed;
proc print data=_pe noobs label; 
run;

title LR Statistics For Type 3 Analysis;
proc print data=_t3 noobs label;
run; 

%if (&OverDisp_d > &ScaleCutpoint) or (&OverDisp_p > &ScaleCutpoint) %then
%do; 
	%if %upcase(&AlternateMod)=GEE %then 
	%do; title1 Analysis Of GEE Parameter Estimates; title2 Empirical Standard Error Esitmates; %end;	
	%if %upcase(&AlternateMod)=NB %then 
	%do; title1 Analysis Of Maximum Likelihood Parameter Estimates (Distribution=Negative Binomial); title2 NOTE: The scale parameter was held fixed; %end;
	%if %upcase(&AlternateMod)=ZIP %then 
	%do; title1 Analysis Of Maximum Likelihood Zero Inflation Parameter Estimates; %end; 
	proc print data=_altmod noobs label;
	run; 

	%if %upcase(&AlternateMod)=GEE %then 
	%do; title Score Statistics For Type 3 GEE Analysis; %end;	
	%if %upcase(&AlternateMod)=NB %then 
	%do; title LR Statistics For Type 3 Analysis; %end;
	%if %upcase(&AlternateMod)=ZIP %then 
	%do; title LR Statistics For Type 3 Analysis of Zero Inflation Model; %end;
	proc print data=_alt3 noobs label;
	run;  

%end;
%if %upcase(&OutForm)=HTML %then %do; ods html close;  %end;
%if %upcase(&OutForm)=RTF %then %do; ods rtf close;	%end;

%ExitCountreg:
	proc datasets nolist; delete _ped _pep _pevif _t3 _pe _alt3 _altmod; quit;

%mend Countreg;
