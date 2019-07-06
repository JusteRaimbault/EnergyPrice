
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Theoretical'))

library(GA)

#'
#'
solvePrices <- function(unit_price,transportation_cost,num_stations,density){
  theta <- function(j,prices){
    return((prices[j+1]-prices[j])/((prices[j+1]+prices[j])*transportation_cost) + 2*pi*j/num_stations + (2*pi*prices[j+1])/((prices[j+1]+prices[j])*num_stations))
  }
  
    
}

