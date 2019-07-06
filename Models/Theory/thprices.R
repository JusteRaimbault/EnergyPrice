
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Theoretical'))

library(GA)

#'
#'
solvePrices <- function(unit_price,transportation_cost,num_stations,density,minPrice=0.001,maxPrice=10,iters=1000,costFunction=function(d){return(d^2)}){
  theta <- function(j,prices){
    return(((prices[((j+1)%%length(prices))+1]-prices[(j%%length(prices))+1])/((prices[((j+1)%%length(prices))+1]+prices[(j%%length(prices))+1])*transportation_cost) + 2*pi*j/num_stations + (2*pi*prices[((j+1)%%length(prices))+1])/((prices[((j+1)%%length(prices))+1]+prices[(j%%length(prices))+1])*num_stations))%%(2*pi))
  }
  
  objective <- function(prices){
    thetas=c();
    for(j in 1:(num_stations+1)){thetas[j]=theta(j-1,prices)}
    cumsum = 0
    for(j in 1:num_stations){
      thetamin = thetas[j];thetamax = thetas[j+1]
      densindmin = (floor(length(density)*thetamin/(2*pi))%%length(density))+1
      densindmax = (floor(length(density)*thetamax/(2*pi))%%length(density))+1
      pops = ifelse(densindmin<=densindmax,density[densindmin:densindmax],density[c(1:densindmax,densindmin:length(density))])
      pop = sum()*(2*pi/length(density))
      pj = prices[j];pjp = prices[((j+1)%%length(prices))+1];pjm=prices[((j-1)%%length(prices))+1]
      intprice = (2 / transportation_cost + 2*pi/num_stations)*(pj - unit_price)*((pjp*density[densindmax])/((pj + pjp)^2)+(pjm*density[densindmin])/((pj + pjm)^2))
      cumsum = cumsum + costFunction(pop - intprice)
    }
    return(cumsum)
  }
  
  optimized <- ga(type = "real-valued", fitness =  function(p) -objective(p),
           lower = rep(minPrice,num_stations), upper = rep(maxPrice,num_stations), 
           popSize = 50, maxiter = iters,parallel = 4)
  return(optimized)
}


uniformdensity = rep(1,10000)
uniformprices <- solvePrices(0.8,1,50,uniformdensity,minPrice=0.01,maxPrice=1.5,iters=2000)
plot(c(uniformprices@solution),type='l')

tentdensity = c(seq(1,50,by=0.1),seq(50,1,by=-0.1))
tentprices <- solvePrices(0.8,1,20,tentdensity,minPrice=0.01,maxPrice=100,iters=10000)
plot(c(tentprices@solution),type='l')




