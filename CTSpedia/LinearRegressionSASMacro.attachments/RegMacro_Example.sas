
/*
Example of how to run a linear regression model using the Linear macro.
*/

options pageno=1 nonumber nodate spool nomlogic nomprint nosymbolgen;
footnote1 'CTSIBERD\BERDmacros\Chen\Linear reg';

data one;
   input low age lwt race $ smoke ht ui ftv ptl bwt;
   datalines;
0     19     182     black     0     0     1     0     0     2523
0     33     155     other     0     0     0     1     0     2551
0     20     105     white     1     0     0     1     0     2557
0     21     108     white     1     0     1     1     0     2594
0     18     107     white     1     0     1     0     0     2600
0     21     124     other     0     0     0     0     0     2622
0     22     118     white     0     0     0     1     0     2637
0     17     103     other     0     0     0     1     0     2637
0     29     123     white     1     0     0     1     0     2663
0     26     113     white     1     0     0     0     0     2665
0     19     95      other     0     0     0     0     0     2722
0     19     150     other     0     0     0     1     0     2733
0     22     95      other     0     1     0     0     0     2750
0     30     107     other     0     0     1     1     1     2750
0     18     100     white     1     0     0     0     0     2769
0     18     100     white     1     0     0     0     0     2769
0     15     98      black     0     0     0     0     0     2778
0     25     118     white     1     0     0     1     0     2782
0     20     120     other     0     0     1     0     0     2807
0     28     120     white     1     0     0     1     0     2821
0     32     101     other     0     0     0     1     0     2835
0     31     100     white     0     0     1     1     0     2835
0     36     202     white     0     0     0     1     0     2836
0     28     120     other     0     0     0     0     0     2863
0     25     120     other     0     0     1     1     0     2877
0     28     167     white     0     0     0     0     0     2877
0     17     122     white     1     0     0     0     0     2906
0     29     150     white     0     0     0     1     0     2920
0     26     168     black     1     0     0     0     0     2920
0     17     113     black     0     0     0     1     0     2920
0     17     113     black     0     0     0     1     0     2920
0     24     90      white     1     0     0     1     1     2948
0     35     121     black     1     0     0     1     1     2948
0     25     155     white     0     0     0     1     0     2977
0     25     125     black     0     0     0     0     0     2977
0     29     140     white     1     0     0     1     0     2977
0     19     138     white     1     0     0     1     0     2977
0     27     124     white     1     0     0     0     0     2992
0     31     215     white     1     0     0     1     0     3005
0     33     109     white     1     0     0     1     0     3033
0     21     185     black     1     0     0     1     0     3042
0     19     189     white     0     0     0     1     0     3062
0     23     130     black     0     0     0     1     0     3062
0     21     160     white     0     0     0     0     0     3062
0     18     90      white     1     0     1     0     0     3076
0     18     90      white     1     0     1     0     0     3076
0     32     132     white     0     0     0     1     0     3080
0     19     132     other     0     0     0     0     0     3090
0     24     115     white     0     0     0     1     0     3090
0     22     85      other     1     0     0     0     0     3090
0     22     120     white     0     1     0     1     0     3100
0     23     128     other     0     0     0     0     0     3104
0     22     130     white     1     0     0     0     0     3132
0     30     95      white     1     0     0     1     0     3147
0     19     115     other     0     0     0     0     0     3175
0     16     110     other     0     0     0     0     0     3175
0     21     110     other     1     0     1     0     0     3203
0     30     153     other     0     0     0     0     0     3203
0     20     103     other     0     0     0     0     0     3203
0     17     119     other     0     0     0     0     0     3225
0     17     119     other     0     0     0     0     0     3225
0     23     119     other     0     0     0     1     0     3232
0     24     110     other     0     0     0     0     0     3232
0     28     140     white     0     0     0     0     0     3234
0     26     133     other     1     0     0     0     1     3260
0     20     169     other     0     0     1     1     1     3274
0     24     115     other     0     0     0     1     0     3274
0     28     250     other     1     0     0     1     0     3303
0     20     141     white     0     0     1     1     1     3317
0     22     158     black     0     0     0     1     1     3317
0     22     112     white     1     0     0     0     1     3317
0     31     150     other     1     0     0     1     0     3321
0     23     115     other     1     0     0     1     0     3331
0     16     112     black     0     0     0     0     0     3374
0     16     135     white     1     0     0     0     0     3374
0     18     229     black     0     0     0     0     0     3402
0     25     140     white     0     0     0     1     0     3416
0     32     134     white     1     0     0     1     1     3430
0     20     121     black     1     0     0     0     0     3444
0     23     190     white     0     0     0     0     0     3459
0     22     131     white     0     0     0     1     0     3460
0     32     170     white     0     0     0     0     0     3473
0     30     110     other     0     0     0     0     0     3475
0     20     127     other     0     0     0     0     0     3487
0     23     123     other     0     0     0     0     0     3544
0     17     120     other     1     0     0     0     0     3572
0     19     105     other     0     0     0     0     0     3572
0     23     130     white     0     0     0     0     0     3586
0     36     175     white     0     0     0     0     0     3600
0     22     125     white     0     0     0     1     0     3614
0     24     133     white     0     0     0     0     0     3614
0     21     134     other     0     0     0     1     0     3629
0     19     235     white     1     1     0     0     0     3629
0     25     95      white     1     0     1     0     1     3637
0     16     135     white     1     0     0     0     0     3643
0     29     135     white     0     0     0     1     0     3651
0     29     154     white     0     0     0     1     0     3651
0     19     147     white     1     0     0     0     0     3651
0     19     147     white     1     0     0     0     0     3651
0     30     137     white     0     0     0     1     0     3699
0     24     110     white     0     0     0     1     0     3728
0     19     184     white     1     1     0     0     0     3756
0     24     110     other     0     0     0     0     1     3770
0     23     110     white     0     0     0     1     0     3770
0     20     120     other     0     0     0     0     0     3770
0     25     241     black     0     1     0     0     0     3790
0     30     112     white     0     0     0     1     0     3799
0     22     169     white     0     0     0     0     0     3827
0     18     120     white     1     0     0     1     0     3856
0     16     170     black     0     0     0     1     0     3860
0     32     186     white     0     0     0     1     0     3860
0     18     120     other     0     0     0     1     0     3884
0     29     130     white     1     0     0     1     0     3884
0     33     117     white     0     0     1     1     0     3912
0     20     170     white     1     0     0     0     0     3940
0     28     134     other     0     0     0     1     0     3941
0     14     135     white     0     0     0     0     0     3941
0     28     130     other     0     0     0     0     0     3969
0     25     120     white     0     0     0     1     0     3983
0     16     95      other     0     0     0     1     0     3997
0     20     158     white     0     0     0     1     0     3997
0     26     160     other     0     0     0     0     0     4054
0     21     115     white     0     0     0     1     0     4054
0     22     129     white     0     0     0     0     0     4111
0     25     130     white     0     0     0     1     0     4153
0     31     120     white     0     0     0     1     0     4167
0     35     170     white     0     0     0     1     1     4174
0     19     120     white     1     0     0     0     0     4238
0     24     116     white     0     0     0     1     0     4593
0     45     123     white     0     0     0     1     0     4990
1     28     120     other     1     0     1     0     1     709
1     29     130     white     0     0     1     1     0     1021
1     34     187     black     1     1     0     0     0     1135
1     25     105     other     0     1     0     0     1     1330
1     25     85      other     0     0     1     0     0     1474
1     27     150     other     0     0     0     0     0     1588
1     23     97      other     0     0     1     1     0     1588
1     24     124     black     0     0     0     1     1     1701
1     24     132     other     0     1     0     0     0     1729
1     21     165     white     1     1     0     1     0     1790
1     32     105     white     1     0     0     0     0     1818
1     19     91      white     1     0     1     0     1     1885
1     25     115     other     0     0     0     0     0     1893
1     16     130     other     0     0     0     1     0     1899
1     25     92      white     1     0     0     0     0     1928
1     20     150     white     1     0     0     1     0     1928
1     21     200     black     0     0     1     1     0     1928
1     24     155     white     1     0     0     0     1     1936
1     21     103     other     0     0     0     0     0     1970
1     20     125     other     0     0     1     0     0     2055
1     25     89      other     0     0     0     1     1     2055
1     19     102     white     0     0     0     1     0     2082
1     19     112     white     1     0     1     0     0     2084
1     26     117     white     1     0     0     0     1     2084
1     24     138     white     0     0     0     0     0     2100
1     17     130     other     1     0     1     0     1     2125
1     20     120     black     1     0     0     1     0     2126
1     22     130     white     1     0     1     1     1     2187
1     27     130     black     0     0     1     0     0     2187
1     20     80      other     1     0     1     0     0     2211
1     17     110     white     1     0     0     0     0     2225
1     25     105     other     0     0     0     1     1     2240
1     20     109     other     0     0     0     0     0     2240
1     18     148     other     0     0     0     0     0     2282
1     18     110     black     1     0     0     0     1     2296
1     20     121     white     1     0     1     0     1     2296
1     21     100     other     0     0     0     1     1     2301
1     26     96      other     0     0     0     0     0     2325
1     31     102     white     1     0     0     1     1     2353
1     15     110     white     0     0     0     0     0     2353
1     23     187     black     1     0     0     1     0     2367
1     20     122     black     1     0     0     0     0     2381
1     24     105     black     1     0     0     0     0     2381
1     15     115     other     0     0     1     0     0     2381
1     23     120     other     0     0     0     0     0     2395
1     30     142     white     1     0     0     0     1     2410
1     22     130     white     1     0     0     1     0     2410
1     17     120     white     1     0     0     1     0     2414
1     23     110     white     1     0     0     0     1     2424
1     17     120     black     0     0     0     1     0     2438
1     26     154     other     0     1     0     1     1     2442
1     20     105     other     0     0     0     1     0     2450
1     26     190     white     1     0     0     0     0     2466
1     14     101     other     1     0     0     0     1     2466
1     28     95      white     1     0     0     1     0     2466
1     14     100     other     0     0     0     1     0     2495
1     23     94      other     1     0     0     0     0     2495
1     17     142     black     0     1     0     0     0     2495
1     21     130     white     1     1     0     1     0     2495
;
run;

proc format; value ynfmt . = ' ' 0 = 'No' 1 = 'Yes';
             value low   . = ' ' 0 = '>= 2500 g' 1 = '< 2500g';
             value smoke . = ' ' 0 = 'NonSmoker' 1 = 'Smoker';
             value missint . = ' ' other = [3.];
run;

data one;
	set one;
   label Low = 'Categorized birth weight'
         Age = 'Age of mother'
         Lwt = 'Weight at last menstrual period'
         Race = 'Race (3 categories)'
         Smoke = 'Smoking status during pregnancy'
         Ptl = 'History of premature labor'
         Ht = 'History of hypertension'
         Ui = 'Uterine irritability'
         Ftv = '# of physician visits first trimestor'
         Bwt = 'birth weight (g)';
   format low low. smoke smoke. ht ui ptl ynfmt.;

run;

filename RegMacro URL "http://www.ctspedia.org/wiki/pub/CTSpedia/LinearRegressionSASMacro/RegMacro.sas";
%include RegMacro;


%RegMacro(DSName=one,
			ID=,
			Dir=C:\mysas\,
			Outcome=bwt,
			PredictNum=age lwt,
			PredictClass=smoke race ht ui,
			ClassRef= . black 0 .,
			Format=smoke. . ynfmt. ynfmt.,
			Diagnostic=ResidQuantile, 
			Plot=Multiple, 
			Outdata=Outdataset, 
			Outfile=RegMacroOutput, 
			Demographics=Y);

