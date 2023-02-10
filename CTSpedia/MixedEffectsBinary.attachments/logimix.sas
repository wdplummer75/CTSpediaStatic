/********************************************************************
PROGRAM NAME:	logimix.sas
DESCRIPTION:	Macro to condense output from proc nlmixed, for
		binary outcomes.  Calculates a Likelihood Ratio test
		p-value for the random effect variance.
USAGE:		%logimix(dsname,outvar,resubj,preds=,feparms=,reparm=0.1,
		  tech=quanew,qpoints=20,absgconv=1e-5,print=Y,label=Y,
		  out=work._nlmix_);
		dsname	: SAS one- or two-level dataset name.
		outvar	: Binary (0/1) dependent variable.
		resubj	: Random effect variable.  Data must be
			  sorted by this variable.
		preds	: Fixed effect predictors, numeric only
			  (default=intercept only).
		feparms	: List of initial values for fixed effects
			  parameters (in same order as preds),
			  including the intercept.
			  (default=0 for all fixed effects)
		reparm	: Initial value for random effect parameter.
			  (default=0.1)
		tech	: Optimization technique (default=quanew)
		qpoints	: # of quadrature points (default=20)
		absgconv: absolute gradient convergence criterion
			  (default=1e-5)
		print	: Requests that results be printed (default=Y)
		label	: Requests labels for columns (default=Y)
		out	: Directs results to dataset (default=work._nlmix_)
BY:		Jessica Watson
CREATED:	Aug 2000
LAST UPDATED:	Oct 2008

POSSIBLE FUTURE WORK:
	Make final calculations (e.g., exp(upper)) robust against extreme or missing
	values.  The test case without random effects in logimix-test.sas exposes this.

	Make robust against non-convergence.

=====================================================================
UPDATE LOG:
	Sep 2000	Added options for specifying initial values
			for fixed and random effects parameters.
	Jan 2001	Added step to delete observations with missing
			values (NLMIXED can break when given a lot of
			missing data).
	Feb 2001	Corrected likelihood ratio test.
	Oct 2008	Use fixed effects only model to get initial values
				for random effects model (Ross Boylan).
********************************************************************/

%macro logimix(dsname,outvar,resubj,preds=,feparms=,reparm=0.1,
	tech=quanew,qpoints=20,absgconv=1e-5,print=Y,label=Y,
	out=work._nlmix_);
  %if &preds= %then %let numpred=0;
  %else %do;
	data _null_;
	  array predd[*] &preds;
	  call symput('numpred',left(put(hbound(predd),8.)));
	run;
  %end;
  %let parmlist=;
  %do _i_=1 %to &numpred;
	%let parmlist=&parmlist b&_i_;
  %end;
  data _null_;
	length fe_initial fe_rhs $32767;
	%if %length(&feparms)>0 %then %do;
	  array feparms[%eval(&numpred+1)] _temporary_ (&feparms);
	  fe_initial='b0='||left(put(feparms[1],best.));
	%end;
	%else %do;
	  fe_initial='b0=0';
	%end;
	fe_rhs='b0';
	%if &preds ne %then %do;
	  array predd[*] &preds;
	  array parms[*] &parmlist;
	  do i=1 to dim(predd);
		%if %length(&feparms)>0 %then %do;
		  fe_initial=trim(fe_initial)||' '||vname(parms[i])||'='||
			left(put(feparms[i+1],best.));
		%end;
		%else %do;
		  fe_initial=trim(fe_initial)||' '||vname(parms[i])||'=0';
		%end;
		fe_rhs=trim(fe_rhs)||'+'||vname(parms[i])||'*'||vname(predd[i]);
	  end;
	%end;
	call symput('fe_initial',trim(fe_initial));
	call symput('fe_rhs',trim(fe_rhs));
  run;
 *delete observations with missing outcome, subject id, or predictor;
  data _nlmixdata_;
	set &dsname;
	array varrs[*] &outvar &resubj &preds;
	do i=1 to dim(varrs);
	  if varrs[i]=. then delete;
	end;
	keep &outvar &resubj &preds;
	proc sort; by &resubj;
  run;
  ods listing close;
  ods output parameterestimates=_parmestsml_;
  ods output fitstatistics=_lliksml_;
  proc nlmixed data=_nlmixdata_ tech=&tech qpoints=&qpoints absgconv=&absgconv;
	parms &fe_initial;
	eta=&fe_rhs;
	p=1/(1+exp(-eta));
	model &outvar ~ binary(p);
  run;
  ods listing;
  data _parmnu_;
  	parameter = "nu";
	estimate = &reparm;
  data _parmestsml_;
  	set _parmestsml_ _parmnu_;
	run;

ods listing close;
  ods output parameterestimates=_parmest_;
  ods output fitstatistics=_llikbig_;
  proc nlmixed data=_nlmixdata_ tech=&tech qpoints=&qpoints absgconv=&absgconv;
	parms / data=_parmestsml_;
	eta=&fe_rhs+u;
	p=1/(1+exp(-eta));
	model &outvar ~ binary(p);
	random u~Normal(0,exp(nu)) subject=&resubj;
  run;
  ods listing;

  data _llik_;
	merge _llikbig_(rename=(value=llikbig) where=(descr='-2 Log Likelihood'))
	_lliksml_(rename=(value=lliksml) where=(descr='-2 Log Likelihood'));
	parameter="nu";
	lr=lliksml-llikbig;
	if lr>=0 then p_lr=(1-probchi(lr,1))/2;
	drop descr;
  run;
  data _parmest_;
	set _parmest_;
	_order_=_n_;
	proc sort; by parameter;
  run;
  data &out;
	length parameter parm $32;
	merge _parmest_ _llik_; by parameter;
	if parameter="nu" then do;
	  parm="Var-&resubj";
	  Est=exp(estimate);
	  StdErr=.;
	  CI95_Low=exp(estimate-tinv(0.975,df)*standarderror);
	  CI95_Up=exp(estimate+tinv(0.975,df)*standarderror);
	  PValue=p_lr;
	end;
	else do;
	  if parameter='b0' then parm='Intercept';
	  %if &preds ne %then %do;
	    array predd[*] &preds;
	    array parms[*] &parmlist;
	    else do;
		do i=1 to dim(predd) until(parm ne '');
		  if parameter=vname(parms[i]) then parm=vname(predd[i]);
		end;
	    end;
	    drop i &preds &parmlist;
	  %end;
	  est=estimate;
	  stderr=standarderror;
	  OR=exp(estimate);
	  ci95_low=exp(lower);
	  ci95_up=exp(upper);
	  PValue=probt;
	end;
	format est stderr 8.4 or ci95_low ci95_up 9.4 pvalue pvalue6.4;
	label	parm	= 'Parameter'
		est	= 'Estimate'
		stderr	= 'Standard Error'
		or	= 'Odds Ratio'
		ci95_low= '95% CI Lower'
		ci95_up	= '95% CI Upper'
		pvalue	= 'P-value';
	proc sort; by _order_;
  run;
  proc datasets nolist;
	delete _parmest_ _llik_ _llikbig_ _lliksml_ _nlmixdata_ _parmestsml_ _parmnu_;
  quit;
  %if %upcase(&print)=Y %then %do;
	proc print uniform data=&out %if %upcase(&label)=Y %then %str(label);;
	  id parm;
	  var est stderr or ci95_low ci95_up pvalue;
	run;
  %end;
%mend logimix;

