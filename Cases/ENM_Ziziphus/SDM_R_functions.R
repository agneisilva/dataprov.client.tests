
gbifDataSearchingAndPreparing <-function(species, country=NULL, hasCoordinate=TRUE, hasGeospatialIssue=FALSE){
  
  resultRaw <-occ_search(country = country, scientificName=species, hasCoordinate = hasCoordinate, hasGeospatialIssue=hasGeospatialIssue, limit = 5000)
  resultReady <- dataPreparing(resultRaw,c("name","decimalLatitude","decimalLongitude"),c("Species","Latitude","Longitude"))
  return(resultReady)
  
}

dataPreparing <-function(dataset, selectedCols, colNames){
  result <- dataset$data[selectedCols]
  colnames(result) <- colNames
  return(result)
}