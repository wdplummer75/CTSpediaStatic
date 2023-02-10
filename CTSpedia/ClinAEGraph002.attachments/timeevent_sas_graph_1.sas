 /**********************************************************************
 *   Author: Max Cherny, GlaxoSmithKline
 *
 *   The purpose of the program is to create time to event graph using tmevent.csv file
 *   
 *   Key assumptions:
 *   Input file is located in the default user directory
 *   SAS 9.2 is used
 *   All symbols, colors and labels are manually hard-coded. 
 *   The output file is created in the default user directory
 *   The code only works for 2x2 template. Any other combination of graphs would require re-programming of proc greplay
 ***********************************************************************/


    data TMEVENT                                 ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile 'tmevent.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

       length survarg $30;
       informat timearg best32. ;
       informat panarg best32. ;
       informat trtarg $8. ;
       informat survarg $10. ;
       informat VAR5 best32. ;
       format timearg best12. ;
       format panarg best12. ;
       format trtarg $8. ;
       format survarg $30. ;
       format VAR5 best12. ;
    input
                timearg
                panarg
                trtarg $
                survarg $
                VAR5
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
    run;
options orientation=landscape  ;

goptions reset=all; device=SASPRTC target=SASPRTC ftext='Helvetica' ftitle='Helvetica/bold' ;

/*
/ Reformat and re-code data 
/-------------------------------------------------*/
data tmevent1;
  length trtarg $20;
  set tmevent;
  y=1-var5;
  if survarg="treat=High" then trt=1;
  if survarg="treat=Mid" then trt=3;
  if survarg="treat=Low" then trt=2;
  if survarg="treat=Placebo" then trt=4;
  label trt="Treatment"
  y="Proportion of subjects reporting event"
  panarg="Time (days)";
  if compress(trtarg)=:"Abdom" then trtarg="Abdominal Pain";
  format trtarg $20.;

run;

/*
/ Y axis
/-------------------------------------------------*/
axis2 label=(a=90 r=0 h=2 ) value=(h=2.4) ;

/*
/ Symbols
/-------------------------------------------------*/
symbol1 c=purple i=j w=10 line=1;
symbol2 c=green i=j w=5 line=5 ;
symbol3 c=red i=j w=3 line=34 ;
symbol4 c=black i=j w=2 line=6;

/*
/ Legend
/-------------------------------------------------*/
legend1 label=(h=2  "Treatments:" )  position=(bottom center outside) value=(h=2.4);

/*
/ Format treatments
/-------------------------------------------------*/
proc format;
  value trt
  1="High"
  2="Mid"
  3="Low"
  4="Placebo"
  ;
run;

/*
/ Remove catalog entries before plotting data
/ This will produce an error first time the code is run. Additional code may be added to check for existance of the entries
/-------------------------------------------------*/
 proc greplay gout=sasuser.excat igout=excat nofs;
   delete gplot gplot1 gplot2 gplot3 ;
quit;

/*
/ Produce plot for each AE.
/-------------------------------------------------*/
%macro plot_(gout=, where=,hide_legend=N);
  /*
  / X Axis. X -axis may be turned off if required
  /-------------------------------------------------*/
  axis1 value=(h=3) label=(h=3);

  %if &hide_legend=Y %then %do;
   axis1 label=none value=none minor=none major=none;
  %end; 


  options mprint;

  /*
  / Plot data. save each plot as a separate catalog entry
  /-------------------------------------------------*/
  proc gplot data=tmevent1 gout=excat;
    plot y*panarg=trt /vaxis=axis2 haxis=axis1

    %if &hide_legend=N %then %do;
     legend=legend1
    %end;

    %if &hide_legend=Y %then %do;
     nolegend
    %end; 
    ; 
    format trt trt.;
    title "&where";
    where trtarg="&where";
    run;
  quit;
%mend;
%plot_(gout=plot1, where=Headache,hide_legend=N);
%plot_(gout=plot1, where=Nausea);
%plot_(gout=plot1, where=Abdominal Pain,hide_legend=N );
%plot_(gout=plot1, where=Dizzines);

/*
/ Save plot as PDF
/-------------------------------------------------*/
ods listing close;
ods pdf file="timeevent.pdf" notoc;

/*
/ Produce all graphs one one page
/-------------------------------------------------*/
proc greplay gout=sasuser.excat igout=excat nofs
  tc=sashelp.templt template=l2r2;
  device win;
  treplay 1:gplot 2:gplot1 3:gplot2 4:gplot3 ;
quit;


ods pdf close;
ods listing;
