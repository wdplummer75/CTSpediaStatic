
filename EFDPNL URL "http://www.ctspedia.org/wiki/pub/CTSpedia/PowESDNested/EFDPowNested.sas";
%include EFDPNL;

%EFDPowNested(alpha=0.05,
			  Power=0.8,
			  EFD=0.5, 	
			  Test=2,
			  Nrep=3,
			  ICC=0.1,
			  Ngrp1=40,	
			  group=10,
			  CorrCoef=0.5,
			  MissRate=0.20,
			  startp = 0.01);
