*====================================================================================;
* Macro function CheckNumVar checks that the variable exists in the specified data set,
  and is numeric.  The macro parameters are:
	dataset       = name of SAS data set
	var           = variable to be checked.
    Message       = Y/N. If Y, then an error message is displayed in the log.  

   If the variable is present and numeric, then the CheckNumVar returns the value of one. 
   If the variable is not present, CheckNumVar returns the value of zero and writes
     an error message to the SAS log.

   example:  %If %CheckNumVar(work.a,id,Y) %Then %Do ;

%Macro CheckNumVar(dataset,var,Message);
  %Let CheckNumVar=1;
  %Let dsid=%Sysfunc(Open(&dataset,Is));
  %Let varnum=%Sysfunc(Varnum(&dsid,&var));
  %If &varnum=0 %Then %Do;
    %Let CheckNumVar=0;
    %If &Message=Y %then %Put ERROR: Variable "&var" not in dataset &dataset;
  %End; %Else %If "%Sysfunc(Vartype(&dsid,&varnum))"^="N" %Then %Do;
    %Let CheckNumVar=0;
    %If &Message=Y %then %Put ERROR: Variable "&var" must be numeric;
  %End;
  %Let done=%Sysfunc(Close(&dsid));
  &CheckNumVar
%Mend CheckNumVar;

