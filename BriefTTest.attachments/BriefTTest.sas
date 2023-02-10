/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
Macro Procedure BriefTTest shortens the Ttest output down to one line per test:

Outcome     N(A)   Mean(Std)(A)   N(B)   Mean(Std)(B)   t Value   P Value

It selects the Pooled or Satterthwaite P based on the Equality of variance.
(If Equality of variance<0.05 then Satterthwaite, else Pooled)

This macro also creates a dataset with most of the data from proc TTest. 

The macro parameters are:

%Macro BriefTTest(dataset,dataout,class,varlist,digits);

    dataset  = Dataset to use.
    dataout  = Output dataset.
    class	 = Class variable.
    varlist  = List of variables to be used in the analysis.
    digits   = Number of digits to keep after the decimal.

Example:  
%BriefTTest(dataset,dataout,class,varlist,digits)

*/

Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckVariabs.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVars.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumber.sas";
%Include inclmm;

%Macro BriefTTest(dataset,dataout,class,varlist,digits);
  %Put ;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %Put Executing the University of Rochester, Biostatistics Macro: ShortTTest.;
  %Put    Released in December 2009;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %If %CheckTTestParam %Then %Do;
    *Proc Printto Log='junk.log' New; *Run;

    *Save the labels for later;
    Options Obs=1;
    Data work._tmp; Set &dataset; Run;
    Options Obs=Max;
    Proc Transpose Data=work._tmp Out=work.mlabels1; Var &varlist; Run;
    *Save the order of the variables, to be used later;
    Data work.mlabels;
      Retain _order 0;
      Set work.mlabels1;
      _order=_order+1;
    Run;
    Proc Sort Data=work.mlabels; By _name_; Run;
    
    Ods Listing Select None;
    Ods Output Clear;
    Ods Output statistics(Persist=Run)=work.mstat ttests(Persist=Run)=work.mttest Equality(Persist=Run)=work.mEquality;
    Proc Ttest data=&dataset; Class &class; Var &varlist; Run;
    Ods Output Clear;
    Ods Listing Select All;
	Data work.mstatb;
	  Set work.mstat;
	  If Class='Diff (1-2)' Then Delete;
	Run;
    Proc Sort Data=work.mstatb; By variable class; Run;
    Proc Sort Data=work.mttest; By variable Method; Run;
    Proc Sort Data=work.mEquality; By variable; Run;
    Data work.mstat2;
      Retain n1 . n2 . mean1 . mean2 . std1 . std2 . stderr1 . stderr2 .
        lcl1 . lcl2 . ucl1 . ucl2 . min1 . min2 . max1 . max2 .
        meanstd1 '                   ' meanstd2 '                   ' 
        cl1 '                   ' cl2 '                   ' 
        range1 '                   ' range2 '                   ' ; 
      Set work.mstatb; By variable class;
      If First.variable Then Do;
        n1=n; 
        meanstd1=Compress(Input(Put(mean,12.&digits),$12.))||'('||Compress(Input(Put(stddev,12.&digits),$12.))||')';
        cl1=Compress(Input(Put(lowerclmean,12.&digits),$12.))||'-'||Compress(Input(Put(upperclmean,12.&digits),$12.));
        range1=Compress(Input(Put(minimum,best12.&digits),$12.))||'-'||Compress(Input(Put(maximum,best12.&digits),$12.));
        mean1=mean; 
        std1=stddev; 
        stderr1=stderr; 
        lcl1=lowerclmean; 
        ucl1=upperclmean; 
        min1=minimum; 
        max1=maximum; 
		call symput("mvalueA",compress(class));
      End;
      If Last.variable Then Do;
        n2=n; 
        meanstd2=Compress(Input(Put(mean,12.&digits),$12.))||'('||Compress(Input(Put(stddev,12.&digits),$12.))||')';
        cl2=Compress(Input(Put(lowerclmean,12.&digits),$12.))||'-'||Compress(Input(Put(upperclmean,12.&digits),$12.));
        range2=Compress(Input(Put(minimum,best12.&digits),$12.))||'-'||Compress(Input(Put(maximum,best12.&digits),$12.));
        mean2=mean; 
        std2=stddev; 
        stderr2=stderr; 
        lcl2=lowerclmean; 
        ucl2=upperclmean; 
        min2=minimum; 
        max2=maximum; 
        Output;
		call symput("mvalueB",compress(class));
      End;
      Keep variable n1 n2 mean1 mean2 std1 std2 stderr1 stderr2 lcl1 lcl2 ucl1 ucl2 min1 min2 max1 max2 
        meanstd1 meanstd2 cl1 cl2 range1 range2; 
    Run;
    
    Data work.mttest2;
      Retain tvalue1 tvalue2 probt1 probt2; 
      Set work.mttest; By variable Method;
      If First.variable Then Do;
        tvalue1=tvalue;
    	probt1=probt;
      End;
      If Last.variable Then Do;
        tvalue2=tvalue;
    	probt2=probt;
        Output;
      End;
      Keep variable tvalue1 tvalue2 probt1 probt2; 
    Run;
    
    Data &dataout;
      Merge work.mlabels(rename=(_name_=variable) drop=col1) work.mstat2 work.mttest2 work.mequality(keep=variable probf); By variable;
      If 0<=probf<0.05 Then Do; probt=probt2; tvalue=tvalue2; End; Else Do; probt=probt1; tvalue=tvalue1; End;
	  If _label_=' ' Then _Label_=variable;
      Label _label_="Variable" probt="P-Value" probf="Variance Equality P"
        n1="&mvalueA N" n2="&mvalueB N" mean1="&mvalueA Mean" mean2="&mvalueB Mean" std1="&mvalueA Standard Deviation" 
        std2="&mvalueB Standard Deviation" stderr1="&mvalueA Standard Error" stderr2="&mvalueB Standard Error" 
        lcl1="&mvalueA Lower Confidence Limit" lcl2="&mvalueB Lower Confidence Limit" ucl1="&mvalueA Upper Confidence Limit" 
        ucl2="&mvalueB Upper Confidence Limit" min1="&mvalueA Minimum" min2="&mvalueB Minimum" max1="&mvalueA Maximum" 
        max2="&mvalueB Maximum" meanstd1="&mvalueA Mean(Std)" meanstd2="&mvalueB Mean(Std)" cl1="&mvalueA Confidence Limits" 
        cl2="&mvalueB Confidence Limits" range1="&mvalueA Range" range2="&mvalueB Range" tvalue="t Value"
        tvalue1="Pooled t" tvalue2="Satterthwaite t" probt1="Pooled P" probt2="Satterthwaite P"; 
      Format tvalue1 tvalue2 tvalue f7.2 probt1 probt2 probt PVALUE6.4; 
    Run;
    Proc Sort Data=&dataout; By _order; Run;
	Proc print label; id _label_; var n1 meanstd1 n2 meanstd2 tvalue probt; run;
  %End;
  Proc Printto Log=Log Print=Print; Run;
%Mend BriefTTest;

%Macro CheckTTestParam;
  %Let ok=1;
  %If %CheckData(&dataset,Y) %Then %Do;
    %If %CheckVariabs(&dataset,&class,Y)=0 %Then %Let ok=0;
    %If %CheckNumVars(&dataset,&varlist,Y)=0 %Then %Let ok=0;
  %End;
  %Else %Let ok=0;
  %If %CheckNumber(&digits,N)=0 %Then %Do; 
    %Let ok=0; 
    %Put ERROR: DIGITS must be a number.; 
  %End;
  &ok
%Mend CheckTTestParam;

