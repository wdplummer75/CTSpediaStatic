
/* Macro LONG2WIDE reshapes the data so that for each measurement
(grouped by the &by variables) there are
separate variables for each specified time point.  See example at bottom
of page with test data and calls to both the long2wide and wide2long macros.

The macro parameters are:
	data		= name of long dataset
	by 			= list of variables that you want to transpose by
					(e.g.,subject)
	timeVar 	= numeric variable designating visit number or time point. 
				  IMPORTANT: the timevar variable must be numeric
	levels		= list of all or specific time points that will
					be transposed
	vars		= list of variables to be tranposed
	out			= name of the wide dataset output by the macro

EXAMPLE:
For example, if you had "long" data that looked like this:
patientid	position		timept 	rotation distance
1					0			1	55.5		5
1					1			1	54.2		10
1					2			1	29.0		7
1					0			2	18.8		9
1					1			2	25			10
1					2			2	60			12


And, you want it to instead have one record per subject and position,
as follows:
patientid 	position	rotation1	rotation2	distance1	distance2
1				0		55.5		18.8		5			9
1				1		54.2		25			10			10
1				2		29.0		60			7			12

you would use this call of the macro:
%long2wide(data=long, by=patientid position,
timeVar=timept, levels=1 2, vars=rotation distance, out=wide); 

*/
filename words URL "http://twiki.library.ucsf.edu/twiki/bin/viewfile/CTSpedia/UtilityMacros?rev=1;filename=words.sas";
%include words;
%macro long2wide(data=_last_, by=, timevar=, levels=,vars=, out=_data_); 
%local i j k l m n;

%Let by = %str( )%upcase(%cmpres(&By))%str( );
%let NByVars= %eval(%words(&by));
%let byVar=%scan(&by,1); 
%let i=1;
proc sql; 
create table &out as select distinct 
/* need to comma-separate all byvars */
%do j=1 %to %eval(&NByVars -1); 
			&byvar, 
			%let i=%eval(&i+1); 
  			%let byvar=%scan(&by,&i);
%end;  

&byvar
	
%let dv=%scan(&timeVar,1); 
%let k=1; 
%let v=%scan(&vars,1); 
%do %while("&v"^=""); 
  %let count=%eval(%words(&levels));
  /* FOR EACH TIME POINT SPECIFIED IN &LEVELS,
  CREATE A NEW VAR CALLED VAR&LEVEL, 
  e.g. rotation at time 1 --> rotation1 */
  %do l=1 %to %eval(&count);
  		%let mo1=%scan(&levels, &l);
      , sum(case when &dv=&mo1 then &v end) as &v._&mo1 
   %end; 
  %let k=%eval(&k+1); 
  %let v=%scan(&vars,&k); 
%end; 
from &data 

/* need to group by on all by variables */
group by 
%let byVar=%scan(&by,1); 
%let m=1;
%do n=1 %to %eval(&NByVars-1); &byvar, 
			%let m=%eval(&m+1); 
  			%let byvar=%scan(&by,&m);
%end;  
&byvar
; 
quit;
%mend long2wide;  

	
/* Macro WIDE2LONG reshapes the wide data to long, 
so that for each subject there are separate records for each time point,
The macro parameters are:
	data		= the name of the wide dataset
	by			= the variables you want to transpose by, e.g, patientID
	suffix		= a list of the variable name suffixes that correspond with
				  each time point, e.g., 1 2 3 4 
	vars		= a list of the variables to be tranposed
	out			= name of the ouput long dataset

Note: the suffixes will become values of a variable called "timept" 
(see example below).

EXAMPLE:
For Example, if your data looks like this:
patientid 	position	rotation1	rotation2
1					0				55.5			18.8
1					1				54.2			25
1					2				29.0			60

And, you want it to instead look like this:
patientid	position		timept 				rotation
1					0				1				55.5
1					1				1				54.2
1					2				1				29.0
1					0				2				18.8
1					1				2				25
1					2				2				60

you would use this call of the wide2long macro:

%wide2long(data=wide, by=patientid position, 
suffix=1 2, vars=rotation, out=Long); 
*/
filename words URL "http://twiki.library.ucsf.edu/twiki/bin/viewfile/CTSpedia/UtilityMacros?rev=1;filename=words.sas";
%include words;
%macro wide2long(data= , by=,  suffix=,vars=, out=);
%local a b c i j k l m n o x y xx yy ii jj;
%let nvars = %eval(%words(&vars));
%let nByVars= %eval(%words(&by));
%Let vars = %str( )%upcase(%cmpres(&vars))%str( );
%let NVars= %eval(%words(&vars)); 
%let Var=%scan(&vars,1); 
%let a=1;
%let count=%eval(%words(&suffix));

%do %while("&var"^="");
	/* for each of variables that you want to turn from wide to long */
	proc sql; create table long&a as select distinct * from (

		%let time=%scan(&suffix,1);
	
		%let j=1; %let l=1;
		/* for each timepoint */
		%do k=1 %to %eval(&count);
			
				/* need to comma-separate all byvars */

				select 
					%let byvar = %scan(&by, 1);
					%let yy=1;
					%do xx=1 %to %eval(&NByVars); 

						&byvar, 

						%let yy=%eval(&yy+1); 
	  					%let byvar=%scan(&by, &yy);
					%end;  
					"&time" as timept, &var.&time as &var from &data
					/* don't union the last select statment */
					%if (%eval(&count) ne %eval(&k)) %then %do;
						union
					%end;
			
				%let l= %eval(&l + 1); /* get next timept; */
				%let time = %scan(&suffix, &l);
		
		%end; 
		)  order by 

	/* need to comma-separate all byvars  */
		%let byvar = %scan(&by, 1);
		%let ii=1;
		%do jj=1 %to %eval(&NByVars); 

				&byvar, 

			 %let ii=%eval(&ii+1); 
		  	 %let byvar=%scan(&by,&ii);
		 %end;  

				timept;

	quit;


/* end of do while ************************************/

		%let a=%eval(&a+1); 
		%let var = %scan(&vars, &a);

%end;

%put %eval(&nvars);
data &out; merge %do b=1 %to %eval(%words(&vars));  long&b %end; ;
by &by;

run;


/* delete the individual datasets from working library */
proc datasets library=work; 
delete %do c=1 %to %eval(%words(&vars));  long&c %end; ; run;quit;
%mend wide2long;




/************* EXAMPLE;
*The following block creates a simulated data set for this example;
data testdata;
	do i=1 to 500;
		do j=1 to 3;
			id = i;
			visit=j;
	  		rotation=round(2.5+5*ranuni(123));
			age=round(20+60*ranuni(123));
	  		bmi=round(22+0.1*age+4*rannor(123),.01);

		output;
		end;

	end;

	drop i j;
run;

%long2wide(data=testdata, by=id, timevar=visit, 
levels=1 2 3,vars=rotation age bmi, out=Wide);


%wide2long(data=WideTest, by=id,  suffix=1 2 3,
vars=rotation_ age_ bmi_, out=Long);
*/
