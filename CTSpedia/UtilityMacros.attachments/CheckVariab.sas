*====================================================================================;
* Macro function CheckVariab checks that a variable exists in the specified data set.
  The macro parameters are:
	dataset       = name of SAS data set
	var           = variable to be checked.
    Message       = Y/N. If Y, then an error message is displayed in the log.  

   If the variable is present, then the CheckVariab returns the value of one. 
   If the variable is not present, CheckVariab returns the value of zero and writes
     an error message to the SAS log.

   example:  %If %CheckVariab(work.a,id,Y) %Then %Do ;

%Macro CheckVariab(dataset,var,Message);
  %Let dsid=%Sysfunc(Open(&dataset,Is));
  %If %Sysfunc(Varnum(&dsid,&var))=0 %Then %Do;
    %Let CheckVariab=0;
    %If &Message=Y %then %Put ERROR: Variable "&var" not in dataset &dataset;
  %End; %Else %Do;
    %Let CheckVariab=1;
  %End;
  %Let done=%Sysfunc(Close(&dsid));
  &CheckVariab
%Mend CheckVariab;

