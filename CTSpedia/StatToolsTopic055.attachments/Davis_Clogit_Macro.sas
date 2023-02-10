* Last modified: 09/11/11

* Authors: Tzu-Chun Lin, MS.
		   Department of Statistics, Graduate Group of Biostatistics, UC Davis
		   Chin-Shang Li, Ph.D.
		   Department of Public Health Sciences, Devision of Biostatistics, UC Davis

* Description:
   The proportional odds model (also called cumulative logit model) is applied to study the association between 
   an ordinal outcome and predictor variable(s).
   This macro invokes SAS proc logistic with link clogit. The input parameters are:
   DSName: name of SAS data set
   Dir: directory the macro saved.
   Outcome: name of outcome variable.  This variable is assumed to be ordinal with more than two levels. 
   Freq: a variable that contains the frequency of occurrence of each observation.
   PredictNum: list of numeric predictor variables.
   PredictClass: qualitative variables with reference levels, ex: sex(ref='female'). 
				 The reference levels should correspond to format values if formats are specified.  
   Format: formats of the variables. The first is the format of the outcome variable and the rest are with 
           the same order in PredictClass. 
		   If no format defined for the corresponding qualitattive variable, a dot (.) must be input as a place holder.
   OutFormat: HTML or RTF, Format of output file
   OutFileName: output file name;

OPTIONS	MPRINT		SYMBOLGEN;
%macro CLogit(DSName=, Dir =, Outcome=, Freq=, PredictNum=, PredictClass=, Format=, OutFormat=, OutFileName=);

	filename words URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
	%include words;

	%let NFreq=%words(&Freq);
	%let NClass=%words(&PredictClass);
	%let ClassVar=;

	%Let OutcomeFmt = %qscan(&Format,1,%str( ));
	%if &OutcomeFmt=.	 %then %do; 
		%Let VarFmat =;
	%end;
	%else %do;	
		%Let	VarFmat =  &Outcome%str( )&OutcomeFmt;
	%end;

	%do i=1 %to &NClass; 
	%let ThisVar = %qscan(&PredictClass,&i,%str( ));
	%Let K = %index(&ThisVar,%str(%()); 
	%if &K>0 %then %Let ThisVar = %substr(&ThisVar,1,%eval(&K-1));
		%Let ClassVar = %cmpres(&ClassVar &ThisVar);
		%Let ThisFmt = %qscan(&Format,%eval(&i+1),%str( ));
		%if &ThisFmt=. %then %do; %end;
		%else %do;	
				%Let VarFmat=&VarFmat%str( )&ThisVar%str( )&ThisFmt;
		%end;
	%end;

	%if %upcase(&OutFormat)=HTML %then %do; ods html; %end; 
	%if %upcase(&OutFormat)=RTF %then %do; ods rtf file = "&dir.\&OutFileName..rtf";	%end;
	title "Proportional odds model (Outcome: &Outcome, Predictor variable(s): &PredictNum &ClassVar)";
	*ods	trace on/ listing;
		proc logistic data = &DSName;
		%if  (&NFreq=0)	%then	%do;	%end;
		%else	%do;		freq	&Freq;	%end;
		class &PredictClass / param=ref;
  	 	model	&Outcome = &PredictNum	&ClassVar / link=clogit	clparm = wald clodds = wald covb;
		ods select ResponseProfile	CumulativeModelTest	Type3	ParameterEstimates	OddsRatios;
		%if (%words(&VarFmat)>0) %then format &VarFmat;;
	run;
	*ods trace off;
	%if %upcase(&OutFormat)=HTML %then %do; ods html close;  %end;
	%if %upcase(&OutFormat)=RTF %then %do; ods rtf close;	%end;

%mend Clogit;
