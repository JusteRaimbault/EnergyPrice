
library(dplyr)
library(ggplot2)
library(rgdal)

setwd(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Models/SpatialAnalysis/'))

data1 <- as.tbl(read.csv(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cldata/cl1484114402_data.csv'),sep=";",stringsAsFactors = FALSE))

addresses <- as.tbl(read.csv(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Models/DataCollection/python/loc/adresses.csv'),sep=";",stringsAsFactors = FALSE,quote = ""))

# must do some trim on states / localities


# cities shapefile
cities <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/cb_2015_us_zcta510_500k'),layer = 'cb_2015_us_zcta510_500k',stringsAsFactors = FALSE)

# states
states <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/cb_2015_us_state_500k'),layer = 'cb_2015_us_state_500k',stringsAsFactors = FALSE)


addresses[addresses$code=="02072",]
cities@data[cities@data$ZCTA5CE10=="02072",]
plot(SpatialPolygons(list(cities@polygons[[10605]]),proj4string = cities@proj4string))


## map by state


