
******************************************************************************************************
* The Adjusted Treatment Effect (Ad_TE) Macro is used to account for levels of support by study      *
* participants’ partners in the intervention group (such support is absent for subjects in the      *
* control condition) when estimating treatment effect in randomized controlled multi-layer           *
* intervention studies, such as levels of parent support for children in psychosocial intervention   *
* studies on children. The level of support by the subject’s partner in the intervention            *
* condition is measured as a categorical variable (4 categories as default).  This macro imputes     *
* such levels of support the subjects in the control condition using multiple imputation and         *
* integrates the levels of support into inferences about treatment effects by weighting the subject  * 
* according to the level of support. The approach is based on the notion of Principal Stratification *
* in causal inference, but addresses a special scenario not widely discussed in the statistical      *
* literature, but common in psychosocial treatment studies, especially in community-based,           *
* multi-layered intervention studies.  The Output Table of this Macro contains results of inference  *
* based on mixed-effects for both the popular intent-to-treat (ITT), which ignores the level of      *
* support, and this PS-based approach, that accounts for the support by the subject’s partner.      *
*                                                                                                    *
* The macro parameters are as follows:                                                               *
*                                                                                                    *
* DSmixed    =name of SAS data set for mixed-effects model                         					 *
* WVar       =name of noncompliance categorical variable (4 categories by default)                   *
* Time       =name of time variable                                                                  *
* Wei1-4     =name of indicator of weight assignment(1 is the smallest weight, 4 is the largest)     * 
* Pred       =name of variables in prediction model                                                  *
* Dvar       =name of response variable in mixed-effects model                                          *
* CovCat     =name of categorical covariates in mixed-effects model                                  *
* CovCon     =name of continuous covariates in mixed-effects model                                   *
* id         =name of the variable for subject id  	                                                 *
* Group      =name of random-effects variables (None means intercepte random effect only)            *
* type       =type of working correlation matrix                                                     *
******************************************************************************************************;


%macro Rochester_AdTE_SAS(DSmixed=, WVar=, Time=, Wei1=, Wei2=, Wei3=, Wei4=, Pred=, DVar=,
			 CovCat=, CovCon=, id=, Group=, type= );

data DSpred;
	set &DSmixed;
	by &id;
	if first.&id;
run;

proc mi data=DSpred seed=111001 nimpute=3 out=outfcs;
class  &WVar;
fcs nbiter=1000 discrim(&WVar=&Pred/details);
var &WVar &Pred;
run;

data outfcs1;
set outfcs;
where _Imputation_=1;
if dose=0 then w1= &Wei1;
if dose=1 then w1= &Wei2;
if dose=2 then w1= &Wei3;
if dose=3 then w1= &Wei4;
keep &id w1;
run;

data outfcs2;
set outfcs;
where _Imputation_=2;
if dose=0 then w2= &Wei1;
if dose=1 then w2= &Wei2;
if dose=2 then w2= &Wei3;
if dose=3 then w2= &Wei4;
keep &id w2;
run;

data outfcs3;
set outfcs;
where _Imputation_=3;
if dose=0 then w3= &Wei1;
if dose=1 then w3= &Wei2;
if dose=2 then w3= &Wei3;
if dose=3 then w3= &Wei4;
keep &id w3;
run;

data imp;
merge &DSmixed(in=a) outfcs1(in=b) outfcs2(in=c) outfcs3(in=d);
by &id;
if a and b and c and d;
run;

ods output SolutionF=out0;
proc mixed data=imp;
class &id &Group &CovCat;
model &DVar = &Time &Group &CovCat &CovCon / solution;
random intercept &group /type=&type sub=&id;
run;

ods output SolutionF=out1;
proc mixed data=imp;
class &id &Group &CovCat;
model &DVar = &Time &Group &CovCat &CovCon / solution;
random intercept &group /type=un sub=&id;
weight w1;
run;

ods output SolutionF=out2;
proc mixed data=imp;
class &id &Group &CovCat;
model &DVar = &Time &Group &CovCat &CovCon / solution;
random intercept &group /type=un sub=&id;
weight w2;
run;

ods output SolutionF=out3;
proc mixed data=imp;
class &id &Group &CovCat;
model &DVar = &Time &Group &CovCat &CovCon / solution;
random intercept &group /type=un sub=&id;
weight w3;
run;

data out0;
set out0;
Count+1;
run;
data out1(rename=(Estimate=Est_1 StdErr=StdErr_1 Probt=Probt_1));
set out1;
Count+1;
drop &CovCat;
run; 
data out2(rename=(Estimate=Est_2 StdErr=StdErr_2 Probt=Probt_2));
set out2;
Count+1;
drop &CovCat;
run; 
data out3(rename=(Estimate=Est_3 StdErr=StdErr_3 Probt=Probt_3));
set out3;
Count+1;
drop &CovCat;
run; 

data all;
merge out0 out1 out2 out3;
by count;
run;

data output_&DVar;
set all;
   A_Estimate = round(mean(of Est_1 Est_2 Est_3), 0.000001);
   U = round((StdErr_1*StdErr_1 + StdErr_2*StdErr_3 + StdErr_3*StdErr_3)/3, 0.000000001);
   B = var(of Est_1 Est_2 Est_3);
   A_StdErr = round(sqrt(U + (1+1/3)*B), 0.000001);	
   A_DF = round(2*(1+3*U/(4*B))*(1+3*U/(4*B)));
   A_tValue = round(sign(A_Estimate)*A_Estimate/A_StdErr, 0.001);
   if A_DF<10000  and A_tValue<=5 then Prob = 1 - probt(A_tValue, A_DF);
   if A_DF>=10000 and A_tValue<=5 then Prob = 1 - probnorm(A_tValue);
   if A_DF ne . and A_tValue > 5 then A_Probt = "<.0001"; 
   if prob > 0.0001 then A_Probt = put(Prob,best6.);
   if prob ne . and prob < 0.0001 then A_Probt = "<.0001";
   keep effect &CovCat Estimate StdErr DF tValue Probt A_Estimate A_StdErr A_DF A_tValue A_Probt;
run;

data ITT_&DVar;
set output_&DVar;
keep Effect Trt Estimate StdErr DF tValue Probt;
run;

data Ad_&DVar;
set output_&DVar;
keep Effect Trt A_Estimate A_StdErr A_DF A_tValue A_Probt;
run;

proc print data=ITT_&DVar;
Title "Estiamtion of Treatment Effect for Mixed-effects Model by ITT Method";
run;

proc print data=Ad_&DVar;
Title "Estiamtion of Causal Effect for Mixed-effects Model by Weighted Adjustment Method";
run;
%mend;




