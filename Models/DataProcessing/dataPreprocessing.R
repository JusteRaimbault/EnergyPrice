
##
# full data preprocessing

setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/DataProcessing'))

library(dplyr)
library(rgdal)

datadir = paste0(Sys.getenv('CS_DATA'),'/EnergyPrice/Data/raw/data_20170320/')
cldatadir = paste0(Sys.getenv('CS_DATA'),'/EnergyPrice/Data/raw/cleandata_20170320/')
locfile = paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/DataCollection/python/loc/adresses_20170320.csv')
finaldir = paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/processed/processed_20170320/')

dir.create(cldatadir)
dir.create(finaldir)

# remove not useful rows
#  raw -> clean raw files
if(length(list.files(cldatadir))==0){system(paste0("ls ",datadir, "|grep _data|awk '{print \"cat ",datadir,"\"$0\"|grep [0-9] > ",cldatadir,"\"$0}'|sh"))}


# adresses
adresses <- as.tbl(read.csv(locfile,sep=";",stringsAsFactors = FALSE,quote = ""))

# geographical data
# zips not needed !
#zipareas <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/'),layer = 'zip_us_metro_simpl',stringsAsFactors = FALSE)
#zips <- zipareas@data$ZCTA5CE10

cities <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/citiesx010g_shp_nt00962'),layer = 'citiesx010g',stringsAsFactors = FALSE)
#length(which(paste0(adresses$locality,adresses$region)%in%paste0(cities$NAME,cities$STATE)))/nrow(adresses)
#adresses[which(!(paste0(adresses$locality,adresses$region)%in%paste0(cities$NAME,cities$STATE))),] 
# 94% in cities db
cities$citystate=paste0(cities$NAME,cities$STATE)
#cities$countygeoid=paste0(cities$STATE_FIPS,cities$COUNTYFIPS)
cities = cities[which(!duplicated(cities$citystate)),]

states <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/states'),layer = 'us_metro',stringsAsFactors = FALSE)
state_codes <- unique(states@data$STUSPS)

counties <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/county/'),layer = 'county_us_metro',stringsAsFactors = FALSE)

# join adresses with county -> 
#zip_county <- as.tbl(read.csv(file=paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/county/zcta_county_rel_10.csv'),stringsAsFactors = FALSE,colClasses = rep('character',24)))
#citiescountieszip=as.tbl(left_join(left_join(cities@data,counties@data,by=c('countygeoid'='GEOID')),zip_county,by=c('countygeoid'='GEOID')))
#citiescountieszip$cityzipstate=paste0(citiescountieszip$NAME.x,citiescountieszip$ZCTA5,citiescountieszip$STATE.x)

#counties@data[counties$GEOID=="06001",]
#zip_county[zip_county$GEOID=="06001",]
# -> join by GEOID
# min(sapply(zips,nchar))
# max(sapply(zips,nchar))

# filter adresses
adresseszips = sapply(adresses$code,function(s){substring(s,1,5)})
adressesstates = sapply(adresses$region,trimws)
adresseslocs = sapply(adresses$locality,trimws)

#length(which(adresseszips%in%zips))
#length(which(adresseszips%in%zips&adresses$region%in%state_codes))

adresses$code=adresseszips;
adresses$region=adressesstates
adresses$locality=adresseslocs
adresses$citystate=paste0(adresses$locality,adresses$region)

adresses=adresses[adresses$citystate%in%cities$citystate,]

# -> 118573 adresses on period 11/01->27/03

# cities[duplicated(cities$citystate),]
joinedadresses = left_join(adresses,cities@data[,c(5,7,8,9,10,17,18)])
cladresses = joinedadresses[,c(1,2,3,8,12,10,11,5)]
names(cladresses)<-c("id","address","city","county","countyid","state","stateid","zip")
# export clean adresses
write.table(cladresses,file=paste0(finaldir,'addresses.csv'),sep=';',col.names = T,row.names = F,quote = F)



####
#  Agregate data files

# convention on startTS
# head(list.files(cldatadir))
datafiles = list.files(cldatadir)
firstts = sort(sapply(datafiles,function(s){as.numeric(strsplit(s,'_')[[1]][1])}))[1]
#as.POSIXlt(firstts, origin = "1970-01-01", tz = "GMT")

delayToSec<-function(s){
  if(length(grep("d",s))>0){return(as.numeric(strsplit(s,"d")[[1]][1])*86400)}
  if(length(grep("h",s))>0){return(as.numeric(strsplit(s,"h")[[1]][1])*3600)}
  if(length(grep("m",s))>0){return(as.numeric(strsplit(s,"m")[[1]][1])*60)}
}

currentdata=data.frame();currentfilestamp=firstts
for(f in datafiles){
  show(f);currenttime = as.numeric(strsplit(f,'_')[[1]][1])
  currentd = as.tbl(read.csv(paste0(cldatadir,f),sep=";",stringsAsFactors = FALSE,header=FALSE))
  names(currentd)<-c("id","type","price","delay","user","ts","payment")
  currentd = currentd[currentd$id%in%cladresses$id&currentd$payment=='credit'&currentd$price<10,]
  currentd$time = currentd$ts - sapply(currentd$delay,delayToSec)
  if(currenttime>currentfilestamp+604800){# store data if one week
    show(paste0('writing ',currentfilestamp))
    write.table(currentdata[!duplicated(currentdata),c(1,2,3,8)],file=paste0(finaldir,'weekdata_',currentfilestamp,'.csv'),sep=";",col.names = T,row.names = F,quote = F)
    currentdata=data.frame();currentfilestamp=currenttime
  }
  currentdata=rbind(currentdata,currentd)
}









