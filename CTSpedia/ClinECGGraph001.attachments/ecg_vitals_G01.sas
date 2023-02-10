
/**********************************************************************
 *   ---------------------------------------------READ DATASET
 *
 *   PRODUCT:   SAS
 *   VERSION:   9.2
 *   CREATOR:   External File Interface
 *   DATE:      28AUG12
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/
    data ecg_vitals_g01                            ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile 'ecg_vitals_G01.dat' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
       informat tpd best32. ;
       informat group best32. ;
       informat estimate best32. ;
       informat se best32. ;
       informat df best32. ;
       informat tval best32. ;
       informat pr best32. ;
       informat alpha best32. ;
       informat lower best32. ;
       informat upper best32. ;
       informat n best32. ;
       format tpd best12. ;
       format group best12. ;
       format estimate best12. ;
       format se best12. ;
       format df best12. ;
       format tval best12. ;
       format pr best12. ;
       format alpha best12. ;
       format lower best12. ;
       format upper best12. ;
       format n best12. ;
    input
                tpd
                group
                estimate
                se
                df
                tval
                pr
                alpha
                lower
                upper
                n
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
    run;

/*
/ Initialize various macro variables for annotation positions
/-------------------------------------------------*/
%let distance_between_trt_ns=3;
%let top_annotation_trt_y_position=20;

/*
/ Formats
/-------------------------------------------------*/
proc format;
/* format for x axis labels */
value xlabel 
  0="8:00"
  0.5="8:30"
  1="9:00"
  2="10:00"
  3="11:00"
  4="12:00"
  6="14:00"
  9="17:00"
  12="20:00"
  other=" ";

/* format for group text*/
value group
  1="Exp low" 
  2="Exp hi" 
  3="Pbo" 
  4="Moxi";

/* format for group color*/
value color
  1="cyan"
  2="blue"
  3="red"
  4="black";
run;

/*
/ Jitter time points and create group decode
/-------------------------------------------------*/
data ecg_vitals_g01;
  set ecg_vitals_g01;

  /* create group decode */
  length grouptxt $20;
  grouptxt =put(group, $group.);

  /* jitter timepoints */
  if group=1 then x=tpd;
  if group=2 then x=tpd+0.04;
  if group=3 then x=tpd+0.08;
  if group=4 then x=tpd+0.12;
run;

options mprint;
/*
/ invoke annotate macros 
/-------------------------------------------------*/
%annomac; 

/*
/ create annotation dataset for number of subjects below the plot
/-------------------------------------------------*/
data anno_trt_numbers;
  set ecg_vitals_g01;    
  length text $10;
  %system(2,5);
  text=left(n); /* create text variable for number of subjects */
  %label(tpd,(&top_annotation_trt_y_position-(group*&distance_between_trt_ns)), left(trim(n)), black, 0, 0 ,1 ,'' , 5);
run;

/*
/ create annotation dataset for group text
/-------------------------------------------------*/
proc sort data=ecg_vitals_g01 out =anno_trt_text nodupkey;
  by group;
run;

data anno_trt_text;
  set anno_trt_text;    
  %system(3,5);
  length text $10;
  text=left(grouptxt);
  %label(5,(&top_annotation_trt_y_position-(group*&distance_between_trt_ns)), text, black, 0, 0 ,1 ,'' , 6);
run;

/*
/ create annotation dataset for whisker bars
/-------------------------------------------------*/
data anno_lines ;
  set ecg_vitals_g01;
  tpd=x;
  %system(2,2); /* use Coordinate system '2' */
  /* Draw a line connecting high and low values for each month */
  %line(tpd,upper,tpd,lower,black,1,1);
  /* Draw a small horizontal line on top of each high value
  This is done by connecting a point a little bit to the left of high
  value to a point a little bit to the right of the high value. This
  little distance is 0.04 */
  %line(tpd-0.04,upper,tpd+0.04,upper,black,1,1);
  /* Draw a small horizontal line below each low value */
  %line(tpd-0.04,lower,tpd+0.04,lower,black,1,1); 
run;

/*
/ Combine all annotation datasets together
/ IMPORTANT: make sure text variable is not cut off!
/-------------------------------------------------*/
data anno;
  set anno_lines (in=anno_lines)
      anno_trt_numbers 
      anno_trt_text (in=trt_anno);
  /* set color variable to colors based on group variable */
  if not trt_anno then color=put(group, color.);
run;

/*
/ initialize goptions 
/-------------------------------------------------*/
goptions orientation=landscape reset=all device=SASPRTC target=SASPRTC ftext='Helvetica' ftitle='Helvetica/bold';

/*
/ X axis
/-------------------------------------------------*/
axis2 order=(0 to 13)  minor=NONE  label=none  offset=(3pct,0);

/*
/ Y axis
/-------------------------------------------------*/
axis1 order=(-10 to 30 by 5) label=(a=90 r=0 h=12pt "QTc Change (ms) - Fridericia Correction")  value=(h=10pt) ;

/*
/ legend
/-------------------------------------------------*/
legend1 label=("Treatments:")  position=(bottom center outside) frame cborder=gray origin=(, 21 pct) ;

/*
/ Set symbols. Make sure colors are consistent with colors set in annotation dataset. 
/ some extra code can be written to create symbols based on the same COLOR. format
/-------------------------------------------------*/
symbol1 i=j c=cyan v=square ;
symbol2 i=j c=blue v=dot;
symbol3 i=j c=red v=square;
symbol4 i=j c=black v=circle;

/*
/ Save plot as PDF
/-------------------------------------------------*/
ods listing close;
ods pdf file="ecg_vitals_G01_sas.pdf" notoc;

/*
/ Produce plot
/-------------------------------------------------*/

title1 height=10pt "ECG/VITALS G1" ;
title2 height=10pt "Figure Number #";
title3 height=10pt "SAS/GRAPH";


proc gplot data= ecg_vitals_g01 ;
  plot estimate*x=group/ vaxis=axis1 haxis=axis2 anno=anno legend=legend1 vref=0 lvref=33;
  format x xlabel. group group.;
  run;
quit;

ods pdf close;
ods listing;


