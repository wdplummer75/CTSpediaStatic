* macro Quartiles creates quartile versions of continuous variables. The input
  parameters are:

   QDsname = name of data set containing the continuous variables
   QVars   = list of variables to be quartiled.  These variables are known to exist in QDsname.
             The continuous versions in this data set are replaced by the quartile versions.
             Formats are created and assigned that give the range for each quartile.
				 The variables with their reference values are returned in the global macro variable _ClassVar.
             The names alone are returned in the global macro variable _ClassVariables.
             For example, if QVars = Age, Score, then _ClassVar might be Age(ref='18-23')Score(ref='0-15')
             and _ClassVariables would be Age Score.  The reference value is always the lowest quartile.
            
	The only macro called by quartiles is words;

filename words URL "http://ctspedia.org/twiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;

%macro Quartiles(QDsname=,QVars=);

	%local AFormat Fmt0 Fmt1 Fmt2 Fmt3 I Q1 Q2 Q3 ThisVar;
	%global _ClassVar _ClassVariables;

	%do I = 1 %to %words(&QVars);
      %Let ThisVar = %scan(&QVars,&I);
      proc univariate noprint data = &QDsname; var &ThisVar;
         output out = _quart q1 = q1 median = q2 q3 = q3;
      data _null_;
         set _quart;
         call symput('Q1',q1);
         call symput('Q2',q2);
         call symput('Q3',q3);
      run;
      data _null_;
         set _nomiss (obs = 1);
         Call symput('AFormat',VFormat(&ThisVar));
      run;
      data _nomiss;
         set _nomiss;
         _Save = &ThisVar;                            * Save original values;
         if &ThisVar <= &Q1 then _QuartVar = 0;
         if &Q1 < &ThisVar <= &Q2 then _QuartVar = 1;
         if &Q2 < &ThisVar <= &Q3 then _QuartVar = 2;
         if &Q3 < &ThisVar then _QuartVar = 3;
         &Thisvar = _QuartVar;
      run;

      proc sort data = _nomiss; by &ThisVar;
      proc means data = _nomiss noprint; var _Save; by &ThisVar; output out = _minmax min = min max = max;
      data _null_;
         set _minmax;
         Length Fmt $ 30;
         Fmt = compress(put(min,&AFormat)||'-'||put(max,&Aformat),' ');
         if &ThisVar = 0 then call symput('Fmt0',Fmt);
         if &ThisVar = 1 then call symput('Fmt1',Fmt);
         if &ThisVar = 2 then call symput('Fmt2',Fmt);
         if &ThisVar = 3 then call symput('Fmt3',Fmt);
      run;
      proc format; value _fmt&i.fmt 0 = "&Fmt0" 1 = "&Fmt1" 2 = "&Fmt2" 3 = "&Fmt3";
      data _nomiss;
         set _nomiss;
         format &ThisVar _fmt&i.fmt.;
      run;
      %Let _Classvar = &_Classvar &ThisVar(ref="%trim(&Fmt0)");
      %Let _ClassVariables = &_ClassVariables%str( )&ThisVar;
      %Let _Classvar = %cmpres(&_Classvar);
      %Let _ClassVariables = %str( )%cmpres(&_ClassVariables)%str( );
   %end;
	proc datasets nolist; delete _minmax _quart; quit;

%mend Quartiles;
