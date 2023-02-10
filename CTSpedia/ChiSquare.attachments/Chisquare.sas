/*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}
Chi-Square Macro Library                 Version 1.0 July, 2011
    This set of Macros Counts the number of events, by treatment group,
and calculates Chi-Square tests between the groups. 

%ChiSquare(groups,events,who,byy,group,dataout);
    groups:  List of subjects(denominator) dataset.
    events:  List of events to be counted/compared.
    who:     Subject id.
    byy:     By list(Adverse event, Labtest...).
    group:   Treatment group.
    dataout: Output dataset.

{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*/

Filename inclmm URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%Include inclmm;
Filename inclmm URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckVariab.sas";
%Include inclmm;
Filename inclmm URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckVariabs.sas";
%Include inclmm;
Filename inclmm URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/CheckNumVars.sas";
%Include inclmm;

%Macro ChiSquare(groups,events,who,byy,group,dataout);
  %Put ;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %Put Executing the University of Rochester, Biostatistics Macro: Chisq.;
  %Put    Released in July 2011;
  %Put {*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*}{*};
  %If %CheckChiParam %Then %Do;
    *Creates: NGroups, GMin, GMax, GrpSiz1-n, GrpLab1-n;
    %Global Ngroups GMin Gmax;
    Proc Sort Data=&groups; By &group; Run;
	*Find group sizes;
    Proc Means Data=&groups Noprint; By &group; Var &group; Output Out=work._mAA N=grpsize; Run;
    *Find number of groups;
    Proc Means Data=work._mAA Noprint; Var &group; Output Out=work._mAB N=_Ngroups Min=_GMin Max=_GMax; Run;
    *Save as Macro Variables;
    Data work._mAC;
      Set work._mAB;
      Call Symput('Ngroups',Compress(_Ngroups));
      Call Symput('GMin',Compress(_GMin));
      Call Symput('Gmax',Compress(_Gmax));
    Run;
    %Do i=&GMin %To &GMax;
      %Global grpsiz&i grplab&i;
    %End;
	*Find group format;
    Data work._mAC;
      Set &groups;
      Call Symput('Gformat',Compress(Vformatn(&group)));
    Run;
	*Save group sizes and formats as Macro Variables;
    Data work._mAB;
      Retain _n &GMin;
      Set work._mAA;
      Call Symput(Compress("grpsiz"||_n),Compress(grpsize));
      Call Symput(Compress("grplab"||_n),Compress(Input(Put(&group,&Gformat..),$30.)));
      _n=_n+1;
    Run;

    *find first(frst) and last(key) by variable;
    %Let _temp=&byy;
    %Let frst=%NextWord(_temp);
    %Let _temp=&byy;
    %Do %While (%Length(&_temp)>0);
      %Let key=%NextWord(_temp);
    %End;
    Proc Sort Data=&events; By &who &group &byy; Run;
	*Keep one event per subject so we count the number of subject experiencing each event;
    Data work._mChisqA;
      Set &events;
      By &who &group &byy;
      If First.&key Then Output;
    Run;
    Proc Sort Data=work._mChisqA; By &byy &group; Run;
    *Count the events;
    Proc Means Noprint Data=work._mChisqA;
      By &byy &group; Var &group;
      Output Out=work._mNs N=_Ns;
    Run;
    *To collect variables that will be printed later;
    Data work.&dataout;
      %Do i=&GMin %To &GMax;
        Retain Events&i Percent&i GrpSiz&i &&&grpsiz&i NPct&i '                        ';
      %End;
      Set work._mNs;
      By &byy;
      *Initialize to zero;
      If First.&key Then Do;
        %Do i=&GMin %To &GMax; 
          Events&i=0; Percent&i=0; 
		  NPct&i=%Fixnpct(Events&i,Percent&i);
        %End;
      End;
      *Find the N & % in each group;
      %Do i=&GMin %To &GMax;
        If &group=&i Then Do; 
          Events&i=_Ns; Percent&i=100.0*_Ns/(GrpSiz&i); 
		  NPct&i=%Fixnpct(Events&i,Percent&i);
        End;
        Format Percent&i comma4.2;
        Label GrpSiz&i="# &&&grplab&i" events&i="&&&grplab&i" Percent&i="% &&&grplab&i" npct&i="&&&grplab&i" ;
      %End;
      If Last.&key Then Do;
        %ChiAll;    *Run the chi-square tests;
        Output;
      End;
	  Drop &group _Ns;
    Run;
    *Proc Datasets Library=work Memtype=data NoDetails NoList;
    *  Delete _mAA _mAB _mAC _mNs _mChisqA;
    *Run;
  %End;
  Proc Printto Log=Log Print=Print; Run;
%Mend ChiSquare;

%Macro ChiAll;
  *All Combinations;
  %Do i=&GMin %To &GMax-1;
    %Do j=&i+1 %To &GMax;
      %Let tn=%Eval(&i*(&GMax-1)+&j);
      *%Test(Aevents,Bevents,Aenrolled,Benrolled,Alabel,Blabel,test_number);
      %ChiTest(Events&i,Events&j,GrpSiz&i,GrpSiz&j,&&&grplab&i,&&&grplab&j,&tn);
      Label p&tn="&&&grplab&i/&&&grplab&j" flag&tn="&&&grplab&i/&&&grplab&j" ;
    %End;
  %End;
%Mend ChiAll;

*%Macro Test(Aevents,Bevents,Aenrolled,Benrolled,Alabel,Blabel,test_number);
%Macro ChiTest(A,B,An,Bn,gA,gB,n); *Continuation Adjusted Chi-square;
  total_p=&An+&Bn;       * Total patients;
  total_r=&A+&B;         * Total reports;
  Ahat=total_r*&An/total_p;
  Bhat=total_r*&Bn/total_p;
  NAhat=(total_p-total_r)*&An/total_p;
  NBhat=(total_p-total_r)*&Bn/total_p;
  snd&n=(max(0,abs(&A-Ahat)-0.5))**2/Ahat
    +(max(0,abs(&B-Bhat)-0.5))**2/Bhat
      +(max(0,abs((&An-&A)-NAhat)-0.5))**2/NAhat
        +(max(0,abs((&Bn-&B)-NBhat)-0.5))**2/NBhat;
  reports=&A; p=&An/total_p; flag&n='        ';
  p&n=1.0-Probchi(snd&n,1);
  If (p&n<=0.05 and p&n>.Z) Then Do;
    If reports>total_r*p Then flag&n="&gA";
    If reports<total_r*p Then flag&n="&gB";
  End;
  Format p&n comma5.3;
  drop _type_ _freq_ total_p total_r Ahat Bhat NAhat NBhat snd&n reports p;
%Mend ChiTest;

%Macro Fixnpct(n,pct);
  %Global digits;
  %If %Index(0123456789,&digits)=0 %Then %Let digits=2;
  right(Input(Put(&n,7.0),$7.))||Compress('('||Input(Put(&pct,10.&digits),$10.)||')');
%Mend Fixnpct;

%Macro CheckChiParam;
  %Let ok=1;
  %If %CheckData(&groups,Y) %Then %Do;
    %If %CheckVariab(&groups,&who,Y)=0 %Then %Let ok=0;
    %If %CheckNumVar(&groups,&group,Y)=0 %Then %Let ok=0;
  %End;	%Else %Let ok=0;
  %If %CheckData(&events,Y) %Then %Do;
    %If %CheckVariab(&events,&who,Y)=0 %Then %Let ok=0;
    %If %CheckNumVar(&events,&group,Y)=0 %Then %Let ok=0;
    %If %CheckVariabs(&events,&byy,Y)=0 %Then %Let ok=0;
  %End;	%Else %Let ok=0;
  &ok
%Mend CheckChiParam; 

  
