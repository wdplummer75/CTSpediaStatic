/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
  Macro procedure Deltas creates a dataset with the changes from baseline.  It also
  saves the baseline values in variables _base1-_baseN.  The macro parameters are:

    datain    = Source dataset.
    dataout   =	Output dataset.
    who	      =	Subject id.
    keeps     =	Other variables to keep. ie. Treatment, group...
    visit     =	Visit or time.
    baseline  =	Value of the baseline visit.
    varlist	  =	List of variables to create deltas for.

  example:  

*%Deltas(datain,dataout,who,keeps,visit,baseline,varlist);
%Deltas(work.mydata,work.changes,id,treat,week,0,Cholesterol SystolicBP DiastolicBP Weight);

*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckVariabs.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVars.sas";
%Include inclmm;
Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumber.sas";
%Include inclmm;

%Macro Deltas(datain,dataout,who,keeps,visit,baseline,varlist);
  %Put ;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %Put Executing the University of Rochester, Biostatistics Macro: Deltas.;
  %Put    Released in March 2009;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %If %CheckDltParam %Then %Do;
    Proc Printto Log='junk.log' New; Run;
    *Count the variables in the list;
    %Let Items=%Words(&varlist);
    Proc Sort Data=&datain; By &who &visit; Run;
	*save the labels for later;
	Options Obs=1;
    Data work._temp;
      Set &datain;
      Array _scale &varlist;
	  %Do _i=1 %to &Items;
        Call Symput("_lab&_i","Baseline "||vlabel(_scale{&_i}));
	  %End;
    Run;
	Options Obs=Max;
    *Calculate the changes from baseline.; 
    Data &dataout;
      Retain _base1-_base&Items;
      Array _base{&Items};
      Set &datain;
      By &who;
      Array _scale &varlist;
      If First.&who Then Do _i=1 To Dim(_base); _base{_i}=.; End;
      *Save Baseline Values;
      If &visit<=&baseline Then Do _i=1 To Dim(_base); If _scale{_i}>.Z Then _base{_i}=_scale{_i}; End;
      If &visit>=&baseline Then Do;
        *Changes from baseline;
        Do _i=1 To Dim(_scale); 
          _scale{_i}=_scale{_i}-_base{_i}; 
        End;
		Output;
      End;
	  %Do _i=1 %to &Items;
	    Label _base&_i="&&&_lab&_i";
	  %End;
      Keep &who &keeps &visit &varlist _base1-_base&Items;
    Run;
    Proc Sort Data=&dataout; By &visit; Run;
    Proc Datasets Library=work Memtype=data NoDetails NoList;
      Delete _temp;
    Run;
  %End;
  Proc Printto Log=Log Print=Print; Run;
%Mend Deltas;

%Macro CheckDltParam;
  %Let ok=1;
  %If %CheckData(&datain,Y) %Then %Do;
    %If %CheckVariabs(&datain,&who &keeps,Y)=0 %Then %Let ok=0;
    %If %CheckNumVars(&datain,&visit &varlist,Y)=0 %Then %Let ok=0;
  %End;
  %Else %Let ok=0;
  %If %CheckNumber(&baseline,N)=0 %Then %Do; 
    %Let ok=0; 
    %Put ERROR: BASELINE must be a number.; 
  %End;
  &ok
%Mend CheckDltParam;


