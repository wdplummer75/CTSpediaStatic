*====================================================================================;
* Macro procedure RunPrograms executes a list of sas programs.  The macro parameters are:
	Path         = Directory where the programs are saved.
    ProgramList  = List of programs to run.  

  The .log and .lst files corresponding to each SAS program are saved in the same directory as the programs.

  This example will run the programs first.sas, second.sas and third.sas:  

    %RunPrograms(C:/MyProject/SAS,first second third);


Filename inclmm URL "http://ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/NextWord.sas";
%Include inclmm;
*Execute a list of SAS programs;
%Macro RunPrograms(Path,ProgramList);
  %Let Program=%NextWord(ProgramList);
  %Do %While (%Length(&Program)>0);
    %put "Running &Program..sas";
    Proc Printto New Log="&Path/&Program..log" 
      Print="&Path/&Program..lst"; Run;
    %include "&Path/&Program..sas";
    Proc Printto Log=Log Print=Print; Run;
    %Let Program=%NextWord(ProgramList);
  %End;
%Mend RunPrograms;
