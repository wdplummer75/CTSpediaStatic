*====================================================================================;
* Macro function CheckVariabs checks that variables exists in the specified data set.
  The macro parameters are:
	dataset       = name of SAS data set
	varlist       = variables to be checked.
    Message       = Y/N. If Y, then an error message is displayed in the log.  

   If the variables are present, then the CheckVariabs returns the value of one. 
   If any variable is not present, CheckVariabs returns the value of zero and writes
     an error message to the SAS log.

   example:  %If %CheckVariabs(work.a,id age gender,Y) %Then %Do ;

%Macro CheckVariabs(dataset,varlist,Message);
  %Let dsid=%Sysfunc(Open(&dataset,Is));
  %Let CheckVariabs=1;
  %Let var=%NextWord(varlist);
  %Do %While (%Length(&var)>0);
    %If %Sysfunc(Varnum(&dsid,&var))=0 %Then %Do;
      %Let CheckVariabs=0;
      %If &Message=Y %then %Put ERROR: Variable "&var" not in dataset &dataset;
    %End;
    %Let var=%NextWord(varlist);
  %End;
  %Let done=%Sysfunc(Close(&dsid));
  &CheckVariabs
%Mend CheckVariabs;

%Macro NextWord(string);
  %Let space=%Index(&&&string,%Str( ));
  %Let size=%Length(&&&string);
  %If %Eval(&space)>0 %Then %Do; 
    %Let NextWord=%Substr(&&&string,1,&space); 
    %Let &string=%Substr(&&&string,&space+1,&size-&space); 
  %End; %Else %Do; %Let NextWord=&&&string; %Let &string= ; %End;
  &NextWord
%Mend NextWord;



