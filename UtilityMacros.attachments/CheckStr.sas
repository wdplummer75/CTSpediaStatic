*====================================================================================;
* Macro function CheckStr checks if a parameter is in the specified list.
  The macro parameters are:
	value       = the value passed.
	choices     = lisit of valid choices.
	param       = Parameter name.
    Message     = Y/N. If Y, then an error message is displayed in the log.  

   If the value is present in the list of choices, then the CheckStr returns the value of one. 
   Otherwise, CheckStr returns the value of zero and writes an error message to the SAS log.

   example:  %If %CheckStr(Y,yes no y n,Choice,Y) %Then %Do ;

%Macro CheckStr(value,choices,param,Message);
  %Let value=%Lowcase(&value);
  %Let choices=%Lowcase(&choices);
  %Let checkstr=0;
  %Let choice=%NextWord(choices);
  %Do %While (%Length(&choice)>0);
    %If "&value"="&choice" %Then %Let checkstr=1;
    %Let choice=%NextWord(choices);
  %End;
  %If &checkstr=0 %Then %Do;
    %If &Message=Y %then %put ERROR: Invalid option for &param in parameter list.;
  %End;
  &checkstr
%Mend checkStr;


%Macro NextWord(string);
  %Let space=%Index(&&&string,%Str( ));
  %Let size=%Length(&&&string);
  %If %Eval(&space)>0 %Then %Do; 
    %Let NextWord=%Substr(&&&string,1,&space); 
    %Let &string=%Substr(&&&string,&space+1,&size-&space); 
  %End; %Else %Do; %Let NextWord=&&&string; %Let &string= ; %End;
  &NextWord
%Mend NextWord;



