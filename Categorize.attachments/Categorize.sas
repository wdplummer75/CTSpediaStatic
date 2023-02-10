/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
Categorize Macro Library              Version 3.0  January 2009

  This set of Macros creates 5 lists of the variables from a dataset;
Dates: List of variables formatted as dates.
Discrete: List of variables with interger <=N unique values*.
Continous: List of variables with >N unique values*.
CharDiscr: List of discrete character variables, with <=N unique values*.
Characters: List of non-discrete character variables, with >N unique values*.
This macro also captures the number of discrete and number of continous.
*N is specified in the parameter list.

Syntax:
%Categorize(dataset=,maxcat=,discrete,continous,dates,CharDiscr,Characters,Ndiscrete,Ncontinous);
  dataset:	  Dataset to use.
  maxcat:	  maximum uniqie values for a discrete variable.
  discrete:	  List of variables with <=N unique values.
  continous:  List of variables with >N unique values.
  dates:	  List of variables formatted as dates.
  CharDiscr:  List of discrete character variables with <=N unique values.
  Characters: List of non-discrete character variables with >N unique values.
  Ndiscrete:  Number of numeric discrete variables.
  Ncontinous: Number of continous variables.

{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

%Macro Categorize(dataset,maxcat,_discrete,_continous,_mdates,_CharDiscr,_Characters,_Ndiscrete,_Ncontinous);

filename Getvar URL	"http://www.ctspedia.org/twiki/pub/CTSpedia/CategorizeEX/Getvarlist.sas";
%include Getvar;

filename NextW URL "http://www.ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/NextWord.sas";
%include NextW;

filename Checkd URL	"http://www.ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%include Checkd;


  %If %Checkdata(&dataset,Y) %Then %Do;
    %Global &_discrete &_continous &_mdates &_Ndiscrete &_Ncontinous &_CharDiscr &_Characters;
    *Get a list of all the numeric variables:;
    %Getvarlist(&dataset,Num,vlist); 
    %Getvarlist(&dataset,Char,clist); 
    %Let ttlist=&clist;
    %Let tlist=&vlist;
    %Let &_CharDiscr=;
    %Let &_Characters=;
    %Let avar=%NextWord(clist);
    %Let clist=&ttlist;
	*Are there any character variables;
	%If (%Length(&avar)>0) %Then %Do;
      Ods Listing Select None;
      Ods Output OneWayFreqs(Persist=Proc)=work._mfreq;
	  *Find the frequency count of the character variables;
      proc freq data=&dataset; table &clist; run;
      Ods Output Clear;
      Ods Listing Select all;
      proc sort data=work._mfreq; by table; run;
      Proc Means Data=work._mfreq n noprint; by table; var frequency; output out=work._mfreq2 n=n; Run;
      *Save the frequency counts in macro variables;
      Data work._mcc;
	    retain _c 0;
		length name $7.;
        Set work._mfreq2;
        _c=_c+1;
		name=compress("mn"||_c);
        Call Symput(name,n);
      Run;
      %Let clist=&ttlist;
      %Let _c=0;
      %Let avar=%NextWord(clist);
      %Do %While(%Length(&avar)>0);
        %Let _c=%eval(&_c+1);
  	    *Is it discrete?;
        %If (%Sysevalf(&&&mn&_c<=&maxcat)) %Then %Let &_CharDiscr=&&&_CharDiscr &avar; 
        %Else %Let &_Characters=&&&_Characters &avar; 
        %Let avar=%NextWord(clist);
      %End;
    %End;
    %Let &_Ndiscrete=0;
    %Let &_Ncontinous=0;
    %Let &_discrete=;
    %Let &_continous=;
    %Let avar=%NextWord(vlist);
    %Let vlist=&tlist;
	*Are there any numeric variables;
	%If (%Length(&avar)>0) %Then %Do;
      Ods Listing Select None;
      Ods Output OneWayFreqs(Persist=Proc)=work._mfreq;
	  *Find the frequency count of the character variables;
      proc freq data=&dataset; table &vlist; run;
      Ods Output Clear;
      Ods Listing Select all;
      proc sort data=work._mfreq; by table; run;
      Proc Means Data=work._mfreq n noprint; by table; var frequency; output out=work._mfreq2 n=n; Run;
      *Save the frequency counts in macro variables;
      Data work._mcc;
	    retain _c 0;
		length name $7.;
        Set work._mfreq2;
        _c=_c+1;
		name=compress("mn"||_c);
        Call Symput(name,n);
      Run;
      %Let vlist=&tlist;
      %Let _c=0;
      %Let avar=%NextWord(vlist);
      %Do %While(%Length(&avar)>0);
        %Let _c=%eval(&_c+1);
  	    *Is it discrete?;
        %If (%Sysevalf(&&&mn&_c<=&maxcat)) %Then %Do;
          %Let &_discrete=&&&_discrete &avar; 
          %Let &_Ndiscrete=%Eval(&&&_Ndiscrete+1);
        %End;
        %Else %Do;
          %Let &_continous=&&&_continous &avar; 
          %Let &_Ncontinous=%Eval(&&&_Ncontinous+1);
        %End;
        %Let avar=%NextWord(vlist);
      %End;
    %End;
	*Check for variables formatted as dates:;
    Options Obs=1;
    %Let vlist=&tlist;
    %Let avar=%NextWord(vlist);
    Data work._mddec;
      Retain _c 0;
      Set &dataset;
	  %Do %While(%Length(&avar)>0);
  	    _tf=Vformat(&avar);
	    If Index(_tf,'DATE')>0 Then Do;
  	      _c=_c+1;
	      Call Symput(Compress("date"||_c),"&avar");
  	    End;
        %Let avar=%NextWord(vlist);
      %End;
      Call Symput("ndates",_c);
    Run;
    Options Obs=Max;
    *Combine dates into a macro string:;
    %Let &_mdates=;
    %Do _i=1 %To &ndates;
      %Let &_mdates=&&&_mdates &&&date&_i;
    %End;
    *Remove temporary datasets;
    Proc Datasets Library=work Memtype=data NoDetails NoList;
      Delete _mfreq _mfreq2 _mcc _mddec;
    Run;
	%Put &_discrete=&&&_discrete;
	%Put &_continous=&&&_continous;
	%Put &_mdates=&&&_mdates;
	%Put &_CharDiscr=&&&_CharDiscr;
	%Put &_Characters=&&&_Characters;
	%Put &_Ndiscrete=&&&_Ndiscrete;
	%Put &_Ncontinous=&&&_Ncontinous;
  %End;
  quit;
%Mend Categorize;

