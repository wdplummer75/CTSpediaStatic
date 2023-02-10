%macro Rochester_MWWlongitudinal_SAS(DSName=,
									Timevar=,
									Group=);

proc iml;
	use &DSName;
	read all var{&Timevar} into datamat1;
	read all var{&Group} into datamat2;
	datamat=datamat1||datamat2;	
	run ExportMatrixToR(datamat, "d");

	submit/R;  
	source('http://www.ctspedia.org/wiki/pub/CTSpedia/StatToolsTopic048/MWW_longitudinal.r')
	MWW_longitudinal(d)
	endsubmit;
quit;

%mend Rochester_MWWlongitudinal_SAS;
