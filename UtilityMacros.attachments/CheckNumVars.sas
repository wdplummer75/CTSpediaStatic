*====================================================================================;
* Macro function CheckNumVars checks that the variables exist in the specified data set,
  and are numeric.  The macro parameters are:
	dataset       = name of SAS data set
	varlist       = variables to be checked.
    Message       = Y/N. If Y, then an error message is displayed in the log.  

   If the variables are present and numeric, then the CheckNumVars returns the value of one. 
   If any variable is not present or not numeric, CheckNumVars returns the value of zero
     and writes an error message to the SAS log.

   example:  %If %CheckNumVars(work.a,id age,Y) %Then %Do ;

%Macro CheckNumVars(dataset,varlist,Message);
  %Let CheckNumVars=1;
  %Let dsid=%Sysfunc(Open(&dataset,Is));
  %Let var=%NextWord(varlist);
  %Do %While (%Length(&var)>0);
    %Let varnum=%Sysfunc(Varnum(&dsid,&var));
    %If &varnum=0 %Then %Do;
      %Let CheckNumVars=0;
      %If &Message=Y %then %Put ERROR: Variable "&var" not in dataset &dataset;
    %End; %Else %If "%Sysfunc(Vartype(&dsid,&varnum))"^="N" %Then %Do;
      %Let CheckNumVars=0;
      %If &Message=Y %then %Put ERROR: Variable "&var" must be numeric;
    %End;
    %Let var=%NextWord(varlist);
  %End;
  %Let done=%Sysfunc(Close(&dsid));
  &CheckNumVars
%Mend CheckNumVars;


%Macro NextWord(string);
  %Let space=%Index(&&&string,%Str( ));
  %Let size=%Length(&&&string);
  %If %Eval(&space)>0 %Then %Do; 
    %Let NextWord=%Substr(&&&string,1,&space); 
    %Let &string=%Substr(&&&string,&space+1,&size-&space); 
  %End; %Else %Do; %Let NextWord=&&&string; %Let &string= ; %End;
  &NextWord
%Mend NextWord;



