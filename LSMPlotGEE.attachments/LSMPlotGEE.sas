 
********************************************************************************************
*LSMPlotGEE macro computes  and plots the least squares means from SAS PROC GENMOD based on*
*the Generalized Estimating Equations (GEE) to compare two treatment group means adjusted  *
*for covariates in the model over time.The user can choose one of the available working    *
*correlation matrices in PROC GENMOD. The response variable can be continuous, binary, but *
*not ordinal since least squares means are not available in SAS  version (9.2)for for      *
*ordinal outcomes. The data set needs to follow a longitudinal format as required by PROC  *
*GENMOD.                                                                                   *
*The macro parameters are as follows:                                                      *
*                                                                                          *
*DSname		=name of SAS data set                                                          *
*DVar       =name of response variable                                                     *
*time       =name of time variable                                                         *
*group      =name of treatment groups, which are dichotomized as treatment and control     *
*Endtime    =name of indicator of end time point                                           *
*CovCat     =name of categorical covariates                                                *
*CovCon     =name of continuous covariates                                                 *
*id         =name of the variable for subject id                                           *
*type       =type of working correlation matrix	                                           *
*format     =name of output format                                                         *
*title      =name of title                                                                 *
********************************************************************************************;

%macro LSMPlotGEE(DSname=, DVar=, time=, group=, Endtime=, 
						CovCat=,CovCon=,id=, dist=, type=, format=, title=);

options nodate center;

ods listing close;
ods &format;
proc sort data=&DSname;by &time;run;

proc genmod data=&DSname;
	where &time lt &Endtime;	
	class &time &group &Covcat &id;
	model &DVar=&time &group &CovCon &CovCat &time*&group/dist=&dist type3;
	repeated subject=&id/corrw covb type=&type;
	lsmeans &time &group &time*&group/diff;
	ODS output LSmeans=lsm;
	format &group groupfmt.;
	title "&title"; 
	title2 "&DVar between treatment and control at Visit &Endtime";	
run;

Goptions Device=png Colors=(Black red blue) 
         Display Fby=swissb  Cback=White ;
Axis1 Label=(Angle=90 Rotate=0 Font=swissb h=2 "Least Square Mean") value=(Font=swissb h=2);
Axis2 Label=(Font=swissb h=2 ' ') Value=(Font=swissb h=2);

Symbol1 Value=triangle color=blue Interpol=join  Line=1; 
Symbol2 Value=dot color= red Interpol=join  Line=2; 
legend1 frame label=none value=(Font=swissb h=2);

proc gplot data=lsm;
	where  (&group ne " " )and (&time ne " ");
	plot mean*visit=&group/Frame Vaxis=axis1 Haxis=axis2 Legend=legend1;	
	format mean f7.2;	
run;
quit;

ods &format close;

%mend LSMPlotGEE;

/*%LSMPlotGEE(DSname=PainC,
				   DVar=psqi, 
				   time=visit,
				   group=group,
                   Endtime=4,
        		   CovCat=,
                   CovCon=CESD_PRE,
                   id=id,
                   dist=normal,
				   type= exch,
                   format=html,
				   title=3. psqi-month
 );	*/


