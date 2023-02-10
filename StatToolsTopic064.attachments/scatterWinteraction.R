# file scatterWinteraction.R.

### This function makes a scatterplot of y versus x, with different
### symbols for the two levels of a dummy variable, where the dummy
### variable is coded as 0 or 1.  From the regression of y on x, dummy
### variable, interaction (x * dummy variable) and optionally other
### covariates, the function superimposes on the plot the separate
### slope of y on x for dummy variable = 0 or 1.  These slopes are the
### predicted lines at mean values of the other covariates (in
### "covnames" arguments).  Options include adding a legend, printing
### out the regression results to screen, and varying color, size,
### line type, etc of the lines, as well as plotting symbol and size
### of the points in the plot.

# Contains function to make a scatterplot of y versus x from a regression of y on x*IND,
# where IND=0/1, and show separate ADJUSTED regression lines

scatterWinteraction <- function(tdat,
                             yname,
                             xname,
                             dummyname,
                             x0name,
                             x1name, 
                             covnames,
                             txlab=NULL,
                             tylab=NULL,
                             cex.xylab=1.5,
                             ttitle=NULL,
                             cex.title=1.2,
                             print.results=TRUE,
                             show.legend=TRUE,
                             legend.x0name=NULL,
                             legend.x1name=NULL,
                             legend.loc="topleft",
                             cex.legend=1,
                             confidence.bands=TRUE,
                             lty.lev0=1,
                             lty.lev1=1,
                             lty.confidence=2,
                             col.lev0="blue",
                             col.lev1="red",
                             pch.lev0=1,
                             pch.lev1=4,
                             cex.points=1,
                             lwd.slope=3,
                             lwd.confidence=1,
                             save.plots=FALSE,
                             type.plots="pdf",
                             basename=NULL,
                             ndigits=4) {
  ### ARGUMENTS:
  ### tdat is database
  ### yname is name of y variable in tdat
  ### xname is name of x variable in tdat, for which we want partial plot
  ### dummyvar is name of dummy variable for which we want interaction
  ### x0name is name of x*I(dummy variable==0) (THIS MUST BE PART OF THE DATASET)
  ### x1name is name of x*I(dummy variable==1) (THIS MUST BE PART OF THE DATASET)
  ### covnames is vector of names of remaining variables
  ### txlab is name to go on x-axis of plot (default is xname)
  ### tylab is name to go on y-axis of plot (default is yname)
  ### cex.xylab is size of x and y axes
  ### ttitle is title of plot (default is none)
  ### cex.title is size of title
  ### print.results=TRUE if want to print regression results on screen
  ###
  ### show.legend=TRUE means include legend
  ### legend.x0name is what to go in the legend to indicate slope for x0
  ### legend.x1name is what to go in the legend to indicate slope for x1
  ### legend.loc is location of legend.  Possible values are:
  ###           "topleft","topright","bottomleft","bottomright","top","bottom","left","right","center"
  ### cex.legend is size of legend
  ###
  ### confidence.bands=TRUE if want confidence bands on the plot
  ### lty.lev0 is line type for plotting the line for dummy=0
  ### lty.lev1 is line type for plotting the line for dummy=1
  ### lty.confidence is line type for the confidence interval
  ### col.lev0 is color for points and line for dummy=0
  ### col.lev1 is color for points and line for dummy=1
  ### pch.lev0 is plotting character for dummy=0
  ### pch.lev1 is plotting character for dummy=1
  ### cex.points is size of points
  ###  
  ### lwd.slope is lwd for slopes
  ### lwd.confidence is lwd for confidence bands
  ### 
  ### The user has the option to either view the plots on the screen
  ### (save.plots=FALSE, which is the default), or to save the plots
  ### (save.plots=TRUE)
  ### If save.plots=TRUE, save either to pdf files (type.plots="pdf", the default)
  ### or as eps files (type.plots="eps").   The user controls the base name
  ### of the plots with the basename= argument, so if basename=silly  and
  ### type.plots="pdf" then the plots will be silly1.pdf, silly2.pdf, etc.
  ###
  ### ndigits is number of digits to show when printing regression model

  if (print.results) {
      cat("\n*** Outcome is",yname,"\n")
      cat("Number of observations in original data is",nrow(tdat),"\n")
    }
  
  # Check to see if variable names are valid
  if (is.element(yname,colnames(tdat))==FALSE) stop("yname not a name in database")
  if (is.element(xname,colnames(tdat))==FALSE) stop("xname not a name in database")
  if (is.element(x0name,colnames(tdat))==FALSE) stop("x0name not a name in database")
  if (is.element(x1name,colnames(tdat))==FALSE) stop("x1name not a name in database")
  if (is.element(dummyname,colnames(tdat))==FALSE) stop("dummyname not a name in database")
  if (!is.null(covnames)) {
    for (i in 1:length(covnames)) {
      if (is.element(covnames[i],colnames(tdat))==FALSE) stop("an element of covnames not a name in database")
    }
  }

  # Exclude missing values
  use1.dat <- as.data.frame(tdat)
  use.dat <- na.exclude(use1.dat[,c(yname,xname,dummyname,x0name,x1name,covnames)])
  if (print.results) cat("\nNumber of observations after excluding missing values in the model is",nrow(use.dat),"\n")
  
  # check to see that tdat[,dummyname] is only 0/1
  dummy.loc <- 0
  for (i in 1:length(dummyname)) {
    unique.cat <- unique(use.dat[,dummyname[i]])
    length.unique.cat <- sum(!is.na(unique.cat))
    if (length.unique.cat==2 & max(unique.cat)==1 & min(unique.cat)==0) dummy.loc <- 1
  }
  if (dummy.loc==0) stop("dummyname must contain a variable with exactly 2 different values that are 0,1\n")

  ### get or create name for x=axis and y-axis
  if (is.null(txlab)) txlab <- xname
  if (is.null(tylab)) tylab <- yname

  ### If legend.loc is not specified, make it topleft.  Also check to see if it is valid
  if (is.null(legend.loc)) legend.loc <- "topleft"
  possible.legend.loc <- c("topleft","topright","bottomleft","bottomright","top","bottom","left","right","center")
  if (is.element(legend.loc,possible.legend.loc)==FALSE & show.legend==TRUE) stop("Legend location must be correctly specified\n")

  ### if legend.x0name and legend.x1name are NULL, make them x0name and x1name
  if (is.null(legend.x0name)) legend.x0name <- x0name
  if (is.null(legend.x1name)) legend.x1name <- x1name

  ### Prepare to fit "regular" interaction model  to check
  orig.dat <- use.dat[,c(dummyname,xname,covnames)]
  orig.dat$x.ind <- use.dat[,xname] * use.dat[,dummyname]
  names(orig.dat)[ncol(orig.dat)] <- noquote(paste("Interaction: ",xname," x ",dummyname,sep=""))

  # Prepare to fit interaction model with variables reparameterized - define XX
  XX <- use.dat[,c(dummyname,x0name,x1name,covnames)]
  yvar <- use.dat[,yname]

  showsummary <- function(lm.model,ndigits=4) {
    ### Show key parts of regression output, not the rest
    summ <- summary.lm(lm.model)
    cat("Coefficients\n")
    print(round(summ$coef,ndigits))
    fstats <- summ$fstatistic
    tdf1 <- fstats["numdf"]
    tdf2 <- fstats["dendf"]

    cat("\nResidual standard error=",round(summ$sigma,ndigits),"on",tdf2,"degrees of freedom\n")
    cat("Multiple R-squared=",round(summ$r.squared,ndigits),"\n")
    model.p <- pf(fstats["value"],df1=tdf1,df2=tdf2,lower.tail=FALSE)
    pval.cutoff <- 1/(10^ndigits)
    
    if (model.p < pval.cutoff) {
      show.pval <- paste("<",pval.cutoff)
    } else {
      show.pval <- round(pval.cutoff,ndigits)
    }
    cat("F-statistic:",round(fstats["value"],ndigits),"on",tdf1,"and",tdf2,"df, p-value=",show.pval,"\n\n")
  }  # end of showsummary
    
  ##############################
  if (!is.null(covnames)) {
      ### Adjusted regression
      ### Create a covariate "dataset" with mean values of all covariates
      mean.covars.dat <- matrix(nrow=nrow(use.dat),ncol=length(covnames))
      colnames(mean.covars.dat) <- covnames
      for (j in 1:length(covnames)) {
        thiscov <- covnames[j]
        mean.covars.dat[,thiscov] <- mean(use.dat[,thiscov])
      }

      nocovars.dat <- use.dat[,c(yname,xname,dummyname,x0name,x1name)]
      topred.dat <- as.data.frame(cbind(nocovars.dat,mean.covars.dat))
    } else {
      ### Unadjusted regression
      nocovars.dat <- use.dat[,c(yname,xname,dummyname,x0name,x1name)]
      topred.dat <- as.data.frame(nocovars.dat)
    }

    # create lev0.dat and lev1.dat for the 2 levels of the dummy variable, first without covariates
    lev0.dat <- topred.dat[topred.dat[,dummyname]==0,]
    lev1.dat <- topred.dat[topred.dat[,dummyname]==1,]

    ### If saving plots, open up a pdf or eps file
    if (save.plots)  {
      if (type.plots=="eps") ending <- ".eps" else ending <- ".pdf"
      fname <- (paste(basename,ending,sep=""))
      if (type.plots=="eps") postscript(fname) else pdf(fname)
    }


#  par(mfrow=c(1,1),mar=c(5.1,5.1,2.1,2.1))
    plot(x=use.dat[,xname],y=use.dat[,yname],type="n",xlab=txlab,ylab=tylab,cex.lab=cex.xylab)
    points(x=lev0.dat[,xname],y=lev0.dat[,yname],pch=pch.lev0,col=col.lev0,cex=cex.points)
    points(x=lev1.dat[,xname],y=lev1.dat[,yname],pch=pch.lev1,col=col.lev1,cex=cex.points)
    title(ttitle,cex.main=cex.title)
    lev0.order.dat <- lev0.dat[order(lev0.dat[,xname]),]
    lev1.order.dat <- lev1.dat[order(lev1.dat[,xname]),]

  ##############################
  # Regress y on dummy, x*dummy (2 levels) and covariates
  yvar <- use.dat[,yname]
  ttt <- lm(yvar~.,data=orig.dat)
  if (print.results) {
    cat("\n*** Regression with interaction\n")
    showsummary(ttt,ndigits)
  }

  # Fit interaction model with variables reparameterized
  ttt <- lm(yvar~.,data=XX)

  if (print.results)  {
    cat("*** Reparamaterized model\n")
    showsummary(ttt,ndigits)
  }

    # intercpt is overall intercept, which applied to the dummyname=0 group
    # For the dummyname=1 group, intercept is intercpt+coef for dummyname
    intercpt <- coef(ttt)["(Intercept)"]
    intercpt2 <- intercpt + coef(ttt)[dummyname]
    if (print.results) {
      cat("For",dummyname,"= 0 group: intercept=",round(intercpt,4)," and slope for",xname,"=",round(coef(ttt)[x0name],4),"\n")
      cat("For",dummyname,"= 1 group: intercept=",round(intercpt2,4)," and slope for",xname,"=",round(coef(ttt)[x1name],4),"\n")
    }

    ### MAKE THE PLOT    

    yfit0 <- predict(ttt,newdata=data.frame(lev0.order.dat),type="response",interval="confidence")
    yfit1 <- predict(ttt,newdata=data.frame(lev1.order.dat),type="response",interval="confidence")


    lines(x=lev0.order.dat[,xname],y=yfit0[,"fit"],lty=lty.lev0,lwd=lwd.slope,col=col.lev0)
    lines(x=lev1.order.dat[,xname],y=yfit1[,"fit"],lty=lty.lev1,lwd=lwd.slope,col=col.lev1)
  
  if (confidence.bands) {
    lines(x=lev0.order.dat[,xname],y=yfit0[,"lwr"],lty=lty.confidence,lwd=lwd.confidence,col=col.lev0)
    lines(x=lev0.order.dat[,xname],y=yfit0[,"upr"],lty=lty.confidence,lwd=lwd.confidence,col=col.lev0)
  
    lines(x=lev1.order.dat[,xname],y=yfit1[,"lwr"],lty=lty.confidence,lwd=lwd.confidence,col=col.lev1)
    lines(x=lev1.order.dat[,xname],y=yfit1[,"upr"],lty=lty.confidence,lwd=lwd.confidence,col=col.lev1)
  }

    if (show.legend) legend(legend.loc,c(legend.x0name,legend.x1name),lty=c(lty.lev0,lty.lev1),lwd=c(3,3),col=c(col.lev0,col.lev1),cex=cex.legend)

    if (save.plots) dev.off() 

}
