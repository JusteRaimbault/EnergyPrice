
library(dplyr)
library(ggplot2)
library(rgdal)
library(cartography)

setwd(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Models/SpatialAnalysis/'))



# cities shapefile
cities <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/'),layer = 'zip_us_metro',stringsAsFactors = FALSE)
zips <- cities@data$ZCTA5CE10

# counties


# states
states <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/states'),layer = 'us_metro',stringsAsFactors = FALSE)
state_codes <- unique(states@data$STUSPS)

addresses <- as.tbl(read.csv(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Models/DataCollection/python/loc/adresses.csv'),sep=";",stringsAsFactors = FALSE,quote = ""))


data1 <- as.tbl(read.csv(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cldata/cl1484114402_data.csv'),sep=";",stringsAsFactors = FALSE))
data1 %>% group_by(type) %>% summarise(count=n())
data1 %>% group_by(fuel) %>% summarise(count=n())
records = data1 %>% group_by(id) %>% summarise(record=(sum(as.numeric(fuel=='Regular'))>0)&(sum(as.numeric(type=='credit'))>0))
length(which(records$record))/nrow(records) # -> 96% 



#d = as.tbl(data.frame())
idcounts = c();allids = c();times=c()
for(f in list.files(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cldata'))){
  show(f)
  times=append(times,as.numeric(strsplit(strsplit(f,'cl')[[1]][2],'_')[[1]][1]))
  #currentd = as.tbl(read.csv(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cldata/',f),sep=";",stringsAsFactors = FALSE))
  #allids = union(allids,currentd$id);idcounts=append(idcounts,length(allids))
#  currentd = left_join(currentd,addresses,by="id")
#  currentd = currentd[currentd$region%in%state_codes&currentd$price<10,]
#  currentd$count = rep(1,nrow(currentd))
#  d = rbind(d,currentd[,c("id","price","count")]) %>% group_by(id) %>% summarise(price=sum(price),count=sum(count))
}

plot((times-times[1])/86400,idcounts,xlab='days',ylab='cumulated stations count')

#d$meanprice = d$price/d$count
#save(d,file='data/aggregated.RData')
load('data/aggregated.RData')


# must do some trim on states / localities


addresses[addresses$code=="02072",]
cities@data[cities@data$ZCTA5CE10=="02072",]
plot(SpatialPolygons(list(cities@polygons[[10605]]),proj4string = cities@proj4string))


## map by state
#length(which(addresses$region%in%state_codes))
df = left_join(d,addresses,by="id")
#df = df[df$region%in%state_codes,]
df$zip = sapply(df$code,function(s){substr(s,1,5)})
df = df[df$zip%in%zips&df$region%in%state_codes,]
sdf = df %>% group_by(zip) %>% summarise(meanprice = mean(meanprice))

#intersect(unique(states@data$STUSPS),unique(sdf$region))

cols <- carto.pal(pal1 = "green.pal",n1 = 5, pal2 = "red.pal",n2 = 5)
choroLayer(spdf = states,spdfid = "STUSPS", #cities,spdfid = "ZCTA5CE10",
           df = data.frame(sdf),dfid = 'region',#"zip",
           var="meanprice",
           col=cols,
           nclass=10,
           #breaks = quantile(data$NBMEN11,probs=seq(from=0,to=1,by=0.2),na.rm=TRUE),
           add=FALSE,lwd = 0.01,
           legend.pos = "topleft",
           legend.title.txt = "mean price",
           legend.values.rnd = 0.5
)
#plot(states,border = "grey20", lwd=0.1, add=TRUE)


