*====================================================================================;
* Macro function CheckData checks that the dataset exists.  The macro parameters are:
	dataset       = name of SAS data set
    Message       = Y/N. If Y, then an error message is displayed in the log.  

   If the dataset exists, then CheckData returns the value of one. 
   If the dataset does not exist, CheckData returns the value of zero and writes 
     an error message to the SAS log.

   example:  %If %Checkdata(work.a,Y) %Then %Do ;

%Macro CheckData(dataset,Message);
  %Let dsid=%Sysfunc(Open(&dataset,Is));
  %If &dsid=0 %Then %Do;
    %Let checkdata=0;
    %If &Message=Y %then %Put ERROR: Dataset &dataset is not available.;
  %End; %Else %Do;
    %Let checkdata=1;
    %Let done=%Sysfunc(Close(&dsid));
  %End;
  &checkdata
%Mend CheckData;

