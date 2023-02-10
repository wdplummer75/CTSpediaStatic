/*
This program simply executes the 'SampleLogisticRun.sas' program
*/


filename logi URL "http://ctspedia.org/twiki/pub/CTSpedia/LogisticRegressionMacro/SampleLogisticRun.sas"; 
%include logi;
run; 

