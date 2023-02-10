/* This macro calculate the average studentized residuals within each 10-percentile.
    The arguments are endp, which is the outcome used in the regression, and dbase, which is the
    output from fitting the model. */

%macro residsqr(RSDsname=,endp=,p=,student=,Outset=);
/* create the cutpoints for the 10-quantiles */
proc univariate noprint data = &RSDsname;
	var &p;
	output out=_quantile10 pctlpts=10 20 30 40 50 60 70 80 90 pctlpre=_pct;
run;

/* write the cutpoints to macro variables */
data _test1;
	set _quantile10;
	call symput('_q1',_pct10) ;
	call symput('_q2',_pct20) ;
	call symput('_q3',_pct30) ;
	call symput('_q4',_pct40) ;
	call symput('_q5',_pct50) ;
	call symput('_q6',_pct60) ;
	call symput('_q7',_pct70) ;
	call symput('_q8',_pct80) ;
	call symput('_q9',_pct90) ;
run;

/* create a new variable containing the quintiles */
data _test2;
	set &RSDsname;
	_residsqr = &student * &student;
	if &p=. then Range_of_Percentile=.;
	else if &p <= &_q1 then Range_of_Percentile=1;
	else if &p <= &_q2 then Range_of_Percentile=2;
	else if &p <= &_q3 then Range_of_Percentile=3;
	else if &p <= &_q4 then Range_of_Percentile=4;
	else if &p <= &_q5 then Range_of_Percentile=5;
	else if &p <= &_q6 then Range_of_Percentile=6;
	else if &p <= &_q7 then Range_of_Percentile=7;
	else if &p <= &_q8 then Range_of_Percentile=8;
	else if &p <= &_q9 then Range_of_Percentile=9;
	else Range_of_Percentile=10;
run;

/* calculate the average of squared studentized residual within each 10-quantile.*/
proc format; 
	value _percentile 1 = "0-10th percentile" 2 = "10-20th percentile" 3 = "20-30th percentile"
						4 = "30-40th percentile" 5 = "40-50th percentile" 6 = "50-60th percentile"
						7 = "60-70th percentile" 8 = "70-80th percentile" 9 = "80-90th percentile"
						10 = "90-100th percentile";
proc means data = _test2;
	class Range_of_Percentile;
	var _residsqr;
	format Range_of_Percentile _percentile.;
	output Out = &Outset;
	label _residsqr='(Squared Studentized Residual)';
  	title Average of Squared Studentized Residual within Each 10-Percentile Predicted Outcome (&endp);
run;
proc datasets nolist; 
	delete _test1 _tes2 _test3 _quantile10; 
run;
%mend residsqr;


