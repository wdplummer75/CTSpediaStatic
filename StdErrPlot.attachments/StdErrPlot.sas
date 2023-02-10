/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
StdErrPlot Macro Library               Version 4.0  September, 2010
  This set of Macros creates Standard Error Plots of the changes 
from baseline by group, for a list of variables.  Visits that have 
<20% of enrolled subjects, are automatically dropped.  Available 
plot styles are BlackWhite, Color or PowerPoint.  

%Macro StdErrPlot(dataset,group,x,start,stop,by,jitter,varlist,catalog);
  dataset:    Dataset to use.
  group:      Optional grouping variable.
  x:          X axis/Time/Week/Month.
  start:      X axis Begining.
  stop:       X axis Ending.
  by:         X axis Step.
  jitter:     Space between standard error bars.
  varlist:    List of variables to plot.
  catalog:    Graphics catalog to use.

Optional global macro variables that may be used:
  colors:        modifies the colors used to make the graph:
                 %Let colors=background foreground group1color group2color group3color...        
  font:	         font for all text.	(i.e. %Let font=simplex;)
  height:        height for all text. (i.e. %Let height=2;)
  symbols:       symbols for points outside 1.5*IQR.
                 %Let symbols=circle diamond triangle;        
  legendoptions: options to modify the legend if a group is supplied.

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

%Macro StdErrPlot(dataset,group,x,start,stop,by,jitter,varlist,catalog);
  %Put ;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %Put Executing the University of Rochester, Biostatistics Macro: StdErrPlot.;
  %Put    Released in September 2010;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %If %CheckSEPParam %Then %Do;
    %FindTitles;
    *Count items in varlist;
    %Let varnum=%NItems(&varlist);
	%If %Length(&group)>0 %Then %Do; *Jitter by group;
      %CountGroups(&dataset,&group); *Creates global macro NGroups;
      %Let Legend=Legend=Legend1;
      %Let gp==&group;
    %End; %Else %Do; *No group to jitter by;
      %Let NGroups=0;
      %Let Jitter=0;
      %Let Legend=Nolegend;
      %Let group=;
      %Let gp=;
	%End;
    *Find the means and standard errors;
    %SEPGetStdErr(&dataset,work.mB,&group,&x,&varlist,&varnum,&jitter,&ngroups);

    %SEPSetGoptions;
    *Plot Each scale by time & group/treatment;
    %Let scale=%NextWord(varlist);
    %Do %While (%Length(&scale)>0);
      Proc Gplot Data=work.mB Gout=work.mplot; 
        Plot &scale*&x &gp / Frame Vaxis=axis1 Haxis=axis2 &Legend cframe=&bgColor; 
      Run;
      %Let scale=%NextWord(varlist);
    %End;

    Proc Datasets Library=work Memtype=data NoDetails NoList;
      Delete mA mB mdevice;
    Run;
  %End;
  Proc Printto Log=Log Print=Print; Run;
%Mend StdErrPlot;

%Macro SEPGetStdErr(datain,dataout,group,x,varlist,varnum,jitter,ngroups);
  *Find the means and standard errors;
  Proc Sort Data=&datain; By &group &x; Run;
  Proc means Data=&datain Noprint;
    By &group &x;
    Var &varlist;
    Output Out=work.mAA Mean=&varlist Stderr=_se1-_se&varnum;
  Run;
  *Add & subtract the standard error from the mean to create the StdErr Bars;
  Data &dataout;
    Set work.mAA;
    By &group &x;
    Array _scale &varlist;
    Array _stder _se1-_se&varnum;
	%If %Length(&group)>0 %Then %Do;
      &x=&x+&group*&jitter-&jitter*&ngroups/2.0;
	%End;
    Do i=1 To Dim(_scale);
      If _stder{i}=. Then _stder{i}=0;
      _scale{i}=_scale{i}+_stder{i};
    End;
    Output;
    Do i=1 To Dim(_scale); _scale{i}=_scale{i}-2.0*_stder{i}; End;
    Output;
  Run;
  Proc Sort Data=&dataout; By &group &x; Run;
  Proc Datasets Library=work Memtype=data NoDetails NoList;
    Delete mAA;
  Run;
%Mend SEPGetStdErr;

*%If %Length(&Colors)<150 %Then %Let Colors=%Cmpres(&Colors white black black);
*%If %Length(&Colors)<150 %Then %Let Colors=%Cmpres(&Colors white black black blue green red purple orange magenta lime cyan bilg pink stb);
*%If %Length(&Colors)<150 %Then %Let Colors=%Cmpres(&Colors stb gold white vlib biyg bippk bilg magenta pink gold blue green red orange);

%Macro SEPSetGoptions;
  %Global Colors bgColor fgColor TextColor Font LegendOption Height;
  %If %Length(&Colors)<150 %Then %Let Colors=%Cmpres(&Colors white black black blue green red purple orange magenta lime cyan bilg pink stb);
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
  Axis1 C=&fgColor W=2 Major=(W=2) Minor=(W=2) Label=(C=&fgColor F=&Font H=&Height A=90) 
    Value=(C=&fgColor F=&Font H=&Height);
  Axis2 C=&fgColor W=2 Major=(W=2) Minor=(W=2) Label=(C=&fgColor F=&Font H=&Height) 
    Value=(C=&fgColor F=&Font H=&Height) Order=&start to &stop by &by;
  Legend1 Label=None Value=(C=&fgColor F=&Font H=%Sysevalf(&Height/1.33333) J=L) Cframe=&bgColor 
    Cborder=&fgColor &LegendOption Shape=Line(12);
  %Do mn=1 %To 12;
    %Let color=%NextWord(Colors);
    Symbol&mn V=None I=Hilotj L=1 w=2 C=&Color;
  %End;
%Mend SEPSetGoptions;

%Macro CheckSEPParam;
  %Let ok=1;
  %If %CheckNumber(&start,Y)=0 %Then %Let ok=0; 
  %If %CheckNumber(&stop,Y)=0 %Then %Let ok=0; 
  %If %CheckNumber(&by,Y)=0 %Then %Let ok=0; 
  %If %CheckNumber(&jitter,Y)=0 %Then %Let ok=0; 
  %If %CheckData(&dataset,Y) %Then %Do;
	%If %Length(&group)>0 %Then %Do;
      %If %CheckNumVar(&dataset,&group,Y)=0 %Then %Let ok=0;
    %End;
    %If %CheckNumVar(&dataset,&x,Y)=0 %Then %Let ok=0;
    %If %CheckNumVars(&dataset,&varlist,Y)=0 %Then %Let ok=0;
  %End;	%Else %Let ok=0;
  &ok
%Mend CheckSEPParam;

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

%Macro NItems(list);
  %Let NItems=0;
  %Let templist=&list;
  %Let nw=%NextWord(templist);
  %Do %While (%Length(&nw)>0);
    %Let NItems=%Eval(1+&NItems);
    %Let nw=%NextWord(templist);
  %End;
  &NItems
%Mend NItems;

