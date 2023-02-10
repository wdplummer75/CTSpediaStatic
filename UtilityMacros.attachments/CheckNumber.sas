*====================================================================================;
* Macro function CheckNumber checks that the parameter is a number.  The macro parameters are:
	Text     = number in question.
    Message  = Y/N. If Y, then an error message is displayed in the log.  

   If text is a number, then CheckNumber returns the value of one. 
   If text is not a number, CheckNumber returns the value of zero and writes 
     an error message to the SAS log.

   example:  %If %CheckNumber(24.7,Y) %Then %Do ;

%Macro CheckNumber(text,Message);
  %Let Number=1;
  %Let dot=0;
  %Do _i=1 %To %Length(&text);
    %If %Index(.,%Substr(&text,&_i,1))>0 %Then %Let dot=%Eval(&dot+1);
    %If %Eval(&_i)=1 %Then %If %Index(-0123456789.,%Substr(&text,&_i,1))=0 %Then %Let Number=0;
    %If %Eval(&_i)>1 %Then %If %Index(0123456789.,%Substr(&text,&_i,1))=0 %Then %Let Number=0;
  %End;
  %If %Eval(&dot)>1 %Then Number=0;
  %If &Message=Y %Then %If %Eval(&Number)=0 %Then %Put ERROR: "&text" must be a number.;
  &Number
%Mend CheckNumber;


