
data simulated;
	infile 'Y:\BERDmacros\Xia\MIXED_MSEM\Version1\sim.dat';
	input subj grp X M Y;
run;


filename MSEM URL "http://www.ctspedia.org/wiki/pub/CTSpedia/MIXEDMSEM/MIXED_MSEM.sas";
%include MSEM;

/*filename MSEM "Y:\BERDmacros\Xia\MIXED_MSEM\Version1\Rochester_MIXED_MEDIATION_Main Macro.sas";
%include MSEM;*/


%MIXED_MSEM(DSName=simulated,
			DepVar=Y,
			grp=grp, 
			subj=subj,
			M =M, 
			X=X,
			ddfm=bw, 
			OutFormat=html);




