* Sample to illustrate use of Table1 macro;

options nodate nocenter ls = 147 ps = 47 orientation = landscape;
filename tab1 URL "http://ctspedia.org/twiki/pub/CTSpedia/Table1Macro/Table1.sas";
%include tab1;
filename tab1prt URL "http://ctspedia.org/twiki/pub/CTSpedia/Table1Macro/Table1Print.sas";
%include tab1prt;

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
	  died=0; if ranuni(123)< 0.8 then died=1;
	  weightcat=overweight+2*obese;
	  output;
	end;

	format treatment  tfmt.  died dfmt. weightcat wfmt. obese ynfmt. female died overweight ynfmt.;
	drop i;
run;


%Table1(DSName=testdata,
        GroupVar=Treatment,
        NumVars=Age BMI,
        FreqVars=Female died weightcat,
        Mean=Y,
        Median=Y,
        Total=RC,
        P=W,
        Fisher=Female Died,
        KW=WeightCat,
        FreqCell=N(RP),
        Missing=Y,
        Print=N,
        Label=L,
        Out=Test,
        Out1way=)
title 'Sample characteristics and mortality outcome by treatment';
%Table1Print(DSname=test,Space=Y)

