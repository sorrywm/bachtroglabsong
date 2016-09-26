args <- commandArgs(TRUE)
#arguments: directory to summarize, statistic name/label, desired output filename,
#species name, minimum # to include statistic
#Read in a list of files.
#Files <- scan(args[1],what="character")
#outname <- args[2]
#wspecies <- args[3]
#To do: determine how to add libraries in SAVIO environment
#New: Filters males with damaged wings from fullipi and repipi
#Currently filters out only damaged (not "slight") male wings
#library(mixtools)
origdir <- getwd()
SummarizeSongStatDist <- function(spdir, statname, outname, wspecies, minno, damagefile=NULL) {
	#To use for statname (nasuta): PPB, PTL, IPIdistallmin5pulse
	#To use for statname (virilis): malePPB, malePTL, IPIdistmalemin5pulse
	#Use 100 for minno for PTL/PPB, 500 for IPI
    print("Changing directory")
    setwd(spdir)
    print("Getting file list")
    Files <- list.files(pattern=paste(statname,"\\.txt$",sep=""))
    print(paste("Getting first",statname,"file"))
    ipi <- scan(Files[1],what="numeric")
    print(paste("Getting first set of",statname))
    ipi <- as.numeric(ipi)
    NoIPI <- c(rep(NA,length(Files)))
    StatMean <- c(rep(NA,length(Files)))
    StatMedian <- c(rep(NA,length(Files)))
    StatMode <- c(rep(NA,length(Files)))
    StatLQ <- c(rep(NA,length(Files)))
    StatUQ <- c(rep(NA,length(Files)))
    StatTot <- c(rep(NA,length(Files))) #For total pulse train length (amount of singing)
    WavFiles <- c(rep(NA,length(Files)))
    splitfiles = strsplit(Files[1],'_data')
    WavFiles[1] = splitfiles[[1]][1]
    print(paste("First Files:",Files[1]))
    print(paste("First WavFiles:",WavFiles[1]))
    remfirst <- FALSE
    NoIPI[1] <- length(ipi)
    isdamaged <- FALSE
    if (file.exists(damagefile)) {
        damagedf <- read.csv(damagefile,header=T,as.is=T)
        if (splitfiles[[1]][1] %in% damagedf$Filename) {
            dmale <- damagedf[which(damagedf$Filename == splitfiles[[1]][1]),]$MaleWings
            if (dmale == "damaged") {
                isdamaged <- TRUE
            }
        }
    } else {
        print(paste(damagefile,"does not exist."))
    }
    if ((NoIPI[1] >= minno) && (isdamaged == FALSE)) {
        #Only include individuals with at least minno values in the full model.
        fullipi <- ipi
        repipi <- sample(ipi,minno)
        RepTot <- sum(repipi)
    } else {
        fullipi <- 0
        repipi <- 0
        RepTot <- 0
        remfirst <- TRUE
    }
    if (NoIPI[1] == 0) {
        StatMean[1] <- StatMedian[1] <- StatMode[1] <- StatLQ[1] <- StatUQ[1] <- StatTot[1] <- NA
        next
    }
    StatMean[1] <- mean(ipi)
    StatMedian[1] <- median(ipi)
    if(length(ipi) > 10) {
        h <- hist(ipi, breaks=round(length(ipi)/10))
        StatMode[1] <- h$mids[h$counts == max(h$counts)][1]
    } else {
        StatMode[1] <- names(sort(-table(ipi)))[1]
    } 
    StatLQ[1] <- quantile(ipi,.25)
    StatUQ[1] <- quantile(ipi,.75)
    StatTot[1] <- sum(ipi)
    for (f in 2:length(Files)) {
        #For each file, scan it as numeric (assume a vector of IPIs).
        print(paste("Scanning",Files[f]))
        ipi <- scan(Files[f],what="numeric")
        ipi <- as.numeric(ipi)
        NoIPI[f] <- length(ipi)
        splitfiles = strsplit(Files[f],'_data')
        WavFiles[f] = splitfiles[[1]][1]
        if (NoIPI[f] == 0) {
            StatMean[f] <- StatMedian[f] <- StatMode[f] <- StatLQ[f] <- StatUQ[f] <- StatTot[f] <- NA
            next
        }
        isdamaged=FALSE
        if (file.exists(damagefile)) {
            if (splitfiles[[1]][1] %in% damagedf$Filename) {
                dmale <- damagedf[which(damagedf$Filename == splitfiles[[1]][1]),]$MaleWings
                if (dmale == "damaged") {
                    isdamaged <- TRUE
                }
            }
        }
        if ((length(ipi) >= minno) && (isdamaged == FALSE)) {
            fullipi <- c(fullipi,ipi)
            toaddrepipi <- sample(ipi,minno)
            repipi <- c(repipi,toaddrepipi)
            RepTot <- RepTot + sum(repipi)
        }
        StatMean[f] <- mean(ipi)
        StatMedian[f] <- median(ipi)
        if (length(ipi) > 10) {
            h <- hist(ipi, breaks=round(length(ipi)/10))
    	    StatMode[f] <- h$mids[h$counts == max(h$counts)][1]
        } else {
            StatMode[f] <- names(sort(-table(ipi)))[1]
        } 
    	StatLQ[f] <- quantile(ipi,.25)
        StatUQ[f] <- quantile(ipi,.75)
        StatTot[f] <- sum(ipi)
    }
    #Get the distribution for the species as a whole.
    if (remfirst == TRUE) {
        fullipi <- fullipi[-1]
        repipi <- repipi[-1]
    }
    #First write without summary rows.
    Species <- c(rep(wspecies,length(StatMean)))
    print("Writing output without totals")
    outdf <- data.frame(Species,StatMean,StatMedian,StatMode,StatLQ,StatUQ,StatTot,NoIPI,Files,WavFiles)
    #merge with damagefile, if it exists
    if (file.exists(damagefile)) {
        outdf <- merge(outdf, damagedf, by.x="WavFiles", by.y="Filename", all.x=TRUE)
    }
    write.csv(outdf,file=paste(outname,statname,"NoCombined.csv",sep=""),row.names=F,quote=F)
    Files <- c(Files,paste("AllWithSongFor",wspecies,sep=""),paste("SubWithSongFor",wspecies,sep=""))
    StatMean <- c(StatMean,mean(fullipi),mean(repipi))
    StatMedian <- c(StatMedian,median(fullipi),median(repipi))
    if (length(fullipi) > 10) {
        hf <- hist(fullipi, breaks=round(length(fullipi)/10))
        smf <- hf$mids[hf$counts == max(hf$counts)][1]
    } else {
        smf <- names(sort(-table(fullipi)))[1]
    }
    if (length(repipi) > 10) {
        hr <- hist(repipi, breaks=round(length(repipi)/10))
        smr <- hr$mids[hr$counts == max(hr$counts)][1]
    } else {
        smr <- names(sort(-table(repipi)))[1]
    }
    StatMode <- c(StatMode, smf, smr)
    StatLQ <- c(StatLQ, quantile(fullipi,.25),quantile(repipi,.25))
    StatUQ <- c(StatUQ, quantile(fullipi,.75),quantile(repipi,.75))
    StatTot <- c(StatTot, sum(StatTot), RepTot)
    NoIPI <- c(NoIPI, length(fullipi),length(repipi))
    pdf(paste(outname,statname,"Hist.pdf",sep=""))
    par(mfrow=c(1,2))
    hist(fullipi,breaks=round(length(fullipi)/10),xlab=statname,main=paste("All",wspecies,statname))
    abline(v=mean(fullipi),col="red")
    abline(v=median(fullipi),col="blue")
    abline(v=hf$mids[hf$counts == max(hf$counts)],col="green")
    abline(v=c(quantile(fullipi,.25),quantile(fullipi,.75)),col="brown")
    hist(repipi,breaks=round(length(repipi)/10),xlab=statname,main=paste("Subsampled",wspecies,statname))
    abline(v=mean(repipi),col="red")
    abline(v=median(repipi),col="blue")
    abline(v=hr$mids[hr$counts == max(hr$counts)][1],col="green")
    abline(v=c(quantile(repipi,.25),quantile(repipi,.75)),col="brown")
    legend("topright",legend=c("Mean","Median","Mode","Quartiles"),col=c("red","blue","green","brown"),lty=1)
    dev.off()
    #mixmdlr2 <- normalmixEM(repipi)
    #mixmdlr4 <- normalmixEM(repipi,k=4)
    #mixmdlf2 <- normalmixEM(fullipi)
    #mixmdlf4 <- normalmixEM(fullipi,k=4)
    #pdf(paste(outname,"MixtureModel.pdf",sep=""))
    #par(mfrow=c(2,3))
    #hist(repipi,breaks=1000,main=paste("Sub-sampled",statname))
    #plot(mixmdlr2,which=2,breaks=100,main="2-component mixture")
    #plot(mixmdlr4,which=2,breaks=100,main="4-component mixture")
    #hist(fullipi,breaks=1000,main=paste("All",statname))
    #plot(mixmdlf2,which=2,breaks=100,main="2-component mixture")
    #plot(mixmdlf4,which=2,breaks=100,main="4-component mixture")
    #dev.off()
    Species <- c(rep(wspecies,length(StatMean)))
    print("Writing output with totals")
    outdf <- data.frame(Species,StatMean,StatMedian,StatMode,StatLQ,StatUQ,StatTot,NoIPI,Files)
    write.csv(outdf,file=paste(outname,statname,".csv",sep=""),row.names=F,quote=F)
    setwd(origdir)
}
if (length(args)>5) {
    print("Using damage file information")
    SummarizeSongStatDist(args[1],args[2],args[3],args[4],as.numeric(args[5]),args[6])
} else {
    SummarizeSongStatDist(args[1],args[2],args[3],args[4],as.numeric(args[5]))
}
