
* Example for how to call the macro;
options orientation=landscape pageno=1 center errors=2 nodate;

* to run this exmple, first download sampledata.sas7bdat and save it in the work directory;

data mydata;
	set sampledata;
run;


filename Cate URL "http://www.ctspedia.org/twiki/pub/CTSpedia/CategorizeEX/Categorize.sas";
%include Cate;

%Categorize(work.mydata,8,discrete,continous,mdates,CharDiscr,Characters,Ndiscrete,Ncontinous);
* check the log to see the list names of different types of variables; 


* the descriptive statistics can be run on the resulting variable list produced by the Categorize macro;
* for example;

title 'Means for Continuous Variables';
proc means data=mydata; var &continous; run;

title 'Frequencies for Discrete Variables';
proc freq data=mydata;tables &discrete;run;

title 'Frequencies for Discrete Character Variables';
proc freq data=mydata;tables &CharDiscr;run;

title 'Frequencies for Non-Discrete Character Variables';
proc freq data=mydata;tables &Characters;run;








