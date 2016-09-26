# This script will graph the song data by means
# Use as follows:
# Rscript graph_song_data.R <path.to.data> <title.of.graph> <prefix.for.pdf>

#install.packages("ggplot2", lib="/global/home/users/wynn/bin/Rpackages/", repos="http://cran.cnr.berkeley.edu/")
#install.packages("ggplot2", lib="/global/home/users/wynn/bin/Rpackages/", repos="http://cran.r-project.org")
#ggplot2 is installed.... needs to be loaded as a module
#library(ggplot2, lib.loc="/global/home/users/wynn/bin/Rpackages/")
library(ggplot2)
#install.packages("gdata", lib="/global/home/users/wynn/bin/Rpackages/", repos="http://cran.cnr.berkeley.edu/")
#library(gdata, lib.loc="/global/home/users/wynn/bin/Rpackages/")
#library(dplyr)

args = commandArgs(TRUE) # get the arguments passed
#troubleshoot: this should add median & quartile to violinplot, but currently doesn't work:
#+stat_summary(fun.y=median.quartile,geom='point')
#from: http://stackoverflow.com/questions/17319487/median-and-quartile-on-violin-plots-in-ggplot2

#from http://stackoverflow.com/questions/3483203/create-a-boxplot-in-r-that-labels-a-box-with-the-sample-size-n
give.n <- function(x){
   return(c(y = mean(x), label = length(x)))
}
median.quartile <- function(x){
    out <- quantile(x, probs = c(0.25,0.5,0.75))
    names(out) <- c("ymin","y","ymax")
    return(out) 
}

convert_table <- function(datapath, wsplist, minnoipi, ytitle, dodamage = FALSE, mult1k = FALSE) {
	data = read.csv(datapath, header=T, sep=',') # read in data
	wsp <- scan(wsplist,what="character") #which species to include
	datasub <- data[which(data$Species %in% wsp),]
	datasub <- droplevels(datasub)
	datasub <- datasub[which(as.numeric(as.character(datasub$NoIPI)) > minnoipi),]
	if (dodamage == TRUE) {
		datasub <- datasub[which(datasub$MaleWings != "damaged"),]
	}
	print(table(datasub$Species))
	#wcol <- which(names(datasub)==statname)
	#if (length(wcol) == 0) {
	#	stop(paste(statname,"does not exist in",datapath))
	#}
	#datasub[,wcol] <- as.numeric(as.character(datasub[,wcol]))
	#print(head(datasub[,wcol]))
	datasub$StatMedian <- as.numeric(as.character(datasub$StatMedian))
	if(mult1k == TRUE) {
		#datasub[,wcol] <- 1000*datasub[,wcol]
		datasub$StatMedian <- 1000*datasub$StatMedian
	}
        datasub <- datasub[with(datasub, order(Species)),]
        #datasub <- datasub[match(wsp,datasub$Species),]
        #datasub$Species <- reorder.factor(datasub$Species, new.order=wsp)
	return(datasub)
}

convert_table_modname <- function(datapath, wsplist, minnoipi, ytitle, dodamage = FALSE, namepref="", mult1k = FALSE) {
        print(datapath)
	data = read.csv(datapath, header=T, sep=',') # read in data
	wsp <- scan(wsplist,what="character") #which species to include
        print(wsp)
	datasub <- data[which(data$Species %in% wsp),]
        print("Initial table:")
        print(table(data$Species))
	datasub <- droplevels(datasub)
        noipicol <- which(names(datasub)==paste(namepref,"NoIPI",sep=""))
	datasub <- datasub[which(as.numeric(as.character(datasub[,noipicol])) > minnoipi),]
        print(paste("Filtered for minimum",minnoipi," samples:"))
        print(table(data$Species))
	if (dodamage == TRUE) {
		datasub <- datasub[which(datasub$MaleWings != "damaged"),]
	}
        print("After filtering for damage:")
	print(table(datasub$Species))
        statmediancol <- which(names(datasub)==paste(namepref,"StatMedian",sep=""))
	datasub[,statmediancol] <- as.numeric(as.character(datasub[,statmediancol]))
	if(mult1k == TRUE) {
		#datasub[,wcol] <- 1000*datasub[,wcol]
		datasub[,statmediancol] <- 1000*datasub[,statmediancol]
	}
        #datasub <- datasub[with(datasub, order(Species)),]
        #datasub <- datasub[order(datasub$Species),]
        datasub$Species <- factor(datasub$Species, wsp)
        print("After reordering:")
        print(table(datasub$Species))
        #datasub <- datasub[match(wsp,datasub$Species),]
        #datasub$Species <- reorder.factor(datasub$Species, new.order=wsp)
	return(datasub)
}

graph_song_data <- function(datapath, wsplist, mtitle, ytitle, outfile, minnoipi, 
                            colname = "StatMedian", dodamage = FALSE, namepref = "", ylimits = NA,
                            namemod = FALSE, multcol = FALSE) {
    #switch titles to vectors, then paste
    if (namemod == FALSE) {
	datasub = convert_table(datapath, wsplist, minnoipi, ytitle, dodamage, multcol)
    } else {
        datasub = convert_table_modname(datapath, wsplist, minnoipi, ytitle, dodamage, namepref, multcol)
    }
    if (is.na(ylimits[1])) {
	vp <- ggplot(datasub, aes_string(x="Species", y=colname)) + # define x and y
 	  geom_violin(aes(fill=factor(Species))) + # pick a color
 	  theme(axis.text.x = element_text(colour='black',angle = 60, hjust = 1),
 	        axis.text.y = element_text(colour='black')) +
 	  labs(title=paste(mtitle,collapse=" ")) +
 	  ylab(paste(ytitle,collapse=" ")) +
 	  guides(fill = FALSE) +
 	  stat_summary(fun.data = give.n, geom = "text") 
	ggsave(filename=paste(outfile, 'violin.pdf', sep=''),plot=vp)
     
	bp <- ggplot(datasub, aes_string(x="Species", y=colname)) + # define x and y
 	 geom_boxplot(aes(fill=factor(Species))) + # pick a color
 	 theme(axis.text.x = element_text(colour='black',angle = 60, hjust = 1),
 	       axis.text.y = element_text(colour='black')) +
 	 labs(title=paste(mtitle,collapse=" "))+
  	 ylab(paste(ytitle,collapse=" ")) +
  	 guides(fill = FALSE) +
 	  stat_summary(fun.data = give.n, geom = "text")
        ggsave(filename=paste(outfile, 'boxplot.pdf', sep=''),plot=bp)
    } else {
	vp <- ggplot(datasub, aes_string(x="Species", y=colname)) + # define x and y
 	  geom_violin(aes(fill=factor(Species))) + # pick a color
 	  theme(axis.text.x = element_text(colour='black',angle = 60, hjust = 1),
 	        axis.text.y = element_text(colour='black')) +
 	  labs(title=paste(mtitle,collapse=" ")) +
 	  ylab(paste(ytitle,collapse=" ")) +
 	  ylim(ylimits) +
 	  guides(fill = FALSE) +
 	  stat_summary(fun.data = give.n, geom = "text") 
	ggsave(filename=paste(outfile, 'violin.pdf', sep=''),plot=vp)
     
	bp <- ggplot(datasub, aes_string(x="Species", y=colname)) + # define x and y
 	 geom_boxplot(aes(fill=factor(Species))) + # pick a color
 	 theme(axis.text.x = element_text(colour='black',angle = 60, hjust = 1),
 	       axis.text.y = element_text(colour='black')) +
 	 labs(title=paste(mtitle,collapse=" "))+
  	 ylab(paste(ytitle,collapse=" ")) +
  	 ylim(ylimits) +
  	 guides(fill = FALSE) +
 	  stat_summary(fun.data = give.n, geom = "text")
    ggsave(filename=paste(outfile, 'boxplot.pdf', sep=''),plot=bp)
    } 
}

indatapath = args[1] #make generic? combine files for multiple stats
maintitle = scan(args[2],what="character")
yaxtitle = scan(args[3],what="character")
outfilename = args[4]
specieslist = args[5]
minss = args[6]
whichstat = args[7]
ylow = args[8]
yhigh = args[9]
domult = as.logical(args[10])

graph_song_data(indatapath, specieslist, maintitle, yaxtitle, outfilename, minss,
                paste(whichstat,"StatMedian",sep=""),TRUE, whichstat,NA,TRUE,domult)
graph_song_data(indatapath, specieslist, maintitle, yaxtitle, paste(outfilename,"Zoom",sep=""), minss,
                paste(whichstat,"StatMedian",sep=""),TRUE, whichstat,c(ylow,yhigh),TRUE,domult)
