
*====================================================================================;
* Macro function NextWord returns the first word from a string, and removes 
  the first word from the list.  The macro parameter is:
	string      = a string of words.

   example:  %Let next=%NextWord(string) ;

%Macro NextWord(string);
  %Let space=%Index(&&&string,%Str( ));
  %Let size=%Length(&&&string);
  %If %Eval(&space)>0 %Then %Do; 
    %Let NextWord=%Substr(&&&string,1,&space); 
    %Let &string=%Substr(&&&string,&space+1,&size-&space); 
  %End; %Else %Do; %Let NextWord=&&&string; %Let &string= ; %End;
  &NextWord
%Mend NextWord;



