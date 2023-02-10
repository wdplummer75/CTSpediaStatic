
*Returns a list of Numeric(Num) or Character(Char) variables from the dataset;
%Macro Getvarlist(dataset,type,varlist);

filename Checkd URL	"http://www.ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckData.sas";
%include Checkd;

filename CheckS URL "http://www.ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/CheckStr.sas";
%include CheckS;

  %If %Checkdata(&dataset,Y) %Then %Do;
    %If %CheckStr(&type,Num Char,Choice,Y) %Then %Do;
      %Global &varlist;
      Ods Listing Select None;
      Ods Output Variables(Match_all Persist=Proc)=work._mmvars;
      Proc Contents Data=&dataset; Run;
      Ods Output Clear;
      Ods Listing Select All;
      Data work._mmakvars;
        Retain _mn 0;
        Set work._mmvars;
        If type="&type" Then Do;
          _mn=_mn+1;
          Call Symput(Compress('var'||_mn),variable);
			End;
        Call Symput('mmax',Compress(_mn));
      Run;
      %Let mt=&mmax;
      %Let &varlist=;
      %Do _i=1 %To &mmax;
        %Let &varlist=&&&varlist &&&var&_i;
      %End;
      Proc Datasets Library=work Memtype=data NoDetails NoList;
        Delete _mmvars _mmakvars;
      Run;
    %End;
  %End;
%Mend Getvarlist;

