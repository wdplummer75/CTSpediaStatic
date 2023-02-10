
/* This macro create the dummy varibles for the class variable using reference specified. 
if no reference is specified, the lowest value of the variable is used as reference level.

The macros called by this macro are %words.sas and %dummy.sas ;*/

filename dum URL "http://twiki.library.ucsf.edu/twiki/bin/viewfile/CTSpedia/UtilityMacros?rev=3;filename=dummy.sas";
%include dum;
%macro DummyVar(DumDsname=,ClassVars=,format=,Outset=,fullrank=);

%Global _dummyvar;

%Let _VarList = %cmpres(&ClassVars);
%Let _NVar = %words(&_VarList);
%Let _TempVar=;
%Let _Tempref=;
%Let _Prefix=;
%do _i=1 %to &_NVar;
	%Let _ThisVar = %qscan(&_VarList,&_i,%str( ));
	%if %index(&_ThisVar,%str(%()) > 0 %then
		%do; * separate the variable name and its reference level. ;
			%Let _K = %index(&_ThisVar,%str(%());    * position (   ;
			%Let _L = %index(&_ThisVar,%str(%)));    * position )   ;
			%Let _TempVar = &_TempVar%substr(&_ThisVar,1,%eval(&_K-1))%str( );
			%Let _Tempref = &_Tempref%substr(&_ThisVar,%eval(&_K+1),%eval(&_L-&_K-1))%str( );
			%Let _Prefix = &_Prefix%str(varname)%str( );
		%end;
	%else
		%do; * add the variable with lowest value as its reference.; 
			%Let _TempVar = &_TempVar%str(&_ThisVar)%str( );
			%Let _Tempref = &_Tempref%str(_FIRST_)%str( );
			%Let _Prefix = &_Prefix%str(varname)%str( );
		%end;
%end;

%dummy(data=&DumDsname,
		out=&Outset,
		var=&_TempVar,
		base=&_Tempref,
		prefix = &_Prefix,
		format =&format,
		name  = VAL, 
		fullrank=&fullrank);
%put &_dummyvar;
%mend DummyVar;
