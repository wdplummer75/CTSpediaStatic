/**************************************************************************
 CORONNA  -   Chris 
 Program:     buildfile
 Purpose:     
 Programmer:  Kimberly Johnson
 Date:        6/30/08 
 Comments:  If two observations match on the variables listed; then the log will 
            indicate how many observation matched between the two groups. In this 
            example, 27 patients from both groups matched on gender, ac, and dur.

            NOTE: There were 27 observations read from the data set WORK.GRP1_4.
            NOTE: There were 27 observations read from the data set WORK.GRP2_4.
            NOTE: The data set SAVE.MATCHED_SAMPLE has 54 observations and 6 variables.
            NOTE: DATA statement used (Total process time):
     MLOGIC(MATCHED_SAMPLE):  Ending execution.  
 
 Change History: 
    
***************************************************************************/ 
libname save '\\Bio3\ctsiberd';  

options mlogic mprint ;

%macro matched_sample(filename, group, ptid, keep, last);

*========================================================
 Separate the data into two groups.
 ========================================================;
data g1
     g2;
   set &filename;
   if &group=0 then output g1;
   if &group=1 then output g2;
run;

*========================================================
 For observations in Group 1, do the following:
    Assign the file name to variable FN.
    Assign the observation number to variable NOBS.
    Assign the identifier to variable PT.
    Assign a random number in variable RAND. 
 ========================================================;
data grp1(keep=&keep rand fn pt nobs)
     grp1_all;
   set g1;
   fn='grp1';
   nobs=_N_;
   pt=&ptid;
   rand=ranuni(0);
run;

*========================================================
 For observations in Group 2, do the following:
    Assign the file name to variable FN1.
    Assign the observation number to variable NOBS1.
    Assign the identifier to variable PT1.
 ========================================================;
data grp2(keep=&keep fn1 pt1 nobs1)
     grp2_all;
   set g2; 
   fn1='pa'; 
   nobs1=_N_;   
   pt1=&ptid;   
run;

*========================================================
 Sort observations in Group 1.
 ========================================================;
proc sort data=grp1;
   by &keep rand;
run;

*========================================================
 Sort observations in Group 2.
 ========================================================;
proc sort data=grp2;
   by &keep;
run;

*========================================================
 Determine how many observations there are for each set 
 of variables to be matched in Group 1. This is done by 
 beginning the count each time the first observation for 
 the last matching variable is encountered.
 ========================================================; 
data work.grp1b;
  retain n 0;
  set grp1; 
  by &keep;
  if first.&last then n=0;
  n=n+1;
run;

*========================================================
 Determine how many observations there are for each set 
 of variables to be matched in Group 2. This is done by 
 beginning the count each time the first observation for 
 the last matching variable is encountered.
 ========================================================;
data work.grp2b;
  retain n 0;
  set grp2; 
  by &keep;
  if first.&last then n=0;
  n=n+1;
run;

*========================================================
 Attempt to match the two group files by the matching 
 variables along with the count calculated in the last
 data step.	 If a match is found, put observation in the
 matched output file.
 ========================================================;
data matched 
     losta 
     lostb;
   merge grp2b(in=a) work.grp1b(in=b ); 
   by &keep n;
   if a and not(b) then output losta;
   if b and not(a) then output lostb;
   if a and b then output matched;
run;

*========================================================
 Separate the two groups.
 ========================================================;
data grp1_3(keep=&keep rand fn pt nobs
         rename=(pt=&ptid))
     grp2_3(keep=&keep fn1 pt1 nobs1
         rename=(pt1=&ptid));
   set matched;
run;

*========================================================
 Sort and merge group 1 file with the group 1 all file to 
 pick up the remaining variables for each observation.
 ========================================================;
proc sort data=grp1_3;
   by &ptid nobs;
run;

proc sort data=grp1_all;
   by &ptid nobs;
run;

data grp1_4;
   merge grp1_3(in=a) grp1_all(in=b);
   by &ptid nobs;
   if a and b;
run;

*========================================================
 Sort and merge group 2 file with the group 2 all file to 
 pick up the remaining variables for each observation.
 ========================================================;
proc sort data=grp2_3;
   by &ptid nobs1;
run;

proc sort data=grp2_all;
   by &ptid nobs1;
run;

data grp2_4;
   merge grp2_3(in=a) grp2_all(in=b);
   by &ptid nobs1;
   if a and b;
run;

*========================================================
 Merge the two group files to create the final matched 
 sample file.
 ========================================================;
data save.matched_sample(drop=rand nobs nobs1 fn fn1 pt pt1);
   set grp1_4 grp2_4;
run;

%mend;

/*%matched_sample(save.allobs, group, patient_id, gender ac dur, dur);*/
/*%matched_sample(save.allobs, group, patient_id, gender ac dur smoker, smoker);*/
