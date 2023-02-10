# originally written by Aniko Szabo, December 2010
###################################################
# to compile the file, call from an R session:    #
# source("iris.R")                                #
################################################### 

library(R2wd)
# function to make a subtitle
wdSubtitle <- function (title, label = substring(gsub("[, .]", "_", paste("text", 
    title, sep = "_")), 1, 16), paragraph = TRUE, wdapp = .R2wd) 
{
    wdsel <- wdapp[["Selection"]]
    wdsel[["Style"]] <- -75
    newtext <- title
    newtext[newtext == ""] <- "\n"
    newtext <- paste(newtext, collapse = " ")
    newtext <- gsub("\n ", "\n", newtext)
    newtext <- gsub(" \n", "\n", newtext)
    wdsel$TypeText(newtext)
    wdInsertBookmark(label)
    if (paragraph) {
        wdsel$TypeParagraph()
        wdsel[["Style"]] <- -1
    }
    invisible()
}

wdGet()
wdTitle("Simple R2wd usage example")
wdSubtitle("Analysis of Fisher's iris data")
wdSubtitle("BERD Reproducible Research working group")

# load data
data(iris)

wdBody(sprintf(
"The famous (Fisher's or Anderson's) iris data set gives the measurements in centimeters of the variables sepal length and width, and petal length and width, respectively, for %d flowers from each of %d species of iris. The species are %s.", 
table(iris$Species)[1], nlevels(iris$Species), paste(levels(iris$Species), collapse=", ")))

wdBody("First, let's run a simple ANOVA comparing the sepal lengths of the three species.")

a1 <- aov(Sepal.Length~Species, data=iris)
wdTable(round(summary(a1)[[1]],3), caption=": ANOVA table")

wdBody("We can see that the three species have significantly different sepal lengths. Figure 1 shows the corresponding boxplot.")

wdPlot(Sepal.Length~Species, data=iris, ylab="Sepal length", plotfun=boxplot, width=4, height=4)

wdSave(file.path(getwd(),"iris.docx"))
wdQuit()