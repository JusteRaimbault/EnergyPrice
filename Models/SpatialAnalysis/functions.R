
# functions

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




