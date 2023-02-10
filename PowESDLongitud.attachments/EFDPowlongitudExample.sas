
filename EFDPlong URL "http://www.ctspedia.org/wiki/pub/CTSpedia/PowESDLongitud/EFDPowlongitud.sas";
%include EFDPlong;

%EFDPowlongitud(alpha=0.05,
			  Power=0.8,
			  EFD=0.5,
			  Nrep=2,
			  Ngrp1=40,
			  Test=2,
			  CorrCoef=0.5,
			  MissRate=0.20,
			  startp = 0.01);
