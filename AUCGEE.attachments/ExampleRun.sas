
*---For using this macro, please download Macro %aucgee and  data set aucgee in your computer---*;
libname save "Desktop";

proc format;
value groupfmt 0= 'Control'
			   1= 'Treatment';
value qnumfmt  1='collection and questionare 1'
			   2='collection and questionare 2'
			   3='collection and questionare 3';

run;


%AUCGEE(DSname=save.aucgee,
                  visit=visit,
                  group=txgroup,
                  Endvisit=3,
                  Ntimepoint=5,
                  times=time,
                  Nvalues=5,
                  values=value,
                  CovCat=ConCat,
                  CovCon= CovCon1 CovCon2,
                  id=id,
                  type= ar(1),
                  title=1. AUC over 3 Visits--Treatment vs  Control,
				  format=html
 );

***********************************************************************************************
*This macro is designed to model the area under the curve (AUC) computed from multiple samples*
*within each individual in a longitudinal data setting and compare the differences between two*
*such AUCs while adjusting for covariates’ effects.                                           *
*                                                                                             *
*The AUCGEE macro first computes the area under the curve (AUC) using the trapezoid formula,  *
*then uses the generalized equations estimating (GEE) approach implemented in SAS PROC GENMOD *
*procedure to model the AUC difference between two treatment groups, adjusting for covariates’*
*effects. The least square means (covariate-adjusted group means) are also obtained from the  *
*GEE model and plotted along with the GEE output. The user can specify the output in a HTML,  *
*RTF or listing format.                                                                       *
*                                                                                             *
*The macro assumes that the data has a longitudinal format with several visits (identified by *
*the rows) and within each visit, the multiple outcomes (identified by the columns) represent *
*the multiple samples such as cortisol levels at different time points collected from the same*
*subject.                                                                                     *
*                                                                                             *
*The macro parameters are as follows:                                                         *
*                                                                                             *
*DSname		=name of SAS data set                                                             *
*DVar       =name of response variable                                                        *
*visit      =name of visit variable                                                           *
*group      =name of treatment groups, which are dichotomized as treatment and control        *
*Endvisit   =name of indicator of end visit point                                             *
*Ntimepoint =number of sample time points                                                     *
*Nvalues    =number of samples                                                                *     
*CovCat     =name of categorical covariates                                                   *
*CovCon     =name of continuous covariates                                                    *
*id         =name of the variable for subject id                                              *
*type       =type of working correlation matrix	                                              *
*format     =output format                                                                    *
*title      =name of title                                                                    *
**********************************************************************************************;
%macro AUCGEE(DSname=, DVar=, visit=, group=, Endvisit=, Ntimepoint=, times=, Nvalues=, values=,
                                    CovCat=,CovCon=,id=, type=,  title=, format=);
options nodate center;
ods listing close;
ods &format;
proc sort data=&DSname;by &visit;run;
data temp;
      set &DSname;
    array &times{&Ntimepoint};
    array &values{&Nvalues};
    auc=0;
      do j = 2 to dim(&times);
        auc=auc+(&times{j}-&times{j-1})*(&values{j}+&values{j-1})/120.0;
    end;
 run;
proc genmod data=temp;
      where &visit le &Endvisit;    
      class &visit &group(descending) &Covcat &id;
      model auc=&visit &group &CovCon &CovCat &visit*&group/dist=normal link=identity type3;
      repeated subject=&id/corrw covb type=&type;
      lsmeans &visit &group &visit*&group/diff;
      ODS output LSmeans=lsm;
      format &group groupfmt.;
      title "&title"; 
      title2 "AUC between treatment and control at &visit &Endvisit";   
run;

Goptions Device=png Colors=(Black red blue) 
         Display Fby=swissb  Cback=White ;
Axis1 Label=(Angle=90 Rotate=0 Font=swissb h=2 "Least Square Mean") value=(Font=swissb h=2);
Axis2 Label=(Font=swissb h=2 ' ') Value=(Font=swissb h=2);

Symbol1 Value=triangle color=blue Interpol=join  Line=1; 
Symbol2 Value=dot color= red Interpol=join  Line=2; 
legend1 frame label=none value=(Font=swissb h=2);

proc gplot data=lsm;
	where  (&group ne " " )and (&visit ne " ");
	plot mean*&visit=&group/Frame Vaxis=axis1 Haxis=axis2 Legend=legend1;	
	format mean f7.2;	
run;
quit; 

ods &format close;
ods listing;
%mend AUCGEE;

/*%AUCGEE(DSname=save.aucgee,
                  visit=visit,
                  group=txgroup,
                  Endvisit=3,
                  Ntimepoint=5,
                  times=time,
                  Nvalues=5,
                  values=value,
                  CovCat=ConCat,
                  CovCon= CovCon1 CovCon2,
                  id=id,
                  type= ar(1),
                  title=1. AUC over 3 Visits--Treatment vs  Control,
				  format=html
 );
