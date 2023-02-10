/* Test the logimix.sas macro.
   This is quite rudimentary.

	Created 10/30/08
	By Ross Boylan <ross@biostat.ucsf.edu>

Updated 11/4/08
	By Peter Bacchetti <peter@biostat.ucsf.edu>
	to use filename URL calls

	Released under the GNU Public License v 3 or later.
	(c) 2008 Regents of the University of California.
*/

/* Create synthetic data */
data test;
	do icase = 1 to 200;
		brandom = 2*rannor(5);
		do iwithin = 1 to 5;
			x1 = rannor(5);
			x2 = rannor(5);
			etafixed = -3 + x1 + 2*x2;
			etarand = etafixed + brandom;
			pfixed = 1/(1+exp(-etafixed));
			prand = 1/(1+exp(-etarand));
			r = ranuni(5);
			yfixed = (r < pfixed);
			yrand = (r < prand);
			output;
			end;
		end;
	run;

/* filename lmix URL "http://ctspedia.org/twiki/bin/viewfile/CTSpedia/MixedEffectsBinary?rev=2;filename=logimix.sas"; */
filename lmix URL "http://ctspedia.org/twiki/pub/CTSpedia/MixedEffectsBinary/logimix.sas";
%include lmix;
options mprint;
%logimix(test, yfixed, icase, preds=x1 x2)
%logimix(test, yrand, icase, preds=x1 x2)
options nomprint;

