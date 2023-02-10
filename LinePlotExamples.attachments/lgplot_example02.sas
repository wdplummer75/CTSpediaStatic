%autorun;

proc format; ;
   value groupf
     1 = 'Active'
     2 = 'Control'
     ;
   value grpsf
     1 = 'Act'
     2 = 'Ctr' 
     ;
   value ep
     1="Endpoint";
run;



data smrydata;
  set data_a.figure8_data;
  if treat="Active" then grp=1;else grp=2;
  grp2=grp;
  if week=16 then do;
    timeq=.;
    timeq2=1+(grp-1.5)*0.20;
  end;
  else do;
    timeq=week+(grp-1.5)*0.20;  *bring a slight horizontal shift to avoid error bars to overlap;
    timeq2=.; *timeq - to use in the left column panels, timeq2 to use in the right col panels;
  end; 
run;

proc print;
 
title;
proc template;
   define style styles.redblue;
      parent = styles.default;
      class GraphColors
         "Abstract colors used in graph styles" /
         'gcdata1' = cx0300B3
         'gcdata2' = cxFD1808;
         style color_list from color_list
         "Abstract colors used in graph styles" /
         'bgA'   = cxffffff;
   end;
run;


  * version with lines ;

proc template;
  define statgraph GroupedLG;
    begingraph;
    entrytitle 'Mean Change from Baseline in ALT (U/L)';
    entryfootnote halign=left 'n.obs = Number of Observations at Time point in Treatment group';
    layout lattice / rows=2 rowweights=(.65 .35);
    *upper cell with results over time;
    sidebar / align=top;
          discretelegend "a" / title="Treatment Group";
    endsidebar;
    layout overlay /    
      yaxisopts=(label="Mean (95%%CI) Change from Bsl." griddisplay=on linearopts=(tickvaluesequence=(start=0 end=0.6 increment=0.1) viewmin=-0.05 viewmax=0.65))
      y2axisopts=(display=(line ticks) linearopts=(tickvaluesequence=(start=0 end=0.6 increment=0.1) viewmin=-0.05 viewmax=0.65))
      xaxisopts=(display=(line ticks) linearopts=(tickvaluesequence=(start=0 end=12 increment=2) viewmin=-0.5 viewmax=12.5))
      x2axisopts=(display=(line ticks) linearopts=(tickvaluesequence=(start=0 end=12 increment=2) viewmin=-0.5 viewmax=12.5));
      
      scatterplot x=timeq y=meanchg / group=grp2 name='a' yerrorlower=loerror yerrorupper=uperror  ;
      seriesplot x=timeq y=meanchg / group=grp2 xaxis=x2 yaxis=y2;                                   
    endlayout;

     *lower cell with number of observations over time;
    layout overlay /          
      xaxisopts=(label="Time (Weeks)" linearopts=(tickvaluesequence=(start=0 end=12 increment=2) viewmin=-0.5 viewmax=12.5))
      x2axisopts=(display=(line) linearopts=(tickvaluesequence=(start=0 end=12 increment=2) viewmin=-0.5 viewmax=12.5))
      yaxisopts=(label="n.obs." griddisplay=on linearopts=(tickvaluesequence=(start=130 end=180 increment=10) viewmin=125 viewmax=185))
      y2axisopts=(display=(line ticks) linearopts=(tickvaluesequence=(start=130 end=180 increment=10) viewmin=125 viewmax=185));
      
      scatterplot x=timeq y=atrisk /  group=grp2 ;
      seriesplot x=timeq y=atrisk /  group=grp2 xaxis=x2 yaxis=y2; 
    endlayout;
         
    endlayout;
  endgraph;
end;
run;


ods listing close;
ods rtf style=Styles.Redblue file="./lgplot_example03.rtf";
goptions reset=goptions device=sasemf target=sasemf ftext='Arial' ftitle='Arial/bold';
ods graphics / reset noborder width=600px height=600px noscale;
proc sgrender data=smrydata template=GroupedLG;
   format grp grpsf. grp2 groupf. timeq2 ep. ;
run;
ODS RTF CLOSE;
ods listing;
quit;
 ;
