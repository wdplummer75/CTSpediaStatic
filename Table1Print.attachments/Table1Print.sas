* Macro Table1Print is designed to print an output data set created by the table1 macro.
  
  The macro parameters are:

		Dsname = name of data set created by logistic macro
		Space = Y/N.  If Y, then a space is inserted after each variable.  Spaces are always inserted after
				  each model  (Default = Y)
	Revision date: June 20, 2008;

%macro Table1Print(DSname=,Space=Y);

	%Local BadData FoundTotal ;

	%Let Space = %upcase(&Space);
	* Check that data set is the right type;
	proc contents data = &dsname out = _check noprint;			* This output dataset has variable TypeMem;
   data _null_;
      set _check (obs = 1);
		if TypeMem ne 'TABLE1' then
			do;
				put;
				put "Error: Dataset &dsname was not created by the Table1 macro.";
				put;
				call Symput('BadData',1);
			end;
		else
			do;
				NGroups = substr(MemLabel,8,1);
				call symput('NGroups',NGroups);
				K = index(MemLabel,"P=");
				Call symput('P',substr(MemLabel,K+2));
			end;
	run;
	%Let FoundTotal = 0;
	data _null_;
		set _check;
		if Name = 'Total' then call Symput('FoundTotal',1);
	run;

	%if &BadData = 1 %then %goto ExitTable1Print;
	* Look for various types of PValues;
	data _null_;
	   set &dsname end = done;
		if _n_ = 1 then do; HasT = 0; HasMW = 0; HasChisq = 0; HasFisher = 0; end;
		retain HasMW HasChisq HasFisher HasT;
		%if &P = T or &P = TW or &P = WT %then
			%do;
				if index(PValue1,Byte(176)) > 0 or Index(PValue2,Byte(176)) > 0 then HasT = 1;
			%end;
		if index(PValue1,Byte(185)) > 0 then HasMW = 1;
		if index(PValue1,Byte(178)) > 0 then HasChiSq = 1;
		if index(PValue1,Byte(179)) > 0 then HasFisher = 1;
		if done then
			do;
				Length Msg0 Msg1 Msg2 Msg3 $ 40;
				Msg0 = Byte(176)||" based on pooled variances t-test";
				%if &NGroups = 2 %then
					%do;
						Msg1 = Byte(185)||" based on Mann-Whitney test";
					%end;
				%if &NGroups > 2 %then
					%do;
						Msg1 = Byte(185)||" based on Kruskal-Wallis test";
					%end;
				Msg2 = Byte(178)||" based on Chi-square test";
				Msg3 = Byte(179)||" based on Fisher's exact test";
				Call Symput('HasT',HasT);
				call Symput('HasMW',HasMW);
				call Symput('HasChisq',HasChisq);
				call Symput('HasFisher',HasFisher);
				Call Symput('Msg0',Msg0);
				call Symput('Msg1',Msg1);
				call Symput('Msg2',Msg2);
				call Symput('Msg3',Msg3);
			end;
	data _use;
	   set &dsname;
		%if &Space=N %then
			%do;
				if Label = '' then delete;
			%end;
	run;

	ods listing;
	proc print data = _use noobs split = '/' label uniform; var 
	%do i = 1 %to &NGroups;
		GroupVal&i
	%end;
	%if &NGroups > 1 %then
		%do;
			%if &FoundTotal = 1  %then %do; Total %end;
			%if &P ne N %then %do; PValue1 %end;
			%if &P = TW or &P = WT %then %do; PValue2 %end;
		%end;
	;
	id Label;
	%Let NNote = 0;

	%if &HasT = 1 %then
		%do;
			%Let NNote = %eval(&NNote+1);
			FootNote%trim(&NNote) "&Msg0";
		%end;
	%if &HasMW = 1 %then 
		%do;
			%Let NNote = %eval(&NNote + 1);
			FootNote%trim(&NNote) "&Msg1";
		%end;
	%if &HasChisq = 1 %then
		%do;
			%Let NNote = %eval(&NNote+1);
			FootNote%trim(&NNote) "&Msg2";
		%end;
	%if &HasFisher = 1 %then
		%do;
			%Let NNote = %eval(&NNote+1);
			FootNote%trim(&NNote) "&Msg3";
		%end;
	run;
	data _null_;
		Footnote1 " ";
		Footnote2 " ";
		Footnote3 " ";
		Footnote4 " ";
	run;
	
	%ExitTable1Print:
   proc datasets nolist; delete _check _use; quit; 

%mend Table1Print;
