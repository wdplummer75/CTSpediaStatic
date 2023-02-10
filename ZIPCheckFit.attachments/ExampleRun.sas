
libname save '\\Bio3\ctsiberd\BERDmacros\Xia\ZIPCheckFit\Version1';

*SAS for ZIPCheckFit using a sample Data;
data ZIPCheckFit;
	set save.ZIPCheckFit;
run;


filename ZIPCheck URL "http://www.ctspedia.org/wiki/pub/CTSpedia/ZIPCheckFit/ZIPCheckFit.sas";
%include ZIPCheck;

%ZIPCheckFit(DSname=ZIPCheckFit,
			 DepVar=Count,
			 ClassVar=Treatment Cat_ConVar1  Cat_ConVar2  Cat_ConVar3  Cat_ConVar4
					   ConVar5,
             IndepVar= Con_ConVar Cat_ConVar1  Cat_ConVar2  Cat_ConVar3  Cat_ConVar4
					   ConVar5 Treatment, 
             ZeroInflatVar=Con_ConVar Cat_ConVar1  Cat_ConVar2  Cat_ConVar3  Cat_ConVar4
					   ConVar5 Treatment, 
             format=html 
             );	

