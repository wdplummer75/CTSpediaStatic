

************************************************************************
************************************************************************
** Propose: TheMacro FDR computes FDR for controlling type I error    **
**                                                                    **
**The macro parameters are:                                           **
**dsn	  = name of SAS data set                                      **
**group   = name of subset of p-values to be used for FDR             **
**inputs  = names of variables of p-values                            **
**pvalues =	name of p-values for each variables                       **
**alpha   = significant level to be used to calculate FDR             **
**ResultsFormat  = html format of the reults file                     **
**the format can be updated based on user' choice                     **
**How to use: Specify the data set, group, inputs, pvalues, alpha.    **
**when you want to use the whole data, specify group=.                **
************************************************************************
************************************************************************;

%macro fdr(dsn=, group=, inputs=,pvalue=, alpha=); 
options nodate;
ods listing close;
ods html;
	
	title "False Discovery Rate(FDA)using P-values from &dsn";
	%if &group>. %then %do;
		proc sort data = &dsn;
			where group=&group;	
			by &pvalue;			
			title2 "Where group=&group";			
		run; 		

		proc means data=&dsn n;
			where group=&group;
			var &pvalue;
			ods output Summary=_count;
		run;	
		
		data _null_;
			set _count;
			call symput('Nobs',p_N);
		run;
		

		data dsn&dsn;
			set &dsn ;
			alpha = &alpha; 
			cutoff = (_n_ / &Nobs)*alpha; 
			if p < cutoff;
			keep group &inputs  &pvalue cutoff alpha; 
			run; 

			proc print data = dsn&dsn; 
			run;
			quit;
		%end;
		

		%else %do;
		proc sort data = &dsn;				
			by &pvalue;					
		run; 		

		proc means data=&dsn n;			
			var &pvalue;
			ods output Summary=_count;
		run;	
		
		data _null_;
			set _count;
			call symput('Nobs',p_N);
		run;
		
		data dsn&dsn;
			set &dsn ;
			alpha = &alpha; 
			cutoff = (_n_ / &Nobs)*alpha; 
			if p < cutoff;
			keep   &inputs  &pvalue cutoff alpha; 
			run; 

			proc print data = dsn&dsn; 
			run;
			quit;
		%end;
			
ods html close;	
%mend fdr;
