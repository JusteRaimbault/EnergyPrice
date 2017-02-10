
library(dplyr)
library(ggplot2)

setwd(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Models/DataCollection/test'))

#ids <- read.csv('data/test_all.csv',sep=";",header=FALSE)

data1 <- as.tbl(read.csv('data/full_20170111.csv',sep=';',header=TRUE))
data2 <- as.tbl(read.csv('data/full_20170114.csv',sep=';',header=TRUE))

# canadian prices
hist(data$price[data$price>50],breaks=1000)
summary(data$price[data$price>50])

# us prices
hist(data1$price[data$price<50],breaks=10000)

summary(data1$price[data1$price<50])
summary(data2$price[data2$price<50])
data2[data2$price==min(data2$price),]


g=ggplot(data[data$price<50,])
g+geom_density(aes(x=price),alpha=0.4)


# todo discard time-series with too few observations
