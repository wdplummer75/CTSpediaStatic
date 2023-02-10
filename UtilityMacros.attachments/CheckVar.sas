* Macro checkvar checks that needed variables exist in a particular data set.  The macro parameters are:
	CVDSName       = name of SAS data set
	CVVars         = variables to be checked (no shortcut lists).
   Message        = Y/N. If Y, then an error message is displayed in the log.  

   If all variables are present, then the checkvar returns a zero in the global macro variable _Error. 
	If any variable is not present, checkvar writes an error message to the SAS log and returns a one in _Error.
	Only the first non-present variable is detected.;

%macro CheckVar(CVDSName=,CVVars=,Message=);

	%Local K Var;
	%Global _Error;

	%Let Message = %upcase(&Message);
    ods listing close;
	proc contents data = &CVDSName out = _chkvar (keep = name rename = (name = _name_));
   data _chkvar2;
      set _chkvar;
      length _name $ 32;
      _name = upcase(_name_);
   run;
   proc sort data = _chkvar2; by _name;
   %do %while (%length(&CVVars) > 0);
      %Let Var = %upcase(%scan(&CVVars,1,%str( )));
      data _test;
          length _name $ 32;
         _name = Symget('Var');
      run;
      proc sort data = _test; by _name;
      %Let _Error = 0;
      data _null_;
         merge _chkvar2 (in = f1) _test; by _name;
         if f1 = 0 then
            do;
               Call Symput('_Error',1);
					%if &Message = Y %then
						%do;
               		put '   ';
               		put "Error: Variable &Var is not in data set &dsname.";
               		put '   ';
						%end;
            end;
      run;
      %if &_Error = 1 %then %goto ExitCheckVar;
      %let K = %eval(%length(&Var) + 2);
      %if &K <= %length(&CVVars) %then %let CVVars = %substr(&CVVars,&K); %else %let CVVars = ;
   %end;
	%ExitCheckVar:
	proc datasets nolist; delete _chkvar _chkvar2 _test; quit;

%mend CheckVar;
