
libname excel 'C:\ADLBC.xlsx';
%let gpath='C:\';
%let dpi=100;

data lfts;
  set excel.'ADLBC$'n;
  keep visit visitnum usubjid lbtestcd lbstresn lbstnrhi xuln trtpn treat;
  if lbtestcd in ('ALT', 'AST', 'BILI', 'ALP');
  xuln = lbstresn/lbstnrhi;
  if trtpn=0 then treat='Control';
  else treat='Active';
run;

libname excel clear;

/*Subset into base and max datasets, created ULN values specific for each lab test.
** Sorted each dataset ascending by lab result and took the last (maximum) value for
** the lab result. Output the maximim (last) value after sorting by subject and
** ascending ULN value */

 data labbase;
 set lfts;
 if visitnum=1;
 if xuln ne .;
 baseuln=xuln;
 run;

 data labbase;
 set labbase;
 keep usubjid treat lbtestcd baseuln;
 run;

 proc sort data=labbase;
 by usubjid lbtestcd;
 run;
 proc sort data=lfts;
 by lbtestcd usubjid xuln;
 run;

 data labmax;
 set lfts;
 if xuln ne .;
 if visitnum ne 1;
 maxuln=xuln;
 by lbtestcd usubjid xuln;
 if last.usubjid then output;
 run;

 data labmax;
 set labmax;
 keep usubjid lbtestcd maxuln;
 run;

 proc sort data=labmax;
 by usubjid lbtestcd;
 run;

/* Merge the baseline and maximum datasets */
data lftscatter;
 merge labbase labmax;
 by usubjid lbtestcd;
run;

 data lftscatter;
 set lftscatter;
 if maxuln ne . and baseuln ne .;
 run;

/* Create format for test name */
proc format;
  value test
    1='AST'
	2='ALT'
	3='ALKPH'
	4='BILTOT';
	run;

/*--Find unique subject counts--*/
proc sort data = lftscatter nodupkey out=count;
  By usubjid;
run;

data _null_;
  retain n na nc 0;
  set count end=last;
  by usubjid;

  if last.usubjid then do;
    n+1;
    if treat eq "Active" then na+1;
    else nc+1; 
  end;

  if last then do;
    call symput("NA", na);
	call symput("NC", nc);
	call symput("N", n);
  end;

  run;

data lftPanel;
  set lftscatter(keep=usubjid lbtestcd treat baseuln maxuln) end=last;
  drop lbtestcd na nc;
  label baseuln='Baseline (/ULN)';
  label maxuln='Maximum (/ULN)';
  format test test.;
  retain na nc 0;

  if baseuln ne . and maxuln ne .;

  if lbtestcd eq 'ALT' then test=1;
  else if lbtestcd eq 'AST' then test=2;
  else if lbtestcd eq 'ALP' then test=3;
  else test='4';
run;
/*proc print;run;*/

proc sort data=lftPanel out=lftpanelSort;
by test treat;
run;

data lftPanelRef;
  length treat1 $18;
  set lftpanelSort end=last;
  by test;
  
  if treat eq "Active" then treat1=cat(treat, ' (N=', &na, ')');
  else treat1=cat(treat, ' (N=', &nc, ')');

  if last.test then do;
    output;

	/*--Add data values for 45 degree line--*/
	ref=0; output;  
    ref=4; output;
    ref=.;

	/*--Add data values for CCL reference lines--*/
    test=1; ref1=1; output;
    test=2; ref1=1; output;
    test=3; ref1=1; output;
    test=4; ref1=1; output;

    test=1; ref1=3; output;
    test=2; ref1=3; output;
    test=3; ref1=2; output;
    test=4; ref1=2; output;
  end;
  else output;
  run;

proc template;
   define style lft; 
      parent = Styles.listing; 
      style GraphFonts from GraphFonts                                                      
         "Fonts used in graph styles" /                                                         
         'GraphValueFont' = ("<sans-serif>, <MTsans-serif>",10pt)              
         'GraphLabelFont' = ("<sans-serif>, <MTsans-serif>",11pt)        
         'GraphFootnoteFont' = ("<sans-serif>, <MTsans-serif>",11pt)          
         'GraphTitleFont' = ("<sans-serif>, <MTsans-serif>",13pt,bold); 
      style GraphData1 from GraphData1 /                                                      
         markersymbol = "circle";                                                                                    
      style GraphData2 from GraphData2 /                                                      
         markersymbol = "triangle";                                               
   end;
run;

title "Panel of LFT Shift from Baseline to Maximum by Treatment";
footnote1 j=l "The Clinical Concern Level for ALT and AST is 3 x ULN;";
footnote2 j=l "For BILTOT and ALKPH is 2 x ULN: where ULN is Upper Level of Normal Range";

/*--1 x 4 Panel--*/
ods listing style=lft image_dpi=&dpi gpath = &gpath;
ods graphics / reset width=9in height=3.65in  antialiasmax=900 imagename="LFT_Panel_1";
proc sgpanel data=lftPanelRef tmplout='c:\panel1';
  panelby test / layout=panel columns=4 spacing=10 novarname;
  scatter x=baseuln y=maxuln / group=treat1 name='s' transparency=0.4 nomissinggroup;
  series x=ref y=ref / lineattrs=graphreference;
  refline ref1 / axis=Y lineattrs=(pattern=shortdash); 
  refline ref1 / axis=X lineattrs=(pattern=shortdash);
  rowaxis integer min=0 max=4;
  colaxis integer min=0 max=4;
  keylegend 's' / title="" noborder;
  run;

/*--2 x 2 Panel--*/
ods listing style=lft image_dpi=&dpi gpath = &gpath;
ods graphics / reset width=6in height=7in  scale=off imagename="LFT_Panel_2";
  proc sgpanel data=lftPanelRef;
  panelby test / layout=panel columns=2 spacing=10 novarname;
  scatter x=baseuln y=maxuln / group=treat1 name='s' transparency=0.4 nomissinggroup;
  series x=ref y=ref / lineattrs=graphreference;
  refline ref1 / axis=Y lineattrs=(pattern=shortdash); 
  refline ref1 / axis=X lineattrs=(pattern=shortdash);
  rowaxis integer min=0 max=4;
  colaxis integer min=0 max=4;
  keylegend 's' / title="" noborder;
  run;

