*
   DSName       = name of a SAS longitudinal dataset
   Timevar      = name of (multiple) time variables.
   OutForm      = if left empty, results are only shown in the output window in the screen
				  if HTML, a html file of the output is generated;

%macro Rochester_UICC_SAS(DSName=,
					Timevar=,
					OutForm=);

filename words URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;	

%let ntimes=%words(&Timevar);

proc iml;  

start UICC(datamat,estimate,standard_error);
	nobs=nrow(datamat);	
	ntimes=&ntimes;
	tth1=0;
	tth2=0;	
	do i=1 to (nobs-1);
		do j=i+1 to nobs;
			do k=1 to (ntimes-1);
				do m=k+1 to ntimes;
					tth1=tth1+0.5*(datamat[i,k]-datamat[j,k])*(datamat[i,m]-datamat[j,m]);
				end;
			end;
			do k=1 to ntimes;
				tth2=tth2+0.5*(datamat[i,k]-datamat[j,k])##2;
			end;
		end;
	end;
	tth1=tth1/(ntimes*(ntimes-1)/2)/(nobs*(nobs-1)/2); 
	tth2=tth2/ntimes/(nobs*(nobs-1)/2);
	tth=tth1||tth2; 

	u1=J(1,nobs,0);
	u2=J(1,nobs,0);
	do i=1 to nobs;
		do k=1 to (ntimes-1);
			do m=k+1 to ntimes;
				u1[i]=u1[i]+(datamat[i,k]-1)*(datamat[i,m]-1);
			end;
		end;
		u1[i]=u1[i]/(ntimes*(ntimes-1)/2);
	end;

	do i=1 to nobs;
		do k=1 to ntimes;
			u2[i]=u2[i]+(datamat[i,k]-1)##2;
		end;
		u2[i]=u2[i]/ntimes;
	end;
	u=u1//u2;

	sigh=0;
	do i=1 to nobs;
		ui=u[,i]-tth`;
		sigh=sigh+ui*ui`;
	end;
	sigh=sigh/(nobs-1);
	gg=(1/tth2)||(-tth1/(tth2##2));
	xsigh=gg*sigh*gg`;
	rouh=tth1/tth2;

	estimate=rouh;
	standard_error=sqrt(xsigh/nobs);
finish;


use &DSName;
read all var{&Timevar} into datamat; 

run UICC(datamat,estimate,standard_error);

%if %upcase(&OutForm)=HTML %then %do; ods html; %end; 
print estimate;	
print standard_error;
%if %upcase(&OutForm)=HTML %then %do; ods html close;  %end;

quit;


%mend Rochester_UICC_SAS;
