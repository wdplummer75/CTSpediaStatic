* Varlist takes a shortcut list of SAS variables as input and returns the expanded list of variable names.
  Shortcut lists include x1-x15 or age--race.  This macro differs from standard SAS in that the variables in 
  either shortcut list can be a mix of numeric and alpha varibles.
  
  The parameters are:
  VLDsname = name of SAS data set containing the referenced variables
  ShortList = shortcut list

  The expanded list is returned in the global macro variable _LongList;
  
%macro varlist(VLDsname=,ShortList=);
	*options mprint;

	%Local I K LastVar Minus Name NewShortList NNames Root1 Root2 Suff1 Suff2 Temp Var;
	%Global _LongList;
   %Let Minus = -;   
   proc contents noprint data = &VLDsname out = _temp;
   run;
	%Let Longlist = ;
   %if %index(%quote(&ShortList),-) = 0 %then 
      %do;
         %Let LongList = &ShortList;
      %end;
   %else
      %do %while(%length(&ShortList) ne 0);
		   %Let ShortList = &Shortlist%str( );    * add a blank to the end of the list;
         %Let Var = %scan(&ShortList,1);        * get the first variable name;
			* First variable delimited by a blank;
         %if %index(%quote(&ShortList),%str( )) = %eval(%length(&Var) + 1) %then
            %do;
               %Let K = %index(%quote(&ShortList),%str( )); * save location of next blank in K;
               %Let LongList = &LongList%str( )&Var;  * add this var name to longlist;
               %Let NewShortList = %trim(%substr(%quote(&ShortList),%eval(&K+1)));
            %end;
			* First variable delimited by - or --;
         %if %index(%quote(&ShortList),-) = %eval(%length(&Var) + 1) %then
            %do;
               %Let K = %index(%quote(&ShortList),-); * save location of - in K;
               * Deal with a list of the form x--y;
               %if %quote(%substr(%quote(&ShortList),%eval(&K + 1),1)) = %quote(&Minus) %then
                  %do;
                     %Let ShortList = %trim(%substr(%quote(&ShortList),%eval(&K+2)));
                     %Let LastVar = %scan(%quote(&ShortList),1);
							%Let K = %eval(%Length(&LastVar)+1);
							%Let NewShortList = ;
                     %if &K < %length(&ShortList) %then %Let NewShortList = %trim(%substr(%quote(&ShortList),%eval(%length(&LastVar)+1)));
                     proc sort data = _temp; by varnum;  * sort contents file by variable position;
                     data _null_;
                        set _temp;
                        if upcase(name) = "%upcase(&var)" then do; InList = 1; i = 0; end;
                        retain InList i;
                        if InList then
                           do;
                              i = i + 1;
                              call symput('n'||left(i),name);
                           end;
                        if upcase(name) = "%upcase(&Lastvar)" then
                           do;
                              InList = 0;
                              call symput('NNames',i);
                           end;
                     run;
                     %do i = 1 %to &NNames;
                        %Let LongList = &LongList%str( )&&N&i;
                     %end;
                  %end;
               %else
                  %do;
						   * Short cut list of the x1-x10 form;
                     %Let ShortList = %trim(%substr(%quote(&ShortList),%eval(&K+1)));
                     %Let LastVar = %scan(%quote(&ShortList),1);
							%Let K = %eval(%length(&LastVar)+1);
							%Let NewShortList = ;
							%if &K < %length(&ShortList) %then %Let NewShortList = %trim(%substr(%quote(&ShortList),%eval(%length(&LastVar)+1)));
                     %do I = %length(&Var) %to 1 %by -1;
                        %Let K = %substr(&Var,&I,1);
                        %if %index(0123456789,&K) = 0 %then
                           %do;
                              %Let Root1 = %substr(&Var,1,&I);
                              %Let Suff1 = %substr(&Var,%eval(&I+1));
										%Let I = 0;					* to get out of loop;
                           %end;
                     %end;
                     %do I = %Length(&LastVar) %to 1 %by -1;
                        %Let K = %substr(&LastVar,&I,1);
                        %if %index(0123456789,&K) = 0 %Then
                           %do;
                              %Let Root2 = %substr(&LastVar,1,&I);
                              %Let Suff2 = %substr(&LastVar,%eval(&I+1));
										%Let I = 0;
                           %end;
                     %end;
                     %if &Root1 = &Root2 and &Suff1 <= &Suff2 %then
                        %do I = &Suff1 %to &Suff2;
                           %Let Name = &Root1&i;
                           %Let Longlist = &LongList%str( )&Name;
                        %end;
                  %end;
            %end;
        %Let ShortList = &NewShortlist;
      %end;
	%Let _LongList = %trim(&LongList);
	

%mend Varlist;
