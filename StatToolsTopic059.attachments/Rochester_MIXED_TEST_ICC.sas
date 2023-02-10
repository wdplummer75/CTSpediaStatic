      

*******************************************************************************************
*******************************************************************************************
**  DSName   = name of a SAS  dataset                                                    **
**  DepVar   = name of dependent variable                                                **   
**  grp      = name of group or between level variable                                   **
**  subj	 = name of individual or within level variable                               **
** OutForm   = left empty, results will be only shown with listing format in the output  **
**             window screen, HTML, PDF, RTF are for html, pdf, rtf output format will be**
**            generated, respectively.                                                   **	
*******************************************************************************************
*******************************************************************************************	;
options nodate center  ls=160 ps=50 pageno=1;
%macro MIXED_TEST_ICC(DSName=,DepVar=,grp=, subj=,OutFormat=);

ods listing close;
ods &OutFormat;

proc sort data=&DSName;
    by &grp &subj;
proc mixed data=&DSName method=type3;
    class &grp &subj;
    model &DepVar=&grp &subj;
    ods output type3=msout1;
run;

*--Calculate ICC--*;
data msout2;
    set msout1;
    flag=1;
    if source='Residual' then do; mserr=ms; dferr=df; end;
    if source="&grp" then do; msgrp=ms; dfgrp=df; end;
    if source="&subj" then do; mssubj=ms; dfsubj=df; end;
    retain mserr dferr msgrp dfgrp mssubj dfsubj;
    keep mserr dferr msgrp dfgrp mssubj dfsubj flag;
data msout3;
    set msout2;
    by flag;
    format icc lower upper 5.4;
    if last.flag;  
    icc=(msgrp-mserr)/(msgrp+(dfsubj*mserr));
    fl=(msgrp/mserr)/finv(0.975,dfgrp,dfgrp*dfsubj);
    fu=(msgrp/mserr)*finv(0.975,dfgrp*dfsubj,dfgrp);
    lower=(fl-1)/(fl+dfsubj);
    upper=(fu-1)/(fu+dfsubj); 
	label icc='ICC'         
          lower='Lower 95% confidence limit'
          upper='Upper 95% confidence limit'; 	
    
*--Testing ICC--*;
data ftests;
    set msout3;
	FV=(1+(dfsubj*icc))/(1-icc);
	numdf=dfgrp; dendf=(dfgrp+1)*dfsubj;
	Pvalue = 1-probf(FV,numdf,dendf);	
	label FV = 'F Value'
		  Pvalue ='P-value '         
          numdf='Numerator df'
          dendf='Denominator df';
proc print data=ftests noobs label;
    var icc lower upper FV numdf dendf Pvalue;
    run;
	quit;

ods &Outformat close;
ods listing;

%mend MIXED_TEST_ICC;

%MIXED_TEST_ICC(DSName=simICC,
                      DepVar=DepVAr,
                      grp=group,
                      subj=subject,
                      OutFormat=pdf);


