

OccurrencesCleaning <- function(data, scientificName){

  cleanedData <- subset(ocorr,ocorr$TaxonName== scientificName)
  head(cleanedData)
  class(cleanedData$Latitude)
  cleanedData$Latitude <- as.numeric((as.character(cleanedData$Latitude)))
  cleanedData <- subset(cleanedData, !is.na(cleanedData$Latitude) & !is.na(cleanedData$Longitude))

}