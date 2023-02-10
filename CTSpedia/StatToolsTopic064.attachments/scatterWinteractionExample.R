# file scatterWinteractionsExample.R - this is an example file for using scatterWinteractions.R
### To use this function, you need to define a dataframe (or matrix) of data with
### the interaction variable ALREADY created.  

### Here I run adjusted and unadjusted regressions, showing a few different plotting options.

source("https://www.ctspedia.org/wiki/pub/CTSpedia/StatToolsTopic064/scatterWinteraction.R")
airquality.dat <- airquality
airquality.dat[,"Log.Ozone"] <- log(airquality.dat[,"Ozone"])

# no missing values for Wind.  Create dummy variable for Hi.Wind
airquality.dat$Hi.Wind <- 1*(airquality.dat[,"Wind"]>10)

# Intererested in interaction of Hi.Wind with Temp.  Create interactions
airquality.dat$Temp.HiWind <- airquality.dat$Temp * airquality.dat$Hi.Wind
airquality.dat$Temp.LowWind <- airquality.dat$Temp * (1 - airquality.dat$Hi.Wind)

### Now make plots corresponding to an adjusted or unadjusted regression
par(mfrow=c(2,2),mar=c(4.1,4.1,2.1,2.1))

### adjust for month and solar.R
temp <- scatterWinteraction(airquality.dat,yname="Log.Ozone",xname="Temp",dummyname="Hi.Wind",x0name="Temp.LowWind",x1name="Temp.HiWind",covnames=c("Month","Solar.R"),confidence.bands=TRUE,txlab="Temperature (degrees F)",tylab="Log(ozone, ppb)",cex.legend=1,legend.x0name="Slope for low wind",legend.x1name="Slope for high wind",ttitle="Adjusted for month, solar.R",lty.lev1=2)

### Unadjusted
temp <- scatterWinteraction(airquality.dat,yname="Log.Ozone",xname="Temp",dummyname="Hi.Wind",x0name="Temp.LowWind",x1name="Temp.HiWind",covnames=NULL,print.results=FALSE,confidence.bands=TRUE,txlab="Temperature (degrees F)",tylab="Log(ozone, ppb)",legend.x0name="Slope for low wind",legend.x1name="Slope for high wind",ttitle="Unadjusted for other covariates",legend.loc="bottom",cex.legend=1.2,lwd.slope=2,pch.lev1=3,col.lev1="purple",cex.points=0.8,cex.title=1.2,cex.xylab=1.5)

### adjust for month and solar.R - don't show confidence bands
temp <- scatterWinteraction(airquality.dat,yname="Log.Ozone",xname="Temp",dummyname="Hi.Wind",x0name="Temp.LowWind",x1name="Temp.HiWind",covnames=c("Month","Solar.R"),print.results=FALSE,confidence.bands=FALSE,txlab="Temperature (degrees F)",tylab="Log(ozone, ppb)",legend.x0name="Slope for low wind",legend.x1name="Slope for high wind",ttitle="Adjusted for month, solar.R",cex.legend=1.2,cex.xylab=1.2,lty.lev1=2,cex.title=1.2)

### Unadjusted - don't show confidence bands
temp <- scatterWinteraction(airquality.dat,yname="Log.Ozone",xname="Temp",dummyname="Hi.Wind",x0name="Temp.LowWind",x1name="Temp.HiWind",covnames=NULL,print.results=FALSE,confidence.bands=FALSE,txlab="Temperature (degrees F)",tylab="Log(ozone, ppb)",legend.x0name="Slope for low wind",legend.x1name="Slope for high wind",ttitle="Unadjusted for other covariates",legend.loc="bottomright",cex.legend=1.8,lwd.slope=2,pch.lev0=1,pch.lev1=1,col.lev1="purple",lty.lev1=2,cex.points=0.8,cex.title=1,cex.xylab=1.5)

