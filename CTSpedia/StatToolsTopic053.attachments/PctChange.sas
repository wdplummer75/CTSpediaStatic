/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
20%Change Macro Library                     Version 1.0  July 2011
  This set of Macros runs Chi-Square tests on the number of subjects
with a N% change from baseline on a list of variables.  

%PctChange(dataset,who,group,percent,visit,baseline,varlist,dataout);
*%PctPrint(dataset,who,group,percent,visit,baseline,varlist,dataout) / Store;
  dataset:    Dataset to use.
  who:        Subject ID.
  group:      Treatment group.
  percent:    %Change to count.
  visit:      Time variable: visit, week, month...
  baseline:   Baseline visit.
  varlist:    List of variables to Tabulate.
  dataout:    Output dataset.
{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

Filename inclch URL "http://ctspedia.org/wiki/pub/CTSpedia/StatToolsTopic052/Chisquare.sas";
%Include inclch;
Filename inclcn URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumber.sas";
%Include inclcn;
Filename inclcd URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%Include inclcd;
Filename inclcv URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckVariab.sas";
%Include inclcv;
Filename inclcnv URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVar.sas";
%Include inclcnv;
Filename inclcnv URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVars.sas";
%Include inclcnv;

%Macro PctChange(dataset,who,group,percent,visit,baseline,varlist,dataout);
  %Put ;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %Put Executing the University of Rochester, Biostatistics Macro: PctChange.;
  %Put    Released in July 2011;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  Proc Printto Log='junk.log' New;
  %If %CheckPctParam %Then %Do;
    *Count items in varlist;
    %Let varnum=%NItems(&varlist);
    Proc Format;
      Value mchange -1='Decrease' 1='Increase' 2='Any Change';
    Run;
    %FormatVarList(&dataset,&who,&visit,&varlist);
    Proc Sort Data=&dataset; By &who &visit; Run;
    Data work._m1;
      Set &dataset;
      If &visit=&baseline Then Output;
    Run;
    Data work._m2;
      retain _mb1-_mb&varnum;
      Set &dataset;
      By &who;
      Array _mb{&varnum};
      Array _outcms &varlist;
      If first.&who Then Do i=1 To Dim(_mb); _mb{i}=.; End;
      If &visit<=&baseline Then Do i=1 To Dim(_mb); 
        If _outcms{i}>.Z Then _mb{i}=_outcms{i}; 
      End;
      If &visit>&baseline Then do _scale=1 to dim(_mb);
        _change=-1;
        If .Z<(100.0*(_outcms{_scale}-_mb{_scale})/_mb{_scale})<-&percent Then Output;
        _change=1;
        If (100.0*(_outcms{_scale}-_mb{_scale})/_mb{_scale})>&percent Then Output;
        _change=2;
        If Abs(100.0*(_outcms{_scale}-_mb{_scale})/_mb{_scale})>&percent Then Output;
      End;
      Keep id &visit &group _scale _change;
      Format _change mchange. _scale fscale.; *Created in FormatVarList;
      Label _scale='Scale' _change='Change';
    Run;
    %ChiSquare(_m1,_m2,&who,_scale _change,&group,&dataout)
    Proc Datasets Library=work Memtype=data NoDetails NoList;
      Delete _m1 _m2;
    Run;
  %End;
  Proc Printto Log=Log Print=Print; Run;
%Mend PctChange;

%Macro FormatVarList(dataset,who,visit,varlist);
  *Proc Means and Transpose captures the variable Names and Labels from varlist;
  Proc Means Data=&dataset Noprint; Var &varlist; Output Out=work._mA Mean=&varlist; Run;
  Proc Transpose Data=work._mA Out=work._mB Prefix=mean; By _type_; Var &varlist; Run;
  /*Assign consecutive numbers to the scales.
    This Datastep creates the following Macro Variables:
      Scale1-n: The assigned Scale numbers(To be formated with the variable labels.)
      Var1-n: The variables to be tabulated.
      Label1-n: The labels, for the format statement.                        */
  Data work._mC;
    Retain scale 0;
    Set work._mB;
	By _type_;
	scale=scale+1;
    Call Symput(Compress('scale'||scale),scale);
	Call Symput(Compress('var'||scale),_name_);
 	Call Symput(Compress('label'||scale),Trim(_label_));
	If last._type_ Then Do;
      *Set flag to stop loops;
      Call Symput(Compress('scale'||scale+1),'STOP');
	  Call Symput(Compress('var'||scale+1),'STOP');
	End;
  Run;
  *Create the Format for the Scales;
  %FormatPctValues;
  Proc Datasets Library=work Memtype=data NoDetails NoList;
    Delete _mA _mB _mC;
  Run;
%Mend FormatVarList;

%Macro FormatPctValues;
  *Create the Format for the Scales.;
  %Let values=0=" ";
  %Let x=1;
  %Do %While ("&&&scale&x" NE "STOP");
    %If "&&&var&x" EQ "." %Then %Let values=&values &x=" ";
      %Else %Let values=&values &x="&&&label&x";
    %Let x=%Eval(&x+1);
  %End;
  %Let values=&values &x=" ";
  Proc Format;
    Value fscale -1="Subjects" &values;
  Run;
%Mend FormatPctValues;

%Macro CheckPctParam;
  %Let ok=1;
  %If %CheckNumber(&baseline,Y)=0 %Then ok=0;
  %If %CheckNumber(&percent,Y)=0 %Then ok=0;
  %If %CheckData(&dataset,Y) %Then %Do;
    %If %CheckVariab(&dataset,&who,Y)=0 %Then %Let ok=0;
    %If %CheckNumVars(&dataset,&group &visit &varlist,Y)=0 %Then %Let ok=0;
  %End;	%Else %Let ok=0;
  &ok
%Mend CheckPctParam;

