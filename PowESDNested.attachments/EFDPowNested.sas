*************************************************************************
** This program computes detectable Effect Size for a pre-specified    ** 
** power or Power for a pre-specified effect size between two          ** 
** treatment conditions for group study within a longitudinal setting, ** 
** assuming equal group size.  	                                       ** 
** Effect size is defined as in Cohen (1988):                          ** 
**              ef = (mu1 - mu2)/ sqrt[(var1 + var2)/2]                ** 
*************************************************************************;


%macro EFDPowNested(alpha=,
			  Power=,
			  EFD=,	
			  Test=,
			  Nrep=, 
			  ICC=,
			  Ngrp1=,
			  group=,
			  CorrCoef=,
			  MissRate=,
			  startp = 0.01);

%if &Power>. %then
%do;
	*************************************************
	** Compute EFD for power analysis              ** 
	*************************************************; 
	data input; 
		alpha=&alpha;    
		Power=&Power;
		Nrep=&Nrep;	
		ICC=&ICC;
		Ngrp1=&Ngrp1;
		group=&group; 
		CorrCoef=&CorrCoef;
		MissRate=&MissRate;
		startp=&startp;    
	run; 

	proc iml; 
		use input; 
		read all into matrix;  
		alpha  = matrix[1]; 	
		powlvl = matrix[2];
		k      = matrix[3];                  * number of repeated measures;
		icc	   = matrix[4]; 					* intraclass correlation;
		ngp1   = matrix[5];                  * sample size for group 1;
		ngp2   = matrix[5];                  * sample size for group 2; 
		if &Test=1 then z = abs(probit(matrix[1]));      * one-sided test;
		if &Test=2 then z = abs(probit(matrix[1]/2));    * two-sided test;
		m      = matrix[6];                 	* group size; 
		rho    = matrix[7];                 	* correlation coefficient;
		d      = matrix[8];                	* d is missing rate over entire study period;  
		startp = matrix[9];                  * change this value if error appears in the log file; 

		** Commencing of MAIN Program **; 
		n1 = (m * ngp1)/(1+ icc * (m-1)); 
		n2 = (m * ngp2)/(1+ icc * (m-1)); 
		nuse1 = (n1 * k * (1-d)##(1/(k-1))) / (1 + rho * (k-1));
		nuse2 = (n2 * k * (1-d)##(1/(k-1))) / (1 + rho * (k-1)); 

		start power(x) global (nuse1,nuse2,z,powlvl);
		   f = probnorm(x* (nuse1/2)##0.5 - z) - powlvl;
		   return(f);
		finish power;

		x = startp;
		error = 1;
		count = 1; 
		do while(error > 0.000001);
		   call NLPFDD(pow,grad,hess,"power",x);
		   if grad = 0 then do; x = startp + count * 0.01; error = 1; count = count + 1; end; 
		   else do; 
		        temp = x - grad##(-1) * pow;
		        error = abs(temp-x);
		        x = temp;
		   end;  
		end;  
		EFD=x;
		print "Minimum detectable EFD: " EFD; 
		create EFDdata from x;
		append from x;
		close  EFDdata;
	quit;
%end;


%if &EFD>. %then
%do; 
	*************************************************
	** Compute EFD for power analysis              ** 
	*************************************************; 
	data input; 
		alpha=&alpha;   
		EFD=&EFD; 
		Nrep=&Nrep;	
		ICC=&ICC;
		Ngrp1=&Ngrp1;
		group=&group;
		CorrCoef=&CorrCoef;
		MissRate=&MissRate;
		startp=&startp;     
	run;  
	proc iml; 
		use input; 
		read all into matrix;  
		alpha  = matrix[1]; 	
		efd    = matrix[2];
		k      = matrix[3];                  * number of repeated measures;
		icc	   = matrix[4]; 					* intraclass correlation;
		n1     = matrix[5];                  * sample size for group 1;
		n2     = matrix[5];                  * sample size for group 2; 
		if &Test=1 then z = abs(probit(matrix[1]));      * one-sided test;
		if &Test=2 then z = abs(probit(matrix[1]/2));    * two-sided test;
		m      = matrix[6];                 	* group size; 
		rho    = matrix[7];                 	* correlation coefficient;
		d      = matrix[8];                	* d is missing rate over entire study period;  
		startp = matrix[9];                  * change this value if error appears in the log file;  

		** Commencing of MAIN Program **; 
		n1 = (m * ngp1)/(1+ icc * (m-1)); 
		n2 = (m * ngp2)/(1+ icc * (m-1)); 
		nuse1 = (n1 * k * (1-d)##(1/(k-1))) / (1 + rho * (k-1));
		nuse2 = (n2 * k * (1-d)##(1/(k-1))) / (1 + rho * (k-1)); 

		power = probnorm(efd * (nuse1/2)##0.5 - z); 
		print "Power: " power;

		create powerdata from power;
		append from power;
		close  powerdata;
	quit;
%end;

%mend EFDPowNested;
