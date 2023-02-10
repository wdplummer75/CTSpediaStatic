*
   DSName       = name of a SAS longitudinal dataset
   Outcome      = name of outcome variable.  This variable is a count variable  
   PredictNum   = list of numeric predictor variables, these variables are continuous.
   ID			= name of unique id for each subject
   Time		    = variable indicating time of the ourcome and predictor variables to be observed
   OutForm      = if left empty, results are only shown in the output window in the screen
				  if HTML, a html file of the output is generated;

%macro GEEZIP(DSName=,
		Outcome=,
		PredictNum=, 
		ID=,
		Time=,
		OutForm=);


filename words URL "http://www.ctspedia.org/wiki/pub/CTSpedia/UtilityMacros/words.sas";
%include words;	

%let npredictors=%words(&PredictNum);
	
proc iml;  

start gee(iter,theta,sigma,theta0,datamat);
	theta=J(&npredictors+2,1,0);
	sigma=J(&npredictors+2,1,0);
	npar=nrow(theta0);
	if iter>=30 then 
	do;
		print "Algorithm is not convergent";
		theta=theta0;
	end;
	else do;
		beta=theta0[1];
		alpha=theta0[2:npar];

		nobs=nrow(datamat);
		id=datamat[,1];
		time=datamat[,2];
		outcome=datamat[,3];
		covariates=J(nobs,1,1)||datamat[,4:(npar+1)];	
		nsubjs=ncol(unique(id));
		tpts=unique(datamat[,2]);

		rho=1/(1+exp(-beta));
		mu=exp(covariates*alpha);  
		f=rho+1/(1+exp(beta))*exp(-mu);	
		g=mu/(1+exp(beta));	
		v=f-f##2;  	
		w=1/(1+exp(beta))*mu#(1+mu);  
		R=1*(outcome=0);	

		dfdbeta=rho##2*exp(-beta)-exp(beta)/(1+exp(beta))##2*exp(-mu);
		dgdbeta=-mu*exp(beta)/(1+exp(beta))##2; 
		dfdalpha=-1/(1+exp(beta))*repeat(exp(-mu)#mu,1,npar-1)#covariates; 	
		dgdalpha=repeat(mu,1,npar-1)#covariates/(1+exp(beta));

		dfdtheta=dfdbeta||dfdalpha;
		dgdtheta=dgdbeta||dgdalpha;

		J=R[loc(time=min(tpts))]||R[loc(time=max(tpts))]||outcome[loc(time=min(tpts))]||outcome[loc(time=max(tpts))];
		H=f[loc(time=min(tpts))]||f[loc(time=max(tpts))]||g[loc(time=min(tpts))]||g[loc(time=max(tpts))]; 
		S=J-H;
		v1=v[loc(time=min(tpts))]; 
		v2=v[loc(time=max(tpts))]; 
		w1=w[loc(time=min(tpts))]; 
		w2=w[loc(time=max(tpts))]; 
		dfdtheta1=dfdtheta[loc(time=min(tpts)),];  
		dfdtheta2=dfdtheta[loc(time=max(tpts)),]; 
		dgdtheta1=dgdtheta[loc(time=min(tpts)),];  
		dgdtheta2=dgdtheta[loc(time=max(tpts)),];
		
		Q=0;
		weight=0;
		sandwich=0;
		do i=1 to nsubjs;
			*Vi=block(v1[i],v2[i],w1[i],w2[i]); 
			*invVi=inv(Vi);
			invVi=block(1/v1[i],1/v2[i],1/w1[i],1/w2[i]);
			Di=dfdtheta1[i,]//dfdtheta2[i,]//dgdtheta1[i,]//dgdtheta2[i,];
			Si=S[i,]; 
			Qi=Di`*invVi*Si`;
			sandwich=sandwich+Qi*Qi`;
			Q=Q+Qi;
			weight=weight+Di`*invVi*Di;
		end; 
		theta=theta0+inv(weight)*Q;
		sigma=sqrt(vecdiag(inv(weight)*sandwich*inv(weight`)));
	end;
finish;



use &DSName;
read all var{&Time} into time; 
read all var{&ID} into id; 
read all var{&Outcome} into outcome;
read all var{&PredictNum} into covariates;

datamat= id || time || outcome || covariates;


theta=J(&npredictors+2,1,0.8);
theta0=J(&npredictors+2,1,0);
*bound=sqrt((theta`-theta0`)*(theta-theta0));	
bound=max(abs(theta-theta0));	
iter=0;	

do while (bound>0.0001 & iter<30); 
	theta0=theta; 
	run gee(iter,theta,sigma,theta0,datamat); 
	iter=iter+1;
	*bound=sqrt((theta`-theta0`)*(theta-theta0));
	bound=max(abs(theta-theta0));
end; 

%if %upcase(&OutForm)=HTML %then %do; ods html; %end;
*print iter;
print theta;
print sigma;
%if %upcase(&OutForm)=HTML %then %do; ods html close;  %end;

quit;


%mend GEEZIP;
