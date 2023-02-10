# file scatter.wslope.example.R - example file for calling on scatterWslope
#source("scatterWslope.R")

source("http://www.ctspedia.org/wiki/pub/CTSpedia/StatToolsTopic057/Thurston_scatterWslope.R.txt")
par(mfrow=c(2,2),mar=c(4.1,4.1,2.1,2.1))
airquality.dat <- airquality
airquality.dat[,"Log.Ozone"] <- log(airquality.dat[,"Ozone"])

### Plot 1: default (adjusted)
scatterWslope(airquality.dat,yname="Log.Ozone",xname="Solar.R",covnames=c("Wind","Temp","Month"))

### Plot 2: still adjusted only, with title, better legends, different plotting characters
scatterWslope(airquality.dat,yname="Log.Ozone",xname="Solar.R",covnames=c("Wind","Temp","Month"),unadjusted=FALSE,adjusted=TRUE,txlab="Solar radiation (Langleys)",tylab="Log(ozone, ppb)",ttitle="Adjusted slope",show.legend=TRUE,cex.legend=1.2,pch.points=4,cex.xylab=1.2)

### Plot 3: unadjusted regression line only, with different fonts and a different location of the legend.
scatterWslope(airquality.dat,yname="Log.Ozone",xname="Solar.R",covnames=c("Wind","Temp","Month"),unadjusted=TRUE,adjusted=FALSE,txlab="Solar radiation (Langleys)",tylab="Log(ozone, ppb)",cex.xylab=1,ttitle="Unadjusted slope",show.legend=TRUE,cex.legend=1.4,legend.loc="bottomright",round.slope=4)

### Plot 4: both adjusted and unadjusted regression lines, only show confidence bands for adjusted,
### make points smaller, and make the unadjusted slope in red.

scatterWslope(airquality.dat,yname="Log.Ozone",xname="Solar.R",covnames=c("Wind","Temp","Month"),unadjusted=TRUE,adjusted=TRUE,txlab="Solar radiation (Langleys)",tylab="Log(ozone, ppb)",ttitle="Adjusted and unadjusted slopes",col.unadj="red",cex.title=1,print.results=FALSE,show.legend=TRUE,conf.bands.adj=TRUE,conf.bands.unadj=FALSE,cex.points=0.5,cex.legend=0.8,cex.xylab=1,legend.loc="bottomright",round.slope=4)

### Text so far is the same as in scatterWslopeExample.Rnw.  Now repeat last plot, but save to a pdf file.
### Also change fonts since one plot (not 4 per page).

scatterWslope(airquality.dat,yname="Log.Ozone",xname="Solar.R",covnames=c("Wind","Temp","Month"),unadjusted=TRUE,adjusted=TRUE,txlab="Solar radiation (Langleys)",tylab="Log(ozone, ppb)",ttitle="Adjusted and unadjusted slopes",col.unadj="red",cex.title=1.2,print.results=FALSE,show.legend=TRUE,conf.bands.adj=TRUE,conf.bands.unadj=FALSE,cex.points=0.5,cex.legend=1.2,cex.xylab=1.2,legend.loc="bottomright",round.slope=4,save.plot=TRUE,basename.plot="scatterWslopeOneplot")
