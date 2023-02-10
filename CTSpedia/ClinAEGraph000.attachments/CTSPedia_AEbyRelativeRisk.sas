libname excel 'C:\Work\ClinicalGraphs\CTSPedia\data\ae.xlsx';
%let gpath='C:\Work\ClinicalGraphs\CTSPedia\image';
%let dpi=200;

/*--Extract required columns from CDISC data--*/ 
data ae_data;
  set excel.'ae$'n;
  Value=sae/sn;
run;
/*proc print data=ae_data;run;*/

/*--Sort by preferred ae name--*/ 
proc sort data=ae_data;
  by pref;
  run;

/*--Change data structure to multi column format--*/ 
data ae_multi;
  set ae_data;
  retain A B SNA SNB;
  keep pref A B SNA SNB;
  by pref;

  if first.pref then do; 
    A=value; SNA=sn; 
    call symput('NA', put(sn, 3.)); 
  end;
  else do; 
    B=value; SNB=sn; 
    call symput('NB', put(sn, 3.)); 
    output;  
  end;
run;

/*--Compute relative risk values--*/
data ae_risk;
  set ae_multi;
  factor=1.96*sqrt(a*(1-a)/sna + b*(1-b)/snb);
  lcl=a-b+factor;
  ucl=a-b-factor;
  mean=0.5*(lcl+ucl);
run;

/*--Sort by mean value--*/
proc sort data=ae_risk out=ae_sort;
  by mean;
run;
 
/*--Create template for AE graph--*/
proc template;
  define statgraph AEbyRelativeRisk_multi;
    begingraph;
	  entrytitle 'Most Frequent On-Therapy Adverse Events Sorted by Risk Difference';
      layout lattice / columns=2 rowdatarange=union columngutter=5;
	  
	    /*--Row block to get common external row axes--*/
	    rowaxes;
	      rowaxis / griddisplay=on display=(tickvalues) tickvalueattrs=(size=5);
	    endrowaxes;

		/*--Column headers with filled background--*/
		column2headers;
		  layout overlay / border=true backgroundcolor=cxdfdfdf opaque=true; 
            entry "Proportion"; 
          endlayout;
		  layout overlay / border=true backgroundcolor=cxdfdfdf opaque=true; 
            entry "Risk Difference with 0.95 CI"; 
          endlayout;
        endcolumn2headers;

	    /*--Left side cell with proportional values--*/
        layout overlay / xaxisopts=(display=(ticks tickvalues)  tickvalueattrs=(size=7));
	      scatterplot y=pref x=a / markerattrs=graphdata2(symbol=circlefilled)
                        name='a' legendlabel="Treatment (N=&NA)";
	      scatterplot y=pref x=b / markerattrs=graphdata1(symbol=trianglefilled)
                        name='b' legendlabel="Control (N=&NB)";
	    endlayout;

		/*--Right side cell with Relative Risk values--*/
	    layout overlay / xaxisopts=(label='Less Risk                    More Risk'
                         labelattrs=(size=8)  tickvalueattrs=(size=7));
	      scatterplot y=pref x=mean / xerrorlower=lcl xerrorupper=ucl 
                      markerattrs=(symbol=circlefilled size=5);
		  referenceline x=0 / lineattrs=graphdatadefault(pattern=shortdash);
	    endlayout;

	    /*--Centered side bar for legend--*/
        sidebar / spacefill=false;
          discretelegend 'a' 'b' / border=false;
	    endsidebar;
	  endlayout;
	endgraph;
  end;
run;

/*--Render the graph--*/
ods html close;
ods listing gpath=&gpath image_dpi=&dpi style=listing;
ods graphics / reset width=6in height=4in imagename='AEbyRelativeRisk_multi';
proc sgrender data=ae_sort template=AEbyRelativeRisk_multi;
run;
