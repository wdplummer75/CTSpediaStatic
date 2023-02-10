# file summarize.example.R - illustrate functions in summarize.R

source("http://www.ctspedia.org/wiki/pub/CTSpedia/SummarizeRmacro/summarize.R")
#### Example 1: illustrate using airquality dataset available in R

## Default settings
summarize(airquality)

## Don't show quantiles, sbut show # missing and # unique values
summarize(airquality,nmis=TRUE,uniq=TRUE)

## Create a table to input into a LaTeX file, using defaults
## NOTE: make screen=FALSE if don't want to also display on screen
#sink("summarize.airquality.Rout")
summarize(airquality,screen=TRUE,latex=TRUE,caption="Illustration of summarize using air quality data")
#sink()

###################################################
### Example 2: simulate data and illustrate use of longnames

n <- 150
x1 <- round(10 + rnorm(n,sd=3))
x2 <- round(100 + rnorm(n,sd=5),2); x2[1:10] <- NA
x3 <- round(10 + rnorm(n),2); x3[1:5] <- NA
x4 <- round(28 + rnorm(n,sd=3)); x4[20:28] <- NA
x5 <- c(rep(1,70),rep(0,n-70)) 
XX <- cbind(x1,x2,x3,x4,x5)
beta <- c(0.2,0.3,0.1,0,0)
y <- 70 + XX %*% beta + rnorm(n,sd=5)

test.dat <- as.data.frame(cbind(y,XX))
dimnames(test.dat)[[2]] <- c("y","x1","x2","x3","x4","x5")
longnames <- c("y=verbal IQ","x1=home score","x2=mothers IQ","x3=childs age","x4=mothers age","x5=boy")
names(longnames) <- names(test.dat)

cat("\n\nExample 2: \n")
## Show longnames
cat("longnames\n")
print(as.matrix(longnames))

## Call on summarize without using lookup
cat("\n*** Without lookup, also include number unique values\n")
summarize(test.dat,uniq=TRUE)

## Call on summarize, using lookup.vec
cat("\n*** Use lookup.vec, use other options\n")
summarize(test.dat,lookup.names=longnames,uniq=TRUE)

## Call on summarize, using lookup.vec and save to LaTeX file
cat("\n*** Use lookup.vec, use other options\n")
summarize(test.dat,lookup.names=longnames,uniq=TRUE,latex=TRUE,full.latex=TRUE,filename="example")
