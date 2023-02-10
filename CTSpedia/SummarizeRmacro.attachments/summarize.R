### file summarize.R:created in R version 2.8.0
###
### This contains 2 functions (1) lookup; and (2) summarize.
### Summarize is the main function
###
### (1) lookup assumes that the user has created a vector of longer
### variable names, where the name of the vector matches the variable
### names in a dataset, e.g. 
###      dimnames(test.dat)[[2]] <- c("y","x")
###      longnames <- c("verbal IQ","prenatal mercury exposure (ppm)")
###      names(longnames) <- names(test.dat)
### Then lookup, with proper arguments, will return the longer name, e.g.
###     yaxis <- lookup("y",longnames)
### Now yaxis will be "verbal IQ" instead of "y"
### The advantage here is that one can work with short names (saves typing)
### then use the longer names when needed for nice output.
###
### (2) summarize: This function gives a 1-line summary for each
### variable in a dataframe.  The summary can be as short as just the
### name, n, mean, or can include SD, number missing (nmis), number of
### unique values or categories (uniq), and any quantiles that the
### user wants.  User can use lookup to list the variables by the
### longer name.  Output can be put to the screen, and/or output to a
### file.  The output can either be in tabular format, or in a LaTeX
### table.


###%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lookup <- function(colname,longnames) {
  ### Function to return a longer version of a variable name.
  ### The point is to be able to use short names of variables
  ### in a data frame, but be able to refer to a longer name
  ### such as for a plot label or elsewhere.
  
  ### REQUIRED Arguments:
  ###      colname    = a character string that generally corresponds
  ###                   to a column names of a dataframe.  This
  ###                   would generally be a short name, for which
  ###                   a longer name is desired for a plot or table
  ### 
  ###      longnames = a vector of longer variable names, where
  ###                   the names of longnames should
  ###                   include colname
  
  ### Return the "long" name from longnames, or if there
  ### is not a match, return the original variable name

  ### Example of some code prior to calling lookup:
  ###      dimnames(test.dat)[[2]] <- c("y","x")
  ###      longnames <- c("verbal IQ","prenatal mercury exposure (ppm)")
  ###      names(longnames) <- names(test.dat)
  ###      print(as.matrix(longnames)) # if want to verify naming
  ### Example of using lookup: 
  ###     yaxis <- lookup("y",longnames)
  ### Now yaxis will be "verbal IQ" instead of "y"
  
  if (colname %in% names(longnames) == FALSE) {
    return(colname)
  } else {
    return(longnames[match(colname,names(longnames))])
  }
}


###%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

summarize <- function(tmat,
                      digits=2,
                      quants=c(0,0.25,0.5,0.75,1),
                      SD=TRUE,
                      nmis=FALSE,
                      uniq=FALSE,
                      latex=FALSE,
                      full.latex=FALSE,
                      lookup.names=NULL,
                      filename=NULL,
                      screen=TRUE,
                      caption=NULL) {

  ### REQUIRED arguments are:
  ###      tmat = dataframe containing variable for which we want a summary
  ### OPTIONAL arguments are:
  ###     digits = number of digits to show in the summary
  ###     quants = quantiles to be included. Default is c(0,.25,.5,.75,1)
  ###             If don't want quantiles, make quants=NULL
  ###     latex = TRUE if want output in LaTeX
  ###     full.latex = TRUE if want latex output to be a stand-alone
  ###             LaTeX file.  If latex=TRUE and full.latex=FALSE, the
  ###             output can be included with an \include{filename} command.
  ###             (may be useful if output from this function will be
  ###             included as one part of a larger set of function calls.)
  ###     SD = TRUE if want to show SD
  ###     nmis = TRUE if want to show number missing observations
  ###     uniq = TRUE if want to show number of categories
  ###     lookup.names = vector of longer variable names, where column names
  ###                       should match variable names in tmat
  ###     filename = name of file where output should be saved
  ###                       (default is NULL, not to save it to a file)
  ###     screen = TRUE if want to view results on the screen
  ###     caption = caption for LaTeX format
  
  ### if tmat is a vector, turn into matrix   
  if (is.vector(tmat)) tmat <- as.matrix(tmat)
  
  ### if more than 1 variable, set matnames to be name of variables,
  ### and count number of variables
  if (ncol(tmat) > 1) {
    if(length(dimnames(tmat)[[2]])==0) stop("Need dimnames for a matrix\n")
    matnames <- dimnames(tmat)[[2]]
    nvars <- length(matnames)
  } else {
    nvars <- 1
  }

  if (!is.null(quants)) {
     if ((min(quants) < 0) | (max(quants) > 1)) stop("Quantiles must be in (0,1)")
  }
  
  ### Create a matrix, summaries, in which to store results.  First figure out # cols
  ### Always have cols for name, n, mean
  nopt1 <- 1*(SD==1) + 1*(nmis==1) + 1*(uniq==1)
#  cat("nopt1=",nopt1,"\n")
  if (is.null(quants)) nopt2 <- 0 else nopt2 <- length(quants)
#  cat("nopt2=",nopt2,"\n")
  number.cols <- 2 + nopt1 + nopt2
#  cat("number.cols=",number.cols,"\n")
  summaries <- as.data.frame(matrix(nrow=nvars,ncol=number.cols))
  summaries.names <- "nobs"
  if (nmis) summaries.names <- c(summaries.names,"nmis")
  if (uniq) summaries.names <- c(summaries.names,"uniq")
  summaries.names <- c(summaries.names,"mean")
  if (SD) summaries.names <- c(summaries.names,"SD")

  if (!is.null(quants)) {
    quantnames <- as.character(quants)
#    print(quantnames)
    for (j in 1:length(quantnames)) {
#      cat("j=",j,"quantnames[j]=",quantnames[j],"\n")
      quantnames[j] <- paste(as.character(quants[j]*100),"%",sep="")
      if (quants[j]==0) quantnames[j] <- "min"
      if (quants[j]==1) quantnames[j] <- "max"
    }
      
    summaries.names <- c(summaries.names,quantnames)
  }
   
  colnames(summaries) <- summaries.names

  ### MAIN PART OF PROGRAM: fill values of summaries
  ### Loop through each variable in the dataframe
  for (j in 1:ncol(tmat)) {
      ### If more than one variable, assign row names - use lookup
      ### to give a more descriptive name, if there is one
    if (ncol(tmat) > 1) rownames(summaries)[j] <- lookup(matnames[j],lookup.names)
    thisvar <- tmat[,j]
    ### define vector where 1's are observed values
    OK.nomiss <- !is.na(thisvar)
    ### Count number of non-missing and missing values
    summaries[j,"nobs"] <- sum(OK.nomiss)
    
    ### If want long summary, count number of missing values, and 
    ### number of categories (excluding missing values), 
    if (nmis)  summaries[j,"nmis"] <- sum(is.na(thisvar))
    if (uniq)  summaries[j,"uniq"] <- length(unique(thisvar[OK.nomiss]))
    summaries[j,"mean"] <- round(mean(thisvar[OK.nomiss]),digits)
    if (SD)  summaries[j,"SD"] <- round(sd(thisvar[OK.nomiss]),digits)
    
    ### If the variable is numeric, get mean and quantiles
    if (is.numeric(thisvar)) {
      if (!is.null(quants)) summaries[j,quantnames] <- round(quantile(thisvar[OK.nomiss],probs=quants),digits)
    }
  }  ### End of looping through each variable


  ### Output results
  output.results <- function() {
    ### if user wants results as LaTeX, use xtable to make a LaTeX table
    if (latex) {
      ### if user wants to save as full LaTeX file, need commands at top 
      if (full.latex) {
        cat("\\documentclass{article}")
        cat("\\begin{document}")
      }
      library(xtable)
      print(xtable(summaries,floating=FALSE,table.placement="H!",caption=caption))
      ### if save as full LaTeX file, need commands at bottom
      if (full.latex)  cat("\\end{document}\n")
      ### if user doesn't want LaTeX, just print the results
    }  else print(summaries)
  }  ### end of output.results

  
  ### If user wants to view results on screen
  if (screen) {
    output.results()
  }

  ### If user wants to save results to a file,
  ### open filename, call on output.results(), close file.
  if (!is.null(filename)) {
    if (latex) sink(paste(filename,".tex",sep=""))
    else sink(paste(filename,".Rout",sep=""))
    output.results()
    sink()
  }

  ### return the results (summary matrix)
  return(summaries)
  }
