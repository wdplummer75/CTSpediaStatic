*******************************************************************************************
*******************************************************************************************
**  DSName   = name of a SAS dataset                                                     **
**  DepVar   = name of dependent variable                                                **   
**  grp      = name of group or between level variable                                   **
**  subj	 = name of individual or within level variable                               **
**  M		 = name of mediation variable                                                **
**  X		 = name of independent variable                                              **
**  ddfm	 = name of method for computing denominator degrees                          **
**            of freedom for the fixed effect. ddfm=bw for the between and within method,**
**            for unbalanced data ddfm=satterhwaithe is often reconmmended, which is for **
**            Satterhwaithe method                                                       **
** OutForm   = left empty, results will be only shown with listing format in SAS 9.2, and**
**             HTML format in SAS 9.3 in the output window screen, HTML, PDF, RTF are    **   
**             html, pdf, rtf output format will be generated, respectively.             **                                                  **	
*******************************************************************************************
*******************************************************************************************	;
options nodate center  ls=160 ps=50 pageno=1;
%macro MIXED_MSEM(DSName=,DepVar=,grp=, subj=,M =, X=, ddfm=, OutFormat=);

ods listing close;
ods &OutFormat;

proc sort data=&DSName; by &grp &subj;run;

proc mixed data=&DSName covtest;
	class &grp;
	model &m = &x/solution ddfm=&ddfm notest;
	random intercept /type=un sub=&grp;
	title 'Multilevel Mediation Analysis';
	ods output  SolutionF=estout1;
run;

proc mixed data=&DSName covtest;
	class &grp;
	model &DepVar =&x &m /solution ddfm=&ddfm notest;
	random intercept /type=un sub=&grp;
ods output  SolutionF=estout2;
run;

data estout1a;
set estout1;
    if Effect="&x" then do; a=Estimate; astderr=StdErr;atvalue=tValue; end;
    retain a astderr atvalue;
    keep a astderr atvalue; 
	if a=. then delete;
	run;

data estout2a;
set estout2;
    if Effect="&m" then do; b=Estimate; bstderr=StdErr;btvalue=tValue; end;
    retain b bstderr btvalue;
    keep b bstderr btvalue; 
	if b=. then delete;
	run;

data merged;merge estout1a estout2a;run;

data mediation;
    set merged;	
    format ab Sab LCL UCL Stab tLCL tUCL 5.4;
    ab=a*b;
    Sab=sqrt((a*a*bstderr*bstderr)+(b*b*astderr*astderr));
    LCL=ab - 1.96*Sab;
    UCL=ab + 1.96*Sab;
	Stab=a*b*sqrt(atvalue*atvalue+btvalue*btvalue)/(atvalue*btvalue);
	tLCL=ab - 1.96*Stab;
    tUCL=ab + 1.96*Stab;
	label ab='Mediated Effect' 
		  Sab='Standard error' 
          LCL='Lower 95% confidence limit'
          UCL='Upper 95% confidence limit'
		  Stab='Standard error based on t-value'
		  tLCL='Lower 95% confidence limit based on t-value'
          tUCL='Upper 95% confidence limit based on t-value';
run;
proc print data=mediation noobs label;
    var ab Sab LCL UCL Stab tLCL tUCL;
	title 'Mediated effect,standard error and confidence limit';
    run;
	quit;

ods &Outformat close;
ods listing;

%mend MIXED_MSEM;

/*%MIXED_MSEM(DSName=simulated,
			DepVar=Y,
			grp=grp, 
			subj=subj,
			M =M, 
			X=X,
			ddfm=bw, 
			OutFormat=html);*/
