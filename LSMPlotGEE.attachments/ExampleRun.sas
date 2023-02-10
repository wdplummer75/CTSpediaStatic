

*A sample Data used for SAS Macro LSMPlotGEE;
data  LSMPlotGEE;
	input Obs      ID    treatment    concovariate1    concovariate2    visit    response;
datalines;
          1       1        1              56               23           0          24
          2       2        1              41                8           0          30
          3       6        1              43               23           0         112
          4       7        4              53                0           0          10
          5       8        4              51               29           0          33
          6      17        4              53               19           0          10
          7      19        4              52                4           0          12
          8      21        1              56               11           0          25
          9      22        1              38               19           0          61
         10      26        1              40               14           0          98
         11      77        1               .                7           0           8
         12    1919        1               .                2           0           5
         13       1        1              56               23           1          10
         14       2        1              41                8           1          11
         15       6        1              43               23           1          13
         16       7        4              53                0           1          12
         17       8        4              51               29           1          31
         18      17        4              53               19           1          10
         19      19        4              52                4           1           5
         20      21        1              56               11           1           6
         21      22        1              38               19           1          23
         22      26        1              40               14           1          15
         23      77        1               .                7           1           5
         24    1919        1               .                2           1           5
         25       1        1              56               23           2           6
         26       2        1              41                8           2           8
         27       6        1              43               23           2          14
         28       7        4              53                0           2          12
         29       8        4              51               29           2          42
         30      17        4              53               19           2          12
         31      19        4              52                4           2          11
         32      21        1              56               11           2           6
         33      22        1              38               19           2          30
         34      26        1              40               14           2          18
         35      77        1               .                7           2           .
         36    1919        1               .                2           2           .
         37       1        1              56               23           3          11
         38       2        1              41                8           3           7
         39       6        1              43               23           3          13
         40       7        4              53                0           3           .
         41       8        4              51               29           3           9
         42      17        4              53               19           3          10
         43      19        4              52                4           3           5
         44      21        1              56               11           3           5
         45      22        1              38               19           3          56
         46      26        1              40               14           3          16
         47      77        1               .                7           3           .
         48    1919        1               .                2           3           .
run;


proc format;
value groupfmt 1= 'treatment'
			   4= 'Control';

run;

proc sort data=lsmplotgee;by id visit treatment;run;

filename LSMPlotG URL "http://www.ctspedia.org/wiki/pub/CTSpedia/LSMPlotGEE/LSMPlotGEE.sas";
%include LSMPlotG;

%LSMPlotGEE(DSname=LSMPlotGEE,
				   DVar=response, 
				   time=visit,
				   group=treatment,
                   Endtime=3,
        		   CovCat=,
                   CovCon=concovariate1 concovariate2,
                   id=id,
                   dist=normal,
				   type= exch,
                   format=html,
				   title=1. Outcome at 3 month follow-up Visit
 );

 
