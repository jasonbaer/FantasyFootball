rm(list = ls())

# install.packages("mclust")
# install.packages("ggplot2")
# install.packages("readr")

require("mclust")
require("ggplot2")
require("readr")


setwd("/Users/jasonbaer/Documents/My Documents/git")

workingDirectory <- getwd()
baseFolder <- "FantasyFootball/DraftTiers"
sourceFolder <- paste(baseFolder, "/src", sep="")
source(paste(sourceFolder, "/functions.R", sep=""), chdir=T)

### Parameters 
options(echo = TRUE)
args 	<- commandArgs(trailingOnly <- TRUE)
args <- TRUE
if (length(args) != 1) {
  print("Expected args format: Rscript main.R TRUE/FALSE")
  stopifnot(FALSE)
}
download = toupper(as.character(args[1]))
if (download=="T") download <- TRUE
if (download=="F") download <- FALSE

thisweek <- as.numeric(floor((as.Date(Sys.Date(), format="%Y/%m/%d") - as.Date("2018-09-04", format="%Y-%m-%d"))/7))+1
thisweek <- max(0, thisweek) # 0 for pre-draft
download.ros <- FALSE
useold <- FALSE		# Do we want to use the original version of the charts?
year <- 2018
download <- TRUE		# Do we want to download fresh data from fantasypros?


### Set and create input / output directories
datdir <- paste(baseFolder, "/dat/", year,"/", sep=""); mkdir(datdir)
outputdir <- paste(baseFolder, "/out/week", thisweek, "/", sep=""); mkdir(outputdir)
outputdircsv <- paste(baseFolder, "/out/week", thisweek, "/csv/", sep=""); mkdir(outputdircsv)
outputdirpng <- paste(baseFolder, "/out/week", thisweek, "/png/", sep=""); mkdir(outputdirpng)
outputdirtxt <- paste(baseFolder, "/out/week", thisweek, "/txt/", sep=""); mkdir(outputdirtxt)
gd.outdir <- paste(baseFolder, "/out/current/", sep=""); mkdir(gd.outdir)
gd.outputdircsv <- paste(gd.outdir, "csv/", sep=""); mkdir(gd.outputdircsv)
gd.outputdirpng <- paste(gd.outdir, "png/", sep=""); mkdir(gd.outputdirpng)
gd.outputdirtxt <- paste(gd.outdir, "txt/", sep=""); mkdir(gd.outputdirtxt)
system(paste("rm ", gd.outputdircsv, "*", sep=""))
system(paste("rm ", gd.outputdirpng, "*", sep=""))
system(paste("rm ", gd.outputdirtxt, "*", sep=""))

## If there are any injured players, list them here to remove them
injured <- c("Jerick McKinnon")

### Predraft data
if (download == TRUE) download.predraft.data(datdir)

# if (FALSE) {
#   scoring.type.list = c('all', 'all-ppr', 'all-half-ppr')
#   for (scoring.type in scoring.type.list) {
#     high.level.tiers = draw.tiers(scoring.type, 1, 200, 3, XLOW=5, highcolor=720, save=FALSE)
#     nt.std.1 = draw.tiers(scoring.type, 1, high.level.tiers[1], 10, XLOW=10, highcolor=720)
#     nt.std.2 = draw.tiers(scoring.type, high.level.tiers[1]+1, high.level.tiers[1]+high.level.tiers[2], 8, adjust=1, XLOW=18, highcolor=720, num.higher.tiers=length(nt.std.1))
#     nt.std.3 = draw.tiers(scoring.type, high.level.tiers[1]+high.level.tiers[2]+1, high.level.tiers[1]+high.level.tiers[2]+high.level.tiers[3], 8, adjust=2, XLOW=20, highcolor=720, num.higher.tiers=(length(nt.std.1)+length(nt.std.2)))
#   }
# }


if (download == TRUE) {
  download.data(c('qb','k','dst'))
  if (thisweek == 0) {
    download.data(c('rb','wr','te'), scoring='STD')
    download.data(c('rb','wr','te'), scoring='PPR') 
    download.data(c('rb','wr','te'), scoring='HALF')
  }
  if (thisweek > 0) {
    download.data(c('flx','rb','wr','te'), scoring='STD')
    download.data(c('flx','rb','wr','te'), scoring='PPR') 
    download.data(c('flx','rb','wr','te'), scoring='HALF')	
  }
}


## Weekly
draw.tiers("qb", 1, 26, 8, highcolor=360)
draw.tiers("rb", 1, 40, 9, highcolor=400, scoring='STD')
draw.tiers("wr", 1, 60, 12, highcolor=500, XLOW=10, scoring='STD')
draw.tiers("te", 1, 24, 8, XLOW=5, scoring='STD')
draw.tiers("k", 1, 20, 5, XLOW=5)
draw.tiers("dst", 1, 20, 6, XLOW=2)

draw.tiers("rb", 1, 40, 10, scoring='PPR')
draw.tiers("wr", 1, 60, 12, highcolor=500, XLOW=10, scoring='PPR')
draw.tiers("te", 1, 25, 8, scoring='PPR')

draw.tiers("rb", 1, 40, 9, scoring='HALF')
draw.tiers("wr", 1, 60, 10, highcolor=400, XLOW=10, scoring='HALF')
draw.tiers("te", 1, 25, 7, scoring='HALF')

if (thisweek > 0) {
  draw.tiers("flx", 25, 100, 14, XLOW=5, highcolor=650, scoring='STD')
  draw.tiers("flx", 25, 100, 14, XLOW=5, highcolor=650, scoring='PPR')
  draw.tiers("flx", 25, 100, 15, XLOW=5, highcolor=650, scoring='HALF')
}


download.data.ecr(thisweek, c('qb','flx','rb','wr','te'))


kCutoffs = c(QB = 24, RB = 40, WR = 60, TE = 24, K = 24, DST = 24)
kTiers = c(QB = 8, RB = 9, WR = 12, TE = 8, K = 5, DST = 6)


pos="QB"

ecr_df = read_ecr_data(paste(gd.outputdircsv, "weekly-", toupper(pos), ".csv", sep=""))
ecr_df = ecr_df[1:kCutoffs[pos], ]  # The data is ordered from best rank to worst rank 
ecr_df$TierRank = computeTiers(ecr_df$Avg.Rank, kTiers[pos])

ecr_df$nchar = nchar(as.character(ecr_df$Player.Name))  # For formatting later

# Calculate position rank, negative so lowest rank will be on top in the plot
# below
ecr_df$position.rank = -seq(nrow(ecr_df))

# Plotting
font = 3.5
barsize = 1.5  
dotsize = 2 

p = ggplot(ecr_df, aes(x = position.rank, y = Avg.Rank))
p = p + geom_errorbar(aes(ymin = Avg.Rank - Std.Dev/2, ymax = Avg.Rank + Std.Dev/2, width=0.2, colour=TierRank), size=barsize*0.8, alpha=0.4)
p = p + coord_flip()
p = p + geom_text(aes(label=Player.Name, colour=TierRank, y = Avg.Rank - nchar/6 - Std.Dev/1.4), size=font)
p = p + scale_x_continuous("Expert Consensus Rank")
p = p + ylab("Average Expert Rank")
p



sdf = read_score_data(fn$identity("data/2015/FFA-CustomRankings-Week-`week`.csv"), week)

