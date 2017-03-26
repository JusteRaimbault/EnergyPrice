
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/SpatialAnalysis'))

library(dplyr)
library(rgdal)
library(cartography)
library(classInt)
library(rgeos)
library(ggplot2)

countydata = as.tbl(read.csv(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/processed/processed_20170320/county_daily_data.csv'),sep=";",header=T,stringsAsFactors = F,colClasses = c("character","integer","character","numeric","numeric","numeric","numeric")))
addresses = as.tbl(read.csv(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/processed/processed_20170320/addresses.csv'),sep=";",header=T,stringsAsFactors = F))
counties <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/processed/processed_20170320/gis'),layer = 'county_us_metro',stringsAsFactors = FALSE)
states <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/states'),layer = 'us_metro',stringsAsFactors = FALSE)
extent <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/processed/processed_20170320/gis'),layer = 'extent',stringsAsFactors = FALSE)

resdir <- paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Results/SpatialAnalysis/')


# number of obeservations per fuel
nobstot = sum(countydata$nobs)
countydata%>%group_by(type)%>%summarise(nobs=sum(nobs)/nobstot)

# number of stations
nstations = length(unique(addresses$id))


# maps of prices per county

# group by month

countydata$month = floor(countydata$day/100)
countydata%>%group_by(month)%>%summarise(count=n())

opar <- par(mar = c(0.75,0.75,1.5,0.75))
#plot(states, border = NA, col = "white", bg = "#A6CAE0")
#plot(world.spdf, col  = "#E3DEBF", border=NA, add=TRUE)

#sdata = countydata%>%group_by(countyid)%>%summarise(price=mean(meanprice))
sdata = countydata[countydata$type=="Regular"&countydata$month>201702,]%>%group_by(countyid)%>%summarise(price=mean(meanprice))


layoutLayer(title = "Average price by county, March 2017", sources = "",
            author = "", col = "grey", coltitle = "black", theme = NULL,
            bg = NULL, scale=NULL , frame = TRUE, north = F, south = FALSE,extent=extent)

breaks=classIntervals(sdata$price,20)

plot(states, border = NA, col = "white",add=T)
cols <- carto.pal(pal1 = "green.pal",n1 = 10, pal2 = "red.pal",n2 = 10)
choroLayer(spdf = counties,spdfid = "GEOID",
           df = data.frame(sdata),dfid = 'countyid',#"zip",
           var="price",
           col=cols,breaks=breaks$brks,
           add=TRUE,lwd = 0.01,
           legend.pos = "n"
)
legendChoro(pos = "left",title.txt = "Price\n($/gal)",
            title.cex = 0.8, values.cex = 0.6, breaks$brks, cols, cex = 0.7,
            values.rnd = 2, nodata = TRUE, nodata.txt = "No data",
            nodata.col = "white", frame = FALSE, symbol = "box"
            )
plot(states,border = "grey20", lwd=0.75, add=TRUE)


############
############

# autocorrelation analysis
source('functions.R')

getDailyPrices<-function(day){
  sdata = data.frame(countydata[countydata$type=="Regular"&countydata$day==day,]%>%group_by(countyid)%>%summarise(price=mean(meanprice)))
  rownames(sdata)<-as.character(sdata$countyid)
  prices = sdata[counties$GEOID,2]
  #prices=prices[!is.na(prices)]
  prices[is.na(prices)]=0
  return(prices)
}

daycounts = countydata[countydata$type=="Regular",]%>%group_by(day)%>%summarise(count=n())
# -> le 6 mars est chie, à virer (corresponds to end of hole ?)

m = matrix(rep(1,n*n),nrow=n,ncol=n);diag(m)<-0

# search for some kind of transition at the state scale ?
alldecays=c(1,10,100,1000)
alldays=sort(unique(countydata$day[countydata$day!=20170306]))
# plot(1:length(alldays),alldays)

autocorrs = c();days=c();decays=c()
for(decay in alldecays){
  show(decay)
  w=weightMatrix(decay,counties)
  for(day in alldays){
    show(day)
    prices = getDailyPrices(day)
    rho = autocorr(prices,w,m)
    #autocorrs=append(autocorrs,rho)
    #days=append(days,rep(day,length(rho)));decays=append(decays,rep(decay,length(rho)))
    autocorrs=append(autocorrs,mean(rho));days=append(days,day);decays=append(decays,decay)
  }
}

g=ggplot(data.frame(rho=autocorrs,day=strptime(as.character(days),format='%Y%m%d'),decay=as.character(decays)),aes(x=day,y=rho,color=decay,group=decay))
g+geom_point(size=0.5)+stat_smooth(se = T,span = 0.2)+ylab("Moran index") + 
  theme(axis.title = element_text(size = 15), axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10))
ggsave(file=paste0(resdir,'moran_days.pdf'),width=15,height=10)


## by week, as function of decay

getWeeklyPrices<-function(startDayIndex){
  currentdays = alldays[startDayIndex:min((startDayIndex+6),length(alldays))]
  sdata = data.frame(countydata[countydata$type=="Regular"&countydata$day%in%currentdays,]%>%group_by(countyid)%>%summarise(price=mean(meanprice)))
  rownames(sdata)<-as.character(sdata$countyid)
  prices = sdata[counties$GEOID,2]
  #prices=prices[!is.na(prices)]
  prices[is.na(prices)]=0
  return(prices)
}

alldecays=10^seq(from=0,to=4,by=0.2)

autocorrs = c();days=c();decays=c()
for(decay in alldecays){
  show(decay)
  w=weightMatrix(decay,counties)
  for(day in seq(from=1,to=length(alldays),by=8)){
    show(day)
    prices = getWeeklyPrices(day)
    rho = autocorr(prices,w,m)
    autocorrs=append(autocorrs,mean(rho));days=append(days,day);decays=append(decays,decay)
  }
}





