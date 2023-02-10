***********************************************************************
** This program computes detectable Effect Size Difference (EFD) or  ** 
** Power between two groups for a pre-specified power for repeated   ** 
** measures design (e.g. Diggle, Liang and Zeger, 1994), assuming    ** 
** equal sample sizes and unequal standard deviation for two groups  **  
** AND provides effect size difference estimates for real study data **
**                                                                   ** 
** Effect size is defined as in Cohen (1988):                        ** 
**              ef = (mu1 - mu2)/ sqrt[(var1 + var2)/2]              ** 
***********************************************************************;

%macro EFDPowlongitud(alpha=,
			  Power=,
			  EFD=,
			  Nrep=,
			  Ngrp1=,
			  Test=,
			  CorrCoef=,
			  MissRate=,
			  startp = 0.01);

%if &Power>. %then
%do;
	data input; 
		alpha=&alpha;    
		Power=&Power;
		Nrep=&Nrep;
		Ngrp1=&Ngrp1;
		Ngrp2=&Ngrp1;
		CorrCoef=&CorrCoef;
		MissRate1=&MissRate;
		MissRate2=&MissRate;
		startp=&startp;    
	run; 
	proc iml workspace = 30000; 
		use input; 
		read all into m;  
		alpha  = m[1]; 	
		powlvl = m[2];
		k      = m[3];                   * number of repeated measures;
		n1     = m[4];                  * sample size for group 1;
		n2     = m[5];                  * sample size for group 2; 
		if &Test=1 then z = abs(probit(m[1]));      * one-sided test;
		if &Test=2 then z = abs(probit(m[1]/2));     * two-sided test;
		rho    = m[6];                 * correlation coefficient;
		d1     = m[7];                * d is missing rate over entire study period;  
		d2     = m[8];                * d is missing rate over entire study period; 
		startp = m[9];                * change this value if error appears in the log file; 

		** Commencing of MAIN Program **;
		nuse1 = (n1 * k * (1-d1)##(1/(k-1))) / (1 + rho * (k-1));
		nuse2 = (n2 * k * (1-d2)##(1/(k-1))) / (1 + rho * (k-1));
		
		start power(x) global (nuse1,nuse2,z,powlvl);
	   	f = probnorm(x* (nuse1/2)##0.5 - z) - powlvl;
	   	return(f);
		finish power;

		x = startp;
		error = 1; 
		count = 1; 
		do while(error > 0.000001); 
		   call NLPFDD(pow,grad,hess,"power",x); *print x; 
		   if grad = 0 then do; x = startp + count * 0.01; error = 1; count = count + 1; end; 
		   else do; 
		        temp = x - grad##(-1) * pow;
		        error = abs(temp-x);
		        x = temp;
		   end;  
		   *print error; 
		end;   	
		EFD=x;
		print "Effect Size Difference: " EFD;
		create EFDdata from x;
		append from x;
		close  EFDdata;
	quit;
%end;

%if &EFD>. %then
%do;
	data input; 
		alpha=&alpha;   
		EFD=&EFD;
		Nrep=&Nrep;
		Ngrp1=&Ngrp1;
		Ngrp2=&Ngrp1;
		CorrCoef=&CorrCoef;
		MissRate1=&MissRate;
		MissRate2=&MissRate;
		startp=&startp;    
	run; 
	proc iml; 
		use input; 
		read all into m;  
		alpha  = m[1]; 	
		efd    = m[2];
		k      = m[3];                   * number of repeated measures;
		n1     = m[4];                  * sample size for group 1;
		n2     = m[5];                  * sample size for group 2; 
		if &Test=1 then z = abs(probit(m[1]));      * one-sided test;
		if &Test=2 then z = abs(probit(m[1]/2));     * two-sided test;
		rho    = m[6];                 * correlation coefficient;
		d1     = m[7];                * d is missing rate over entire study period;  
		d2     = m[8];                * d is missing rate over entire study period; 
		startp = m[9];                * change this value if error appears in the log file; 

		** Commencing of MAIN Program **;
		nuse1 = (n1 * k * (1-d1)##(1/(k-1))) / (1 + rho * (k-1));
		nuse2 = (n2 * k * (1-d2)##(1/(k-1))) / (1 + rho * (k-1));
		
		power = probnorm(efd * (nuse1/2)##0.5 - z); 
		print "Power: " power;

		create powerdata from power;
		append from power;
		close  powerdata;
	quit;
%end;



%mend EFDPowlongitud;
