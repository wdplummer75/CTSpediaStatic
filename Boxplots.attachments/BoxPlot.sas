/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
BoxPlot Macro Library              Version 1.0  August 24, 2010
  This set of Macros creates side-by-side boxplots by grouping variables with 
similar ranges onto the same graph.  This is a quick way to check the distribution 
of several variables.  This procedure can also be used after calling the Deltas 
macro, to check the distribution  of changes from baseline.

Syntax:
%Boxplot(dataset,group,varlist,maxperplot,tolerance,catalog);
  dataset:    Dataset to use.
  group:      Optional grouping variable.
  varlist:    List of variables to Boxplot.
  maxperplot: Maximum number of variables on a graph.
  tolerance:  Tolerance Pecentage(T)(0-100) (70 is a good start.)
              If the range of B is within T% of A, then put on the same graph.
  catalog:    Graphics catalog to use.

Optional global macro variables that may be used:
  colors:        modifies the colors used to make the graph:
                 %Let colors=background foreground group1color group2color group3color...        
  font:	         font for all text.	(i.e. %Let font=simplex;)
  height:        height for all text. (i.e. %Let height=2;)
  symbols:       symbols for points outside 1.5*IQR.
                 %Let symbols=circle diamond triangle;        
  legendoptions: options to modify the legend if a group is supplied.
  ylabel:        label for the Y axis.

Since the graphics catalog is cumulative, it may be helpful to clear the catalog 
while you are refining your graphs.  You can clear the graphics catalog using 
"Proc Datasets":

Proc Datasets Library=work Memtype=Catalog; Delete catalog; Run;

{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVar.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVars.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumber.sas";
%Include inclmmm;

%Macro Boxplot(dataset,group,varlist,maxperplot,tolerance,catalog);
  %Put ;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %Put Executing the University of Rochester, Biostatistics Macro: Boxplot.;
  %Put    Released in January 2010;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %If %CheckBPParam %Then %Do;
	%If %Length(&group)>0 %Then %Do; *Jitter by group;
      %CountGroups(&dataset,&group); *Creates global macro NGroups;
      %Let jitter=&group*(0.5/&ngroups)-(0.5/&ngroups)*&ngroups/1.5;
      %Let Legend=Legend=Legend1;
      %Let gp==&group;
    %End; %Else %Do; *No group to jitter by;
      %Let Jitter=0;
      %Let Legend=Nolegend;
      %Let group=;
      %Let gp=;
	%End;
    %FindTitles;
    *Find the Maximum of each variable in the Var List;
    Proc Means Data=&dataset Noprint; Var &varlist; Output Out=work.mA Max=&varlist; Run;
    *Transpose captures the variable Name, variable Label and the Maximum value;
    Proc Transpose Data=work.mA Out=work.mB Prefix=mmax; By _type_; Var &varlist; Run;
    *Sort by the Maximums so we can group the scales appropriatly;
    Proc Sort; By _type_ mmax1; Run;

    /*Assign consecutive numbers to the sorted scales, skipping one number between
    grouped scales, so as not to squish a box against the vertical axis.
      This Datastep creates the following Macro Variables:
        Scale1-n: The assigned Scale numbers(To be formated with the variable labels.)
        Var1-n:   The variable names to be plotted.
        Label1-n: The labels, for the format statement.
        Start1-x: The starting range points for the X axis.
        Stop1-x:  The ending range points for the X axis.                         */
    Data work.mC;
      Retain range 0 scale 0 begin 0 prev 999;
      Set work.mB;
	  By _type_ mmax1;
	  scale=scale+1;
	  If scale-begin>&maxperplot Or prev<mmax1*(&tolerance)/100.0 Then Do;
	    *Start next group. Skip one number and save the range;
        Call Symput(Compress('scale'||scale),scale);
        Call Symput(Compress('var'||scale),'.');
        Call Symput(Compress('label'||scale),' ');
	    range=range+1;
        Call Symput(Compress('start'||range),begin);
        Call Symput(Compress('stop'||range),scale);
	    begin=scale;
	    scale=scale+1;
	  End;
      Call Symput(Compress('scale'||scale),scale);
	  Call Symput(Compress('var'||scale),_name_);
	  Call Symput(Compress('label'||scale),Quote(Trim(_label_)));
	  If last._type_ Then Do;
        *Save the final range;
	    range=range+1;
	    scale=scale+1;
        Call Symput(Compress('start'||range),begin);
        Call Symput(Compress('stop'||range),scale);
        Call Symput('ranges',range);
        *Set flags to stop loops;
        Call Symput(Compress('start'||range+1),'STOP');
        Call Symput(Compress('stop'||range+1),'STOP');
        Call Symput(Compress('scale'||scale),'STOP');
	    Call Symput(Compress('var'||scale),'STOP');
	  End;
      prev=mmax1;
    Run;

    *Transpose the data and assign the scale number;
    Data work.mD;
      Set &dataset;
	  %Flipdata;
      Keep _scale _result &group;
    Run;
    Proc Sort Data=work.mD; By _scale; Run;
    *Create the Format for the Scales;
    %FormatValues;

    *Jitter the boxplots by group;
    Data work.mE;
      Set work.mD;
	  _scale=_scale+&jitter;
	Run;
    Proc Sort Data=work.mE; By _scale; Run;

    *Set the plot style;
    %BPSetGoptions;

	%Global ylabel;
    %If %Length(&ylabel)<1 %Then %Let ylabel=Observed;

    *For each defined range, plot the observed values;
    %Let x=1;
    %Do %While ("&&&start&x" NE "STOP");
      Axis2 Color=&TextColor Width=2 Major=(Width=2) Minor=(Width=2) Label=none
        Value=(C=&TextColor Font=&Font Height=%Sysevalf(&Height/1.33333)) Order=&&&start&x To &&&stop&x By 1;
      Proc Gplot Data=work.mE Gout=&catalog;
        Where (&&&start&x<_scale<&&&stop&x);
        Plot _result*_scale &gp / Frame Vaxis=Axis1 Haxis=Axis2 &Legend cframe=&bgColor;
        Label _scale='Scale' _result="&ylabel";
        Format _scale fscale.;
      Run;
      %Let x=%Eval(&x+1);
    %End;

    Proc Datasets Library=work Memtype=data NoDetails NoList;
      Delete mA mB mC mD mE;
    Run;
  %End;
  Proc Printto Log=Log Print=Print; Run;
%Mend Boxplot;

*Default Colors and symbols if not defined;
%Macro BPSetGoptions;
  %Global Colors symbols bgColor fgColor TextColor Font LegendOption Height;
  %If %Length(&Colors)<150 %Then %Let Colors=%Cmpres(&Colors white black black blue green red purple orange magenta lime cyan bilg pink stb);
  %If %Length(&symbols)<150 %Then %Let symbols=&symbols plus star x circle diamond triangle square dot hash + = #;
  %Let bgColor=%NextWord(Colors);
  %Let fgColor=%NextWord(Colors);
  %Let TextColor=&fgColor;
  %If %Length(&Font)<=1 %Then %Let Font=Centx;
  %If %Length(&LegendOption)<=1 %Then %Let LegendOption= ;
  %If %Length(&Height)<1 %Then %Let Height=2.5;
  Goptions Colors=(&bgColor &fgColor &Colors) Display Hby=&Height Fby=&Font Cback=&bgColor 
    Ctext=&fgColor Hpos=256 Vpos=56;
  %Do mi=1 %to &_NumTitles_;
    %If &mi=1 %Then %Do;
      Title1 C=&fgColor F=&Font H=&Height "&_title1";
	%End; %Else %Do;
      Title&mi C=&fgColor F=&Font H=%Sysevalf(&Height/1.2) "&&&_title&mi";
	%End;
  %End;
  Axis1 C=&fgColor W=2 Major=(W=2) Minor=(W=2) Label=(C=&fgColor F=&Font H=&Height A=90) Value=(C=&fgColor F=&Font H=%Sysevalf(&Height/1.33333));
  Legend1 Label=None Value=(C=&fgColor F=&Font H=%Sysevalf(&Height/1.33333) J=L) Cframe=&bgColor 
    Cborder=&fgColor &LegendOption Shape=Line(12);
  %Let n=0;
  %Let boxColor=%NextWord(Colors);
  %Let symb=%NextWord(symbols);
  %Do %While (%Length(&boxColor)>0);
    %Let n=%Eval(&n+1);
    Symbol&n V=&symb I=box L=1 w=2 Bwidth=2 C=&boxColor;
    %Let boxColor=%NextWord(Colors);
    %Let symb=%NextWord(symbols);
  %End;
%Mend BPSetGoptions;

%Macro CheckBPParam;
  %Let ok=1;
  %If %CheckNumber(&maxperplot,Y)=0 %Then %Let ok=0; 
  %If %Eval(&maxperplot)>30 %Then %Do; 
    %Let ok=0; 
    %Put ERROR: MaxPerPlot must be a number in the range 0-30.; 
  %End;
  %If %CheckNumber(&tolerance,Y)=0 %Then %Let ok=0; 
  %If %Eval(&tolerance)>100 %Then %Do; 
    %Let ok=0; 
    %Put ERROR: Tolerance must be a number in the range 0-100.; 
  %End;
  %If %CheckData(&dataset,Y) %Then %Do;
	%If %Length(&group)>0 %Then %Do;
      %If %CheckNumVar(&dataset,&group,Y)=0 %Then %Let ok=0;
    %End;
    %If %CheckNumVars(&dataset,&varlist,Y)=0 %Then %Let ok=0;
  %End;	%Else %Let ok=0;
  &ok
%Mend CheckBPParam;

%Macro Flipdata;
  *Transpose the data and assign the scale number;
  %Let z=1;
  %Do %While ("&&&scale&z" NE "STOP");
    _scale=&z; _result=&&&var&z; If _result>.Z Then Output;
    %Let z=%Eval(&z+1);
  %End;
%Mend Flipdata;

%Macro FormatValues;
  *Create the Format for the Scales.;
  %Let values=0=" ";
  %Let x=1;
  %Do %While ("&&&scale&x" NE "STOP");
    %If "&&&var&x" EQ "." %Then %Let values=&values &x=" ";
      %Else %Do;
	    %Put &&&label&x  %Length(%Trim(&&&label&x)); 
        %If (%Trim(&&&label&x))=" " %Then %Let values=&values &x=%Trim(&&&var&x);
          %Else %Let values=&values &x=%Trim(&&&label&x);
	  %End;
    %Let x=%Eval(&x+1);
  %End;
  %Let values=&values &x=" ";
  Proc Format;
    Value fscale -1="Subjects" &values;
  Run;
%Mend FormatValues;


%Macro FindTitles;
  %Global _title1 _title2 _title3 _title4 _title5 _NumTitles_;
  %Do N=1 %To 5;
    %Let _title&N=;
  %End;
  Options Nodate Nonumber;
  Data work.mAA; a=0; Output; Run;
  Proc Printto New Print='SASTemp.st'; Run;
  Proc Print Data=work.mAA; Run;
  Proc Printto; Run; *Close the output file;
  Options Date Number Pageno=1;
  Filename ina 'SASTemp.st';
  Data work.mAB;
    Infile ina N=1 Missover Delimiter='~' End=eof;
    Length title $ 200;
	nt=0;
	%Do N=1 %to 5;
	  If not(eof) Then Do;
        Input title;
        title=Trim(Substr(title,1,Length(title)));
	    If Length(trim(title))>1 Then Do;
          Call Symput("_title&N",Trim(title));
		  nt=nt+1;
	    End; Else Do Until (eof); Input title; End;
        Call Symput("_NumTitles_",Trim(nt));
	  End;
    %End;
    Output;
  Run;
  Proc Datasets Library=work Memtype=data NoDetails NoList;
    Delete mAA mAB;
  Run;
%Mend FindTitles;

%Macro CountGroups(dataset,group);
  %Global Ngroups;
  %Global GMin;
  %Global Gmax;
  Proc Sort Data=&dataset; By &group; Run;
  Proc Means Data=&dataset Noprint; By &group; Var &group; Output Out=work.mAA N=Ns; Run;
  Proc Means Data=work.mAA Noprint; Var &group; Output Out=work.mAB N=Ngroups Min=GMin Max=GMax; Run;
  Data work.mAC;
    Set work.mAB;
	Call Symput('Ngroups',Ngroups);
    Call Symput('GMin',compress(GMin));
    Call Symput('Gmax',compress(Gmax));
  Run;
  Proc Datasets Library=work Memtype=data NoDetails NoList;
    Delete mAA mAB mAC;
  Run;
%Mend CountGroups;


