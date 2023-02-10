/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
Macro procedure CrossPlots creates a set of plots of all the X's against all the Y's.
If only X's are given, this procedure plots all the combinations of the X variables.  
If only Y's are given, this procedure plots all the combinations of the Y variables.  
If no X's or Y's are given, this procedure plots the combinations of all the numeric variables.  

If a variable has <= MaxLevel values, a boxplot will be created.
If a variable has > MaxLevel values, a scatterplot will be created.

The macro parameters are:

    dataset  = Dataset to use.
    Xs       = X axis variables to be plotted.
    Ys	     = Y axis variables to be plotted.
    MaxLevel = Maximum number of categories to allow Boxplots.
    Replay   = Number of plots per page. (Options: 1 2 4 6 9 16)

Examples:  
*%CrossPlots(dataset,Xs,Ys,MaxLevel,Replay);
%CrossPlots(a,Weight,Cholesterol SystolicBP DiastolicBP,6,9);
%CrossPlots(a,Cholesterol SystolicBP DiastolicBP Weight,,6,9);
%CrossPlots(a,,,6,16);

Special Features:
  You may change the X & Y axis by creating your axis defintion in macro 
variables xaxis and yaxis. Example:

%Let xaxis=C=Black W=2 Major=(W=2) Minor=(W=2) Label=(C=Black H=2) Value=(C=Black H=2);
%Let yaxis=C=Black W=2 Major=(W=2) Minor=(W=2) Label=(C=Black H=2 A=90) Value=(C=Black H=2);

  You may add regression or confidence lines by setting interpol to any valid SAS interpol option:
%Let interpol=R0CLM;

Since the graphics catalog is cumulative, it may be helpful to clear the catalog 
while you are refining your graphs.  You can clear the graphics catalog using 
"Proc Datasets":

Proc Datasets Library=work Memtype=Catalog; Delete _mplot; Run;

*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/replaygraphs.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/GetVarList.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVars.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumber.sas";
%Include inclmmm;
Filename inclmmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckStr.sas";
%Include inclmmm;

%Macro CrossPlots(dataset,Xs,Ys,MaxLevel,Replay);
  %If %CheckCPParam %Then %Do;
    %Let nplt=0;
    %Let onelist=;
    %If %Length(&Ys)=0 %Then %Do; *Only X variables were passed;
	  %Let onelist=&Xs;
	  %Let axis=1; *X;
	%End;
    %If %Length(&Xs)=0 %Then %Do; *Only Y variables were passed;
	  %Let onelist=&Ys;
	  %Let axis=2; *Y;
	%End;
    %If %Length(&Xs)=0 %Then %If %Length(&Ys)=0 %Then %Do;
      *No variables were passed.  Use all numeric variables;
      %Getvarlist(&dataset,Num,mlist); 
      %Let onelist=&mlist; 
	  %Let axis=1; *X;
	%End;
    %If %Length(&onelist)=0 %Then %Do; *Two Variable lists (a-list x b-list);
	  %Let var1=%NextWord(Xs);
      %Do %While(%Length(&var1)>0);
        %Let templist=&Ys;
        %Let var2=%NextWord(templist);
        %Do %While(%Length(&var2)>0);
		  %Let nplt=%Eval(&nplt+1);
	      %CrsPlot(&dataset,&var1,&var2,&MaxLevel)
          %Let var2=%NextWord(templist);
        %End;
        %Let var1=%NextWord(Xs);
      %End;
    %End;
	%Else %Do; *Single list (cross within the list);
      %Let var1=%NextWord(onelist);
      %Do %While(%Length(&var1)>0);
        %Let templist=&onelist;
        %Let var2=%NextWord(templist);
        %Do %While(%Length(&var2)>0);
		  %If "&var1"^="&var2" %Then %Do;
		    %Let nplt=%Eval(&nplt+1);
		    %If &axis=1 %Then %Do;
		  	  %CrsPlot(&dataset,&var1,&var2,&MaxLevel)
            %End;
		    %Else %Do;
		  	  %CrsPlot(&dataset,&var2,&var1,&MaxLevel)
            %End;
          %End;
          %Let var2=%NextWord(templist);
        %End;
        %Let var1=%NextWord(onelist);
      %End;
    %End;
	*Replay the graphs, many to a page;
	%Replayall(work._mplot,&replay,&nplt);
  %End;
%Mend CrossPlots;

%Macro CrsPlot(pdata,v1,v2,MaxLevl);
  %Global xaxis yaxis interpol;
  %If %Length(&xaxis)=0 %Then %Do; *Defaut axis;
    Axis1 C=Black W=2 Major=(W=2) Minor=(W=2) Label=(C=Black H=2) Value=(C=Black H=2);
  %End;
  %Else %Do; *User defined axis;
    Axis1 &xaxis;
  %End;
  %If %Length(&yaxis)=0 %Then %Do; *Defaut axis;
    Axis2 C=Black W=2 Major=(W=2) Minor=(W=2) Label=(C=Black H=2 A=90) Value=(C=Black H=2);
  %End;
  %Else %Do; *User defined axis;
    Axis2 &yaxis;
  %End;
  *Find the frequency count of the x variable;
  Ods Listing Select None;
  Ods Output OneWayFreqs(Persist=Proc)=work._mfreq;
  proc freq data=&pdata; table &v1; run;
  Ods Output Clear;
  Ods Listing Select all;
  proc sort data=work._mfreq; by table; run;
  Proc Means Data=work._mfreq n noprint; by table; var &v1; output out=work._mfreq2 n=_n min=_min max=_max; Run;
  *Save the frequency counts in a macro variable;
  Data work._mxn;
    Set work._mfreq2;
    Call Symput("_xlevl",_n);
    Call Symput("_xmin",_min-1);
    Call Symput("_xmax",_max+1);
  Run;
  %If &_xlevl>&MaxLevl %Then %Do; *Scatterplot;
    %If %Length(&interpol)=0 %Then %Let interpol=None; *Defaut axis;
    Symbol1 V=Plus I=&interpol L=1 W=2 Bwidth=2 C=Black;
    Proc Gplot Data=&pdata Gout=work._mplot;
      Plot &v2*&v1 / Frame Haxis=Axis1 Vaxis=Axis2 Nolegend;
    Run;
  %End;
  %Else %Do; *Boxplot;
    Symbol1 V=Plus I=Box L=1 W=2 Bwidth=2 C=Black;
	*Add an order to the axis;
    %If %Length(&xaxis)=0 %Then %Do; *Defaut axis;
      Axis1 C=Black W=2 Major=(W=2) Minor=(W=2) Label=(C=Black H=2) Value=(C=Black H=2) order=&_xmin to &_xmax by 1;
    %End;
    %Else %Do; *User defined axis;
      Axis1 &xaxis order=&_xmin to &_xmax by 1;
    %End;
    Proc Gplot Data=&pdata Gout=work._mplot;
      Plot &v2*&v1 / Frame Haxis=Axis1 Vaxis=Axis2 Nolegend;
    Run;
  %End;
  Proc Datasets Library=work; Delete _mfreq _mfreq2 _mxn; Run;
%Mend CrsPlot;

%Macro CheckCPParam;
  %Let ok=1;
  %If %CheckData(&dataset,Y) %Then %Do;
    %If %CheckNumVars(&dataset,&Xs &Ys,Y)=0 %Then %Let ok=0;
  %End;
  %Else %Let ok=0;
  %If %CheckNumber(&MaxLevel,N)=0 %Then %Do; 
    %Let ok=0; 
    %Put ERROR: MaxLevel must be a number.; 
  %End;
  %If %CheckStr(&replay,1 2 4 6 9 16,REPLAY,Y)=0 %Then %Do; 
    %Let ok=0; 
  %End;
  &ok
%Mend CheckCPParam;

