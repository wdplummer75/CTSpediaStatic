/*
Example of how to run a series of logistic regression models using the Logistic macro
and then create an output file using the LogisticHtml macro.
*/
options nodate nocenter;

filename logist URL "http://ctspedia.org/twiki/pub/CTSpedia/LogisticRegressionMacro/Logistic.sas"; 
%include logist;
filename loghtml URL "http://ctspedia.org/twiki/pub/CTSpedia/LogisticRegressionMacro/logisticHtml.sas";
%include loghtml;

%let ResultsDir=L:\BCU macros\Wiki files; * a directory where you want to put your results;
/*
The following block creates a simulated data set for this example
*/
proc format;
	value dfmt 0='Cured' 1='Died';
	value wfmt 0='Not over' 1='Overweight' 2='Obese';
	value tfmt 0='Placebo' 1='Active';
	value ynfmt . = ' ' 0 = 'No' 1 = 'Yes';
run;

data testdata;
	do i=1 to 500;
	  age=round(20+60*ranuni(123));
	  female=0; if ranuni(123)>0.5 then female=1;
	  treatment=0; if ranuni(123)>0.5 then treatment=1;
	  bmi=round(22+0.1*age+4*rannor(123),.01);
	  obese=0; if bmi>30 then obese=1;
	  overweight=0; if 27<=bmi<=30 then overweight=1;
	  *logodds=-2+log(1.5)*(age-20)/10 + 
			log(2.5)*obese + log(1.5)*overweight + log(0.5)*female + log(0.5)*treatment;
	  	logodds=-2+log(1.15)*(age-20)/10 *(age-20)/10;

		  prob=1/(1+exp(-logodds));
	  died=0; if ranuni(123)<prob then died=1;
	  weightcat=overweight+2*obese;
	  output;
	end;

	format treatment  tfmt.  died dfmt. weightcat wfmt. obese ynfmt. female died overweight ynfmt.;
	drop i;
run;

/*
The Series macro automatically runs a number of logistic regression models and accumulates
the results in the data set AllModels.
*/
%Macro Series;
	%Let PredictorList = age age female treatment bmi obese overweight weightcat;
	%Let ClassList = N N Y Y N Y Y Y;			* Y indicates a categorical predictor;
	%Let QuartList = N Y N N Y N N N;			* Y indicates a numeric predictor to be analyzed in quartiles;
	%do i = 1 %to 7;
	   %Let Predictor = %scan(&PredictorList,&i);
		%Let IsClass = %scan(&ClassList,&i);
		%Let IsQuart = %scan(&QuartList,&i);
		%Let CatVar =;
		%if &IsClass = Y %Then %Let CatVar = &Predictor;
		%Let QuartVar =;
		%if &IsQuart = Y %then %Let QuartVar = &Predictor;
		%Logistic(DSName= testdata,Outcome=Died,Predictors=&Predictor,ClassVar=&CatVar,Quartiles=&QuartVar,Print=N,Out=Results,Include=FP,Obs=Y,LL=Y,HL=Y);
		proc append base = AllModels data = Results; run;
		proc datasets ;delete results;run; quit;		
	%end;
	%logistic(dsname=testdata,outcome=died,predictors=age treatment female weightcat ,classvar=female weightcat treatment,Quartiles=age, Out=Results,print=N,Include=FP,Obs=Y,LL=Y,HL=Y)
		proc append base = AllModels data = Results; run;
		proc datasets ;delete results;run; quit;	
%mend;

%Let _Model = 0;						* The global macro variable _Model indexes all generated models;
proc datasets nolist; delete AllModels; quit;  * Delete any results from earlier runs ;
%Series; * This runs the above macro ;

%let mytitle=Example of running a series of univariate models and multivariate models with the logistic macro;

 %LogisticHtml(dsname=allmodels,Space=Y,results=&ResultsDir, filename=LogisticHtmlExample,mytitle =&mytitle);
