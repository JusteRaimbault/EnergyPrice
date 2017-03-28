
# functions


mapCounties<-function(data,variable,filename,title,legendtitle){
  extent <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/processed/processed_20170320/gis'),layer = 'extent',stringsAsFactors = FALSE)
  
  #png(file=paste0(resdir,'average_regular_march_map.png'),width=10,height=6,units='cm',res=600)
  pdf(file=paste0(resdir,filename,'.pdf'),width=10,height=5.5)#paper='a4r')
  par(mar = c(0.4,0.4,2,0.4))
  
  
  layoutLayer(title = title, sources = "",
              author = "", col = "grey", coltitle = "black", theme = NULL,
              bg = NULL, scale=NULL , frame = TRUE, north = F, south = FALSE,extent=extent)
  
  breaks=classIntervals(sdata[,variable],20)
  
  plot(states, border = NA, col = "white",add=T)
  cols <- carto.pal(pal1 = "green.pal",n1 = 10, pal2 = "red.pal",n2 = 10)
  choroLayer(spdf = counties,spdfid = "GEOID",
             df = data,dfid = 'countyid',
             var=variable,
             col=cols,breaks=breaks$brks,
             add=TRUE,lwd = 0.01,
             legend.pos = "n"
  )
  legendChoro(pos = "left",title.txt = legendtitle,
              title.cex = 0.8, values.cex = 0.6, breaks$brks, cols, cex = 0.7,
              values.rnd = 2, nodata = TRUE, nodata.txt = "No data",
              nodata.col = "white", frame = FALSE, symbol = "box"
  )
  plot(states,border = "grey20", lwd=0.75, add=TRUE)
  
  dev.off()
  
}


centroid<-function(polygons){
  coords=matrix(0,0,2)
  for(j in 1:length(polygons@Polygons)){
    coords=rbind(coords,polygons@Polygons[[j]]@coords)
  }
  return(colSums(coords)/nrow(coords))
}


weightMatrix<-function(decay,layer){
  n=length(layer)
  points=matrix(0,n,2)
  for(i in 1:n){
    points[i,]=centroid(layer@polygons[[i]])
  }
  d = spDists(points,longlat=TRUE)
  w = exp(-d/decay)
  diag(w)<-0
  return(w)
}


autocorr<-function(x,w,m){
  n=length(x)
  cx = x - mean(x)
  cxvec=matrix(cx,nrow=n,ncol=1)
  normalization = (w%*%matrix(rep(1,n),nrow=n,ncol=1))*(m%*%(cxvec*cxvec))
  return(((matrix(data = rep(cx,n),ncol = n,nrow = n,byrow = FALSE)*w)%*%cxvec)/normalization)
}

#d[24,2548]
#plot(counties)
#plot(counties[c(24,2548),],col='blue',add=TRUE)
# TODO : check in mile 4158 if consistent

# 4584 km
# miles (google maps by road) 3440 miles = 5500km
# : great circle distance, ok ?








