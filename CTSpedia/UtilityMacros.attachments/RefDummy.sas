
/*This macro create the dummy varibles for the class variable using reference specified. */
/*if no reference is specified, the highest value of the variable is used as reference level.*/

%macro RefDummy(DumDsname=,Outcome=,ClassVars=,Ref_level=,format=,Outset1=,Outset2=);
filename words URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;	

%Global dummyvar DropList;


ods listing close;
%Let VarList = %cmpres(%upcase(&ClassVars));
%let VarRef= %cmpres(&Ref_level); 
%let VarFmt= %cmpres(&format);
%Let NVar = %words(&VarList);
%Let VarFmat=;
%Let dummyvar=;

%do i=1 %to &NVar; 	
	%Let ThisFmt = %qscan(&VarFmt,&i,%str( ));
	%if &ThisFmt=. %then %do; %end;
	%else %do;
		%Let ThisVar = %qscan(&VarList,&i,%str( ));	
		%Let VarFmat=&VarFmat%str( )&ThisVar%str( )&ThisFmt;
	%end;
%end;


%if %words(&VarFmat)=0 %then %do;
	proc glmmod data=&DumDsname outdesign=dummy noprint;
	    class &ClassVars;
	    model &Outcome = &ClassVars;
	run;
	%end;
%else %do; 
	proc glmmod data=&DumDsname outdesign=dummy noprint;
	    class &ClassVars;
	    model &Outcome = &ClassVars; 
		format &VarFmat;
	run;
%end;


proc contents data=dummy ;
	ods output variables=vname_label;
run;

data dummy1;
	set dummy;
run;

%Let DropList=;
%do i=1 %to &NVar;
	%Let ThisVar = %qscan(&VarList,&i,%str( ));	
	%Let ThisRef = %qscan(&VarRef,&i,%str( )); 
	%Let ThisFmt = %qscan(&VarFmt,&i,%str( ));
	%if &ThisRef =. %then
		%do;
			proc freq data=&DumDsname;
				tables &ThisVar / out=_counts;;
				%if &ThisFmt ne . %then %do;
				format &ThisVar	&ThisFmt;
				%end;
			run;
			data _null_;
				set _counts (obs = 1) nobs = last;
				call symput('NObs',Last);
			run;

			data _null_;
				set  _counts (obs = &NObs);	
				call symput('ThisRef',&ThisVar);
			run;
		%end;

	%if &ThisFmt =. %then %do; %end;
	%else %do;
		data fmtvar;
			set &DumDsname;
			ThisRef=put(&ThisRef,&ThisFmt);
		run;
		data _null_;
			set fmtvar;
			call symput('ThisRef',ThisRef);
		run;
	%end;

	%Let Ref_label = %cmpres(%upcase(&ThisVar)%str( )&ThisRef);

	data _null_;
		set vname_label;
		if upcase(label)=upcase("&Ref_label") then call symput('Ref_name',variable);
	run;

	%Let DropList=&DropList%str( )&Ref_name;

	data dummydrop;
		set dummy;
		keep &DropList;
	run;
	data dummy1;
		set dummy1;
		drop &Ref_name;
	run;

%end; 

proc contents data=dummy1 ;
	ods output variables=vardata;
run;

data _null_;
	set vardata nobs = last;
	call symput('NObs',Last);
run;
%do i=2 %to &NObs-1; 
	data _null_;
		set vardata (obs = &i);
		call symput('var_dum',Variable);
	run; 
	%Let dummyvar=&dummyvar%str( )&var_dum;
%end;
data &Outset1;
	merge &DumDsname dummy1;
	drop Col1;
run;

proc contents data=dummydrop;
	ods output variables=&Outset2;
run;

data &Outset2;
	set &Outset2;
	keep label;
run;

data &Outset2;
	set &Outset2;
	K = index(label," ")-1;	
	variable=upcase(substr(label, 1, K)) ; 
	value1=substr(label, K+1) ;
	drop K;
run;

proc datasets nolist; delete  dummy dummy1 dummydrop fmtvar vardata vname_label ;
	quit;
%mend RefDummy;

