
###
# GWR analysis

setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/SpatialAnalysis'))

library(dplyr)
library(rgdal)

library(GWmodel)

# socio-economic variables
countysocioeco <- readOGR(dsn=paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/census/bea009p020_nt00355'),layer = 'bea009p020',stringsAsFactors = FALSE)





