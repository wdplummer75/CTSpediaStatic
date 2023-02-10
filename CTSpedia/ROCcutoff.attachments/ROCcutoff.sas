*
   DSName       = name of SAS data set
   Dir			= directory the result file saved.
   ID			= name of unique id for each observation.
   Outcome      = name of outcome binary variable.  
   PredictNum   = name of numeric predictor variable.
   Format		= format of the outcome variable.
   WSpec        = any number between 0 and 1 which maximizes WSpec*specificity+(1-WSpec)*sensitivity
					e.g. if WSpec=1, the cutpoint is found to maximize the specificity
						 if WSpec=0, the cutpoint is found to maximize the sensitivity
						 if WSpec=0.5, the cutpoint is found to maximize the sum of the specificity and sensitivity
   OutForm      = HTML or RTF, Format of output file;

%macro ROCcutoff(DSName=,
				Dir=,
				ID=,
				Outcome=,
				PredictNum=,
				Format=,
				WSpec=,
				OutForm=);

%if %upcase(&OutForm)=HTML %then %do; ods html; %end; 
%if %upcase(&OutForm)=RTF %then %do; ods rtf file = "&dir.ROCcutoffOutput.rtf";	%end;

ods graphics on;
*ods select ROCCURVE;
title 'logistic regression with the continuous predictor';
proc logistic data=&DSName plots(only)=(roc(id=prob));
	model &Outcome = &PredictNum / scale=none
                            clparm=wald
                            clodds=pl
                            rsquare
                            outroc=roc&DSName roceps=0; 
	output out=out&DSName p=phat;

	*roc 'Continuous predictor' &PredictNum;
	%if &Format~=. %then %do; format &Outcome &Format; %end;;
run;
ods graphics off;

data roc&DSName;
	set roc&DSName;
	cut=_SENSIT_*(1-&WSpec) - _1MSPEC_*&WSpec;
run;

proc sort data=roc&DSName;
	by descending cut;
run;

data _null_;
	set roc&DSName (obs=1);
	call symput('cutprob',_prob_);
run;
%put &cutprob;

data out&DSName;
	set out&DSName;
	diff=abs(phat-&cutprob);
	if diff>. then output; 
run;

proc sort data=out&DSName;
	by diff;
run;

data _null_;
	set out&DSName (obs=1);
	call symput('PredictNumcut',&PredictNum); 
	%if &ID~=. %then %do; call symput('IDcut',&ID); %end;;
run;
data cut&DSName; 
	%if &ID~=. %then %do; &ID=&IDcut; %end;;
	&PredictNum._cutoff=&PredictNumcut; 
run;
proc print data=cut&DSName;run;

data &DSName;
	set &DSName;
	if &PredictNum>=&PredictNumcut then PredictNumcut=1;
	else PredictNumcut=0; 
	if &PredictNum=. then PredictNumcut=.;
run;

title 'logistic regression using the cutoff of the predictor';
proc logistic data=&DSName;
	class PredictNumcut;
	model &Outcome(event=last) = PredictNumcut;   
	%if &Format~=. %then %do; format &Outcome &Format; %end;;
run;

%if %upcase(&OutForm)=HTML %then %do; ods html close;  %end;
%if %upcase(&OutForm)=RTF %then %do; ods rtf close;	%end;

%mend ROCcutoff;
