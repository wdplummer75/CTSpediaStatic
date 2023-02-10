
Data simICC;
	input    id    DepVar    subject    group;
datalines;
       1     32       1         1
       2     43       2         1
       3     42       3         1
       4     51       4         1
       5     42       5         1
       6     43       6         1
       7     43       7         1
       8     62       1         2
       9     43       2         2
      10     62       3         2
      11     34       4         2
      12     15       5         2
      13     27       6         2
      14     46       7         2
      15     45       1         3
      16     47       2         3
      17     43       3         3
      18     34       4         3
      19     34       5         3
      20     36       6         3
      21     26       7         3
      22     32       1         4
      23     46       2         4
      24     48       3         4
      25     51       4         4
      26     57       5         4
      27     56       6         4
      28     74       7         4
      29     73       1         5
      30     44       2         5
      31     46       3         5
      32     73       4         5
      33     42       5         5
      34     55       6         5
      35     56       7         5
      36     27       1         6
      37     44       2         6
      38     27       3         6
      39     42       4         6
      40     37       5         6
      41     44       6         6
      42     81       7         6
      43     42       1         7
      44     41       2         7
      45     53       3         7
      46     71       4         7
      47     71       5         7
      48     33       6         7
      49     52       7         7
      50     41       1         8
 ;
run;
 
filename ICC URL "http://www.ctspedia.org/wiki/pub/CTSpedia/MIXEDICC/MIXED_TEST_ICC.sas";
%include ICC;

/*filename ICC "Y:\BERDmacros\Xia\MIXED_TEST_ICC\Version1\MIXED_TEST_ICC.sas";
%include ICC;*/

%MIXED_TEST_ICC(DSName=simICC,
                      DepVar=DepVAr,
                      grp=group,
                      subj=subject,
                      OutFormat=pdf);


