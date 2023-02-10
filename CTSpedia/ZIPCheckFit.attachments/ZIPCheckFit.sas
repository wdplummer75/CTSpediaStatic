
********************************************************************************************
*ZIPCheckFit macro first check and plot the distribution for variables of interest,then    *
*compare Zero-Inflated Poisson(ZIP) Model and Poisson Model using Vnong test,finally, the  *
*final ZIP full and null models are fitted and tested using Chi-Squared test. The SAS PROC *
*GENMOD is used to carry out the test and modeling.                                        *
*                                                                  	                       *
*The macro parameters are as follows:                                                      *
*                                                                                          *
*DSname		   =name of SAS data set                                                       *
*DepVar        =name of outcome variable                                                   *
*ClassVar      =name of categorical variable(s)                                            *
*IndepVar      =name of predictor variable(s)                                              *
*ZeroInflatVar =name of zero inflated variable                                             *
*format        =output format                                                              *
********************************************************************************************;


%macro ZIPCheckFit(DSname=, DepVar=, ClassVar=,IndepVar=, ZeroInflatVar=, format=);

title "Zero-Inflated Poisson Model Building";

options nodate center;

ods &format;

proc sort data=&DSname;by &DepVar;run;

title2 "Step I: Informally checking with distribution and plots";
proc means data=&DSname mean std min max maxdec=4 var n;
	var &DepVar &IndepVar &ZeroInflatVar;
	title3 "Means checking for the variables of interest";
run;

proc freq data = &DSname;
	tables &DepVar;
	title3 "Frequency checking for the outcome variable";
run;

ods listing;
proc univariate data = &DSname; 
	var &DepVar;
	ods output BasicMeasures=_count;
	title3 "Distribution checking for the outcome variable";
run; 

data _null_;
	set _count;
	if VarMeasure='Range' then do;
	call symput('Nobs',VarValue);
	end;
run; 

proc univariate data = &DSname noprint;
	histogram &DepVar / midpoints = 0 to &Nobs by 1 vscale = count;
	title3 "Plot checking for the outcome variable";
run; 

title2 "Step II: Comparing ZIP and Poisson models using Vnong test";
proc genmod data = &DSname;
	class &ClassVar/descending;
	model &DepVar = &IndepVar /dist=poisson type3;
	output out=poisson_out pred=poisson_pred;
 run;

proc genmod data = &DSname;
	class &ClassVar/descending;
	model &DepVar = &IndepVar /dist=zip type3;
	zeromodel &ZeroInflatVar /link = logit;
	output out=zip_out pred=zip_pred pzero=zeroinflat_prob;
run;

data poisson_pred; 
	set poisson_out; 
	do i = 0 to &Nobs; 
	poisson_prob = pdf('poisson', i , poisson_pred); 
	if &DepVar = i then output; 
	end; 
run; 

data zip_pred; 
	set zip_out;  
	do i = 0 to &Nobs;
	if i = 0 then zip_prob =zeroinflat_prob+(1-zeroinflat_prob)*pdf('poisson',i ,zip_pred); 
	else zip_prob = (1-zeroinflat_prob)*pdf('poisson',i ,zip_pred);; 
	if &DepVar = i then output; 
	end; 
	run; 

data both;
	merge poisson_pred zip_pred;
run;

data both;
	set both;
	m = log(zip_prob/poisson_prob);
	keep poisson_prob zip_prob m;
run;

proc means data=both vardef=n noprint;
	var m;
	output out=vuong_out mean=mean var=var n=n;
run;

data vuong_stats;
	set vuong_out;
	Vuong =(mean /sqrt(var/n));
	P = (1-probnorm(vuong));
	put Vuong=vuong P=P;
	drop  _TYPE_  _FREQ_  mean  var;  
run;

proc print data=vuong_stats split='*' noobs;
	var vuong P;
	label vuong='Vuong test of zip*vs. standard Poisson'
		  p='p-value';
	title2 'Vnong Test for the Zip Model';
run;

title2 "Step III: Comparing and fitting final ZIP and null ZIP models using Chi-square test";
ods output ModelFit=fit1;
proc genmod data = &DSname;
	class &ClassVar/descending;
	model &DepVar = &IndepVar /dist=zip type3;
	zeromodel &ZeroInflatVar /link = logit;
	title3 "1. Fitting final ZIP model";
run;

ods output ModelFit=fit2;
proc genmod data = &DSname;
	class &ClassVar/descending;
	model &DepVar =  /dist=zip type3;
	zeromodel /link = logit;
	title3 "2. Fitting null ZIP model";
run;

data fit1A(rename=(DF=df1 value=reference));
	set fit1;
	if Criterion="Full Log Likelihood" then output;
    if Criterion="Pearson Chi-Square" then output;
	drop valueDF;	
run;

data fit2A(rename=(DF=df2 value=nested));
	set fit2;
	if Criterion="Full Log Likelihood" then output;
    if Criterion="Pearson Chi-Square" then output;
	drop valueDF;
run;

proc sort data=fit1A;by Criterion;run;
proc sort data=fit2A;by Criterion;run;

data temp;
	merge fit1A  fit2A;
	retain loglik_diff;
	if Criterion="Full Log Likelihood" then
	   loglik_diff =2*(reference - nested);
	if Criterion="Pearson Chi-Square" then do;
	df=df2-df1; 
	pvalue = (1 - probchi(loglik_diff,df));
	put loglik_diff = df= pvalue=;
	format pvalue 10.8;
	end;
	if pvalue=. then delete; 
	drop  Criterion reference nested df1 df2;	
run;

proc print data=temp split='*' noobs;
	var loglik_diff df pvalue;
	label loglik_diff='likelihood ratio*test statistic
          *comparing*full Zip model to null ZIP model'
		  df='degrees of*freedom'
		  pvalue='p-value';
	title2 'Likelihood Ratio Test for the Zip Model';
run;

ods listing close;
ods &format close;

%mend ZIPCheckFit;




/*%ZIPCheckFit(DSname=,
			 DepVar=,
			 ClassVar=,
             IndepVar=, 
             ZeroInflatVar=, 
             format=HTML 
             );	*/

