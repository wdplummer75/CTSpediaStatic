
*SAS for Fdr using a sample Data
*--------------------------------------------------------------	;
data sample; 
	input charact$ group p;
datalines;
age1        1  0.799 
educ1       1  0.033
incomeM1    1  0.363 
incomeH1    1  0.096 
maritalD1   1  0.038
maritalM1   1  0.550
religion1   1  0.081
pesticide1  1  0.579 
genderM1    1  0.629
genderH1    1  0.955
genderH1    1  0.946
genderL1    1  0.023  
impulsH1    1  0.001
mental1     1  0.001 
age2        2  0.246 
educ2       2  0.001
incomeM2    2  0.390 
incomeH2    2  0.002 
maritalD2   2  0.312
maritalM2   2  0.047
religion2   2  0.063
pesticide2  2  0.421 
genderM2    2  0.603
genderH2    2  0.096
genderH2    2  0.073
genderH2    2  0.771  
impulsH2    2  0.001
mental2     2  0.001 
;
run;  

filename FDR URL "http://twiki.library.ucsf.edu/twiki/pub/CTSpedia/FdrSASMacro/Fdr.sas";
%include FDR;

%fdr(
	dsn=sample,
	group=., 
	inputs=charact,
	pvalue=p,	
	alpha=0.05);








