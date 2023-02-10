/*
*===============================================================================================================
Program Name : g_volcano.sas
Purpose : Create volcano plots (or P-risk plots) which are scatter plots with a risk measure of adverse events on
              x-axis,e.g. risk differences(RD), hazard ratios(HR), odd ratio(OR) or risk ratio(RR), and p-values on the
              y-axis. AEs are often displayed at preferred term (PT) level and can be color coded by system of organ 
              class (SOC). Reference lines can be added so that AEs with large RD (HR/OR/RR) and small p-values can be
              identified in the upper-right corner of the plot, for which more detailed information is displayed in a 
          page.

              Volcano plot is a tool used for safety signal screening and AE data display. It allows reviewers to evaluate
          AE risks using both estimates of treatment effect and descriptive p-values at the same time. Summarizing a 
          study’s AEs using volcano plot facilitates the examination of the overall balance of AEs between treatment 
          arms, identification of AEs of potential safety concern using different statistical criteria and visualization
          of clustering patterns of AEs from same SOC.
*================================================================================================================*
*/

%macro g_volcano( dataIn=          			     /*Readin dataset names*/
                , ptVar=           				 /*variable for AEDECOD, or AEHLT or AEHLGT */
                , treat0=                        /* Name of (Control) Treatment */
                , treat1=                        /* Name of active treatment */
				, treatVar =                     /* Variable name of actual tretmant*/
                , RDorHR=                        /*RD|HR|RR|OR -plot type: output for Risk Difference or Hazard Ratio or Odd ratio or Risk Ratio*/
				, xVar=           				 /*variable shown on x-axis*/
				, yVar=           				 /*variable shown on y-axis*/
				, outNm=           				 /*graph output file name*/
				, outPth=           			 /*graph output path*/
				, outtyp=pdf                     /*output file type */
                , socLegend= N                   /*Y|N need AESOC legend or not*/
				, socVar=           			 /*variable for AEBODSYS or AESOC */
				, sTerm=N                        /*Y|N short term for labels in up-right corner*/
				, titl=%nrbquote()           	 /*titles*/
				, ftnt1=%nrbquote()           	 /*footnotes*/
				, ftnt2= %nrbquote()          	 /*footnotes*/
				, xLabel=%nrbquote()   			 /*text label for x-axis*/
				, yLabel=%nrbquote()   			 /*text label for y_axis*/
				, pgmNm=                         /* program name with path, for footnote only*/
                , refLine= 0.05                  /* horizontal reference line for p-value, default is 0.05, could be 0.1, 0.01*/
                , plot_color = Y                 /*output the graph in color or black/white. Defualt is in color*/
                );

***************************************************************************************;

/*Data manipulation*/
  data dataIn_0 ;
   set &dataIn.;
   length tn1 tn0 $20;
   tn0=compress(put(incidn0, 8.0)||'/'||put(totaln0, 8.0));
   tn1=compress(put(incidn1, 8.0)||'/'||put(totaln1, 8.0));
%if %substr(%upcase(&RDorHR),2,1)= R %then %do;
   x= log10(&xVar.);
   y=-log10(&yVar.);
   if y>3 then y=3;
   if x>1 then x=1;
   if x<-1 then x=-1;
%end;
%else %if %upcase(&RDorHR.) = RD %then %do;
   length x1 $20;
   x=&xVar.*100;
   x1=compress(put(&xVar.*100, best6.));
   y=-log10(&yVar.);
   if y>3 then y=3;
   if x>2 then x=2;
   if x<-2 then x=-2;
%end;

%if %upcase(&socLegend.)=Y %then %do;
   length soc1 $5 ssoc $20;
   soc1=%substr(%upcase(&socVar.),1,5);
   select;
     when (soc1='BLOOD') ssoc='Blood/Lymph';
     when (soc1='CARDI') ssoc='Cardiac';
     when (soc1='CONGE') ssoc='Congenital';
     when (soc1='EAR A') ssoc='Ear';
     when (soc1='ENDOC') ssoc='Endocrine';
     when (soc1='EYE D') ssoc='Eye';
     when (soc1='GASTR') ssoc='GI';
     when (soc1='GENER') ssoc='General';
     when (soc1='HEPAT') ssoc='Hepatobiliary';
     when (soc1='IMMUN') ssoc='Immune';
     when (soc1='INFEC') ssoc='Infection';
     when (soc1='INJUR') ssoc='Injury/Poison';
     when (soc1='INVES') ssoc='Investigations';
     when (soc1='METAB') ssoc='Metabolism';
     when (soc1='MUSCU') ssoc='Musculoskeletal';
     when (soc1='NEOPL') ssoc='Neoplasms';
     when (soc1='NERVO') ssoc='Nervous System';
     when (soc1='PREGN') ssoc='Pregnancy';
     when (soc1='PSYCH') ssoc='Psych';
     when (soc1='RENAL') ssoc='Renal/Urinary';
     when (soc1='REPRO') ssoc='Reproductive';
     when (soc1='RESPI') ssoc='Respiratory';
     when (soc1='SKIN ') ssoc='Skin';
     when (soc1='SOCIA') ssoc='Social Circum';
     when (soc1='SURGI') ssoc='Surgical';
     when (soc1='VASCU') ssoc='Vascular';
	 otherwise;
   end;
%end;
   run;


proc sql noprint;
select distinct propcase(treat0) into :trtm0
from dataIn_0;
select distinct propcase(treat1) into :trtm1
from dataIn_0; 
quit;

%put &trtm0.,;
%put &trtm1.,;
%let ry=1.3;
%if &refline=0.01 %then %do; %let ry=2; %end;
%else %if &refline=0.1 %then %do; %let ry=1; %end;

/*use short name _Tag_=t# for the terms in up-right corner*/
data dataIn_001 dataIn_002;
set dataIn_0;
if x>=0 and y>=&ry. then output dataIn_002;
else output dataIn_001;
run;

proc sort data=dataIn_002;
by descending y descending x &ptVar.;
run;

data dataIn_002;
set dataIn_002;
length _Tag_ $10;
if x>0 and y>&ry. then _Tag_='T'||compress(put(_n_,4.0));
run;

data dataIn_0;
set dataIn_001 dataIn_002;
run;

   data dataIn_p1  dataIn_p2 dataIn_p3;
   set dataIn_0;
    if x=-1 then output dataIn_p2;
    else if x=1 then output dataIn_p3;
    else output dataIn_p1;
   run;

/*For HR, to avoid symbols be stacking, re-define x-value for the obs >=1 or <=-1;
  values <=-1 will be re-signed between -1.1 and -1
  values >=1 will be re-signed between 1 and 1.1;*/

   %macro rand(in=);
     proc sort data=&in.;
	 by y;
	 run;

	 data &in;
	 set &in;
     if x=1 then do;
       do i=1 to 5;
        x=1+0.018*mod(_n_,5);
	   end;
	 end;
     if x=-1 then do;
       do i=1 to 5;
        x=-1.0-0.018*mod(_n_,5);
	   end;
	 end;
     run;

   %mend rand;

%if %substr(%upcase(&RDorHR),2,1)= R %then %do;

   %rand(in=dataIn_p2);
   %rand(in=dataIn_p3);

   data dataIn_0;
   set dataIn_p1  dataIn_p2 dataIn_p3;
   run;
%end;

  data dataIn_1;set dataIn_0;run;

%macro SymbColorList;
%do i = 1 %to 28;
  %global symbol&i;
        %if &i=1 %then  %let symbol&i.=triangle;
  %else %if &i=2 %then %let symbol&i.=circle ;
  %else %if &i=3 %then %let symbol&i.=square ;
  %else %if &i=4 %then %let symbol&i.=$ ;
  %else %if &i=5 %then %let symbol&i.=diamond ;
  %else %if &i=6 %then %let symbol&i.=# ;
  %else %if &i=7 %then %let symbol&i.== ;
  %else %if &i=8 %then  %let symbol&i.=+;
  %else %if &i=9 %then %let symbol&i.=plus ;
  %else %if &i=10 %then %let symbol&i.=x ;
  %else %if &i=11 %then %let symbol&i.=star ;
  %else %if &i=12 %then %let symbol&i.= hash;
  %else %if &i=13 %then %let symbol&i.= dot;
  %else %if &i=14 %then %let symbol&i.= _;
  %else %if &i=15 %then %let symbol&i.= *;
  %else %if &i=16 %then %let symbol&i.= -;
  %else %if &i=17 %then %let symbol&i.= :;
  %else %if &i=18 %then %let symbol&i.= %;
  %else %if &i=19 %then %let symbol&i.= Y;
  %else %if &i=20 %then  %let symbol&i.=Z;
  %else %if &i=21 %then %let symbol&i.= , ;
  %else %if &i=22 %then %let symbol&i.= );
  %else %if &i=23 %then %let symbol&i.= &;
  %else %if &i=24 %then %let symbol&i.= >;
  %else %if &i=25 %then %let symbol&i.= /;
  %else %if &i=26 %then %let symbol&i.= ?;

  %global color&i;
        %if &i=1 or %sysfunc(mod(&i., 10))=1 %then %let color&i.=blue;
  %else %if &i=2 or %sysfunc(mod(&i., 10))=2 %then %let color&i.=red;
  %else %if &i=3 or %sysfunc(mod(&i., 10))=3 %then %let color&i.=green;
  %else %if &i=4 or %sysfunc(mod(&i., 10))=4 %then %let color&i.=orange;
  %else %if &i=5 or %sysfunc(mod(&i., 10))=5 %then %let color&i.=brown;
  %else %if &i=6 or %sysfunc(mod(&i., 10))=6 %then %let color&i.=CX8080FF;
  %else %if &i=7 or %sysfunc(mod(&i., 10))=7 %then %let color&i.=CX800080;
  %else %if &i=8 or %sysfunc(mod(&i., 10))=8 %then %let color&i.=CX808000;
  %else %if &i=9 or %sysfunc(mod(&i., 10))=9 %then %let color&i.=CX008080;
  %else %if &i=10 or %sysfunc(mod(&i., 10))=0 %then %let color&i.=CXFF8080;
  %if %upcase(&plot_color.)=N %then %let color&i.=black;
%end;
%mend SymbColorList;

%SymbColorList;

%if %upcase(&socLegend.)=Y %then %do;
*decide the number of AESOC/colors;
proc sql;
select count(distinct &socVar.) 
into :cnum
from dataIn_1;

create table all_soc as
select distinct &socVar., ssoc 
from dataIn_1
order by &socVar.;

quit;

%end;
%else %if %upcase(&socLegend.)=N %then %do;

%let cnum=28;

%end;
%annomac;

%if %upcase(&socLegend.)=Y %then %do;
  %let size1=0.7;

/*anno1-symbol legend for AESOC;*/
data anno1;
    set all_soc;
    length xsys ysys when $1 text $200 function color $8;
    xsys='5'; ysys='5'; when='B';
    function='symbol'; size=&size1.;
   %do i=1 %to &cnum.;
    if _n_=&i then do;
	 color="&&color&i.";
	 text="&&symbol&i.";
	 x= /*80*/88.5; 
	 y=98-&i*3;
	end;
   %end; 
run;

/*anno11-text legend for AESOC;*/
data anno11;
    set all_soc;
    length xsys ysys when position $1 text $200 function color $8;
    xsys='5'; ysys='5'; when='B';
	position='6'; function='label'; size=&size1.;
   %do i=1 %to &cnum.;
    if _n_=&i then do;
	 color="&&color&i.";
	 text=ssoc;
	 x= /*81.5*/90; 
	 y=98-&i*3;
	end;
   %end; 
run;
%end;

/*anno12-label for p-values;*/
%let x12=9.21;*8.68;
%if %substr(%upcase(&RDorHR),2,1)^= R %then %do;
  %let x12=9.25;
%end;
data anno12;
    length xsys ysys when position $1 text $200 function color $8;
    xsys='5'; ysys='2'; when='A';position='4';
    function='label'; size=0.85; x= &x12.;
    color='black';text=' 1.0 -'; y=.02;output;
    color='black';text=' 0.1 -'; y=1*1.02;output;
/*    %if %upcase(&plot_color.)=Y %then color='red';;*/
    text='0.05 -'; y=1.313*1.01;output;	
    color='black';text='0.01 -'; y=2*1.01;output;
    color='black';text='<=0.001 -'; y=3*1.0064;output;
run;

/*anno13-label for hazard ratio;*/
%if %substr(%upcase(&RDorHR),2,1)= R %then %do;  %let y1=18; %let y2=21.9;%end;
%else  %if %substr(%upcase(&RDorHR),2,1)^= R %then %do;  %let y1=20; %let y2=23.9;%end;

data anno13;
    length xsys ysys when position $1 text $200 function color $8;
    xsys='2'; ysys='3'; when='A'; position='4';
    function='label'; size=0.85; color='black';
	text=' <=0.1';x= -0.96; y= &y1.; output;
	text=' |';x= -0.997; y= &y2.; output;
	text='1'; x= 0.01; y= &y1.; output;
	text=' |';x= 0.003; y= &y2.; output;
	text='2'; x= 0.312; y= &y1.; output;
	text=' |';x= 0.3035; y= &y2.; output;
	text='5';x= 0.712; y= &y1.; output;
	text=' |';x= 0.7035; y= &y2.; output;
	text='>=10';x= 1.029; y= &y1.; output;
	text=' |';x= 1.0035; y= &y2.; output;
run;

/*Draw arrows*/;
%let down=7; %let up=0; %let siz=0.95;
%if %substr(%upcase(&RDorHR),2,1)= R %then %do; %let down=3; %let up=-0.2; %let siz=0.85; %end;
data anno14;
    length xsys ysys when position $1 text $200 function color $8;
    xsys='2'; ysys='3'; when='A'; position='4';
    function='label'; size=&siz.; color='black';
	text='Favours '||"%lowcase(&treat1.)";x= -0.35; y= &y1.-&down.; output;
	text='Favours '||"%lowcase(&treat0.)"; x= 0.8+&up.; y= &y1.-&down.; output;
    %move(-0.1,&y1.-&down.); 
    %arrow(-0.1, (&y1.-&down.), -0.25, (&y1.-&down.), black, 1,2 ,45, filled);  
    output;
    %move(0.1,&y1.-&down.); 
    %arrow(0.1, (&y1.-&down.), 0.25, (&y1.-&down.), black, 1,2 ,45, filled);  
    output;
run;

/*anno2-draw reference lines*/;
data anno2;
  length xsys ysys when $1 color $8;
  xsys='2';ysys='2';when='A'; 
%if  %substr(%upcase(&RDorHR),2,1)= R  %then %do;
  %move(-1.08,&ry.); 
  %draw(1.08, &ry.,black, 2, 1);  
  output;
%end;
%else %if  %upcase(&RDorHR.) = RD %then %do;
  %move(-2,&ry.); 
  %draw(2, &ry., black, 2, 1);  
  output;
%end;
  %move(0,0); 
  %draw(0,3,black, 2, 1);  
  output;
run;

%if %upcase(&socLegend.)=Y %then %do;

data all_soc;
set all_soc;
cn=_n_;
run;

proc sql;
create table all as 
select a.*, s.cn
from dataIn_1 as a, all_soc as s
where a.&socVar.=s.&socVar.
order by cn, &ptVar.;
quit;

%end;
%else %if %upcase(&socLegend.)=N %then %do;
data all;
set dataIn_1;
if _n_<=28 then cn=_n_;
else cn=mod(_n_, 28)+1;
%end;

/*anno3-symbols for all AEPTs */;
data anno3;
   set all;
   /*retain xsys ysys when;*/
   length xsys ysys when $1 text $200 function color $8 ;
   xsys='2';ysys='2'; when='A'; 
   function='symbol';size=0.9;
   %do i=1 %to &cnum.;
    if cn=&i then do;
	 color="&&color&i.";
	 text="&&symbol&i.";
	end;
   %end; 
    run;

/*anno4-text label for the AEPT in up-right corner*/;
data anno4;
   set all;
   /*retain xsys ysys when;*/
   length xsys ysys when $1 text $200 style color $8;  
   xsys='2';ysys='2';when='A'; 
   %do i=1 %to &cnum.;
%if %substr(%upcase(&RDorHR),2,1)= R %then %do;
    if cn=&i and x>0 and y> &ry. then do;
	 %if %upcase(&sTerm.)=Y  %then %do;
      %label(x,y,_Tag_,&&color&i.,.,.,0.8,SIMPLEX,1);
	 %end;
	 %else %do;
      %label(x,y,&ptVar.,&&color&i.,.,.,0.8,SIMPLEX,1);
	 %end;
      /*%label(x,y,&ptVar.,&&color&i.,.,.,0.8,.,1);*/
%end;
%else %if  %upcase(&RDorHR.)=RD %then %do;
    if cn=&i and x>0 and y> &ry. then do;
	 %if %upcase(&sTerm.)=Y  %then %do;
      %label(x,y,_Tag_,&&color&i.,.,.,0.8,SIMPLEX,3);
	 %end;
	 %else %do;
      %label(x,y,&ptVar.,&&color&i.,.,.,0.8,SIMPLEX,3);
	 %end;
%end;
	end;
   %end; 
    run;


data annoall;
%if %upcase(&socLegend.)=Y and %substr(%upcase(&RDorHR),2,1)= R %then %do;
set anno1 anno11 anno12 anno13 anno14 anno2 anno3 anno4;
%end;
%else %if %upcase(&socLegend.)=Y and %upcase(&RDorHR.)=RD %then %do;
set anno1 anno11 anno14 anno12 anno2 anno3 anno4;
%end;
%else %if  %upcase(&socLegend.)=N and %upcase(&RDorHR.)=RD %then %do;
set anno12 anno14 anno2 anno3 anno4;
%end;
%else %if  %upcase(&socLegend.)=N and %substr(%upcase(&RDorHR),2,1)= R %then %do;
set anno12 anno13 anno14 anno2 anno3 anno4;
%end;

run;

options mprintnest nobyline nodate nonumber NOCENTER NONOTES missing=" "
		bufsize=50k bufno=4 sortsize=max orientation=landscape compress=yes;
%let specialChar=!;
%let titleHeight=3.0;


options topmargin=1.5 cm bottommargin=2.3cm leftmargin=1.5cm rightmargin=1.5 cm;
goptions reset=all gunit=pct cback=white colors=(black blue green red) 
         ftitle=arial ftext=arial htitle=5 htext=2 device=pdfc  
         gsfname=sasgout  display;
ods listing close;
ods pdf file="&outpth./&outNm..pdf" color style=Printer fontscale=80
		bookmarkgen=yes;;
footnote  j=l h=1.5 "&ftnt1.";
footnote2 j=l h=1.5 "&ftnt2.";
footnote3 j=l h=1.5 "Program: &pgmNm..sas";
footnote4 j=l h=1.5 "Output: &outpth.\&outnm..pdf (Date Generated: &sysdate : &systime)"; 
title  j=c h=5  "&titl."; 

/*y-axis*/;
axis1 origin=(9.1 pct,)
      label=(a=90 h=3 "&yLabel.") 
      offset=(0,6) 
      order=(0.0 to 3.0 by 0.5)
	  major=none
	  minor=none
	  value=(h=2.0 c=white t=1 '1.0 ' t=2 ' ' t=3 '0.1 ' t=4 '' t=5 '0.01 ' t=6 '' t=7 '0.001')
     ;
 %if  %substr(%upcase(&RDorHR),2,1)= R %then %do;
/*x-axis*/;
axis2 origin=(9.1 pct,)
      label=(h=3 "&xLabel.")
      offset=(0,0)
      order=(-1.1 to 1.1 by 0.1)
	  minor=none
	  major=none
	  value=(h=2.0 c=white/*t=1 '<=.01' t=2 ' ' t=3 '1' t=4 '' t=5 '>=10'*/)
 %if %upcase(&socLegend.) =Y %then %do;
	  length=78 pct;
 %end;
 %else %if %upcase(&socLegend.) =N %then %do;
	  length=85 pct;
 %end;
%end;
%else %if %upcase(&RDorHR.) = RD %then %do;
/*x-axis*/;
axis2 origin=(9.1 pct,)
      label=(h=3 "&xLabel.")
      offset=(0,0)
      order=(-2 to 2 by 1)
	  minor=none
	  value=(h=2.0 t=1 '<=-2' t=2 '-1' t=3 '0' t=4 '1' t=5 '>=2')
 %if %upcase(&socLegend.) =Y %then %do;
	  length=78 pct;
 %end;
 %else %if %upcase(&socLegend.) =N %then %do;
	  length=85 pct;
 %end;
%end;

*not show the plot symbol;
symbol1 value=circle   h=2 c=white ; 

ods proclabel "Volcano Plot";
proc gplot data=dataIn_1 anno=annoall;
plot y*x/nolegend 
     haxis=axis2 
     vaxis=axis1
     des="&xLabel";;
 run;

title j=c  "&titl. ";
%if  %substr(%upcase(&RDorHR),2,1)= R %then %do;
title2 j=c "List of Terms with p-value <=&refLine. and Ratio >1"; 
%end;
%else %if %upcase(&RDorHR.)=RD %then %do;
title2 j=c "List of Terms with p-value <=&refLine. and Risk Difference(%) >0"; 
%end;


proc sort data=dataIn_1;
by &yVar. &xVar. &ptVar.;
where x>=0 and y>=&ry.;
run;

%if %substr(%upcase(&RDorHR),2,1)= R %then %do;
 ods proclabel "List of Terms with p-value <=&refLine. and Ratio >1";
%end;
%else %if %upcase(&RDorHR.)=RD %then %do;
 ods proclabel "List of Terms with p-value <=&refLine. and Risk Difference(%) >0";
%end;

proc report data=dataIn_1  style(column)=[font_size=2 font_weight=bold]
			nowd style(header)=[background=yellow font_size=2 font_weight=bold]
            split="#" contents="";;
    footnote  font='Arial' h=7pt "&ftnt1.";
    footnote2 font='Arial' h=7pt "&ftnt2.";
	footnote3 font='Arial' h=7pt j=l "Program: &pgmNm..sas";
	footnote4 font='Arial' h=7pt j=l  "Output: &outpth.\&outNm..pdf (Date Generated: &sysdate : &systime)";;
%if %upcase(&ptVar.)=AEHLT or %upcase(&ptVar.)=AEHLGT %then %do;
    column _Tag_ &ptVar. tn1 tn0 %if %substr(%upcase(&RDorHR),2,1)= R %then &xVar.; %else x1; &yVar.;
	define &ptVar. /display style=[cellwidth=13.5 cm just=l];
%end;
%else %do;
    column _Tag_ &socVar. &ptVar. tn1 tn0 %if %substr(%upcase(&RDorHR),2,1)= R %then &xVar.; %else x1; &yVar.;
	define &socVar. /display style=[cellwidth=9 cm just=l];
	define &ptVar. /display style=[cellwidth=4.5 cm just=l];
%end;
	define _Tag_    /display "Term#Number" style=[cellwidth=1.5 cm just=l];
	define tn0    /display "&trtm0.#(n/N)" style=[cellwidth=2 cm just=c];
	define tn1    /display "&trtm1#(n/N)" style=[cellwidth=2.5 cm just=c];
    define %if %substr(%upcase(&RDorHR),2,1)= R %then &xVar.; %else x1; 
           /display %if %substr(%upcase(&RDorHR),2,1)= R %then "Ratio#&trtm1. vs &trtm0."; 
                            %else %if %upcase(&RDorHR.) = RD %then "Risk Difference(%)#&trtm1. vs &trtm0."; 
           style=[cellwidth=2.5 cm just=l];
	define &yVar. /display  "p-value"  style=[cellwidth=2 cm just=c];
run;

ods pdf close; %end;
ods listing;
%end;

%mend g_volcano;


/************************************************************/
/*Following is a smaple data set and code to call the macro.*/
/************************************************************/

options mprint mlogic nofmterr;
%let pgmNm=sample_call;

/*Sample data*/
data sample;
input AESOC $ 1-53 AEPT $ 54-98	TREAT0 $ TREAT1 $ TOTALN0 TOTALN1 INCIDN0 INCIDN1 RD P_RD rdLowerCL	rdUpperCL RR P_RR rrLowerCl	rrUpperCl;
datalines;
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Agranulocytosis	                           PLACEBO	TREAT1	1287	1300	1	0	-0.000777001	0.4974874372	-0.002299303	0.000745301	0.33	0.3148786413	0.0135	8.0932
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Anaemia	                                   PLACEBO	TREAT1	1287	1300	28	38	0.0074747475	0.2620348401	-0.004665109	0.0196146036	1.3436	0.2280680306	0.8297	2.1757
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Eosinophilia	                               PLACEBO	TREAT1	1287	1300	5	8	0.0022688423	0.5801436936	-0.003173904	0.0077115888	1.584	0.4145931863	0.5196	4.829
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Erythropenia	                               PLACEBO	TREAT1	1287	1300	0	1	0.0007692308	1	-0.000737854	0.0022763154	2.97	0.3197423745	0.1211	72.8389
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Iron Deficiency Anaemia	                   PLACEBO	TREAT1	1287	1300	8	4	-0.003139083	0.2634460576	-0.00838337	0.0021052035	0.495	0.2401452656	0.1494	1.6398
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Leukocytosis	                               PLACEBO	TREAT1	1287	1300	0	4	0.0030769231	0.1247289719	0.0000662364	0.0060876097	8.9101	0.0464665798	0.4802	165.3241
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Leukopenia	                                   PLACEBO	TREAT1	1287	1300	5	9	0.003038073	0.4227547321	-0.002606997	0.0086831432	1.782	0.2923841772	0.5988	5.3028
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Neutropenia	                               PLACEBO	TREAT1	1287	1300	4	2	-0.001569542	0.4503402856	-0.00528264	0.0021435566	0.495	0.4067545386	0.0908	2.6978
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Pancytopenia	                               PLACEBO	TREAT1	1287	1300	1	3	0.0015306915	0.6247287764	-0.001489379	0.0045507617	2.97	0.3219117272	0.3093	28.5147
BLOOD AND LYMPHATIC SYSTEM DISORDERS	             Thrombocythaemia	                           PLACEBO	TREAT1	1287	1300	3	1	-0.001561772	0.3722134586	-0.004597015	0.0014734714	0.33	0.3121842641	0.0344	3.1683
CARDIAC DISORDERS	                                 Acute Myocardial Infarction	               PLACEBO	TREAT1	1287	1300	2	4	0.0015229215	0.6871607871	-0.002177813	0.005223656	1.98	0.4208333427	0.3633	10.7911
CARDIAC DISORDERS	                                 Arrhythmia	                                   PLACEBO	TREAT1	1287	1300	14	20	0.0045066045	0.3885806944	-0.004261367	0.0132745758	1.4143	0.3143466968	0.7175	2.7878
CARDIAC DISORDERS	                                 Arteriosclerosis Coronary Artery	           PLACEBO	TREAT1	1287	1300	2	1	-0.000784771	0.6229778998	-0.003412033	0.0018424912	0.495	0.5576818581	0.0449	5.4522
CARDIAC DISORDERS	                                 Atrial Fibrillation	                       PLACEBO	TREAT1	1287	1300	23	21	-0.001717172	0.7630165793	-0.011684692	0.0082503482	0.9039	0.7356136775	0.5028	1.625
CARDIAC DISORDERS	                                 Atrial Flutter	                               PLACEBO	TREAT1	1287	1300	3	0	-0.002331002	0.1229807526	-0.004965655	0.0003036506	0.1414	0.0816047121	0.0073	2.7353
CARDIAC DISORDERS	                                 Bundle Branch Block Right	                   PLACEBO	TREAT1	1287	1300	0	5	0.0038461538	0.0622742247	0.0004814027	0.007210905	10.8901	0.025975207	0.6028	196.7406
CARDIAC DISORDERS	                                 Cardiac Failure	                           PLACEBO	TREAT1	1287	1300	16	15	-0.000893551	0.8585701283	-0.009280942	0.0074938404	0.9281	0.8346033439	0.4608	1.8693
CARDIAC DISORDERS	                                 Cardiac Failure Congestive	                   PLACEBO	TREAT1	1287	1300	4	6	0.0015073815	0.7534605506	-0.003269998	0.0062847611	1.485	0.5368072613	0.42	5.2499
CARDIAC DISORDERS	                                 Cardiogenic Shock	                           PLACEBO	TREAT1	1287	1300	2	0	-0.001554002	0.2473970782	-0.003706024	0.0005980211	0.198	0.1551386279	0.0095	4.1202
CARDIAC DISORDERS	                                 Coronary Artery Disease	                   PLACEBO	TREAT1	1287	1300	10	16	0.0045376845	0.3246410021	-0.003139103	0.0122144722	1.584	0.2473978765	0.7215	3.4774
CARDIAC DISORDERS	                                 Extrasystoles	                               PLACEBO	TREAT1	1287	1300	12	7	-0.003939394	0.2591805433	-0.010527008	0.0026482199	0.5775	0.2407608216	0.2281	1.4622
CARDIAC DISORDERS	                                 Mitral Valve Incompetence	                   PLACEBO	TREAT1	1287	1300	5	4	-0.000808081	0.7523075992	-0.005348478	0.0037323164	0.792	0.7271243808	0.2132	2.9427
CARDIAC DISORDERS	                                 Myocardial Infarction	                       PLACEBO	TREAT1	1287	1300	11	6	-0.003931624	0.2341336568	-0.010166091	0.0023028429	0.54	0.215995664	0.2003	1.4558
CARDIAC DISORDERS	                                 Myocardial Ischaemia	                       PLACEBO	TREAT1	1287	1300	8	10	0.0014763015	0.8139234762	-0.004926353	0.0078789559	1.2375	0.6515736336	0.49	3.1255
CARDIAC DISORDERS	                                 Sinus Bradycardia	                           PLACEBO	TREAT1	1287	1300	4	1	-0.002338772	0.2160537838	-0.00573278	0.0010552357	0.2475	0.1757549055	0.0277	2.2114
CARDIAC DISORDERS	                                 Supraventricular Extrasystoles	               PLACEBO	TREAT1	1287	1300	5	2	-0.002346542	0.2860505104	-0.006357787	0.0016647024	0.396	0.2507472288	0.077	2.0374
CARDIAC DISORDERS	                                 Tachycardia	                               PLACEBO	TREAT1	1287	1300	7	9	0.0014840715	0.8030493954	-0.004554304	0.007522447	1.2729	0.6303008251	0.4755	3.4075
EAR AND LABYRINTH DISORDERS	                         Deafness Unilateral	                       PLACEBO	TREAT1	1287	1300	0	2	0.0015384615	0.499819282	-0.000592057	0.0036689805	4.95	0.159309738	0.2379	103.0054
EAR AND LABYRINTH DISORDERS	                         Ear Pain	                                   PLACEBO	TREAT1	1287	1300	8	5	-0.002369852	0.4205449431	-0.007825112	0.0030854073	0.6188	0.3941259365	0.203	1.8863
EAR AND LABYRINTH DISORDERS	                         Hypoacusis	                                   PLACEBO	TREAT1	1287	1300	9	5	-0.003146853	0.2981401159	-0.008807986	0.00251428	0.55	0.275446407	0.1848	1.6367
EAR AND LABYRINTH DISORDERS	                         Tinnitus	                                   PLACEBO	TREAT1	1287	1300	12	14	0.0014452214	0.8442860217	-0.006239243	0.009129686	1.155	0.7125759319	0.5363	2.4875
ENDOCRINE DISORDERS	                                 Goitre	                                       PLACEBO	TREAT1	1287	1300	9	8	-0.000839161	0.8130505605	-0.007068077	0.0053897552	0.88	0.7917211399	0.3406	2.2737
ENDOCRINE DISORDERS	                                 Hyperthyroidism	                           PLACEBO	TREAT1	1287	1300	7	4	-0.002362082	0.3843810621	-0.007383075	0.0026589104	0.5657	0.3560080097	0.166	1.9278
ENDOCRINE DISORDERS	                                 Hypothyroidism	                               PLACEBO	TREAT1	1287	1300	17	20	0.0021756022	0.7411407153	-0.006971383	0.0113225878	1.1647	0.6412939681	0.6129	2.2132
ENDOCRINE DISORDERS	                                 Thyroiditis	                               PLACEBO	TREAT1	1287	1300	0	3	0.0023076923	0.249728923	-0.000300645	0.0049160292	6.9301	0.084701416	0.3583	134.0286
EYE DISORDERS	                                     Conjunctivitis	                               PLACEBO	TREAT1	1287	1300	17	23	0.0044832945	0.4262086999	-0.005017282	0.0139838706	1.3394	0.3555350147	0.719	2.4952
EYE DISORDERS	                                     Conjunctivitis Allergic	                   PLACEBO	TREAT1	1287	1300	3	7	0.0030536131	0.3428592449	-0.001717874	0.0078251	2.31	0.210855982	0.5987	8.9134
EYE DISORDERS	                                     Eye Haemorrhage	                           PLACEBO	TREAT1	1287	1300	1	5	0.0030691531	0.2182415476	-0.000623942	0.0067622484	4.95	0.1047447545	0.5791	42.3106
EYE DISORDERS	                                     Eye Pain	                                   PLACEBO	TREAT1	1287	1300	3	6	0.0022843823	0.5070997672	-0.002245161	0.0068139259	1.98	0.3239054265	0.4963	7.8999
EYE DISORDERS	                                     Glaucoma	                                   PLACEBO	TREAT1	1287	1300	22	15	-0.005555556	0.2503322711	-0.014712668	0.0036015564	0.675	0.2341704745	0.3518	1.2952
EYE DISORDERS	                                     Keratoconjunctivitis Sicca	                   PLACEBO	TREAT1	1287	1300	1	4	0.0022999223	0.3745479607	-0.001073746	0.0056735905	3.96	0.1830405926	0.4432	35.3817
EYE DISORDERS	                                     Visual Acuity Reduced	                       PLACEBO	TREAT1	1287	1300	9	4	-0.003916084	0.1764202476	-0.009374207	0.0015420396	0.44	0.1590844192	0.1358	1.4252
GASTROINTESTINAL DISORDERS	                         Abdominal Pain Upper	                       PLACEBO	TREAT1	1287	1300	42	41	-0.001095571	0.911430358	-0.014678051	0.0124869085	0.9664	0.8743987392	0.6329	1.4758
GASTROINTESTINAL DISORDERS	                         Colitis	                                   PLACEBO	TREAT1	1287	1300	4	8	0.003045843	0.3866449252	-0.002181059	0.0082727449	1.98	0.2543971528	0.5977	6.5591
GASTROINTESTINAL DISORDERS	                         Diverticulum	                               PLACEBO	TREAT1	1287	1300	9	7	-0.001608392	0.6263409362	-0.007654264	0.0044374805	0.77	0.6019334766	0.2876	2.0613
GASTROINTESTINAL DISORDERS	                         Dry Mouth	                                   PLACEBO	TREAT1	1287	1300	10	7	-0.002385392	0.4771373623	-0.008617369	0.0038465845	0.693	0.4528565301	0.2646	1.815
GASTROINTESTINAL DISORDERS	                         Flatulence	                                   PLACEBO	TREAT1	1287	1300	30	21	-0.007156177	0.2051205143	-0.017876127	0.0035637732	0.693	0.1905783219	0.3989	1.2039
GASTROINTESTINAL DISORDERS	                         Gastric Polyps	                               PLACEBO	TREAT1	1287	1300	3	2	-0.000792541	0.6857000592	-0.00418083	0.0025957489	0.66	0.6463699768	0.1105	3.9433
GASTROINTESTINAL DISORDERS	                         Gastric Ulcer	                               PLACEBO	TREAT1	1287	1300	6	4	-0.001585082	0.5460894237	-0.006372	0.003201837	0.66	0.5160244598	0.1867	2.3333
GASTROINTESTINAL DISORDERS	                         Gastrooesophageal Reflux Disease	           PLACEBO	TREAT1	1287	1300	24	20	-0.003263403	0.5462856811	-0.013232586	0.0067057792	0.825	0.5210541755	0.4581	1.4859
GASTROINTESTINAL DISORDERS	                         Haematochezia	                               PLACEBO	TREAT1	1287	1300	5	1	-0.003115773	0.1227767358	-0.006833605	0.0006020592	0.198	0.0995753444	0.0232	1.6924
GASTROINTESTINAL DISORDERS	                         Haemorrhoids	                               PLACEBO	TREAT1	1287	1300	23	18	-0.004024864	0.4350977255	-0.013654862	0.0056051344	0.7748	0.4125481894	0.4202	1.4287
GASTROINTESTINAL DISORDERS	                         Hiatus Hernia	                               PLACEBO	TREAT1	1287	1300	14	19	0.0037373737	0.4842132913	-0.004903949	0.0123786965	1.3436	0.3971137024	0.6766	2.6681
GASTROINTESTINAL DISORDERS	                         Hyperchlorhydria	                           PLACEBO	TREAT1	1287	1300	4	0	-0.003108003	0.0611096309	-0.006149053	-0.000066953	0.11	0.0442998399	0.0059	2.041
GASTROINTESTINAL DISORDERS	                         Irritable Bowel Syndrome	                   PLACEBO	TREAT1	1287	1300	12	10	-0.001631702	0.6748963232	-0.008711719	0.0054483154	0.825	0.6514020473	0.3577	1.9027
GASTROINTESTINAL DISORDERS	                         Oesophagitis	                               PLACEBO	TREAT1	1287	1300	6	12	0.0045687646	0.2363454686	-0.001824607	0.0109621363	1.98	0.1622595266	0.7454	5.2595
GASTROINTESTINAL DISORDERS	                         Periodontitis	                               PLACEBO	TREAT1	1287	1300	7	2	-0.003900544	0.1071000961	-0.008448647	0.0006475596	0.2829	0.0921100566	0.0589	1.359
GASTROINTESTINAL DISORDERS	                         Stomach Discomfort	                           PLACEBO	TREAT1	1287	1300	5	3	-0.001577312	0.5050524142	-0.005861514	0.0027068913	0.594	0.4701055328	0.1423	2.4804
GASTROINTESTINAL DISORDERS	                         Toothache	                                   PLACEBO	TREAT1	1287	1300	10	2	-0.006231546	0.0215611683	-0.011480447	-0.000982646	0.198	0.0197110756	0.0435	0.9019
GASTROINTESTINAL DISORDERS	                         Vomiting	                                   PLACEBO	TREAT1	1287	1300	34	33	-0.001033411	0.9019240861	-0.013275814	0.0112089922	0.9609	0.8686066329	0.5989	1.5416
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Asthenia	                                   PLACEBO	TREAT1	1287	1300	27	17	-0.007902098	0.1301454488	-0.01787413	0.0020699344	0.6233	0.1202125134	0.3414	1.138
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Influenza Like Illness	                       PLACEBO	TREAT1	1287	1300	10	6	-0.003154623	0.3285077366	-0.00920336	0.0028941134	0.594	0.3062677146	0.2165	1.6296
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Local Swelling	                               PLACEBO	TREAT1	1287	1300	2	5	0.0022921523	0.4525313774	-0.001701937	0.0062862419	2.475	0.2618987455	0.4811	12.7337
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Malaise	                                   PLACEBO	TREAT1	1287	1300	8	11	0.0022455322	0.6464546048	-0.004329444	0.0088205089	1.3613	0.5036977992	0.5493	3.3732
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Oedema Peripheral	                           PLACEBO	TREAT1	1287	1300	53	51	-0.001950272	0.8416236216	-0.017090741	0.0131901967	0.9526	0.8006977584	0.6537	1.3884
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Pain	                                       PLACEBO	TREAT1	1287	1300	12	16	0.002983683	0.5696095527	-0.004984516	0.0109518816	1.32	0.4634454407	0.627	2.7791
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS Pyrexia	                                   PLACEBO	TREAT1	1287	1300	15	17	0.0014219114	0.8592341183	-0.007093909	0.0099377315	1.122	0.7435940934	0.5628	2.237
HEPATOBILIARY DISORDERS	                             Cholelithiasis	                               PLACEBO	TREAT1	1287	1300	18	23	0.0037062937	0.5296246811	-0.005912286	0.0133248737	1.265	0.4505128911	0.686	2.3327
HEPATOBILIARY DISORDERS	                             Hepatic Steatosis	                           PLACEBO	TREAT1	1287	1300	6	8	0.0014918415	0.7899956423	-0.004158191	0.0071418744	1.32	0.6051366816	0.4593	3.7936
IMMUNE SYSTEM DISORDERS	                             Drug Hypersensitivity	                       PLACEBO	TREAT1	1287	1300	3	5	0.0015151515	0.7261665373	-0.002758365	0.0057886684	1.65	0.4877812755	0.3951	6.8899
INFECTIONS AND INFESTATIONS	                         Diverticulitis	                               PLACEBO	TREAT1	1287	1300	12	9	-0.002400932	0.5198070387	-0.009320962	0.0045190972	0.7425	0.4962979657	0.3139	1.7561
INFECTIONS AND INFESTATIONS	                         Ear Infection	                               PLACEBO	TREAT1	1287	1300	6	11	0.0037995338	0.3308002387	-0.002416765	0.0100158321	1.815	0.231821959	0.6732	4.893
INFECTIONS AND INFESTATIONS	                         Fungal Skin Infection	                       PLACEBO	TREAT1	1287	1300	5	0	-0.003885004	0.0303537191	-0.007283676	-0.000486332	0.09	0.0245078539	0.005	1.626
INFECTIONS AND INFESTATIONS	                         Gastroenteritis	                           PLACEBO	TREAT1	1287	1300	32	29	-0.002556333	0.6989379716	-0.014253226	0.0091405607	0.8972	0.6683875626	0.546	1.4741
INFECTIONS AND INFESTATIONS	                         Gastroenteritis Viral	                       PLACEBO	TREAT1	1287	1300	13	10	-0.002408702	0.5375429452	-0.009647542	0.0048301369	0.7615	0.5141223575	0.3351	1.7304
INFECTIONS AND INFESTATIONS	                         Herpes Zoster	                               PLACEBO	TREAT1	1287	1300	29	21	-0.006379176	0.2557278173	-0.016995412	0.0042370588	0.7169	0.2387433031	0.411	1.2504
INFECTIONS AND INFESTATIONS	                         Laryngitis	                                   PLACEBO	TREAT1	1287	1300	11	7	-0.003162393	0.3553304393	-0.009574795	0.0032500088	0.63	0.3333811942	0.245	1.62
INFECTIONS AND INFESTATIONS	                         Localised Infection	                       PLACEBO	TREAT1	1287	1300	7	6	-0.000823621	0.7890120154	-0.006275364	0.0046281223	0.8486	0.7671078012	0.286	2.5181
INFECTIONS AND INFESTATIONS	                         Lower Respiratory Tract Infection	           PLACEBO	TREAT1	1287	1300	29	20	-0.007148407	0.1963961469	-0.017660452	0.0033636376	0.6828	0.1824205212	0.3883	1.2006
INFECTIONS AND INFESTATIONS	                         Onychomycosis	                               PLACEBO	TREAT1	1287	1300	11	8	-0.002393162	0.4998403108	-0.008978428	0.0041921032	0.72	0.4760656342	0.2906	1.7842
INFECTIONS AND INFESTATIONS	                         Otitis Media	                               PLACEBO	TREAT1	1287	1300	6	2	-0.003123543	0.1769328537	-0.007411837	0.001164751	0.33	0.1526073972	0.0667	1.632
INFECTIONS AND INFESTATIONS	                         Pyelonephritis	                               PLACEBO	TREAT1	1287	1300	7	1	-0.004669775	0.0378858115	-0.008961329	-0.00037822	0.1414	0.0324796911	0.0174	1.1479
INFECTIONS AND INFESTATIONS	                         Respiratory Tract Infection	               PLACEBO	TREAT1	1287	1300	16	23	0.0052602953	0.3333385859	-0.004120601	0.0146411912	1.4231	0.2723690156	0.7554	2.6811
INFECTIONS AND INFESTATIONS	                         Respiratory Tract Infection Viral	           PLACEBO	TREAT1	1287	1300	8	6	-0.001600622	0.6045204822	-0.007258685	0.0040574415	0.7425	0.5790808219	0.2584	2.1339
INFECTIONS AND INFESTATIONS	                         Rhinitis	                                   PLACEBO	TREAT1	1287	1300	22	25	0.0021367521	0.768939255	-0.008153234	0.0124267388	1.125	0.6841668407	0.6377	1.9848
INFECTIONS AND INFESTATIONS	                         Sinusitis	                                   PLACEBO	TREAT1	1287	1300	38	36	-0.001833722	0.8141903057	-0.014682515	0.0110150715	0.9379	0.7797056546	0.5985	1.4699
INFECTIONS AND INFESTATIONS	                         Tracheitis	                                   PLACEBO	TREAT1	1287	1300	2	8	0.0045998446	0.1087396645	-0.000164997	0.0093646864	3.96	0.0594592557	0.8425	18.6121
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Back Injury	                               PLACEBO	TREAT1	1287	1300	9	6	-0.002377622	0.4510184151	-0.008234434	0.0034791897	0.66	0.4259000244	0.2356	1.8489
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Excoriation	                               PLACEBO	TREAT1	1287	1300	7	11	0.003022533	0.4792291633	-0.003375759	0.0094208252	1.5557	0.3552027384	0.605	4.0005
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Femur Fracture	                               PLACEBO	TREAT1	1287	1300	10	8	-0.001616162	0.6448833566	-0.00802587	0.0047935467	0.792	0.6210532684	0.3136	2.0003
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Foot Fracture	                               PLACEBO	TREAT1	1287	1300	15	11	-0.003193473	0.4376367122	-0.010885978	0.0044990313	0.726	0.4156206662	0.3347	1.5746
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Humerus Fracture	                           PLACEBO	TREAT1	1287	1300	18	15	-0.002447552	0.6036300117	-0.011099963	0.0062048579	0.825	0.5792032912	0.4176	1.6299
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Joint Injury	                               PLACEBO	TREAT1	1287	1300	14	8	-0.004724165	0.2059887923	-0.011808527	0.0023601973	0.5657	0.1908350303	0.2381	1.3439
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Joint Sprain	                               PLACEBO	TREAT1	1287	1300	18	28	0.0075524476	0.1802590096	-0.002617925	0.01772282	1.54	0.146208831	0.8562	2.7701
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Lumbar Vertebral Fracture	                   PLACEBO	TREAT1	1287	1300	21	10	-0.008624709	0.0477389341	-0.017019009	-0.000230408	0.4714	0.0438641557	0.2229	0.9971
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Muscle Strain	                               PLACEBO	TREAT1	1287	1300	8	18	0.0076301476	0.0741566212	-0.000037103	0.0152973987	2.2275	0.0517765512	0.972	5.1045
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Post-Traumatic Pain	                       PLACEBO	TREAT1	1287	1300	7	10	0.0022533023	0.6279821913	-0.003967776	0.0084743801	1.4143	0.4782663204	0.54	3.704
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Procedural Pain	                           PLACEBO	TREAT1	1287	1300	22	14	-0.006324786	0.1826977207	-0.015359738	0.0027101655	0.63	0.1698073379	0.3238	1.2258
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Skin Laceration	                           PLACEBO	TREAT1	1287	1300	10	5	-0.003923854	0.2066421248	-0.009783324	0.0019356166	0.495	0.1888344299	0.1697	1.4442
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Thoracic Vertebral Fracture	               PLACEBO	TREAT1	1287	1300	17	11	-0.004747475	0.2601467647	-0.012728559	0.0032336094	0.6406	0.2433700522	0.3012	1.3622
INJURY, POISONING AND PROCEDURAL COMPLICATIONS	     Wound	                                       PLACEBO	TREAT1	1287	1300	9	11	0.0014685315	0.823162994	-0.005278237	0.0082153002	1.21	0.6698783855	0.5031	2.9101
INVESTIGATIONS	                                     Blood Cholesterol Increased	               PLACEBO	TREAT1	1287	1300	1	9	0.0061460761	0.0212624885	0.0013886349	0.0109035174	8.91	0.0117906386	1.1305	70.2261
INVESTIGATIONS	                                     Blood Pressure Increased	                   PLACEBO	TREAT1	1287	1300	14	12	-0.001647242	0.6983336087	-0.009337529	0.0060430455	0.8486	0.674561908	0.394	1.8276
INVESTIGATIONS	                                     Weight Decreased	                           PLACEBO	TREAT1	1287	1300	13	12	-0.000870241	0.84355325	-0.008411459	0.0066709769	0.9138	0.8210610531	0.4186	1.9952
METABOLISM AND NUTRITION DISORDERS	                 Anorexia	                                   PLACEBO	TREAT1	1287	1300	4	9	0.0038150738	0.265708195	-0.001622189	0.009252337	2.2275	0.1701144856	0.6877	7.2149
METABOLISM AND NUTRITION DISORDERS	                 Diabetes Mellitus	                           PLACEBO	TREAT1	1287	1300	20	23	0.0021522922	0.7589561505	-0.007697507	0.0120020909	1.1385	0.6686225042	0.6284	2.0626
METABOLISM AND NUTRITION DISORDERS	                 Glucose Tolerance Impaired	                   PLACEBO	TREAT1	1287	1300	6	3	-0.002354312	0.3405568497	-0.006898955	0.0021903303	0.495	0.3093142609	0.1241	1.975
METABOLISM AND NUTRITION DISORDERS	                 Hyperlipidaemia	                           PLACEBO	TREAT1	1287	1300	17	9	-0.006285936	0.1185177354	-0.01398149	0.001409617	0.5241	0.109081222	0.2345	1.1714
METABOLISM AND NUTRITION DISORDERS	                 Hypokalaemia	                               PLACEBO	TREAT1	1287	1300	3	12	0.0068997669	0.0346754987	0.0010717104	0.0127278234	3.96	0.0208538568	1.1201	13.9998
METABOLISM AND NUTRITION DISORDERS	                 Type 2 Diabetes Mellitus	                   PLACEBO	TREAT1	1287	1300	11	9	-0.001623932	0.6608925874	-0.008377379	0.0051295158	0.81	0.637335401	0.3368	1.9481
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Arthralgia	                                   PLACEBO	TREAT1	1287	1300	255	259	0.0010955711	0.9607210109	-0.029655851	0.0318469931	1.0055	0.944342722	0.8613	1.1739
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Arthritis	                                   PLACEBO	TREAT1	1287	1300	16	10	-0.004739705	0.2432312385	-0.012433964	0.002954555	0.6188	0.2269744035	0.2819	1.3583
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Bursitis	                                   PLACEBO	TREAT1	1287	1300	8	13	0.0037839938	0.381479714	-0.003121982	0.0106899691	1.6088	0.2836170752	0.6691	3.8683
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Foot Deformity	                               PLACEBO	TREAT1	1287	1300	6	9	0.0022610723	0.6062418294	-0.003584114	0.0081062583	1.485	0.4489322069	0.5301	4.1601
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Joint Range Of Motion Decreased	           PLACEBO	TREAT1	1287	1300	9	0	-0.006993007	0.0018404088	-0.011545685	-0.002440329	0.0521	0.0025295164	0.003	0.8943
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Joint Swelling	                               PLACEBO	TREAT1	1287	1300	26	14	-0.009432789	0.0565366302	-0.018949153	0.0000835746	0.5331	0.0519091515	0.2796	1.0162
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Muscle Spasms	                               PLACEBO	TREAT1	1287	1300	55	57	0.0011111111	0.9232057068	-0.014572901	0.0167951237	1.026	0.8895964188	0.7141	1.4741
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Muscular Weakness	                           PLACEBO	TREAT1	1287	1300	3	8	0.0038228438	0.2256296651	-0.001178547	0.0088242349	2.64	0.1352278667	0.702	9.9288
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Musculoskeletal Chest Pain	                   PLACEBO	TREAT1	1287	1300	22	24	0.0013675214	0.8820115342	-0.008815624	0.0115506667	1.08	0.792470126	0.6087	1.9161
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Myalgia	                                   PLACEBO	TREAT1	1287	1300	35	34	-0.001041181	0.9032889858	-0.013460006	0.0113776436	0.9617	0.86949156	0.6037	1.532
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Neck Pain	                                   PLACEBO	TREAT1	1287	1300	36	50	0.0104895105	0.1540273422	-0.003310392	0.0242894134	1.375	0.1368218963	0.9022	2.0957
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Osteochondrosis	                           PLACEBO	TREAT1	1287	1300	7	5	-0.001592852	0.5783298418	-0.006833814	0.0036481105	0.7071	0.5511522841	0.225	2.2223
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS	     Spinal Osteoarthritis	                       PLACEBO	TREAT1	1287	1300	32	24	-0.006402486	0.2819178615	-0.01762369	0.0048187169	0.7425	0.2633009587	0.4398	1.2534
NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED	         Basal Cell Carcinoma	                       PLACEBO	TREAT1	1287	1300	9	15	0.0045454545	0.3053356402	-0.002832164	0.011923073	1.65	0.2280045653	0.7247	3.7568
NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED	         Benign Neoplasm Of Thyroid Gland	           PLACEBO	TREAT1	1287	1300	2	6	0.0030613831	0.2883502815	-0.001205533	0.0073282989	2.97	0.1609401123	0.6006	14.6877
NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED	         Lung Neoplasm Malignant	                   PLACEBO	TREAT1	1287	1300	1	8	0.0053768454	0.0387579237	0.0008613256	0.0098923652	7.92	0.0202393187	0.992	63.2325
NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED	         Uterine Leiomyoma	                           PLACEBO	TREAT1	1287	1300	5	7	0.0014996115	0.7739235273	-0.00373266	0.0067318829	1.386	0.5746990151	0.441	4.3556
NERVOUS SYSTEM DISORDERS	                         Carpal Tunnel Syndrome	                       PLACEBO	TREAT1	1287	1300	11	13	0.0014529915	0.8381164825	-0.005932629	0.0088386122	1.17	0.6999761615	0.5261	2.6019
NERVOUS SYSTEM DISORDERS	                         Cerebrovascular Accident	                   PLACEBO	TREAT1	1287	1300	8	12	0.003014763	0.5018750135	-0.003727874	0.0097574001	1.485	0.3814726058	0.609	3.6208
NERVOUS SYSTEM DISORDERS	                         Memory Impairment	                           PLACEBO	TREAT1	1287	1300	19	17	-0.001686092	0.7399508111	-0.010716647	0.007344464	0.8858	0.7143846752	0.4625	1.6964
NERVOUS SYSTEM DISORDERS	                         Paraesthesia	                               PLACEBO	TREAT1	1287	1300	17	21	0.0029448329	0.624696692	-0.006321704	0.01221137	1.2229	0.5336887039	0.6482	2.3072
NERVOUS SYSTEM DISORDERS	                         Radiculopathy	                               PLACEBO	TREAT1	1287	1300	4	7	0.0022766123	0.5480110094	-0.00273075	0.0072839746	1.7325	0.3736804453	0.5084	5.9039
NERVOUS SYSTEM DISORDERS	                         Syncope	                                   PLACEBO	TREAT1	1287	1300	24	19	-0.004032634	0.4455653711	-0.013890612	0.0058253443	0.7838	0.4225563004	0.4315	1.4237
PSYCHIATRIC DISORDERS	                             Anxiety	                                   PLACEBO	TREAT1	1287	1300	28	42	0.0105516706	0.1149203716	-0.001934674	0.0230380149	1.485	0.0982279028	0.9263	2.3806
PSYCHIATRIC DISORDERS	                             Insomnia	                                   PLACEBO	TREAT1	1287	1300	45	43	-0.001888112	0.8287135012	-0.015860348	0.0120841247	0.946	0.7911351204	0.6273	1.4266
PSYCHIATRIC DISORDERS	                             Sleep Disorder	                               PLACEBO	TREAT1	1287	1300	4	13	0.0068919969	0.0483603164	0.000686985	0.0130970088	3.2175	0.030094171	1.0519	9.8415
RENAL AND URINARY DISORDERS	                         Dysuria	                                   PLACEBO	TREAT1	1287	1300	17	6	-0.008593629	0.0214735568	-0.01583801	-0.001349247	0.3494	0.0199275109	0.1382	0.8834
RENAL AND URINARY DISORDERS	                         Pollakiuria	                               PLACEBO	TREAT1	1287	1300	12	6	-0.004708625	0.1636198514	-0.011123166	0.0017059162	0.495	0.1497843968	0.1863	1.3149
RENAL AND URINARY DISORDERS	                         Renal Failure Chronic	                       PLACEBO	TREAT1	1287	1300	0	7	0.0053846154	0.0155066175	0.0014064636	0.0093627671	14.8501	0.0084001402	0.849	259.7401
REPRODUCTIVE SYSTEM AND BREAST DISORDERS	         Breast Pain	                               PLACEBO	TREAT1	1287	1300	8	2	-0.004677545	0.0636781114	-0.009471021	0.0001159321	0.2475	0.055286265	0.0527	1.1633
REPRODUCTIVE SYSTEM AND BREAST DISORDERS	         Fibrocystic Breast Disease	                   PLACEBO	TREAT1	1287	1300	2	7	0.0038306138	0.1789755386	-0.000692316	0.0083535435	3.465	0.0980924111	0.7212	16.648
RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS	     Asthma	                                       PLACEBO	TREAT1	1287	1300	19	23	0.0029292929	0.6414096736	-0.006805676	0.0126642614	1.1984	0.5556299808	0.6559	2.1896
RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS	     Chronic Obstructive Pulmonary Disease	       PLACEBO	TREAT1	1287	1300	8	7	-0.000831391	0.8021261894	-0.006684937	0.0050221551	0.8663	0.7806905098	0.315	2.3818
RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS	     Dysphonia	                                   PLACEBO	TREAT1	1287	1300	5	10	0.0038073038	0.3004300006	-0.002032786	0.0096473936	1.98	0.2023077388	0.6787	5.7768
RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS	     Epistaxis	                                   PLACEBO	TREAT1	1287	1300	7	18	0.0084071484	0.0423557676	0.0008908617	0.0159234351	2.5457	0.0288840825	1.0669	6.0741
RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS	     Pharyngolaryngeal Pain	                       PLACEBO	TREAT1	1287	1300	28	17	-0.008679099	0.099323832	-0.018761833	0.0014036352	0.6011	0.0914236418	0.3306	1.0927
SKIN AND SUBCUTANEOUS TISSUE DISORDERS	             Alopecia	                                   PLACEBO	TREAT1	1287	1300	19	15	-0.003224553	0.4947578741	-0.012006167	0.0055570602	0.7816	0.4715786881	0.3989	1.5313
SKIN AND SUBCUTANEOUS TISSUE DISORDERS	             Ecchymosis	                                   PLACEBO	TREAT1	1287	1300	1	6	0.0038383838	0.1245256156	-0.00014819	0.0078249578	5.94	0.0602811515	0.7161	49.2697
SKIN AND SUBCUTANEOUS TISSUE DISORDERS	             Pruritus	                                   PLACEBO	TREAT1	1287	1300	38	27	-0.008756799	0.1680611332	-0.020824334	0.003310737	0.7034	0.1548440156	0.4321	1.1451
SKIN AND SUBCUTANEOUS TISSUE DISORDERS	             Rash	                                       PLACEBO	TREAT1	1287	1300	23	33	0.0075135975	0.2240520894	-0.00368886	0.018716055	1.4204	0.1892661599	0.8388	2.4054
SKIN AND SUBCUTANEOUS TISSUE DISORDERS	             Skin Ulcer	                                   PLACEBO	TREAT1	1287	1300	7	14	0.0053302253	0.187560401	-0.001570946	0.0122313965	1.98	0.130949523	0.8018	4.8896
SKIN AND SUBCUTANEOUS TISSUE DISORDERS	             Urticaria	                                   PLACEBO	TREAT1	1287	1300	12	8	-0.003170163	0.379220662	-0.009926159	0.0035858328	0.66	0.3574165938	0.2707	1.6092
VASCULAR DISORDERS	                                 Hypertension	                               PLACEBO	TREAT1	1287	1300	205	209	0.0014840715	0.9572398541	-0.026771876	0.0297400193	1.0093	0.9180264231	0.8459	1.2042
VASCULAR DISORDERS	                                 Hypertensive Crisis	                       PLACEBO	TREAT1	1287	1300	4	3	-0.000800311	0.7248869417	-0.004806732	0.00320611	0.7425	0.6952655981	0.1665	3.3109
;
run;


/*Sample call for Risk Ratio*/
%g_volcano      ( dataIn= sample         			     /*Readin dataset name*/
                , ptVar= aept          				 /*variable for AEDECOD, or AEHLT or AEHLGT */
                , treat0= PLACEBO                    /* Name of (Control) Treatment */
                , treat1=  TREAT1                 /* Name of active treatment */
                , RDorHR= RR                         /*RD|HR|RR|OR -plot type: output for Risk Difference or Hazard Ratio or Odd ratio or Risk Ratio*/
				, xVar= rr          				 /*variable shown on x-axis*/
				, yVar= p_rr          				 /*variable shown on y-axis*/
				, outNm= g_volcano_rr          		 /*graph output file name*/
				, outPth=.                           /*graph output path*/
				, outtyp= pdf                        /*output file type*/
                , socLegend= Y                       /*Y|N need AESOC legend or not*/
				, socVar= aesoc          			 /*variable for AEBODSYS or AESOC */
				, sTerm=N                            /*Y|N short term for labels in up-right corner*/
				, titl=%nrbquote(P-risk (Risk Ratio) Plot of Treatment Emergent Adverse Events at PT Level)           	 /*titles*/
				, ftnt1=%nrbquote()           	     /*footnote1*/
				, ftnt2= %nrbquote()          	     /*footnote2*/
				, xLabel=%nrbquote(Risk Ratio)   	 /*text label for x-axis*/
				, yLabel=%nrbquote(RR p-value)   	 /*text label for y_axis*/
				, pgmNm= %nrbquote(.\sample_call)          /* program name with path, for footnote only*/
                , refLine= 0.05                      /* horizontal reference line for p-value, default is 0.05, could be 0.1, 0.01*/
                , plot_color = Y                     /*output the graph in color or black/white. Defualt is in color*/
                );

/*Sample call for Risk Difference*/
%g_volcano      ( dataIn= sample          			     /*Readin dataset names*/
                , ptVar= aept          				 /*variable for AEDECOD, or AEHLT or AEHLGT */
                , treat0= PLACEBO                    /* Name of (Control) Treatment */
                , treat1=  TREAT1                 /* Name of active treatment */
                , RDorHR= RD                         /*RD|HR|RR|OR -plot type: output for Risk Difference or Hazard Ratio or Odd ratio or Risk Ratio*/
				, xVar= rd          				 /*variable shown on x-axis*/
				, yVar= p_rd          				 /*variable shown on y-axis*/
				, outNm= g_volcano_rd          		 /*graph output file name*/
				, outPth=.                          /*graph output path*/
				, outtyp= pdf                        /*output file type*/
                , socLegend= Y                       /*Y|N need AESOC legend or not*/
				, socVar= aesoc          			 /*variable for AEBODSYS or AESOC */
				, sTerm=N                            /*Y|N short term for labels in up-right corner*/
				, titl=%nrbquote(P-risk (Risk Difference) Plot of Treatment Emergent Adverse Events at PT Level)           	 /*titles*/
				, ftnt1=%nrbquote()           	     /*footnote1*/
				, ftnt2= %nrbquote()          	     /*footnote2*/
				, xLabel=%nrbquote(Risk Difference (%))   			 /*text label for x-axis*/
				, yLabel=%nrbquote(Fisher Exact p-value)   		 /*text label for y_axis*/
				, pgmNm= %nrbquote(.\sample_call)                      /* program name with path, for footnote only*/
                , refLine= 0.05                                  /* horizontal reference line for p-value, default is 0.05, could be 0.1, 0.01*/
                , plot_color = Y                                 /*output the graph in color or black/white. Defualt is in color*/
                );
