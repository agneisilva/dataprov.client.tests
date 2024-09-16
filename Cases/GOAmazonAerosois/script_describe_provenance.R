#Author: Agnei de Carvalho Silva

install.packages("raster")
install.packages("rgdal")
install.packages("dismo")
install.packages("XML")
install.packages("maps")
install.packages("rgbif")
install.packages("devtools")
devtools::install_local("BioProv_0.1.tar.gz")

library(raster)
library(rgdal)
library(dismo)
library(XML)
library(maps)
library(BioProv)
library(jsonlite)
library(httr)
library(rgbif)

set_server_url("http://localhost:5000")


ag_daniel <- createAgentProvenance(uri = 'http://bioprov.poli.usp.br/agents/6613529', 
                                  type = 'Researcher',
                                  name = 'Daniel Lins da Silva', 
                                  identifier = 'http://bioprov.poli.usp.br/agents/6613529', 
                                  mbox = 'mailto:daniellins@usp.br',
                                  seeAlso = 'http://lattes.cnpq.br/6502450550040226')

ag_andre <- createAgentProvenance(uri = 'http://bioprov.poli.usp.br/agents/8788438', 
                                  type = 'Researcher',
                                  name = 'Andre Filipe de Moraes Batista', 
                                  identifier = 'http://bioprov.poli.usp.br/agents/8788438', 
                                  mbox = 'mailto:andrefmb@usp.br',
                                  seeAlso = 'http://lattes.cnpq.br/2015345575533420')


### Provenance Record - Bundle of Experiment
bundle <- createProvenanceBundle(uri = 'http://bioprov.poli.usp.br/bundle/2', 
                                 type = 'Experiment',
                                 title = 'Habitat Adequability of Ziziphus juazeiro specie in the Brazilian Semi-arid Region through Ecological Niche Modeling technique',
                                 description = 'This work aims to show the relationship between physical aspects and the occurrence of endemic species of the Brazilian semi-arid 
region through ecological niche modeling technique aided by remote sensing products. It is an interdisciplinary project, integrating Brazilian and Spanish research centers in the 
study fields of biogeography, remote sensing, statistics and computer science. We use the R programming language and DISMO Package to execute this experiment.', 
                                 wasAttributedTo = list(ag_daniel,ag_andre),
                                 source = 'https://gitlab.com/daniellins/Prov_ENM_Ziziphus/',
                                 date = date(), 
                                 creator = ag_daniel)


#source(paste(current_working_dir, "/SDM_R_functions.R", sep = ""))

#occ <- gbifDataSearchingAndPreparing("Ziziphus joazeiro", country = "BR",hasCoordinate = TRUE,hasGeospatialIssue = FALSE)

### Provenance Record - Agents
ag_gbif <- createAgentProvenance(uri = 'http://gbif.org/', 
                                 type = 'Institution',
                                 name = 'Global Biodiversity Information Facility', 
                                 identifier = 'GBIF', 
                                 homepage = 'http://gbif.org/', 
                                 description = 'The Global Biodiversity Information Facility (GBIF) is an international open data infrastructure.')


### Provenance Record - Agents
ag_ropensci <- createAgentProvenance(uri = 'http://ropensci.org/', 
                                 type = 'Institution',
                                 name = 'ROpenSci', 
                                 identifier = 'ropensci.org', 
                                 homepage = 'http://ropensci.org/', 
                                 description = 'Help develop R packages for the sciences via community driven learning, review and maintenance of contributed software in the R ecosystem')


### Provenance Record - Agents
ag_worldclim <- createAgentProvenance(uri = 'http://www.worldclim.org/', 
                                  type = 'Institution',
                                  name = 'Environmental Layers from WorldClim Website.', 
                                  identifier = 'worldclim', 
                                  homepage = 'http://www.worldclim.org/', 
                                  description = 'Environmental Layers from WorldClim Website.')


### Provenance Record - Agents
ag_robertjhijmans <- createAgentProvenance(uri = 'http://desp.ucdavis.edu/people/robert-j-hijmans', 
                                      type = 'Institution',
                                      name = 'Environmental Science & Policy', 
                                      identifier = 'worldclim', 
                                      homepage = 'http://desp.ucdavis.edu/people/robert-j-hijmans', 
                                      description = 'International Agricultural Development Robert Hijmans studies international agricultural development and human health. He is particularly interested in the role of biodiversity in agriculture, and in climate change. He specializes in spatial analysis, ecological modeling and geo-informatics.')


### Provenance Record - Input Data/ Input Parameters and Output Data (Entities)
e_rgbif <- createEntityProvenance(bundle = bundle[1], 
                                  identifier = "rgbif", 
                                  type = "Software", 
                                  uri = 'http://cran.rstudio.com/web/packages/rgbif',
                                  title = 'rgibf',
                                  description = 'Interface to the Global Biodiversity Information Facility API',
                                  source = 'http://cran.rstudio.com/web/packages/rgbif/', 
                                  wasAttributedTo = ag_ropensci)

e_gbifDataSearchingAndPreparing <- createEntityProvenance(bundle = bundle[1], 
                                              identifier = "acquisitionAndPreparationFunction", 
                                              type = "Software", 
                                              uri = 'https://gitlab.com/daniellins/R_functions/blob/master/SDM_R_functions.R',
                                              title = 'GBIF data acquisition and preparation function',
                                              source = 'https://gitlab.com/daniellins/R_functions/blob/master/SDM_R_functions.R', 
                                              wasAttributedTo = ag_daniel,
                                              wasDerivedFrom = e_rgbif)

e_param_species <- createEntityProvenance(bundle = bundle[1], uri = 'http://bioprov.poli.usp.br/param/species', identifier = 'species', type = 'InputParameter', value = 'Ziziphus joazeiro')
e_param_country <- createEntityProvenance(bundle = bundle[1], uri = 'http://bioprov.poli.usp.br/param/country', identifier = 'country', type = 'InputParameter', value = 'BR')
e_param_coordinate <- createEntityProvenance(bundle = bundle[1], uri = 'http://bioprov.poli.usp.br/param/hasCoordinate', identifier = 'hasCoordinate', type = "InputParameter", value = 'TRUE')
e_param_geospatial <- createEntityProvenance(bundle = bundle[1], uri = 'http://bioprov.poli.usp.br/param/hasGeospatialIssue', identifier = 'hasGeospatialIssue', type = 'InputParameter', value = 'FALSE')

e_dataset <- createEntityProvenance(bundle = bundle[1], 
                                       identifier = 'http://bioprov.poli.usp.br/occ_ziziphus_juazeiro',
                                       type = 'Dataset',
                                       uri = 'http://bioprov.poli.usp.br/occ_ziziphus_juazeiro',
                                       title = 'Occurrence Dataset of Ziziphus juazeiro in Brazil',
                                       wasAttributedTo = ag_gbif)

### Provenance Record - Data Preparing Activity (used Input Data/Parameters, generated Output Data)
act_dataSearching <- createActivityProvenance(bundle = bundle[1], 
                                              uri = 'http://bioprov.poli.usp.br/acquisition', 
                                              type = 'Acquisition', 
                                              title = 'Retrieving and Preparing Occurrence Records from GBIF', 
                                              used = list(e_gbifDataSearchingAndPreparing, e_param_species, e_param_country, e_param_coordinate, e_param_geospatial), 
                                              generated = e_dataset)
 


#map()
#points(occ$Longitude, occ$Latitude, col="red", pch=19, xlab="Longitude", ylab="Latitude")
#plot(occ$Longitude, occ$Latitude,xlim=c(-90,-25),ylim=c(-60,20),col="red",pch=19,xlab="Longitude",ylab="Latitude")
#map(add=T)

#files <- list.files(paste(current_working_dir, "/clima/", sep = ""), pattern='grd', full.names=TRUE)
#files
#predictors <- stack(files)
#predictors
#names(predictors)
#plot(predictors, main=NA)

#zizi.coord <- data.frame(occ$Longitude, occ$Latitude)
#bio.ziziphus <- bioclim(predictors,zizi.coord)

### Provenance Record - Input Data/ Input Parameters and Output Data (Entities)
e_environmentalLayers <- createEntityProvenance(bundle = bundle[1], 
                                                uri = 'http://bioprov.poli.usp.br/bioclim_env_layers',
                                                identifier = 'http://bioprov.poli.usp.br/bioclim_env_layers',
                                                type = 'RasterLayer', 
                                                title = 'Worldclim Environmental Layers', 
                                                source = 'https://gitlab.com/daniellins/Prov_ENM_Ziziphus/tree/master/clima', 
                                                wasAttributedTo = ag_worldclim,
                                                description = "Environmental Layers from WorldClim Website.")

e_enmAlgorithm <- createEntityProvenance(bundle = bundle[1], 
                                         identifier = "Bioclim",
                                         type = "Software",
                                         uri = "http://cran.r-project.org/web/packages/dismo",
                                         title = "BIOCLIM implementation of DISMO package",
                                         hasVersion = '1.0-15',
                                         wasAttributedTo = ag_robertjhijmans,
                                         source = "http://cran.r-project.org/src/contrib/dismo_1.0-15.tar.gz",
                                         seeAlso = list('http://finzi.psych.upenn.edu/library/dismo/html/bioclim.html','http://cran.r-project.org/web/packages/dismo/dismo.pdf'))

e_resultModeling <- createEntityProvenance(bundle = bundle[1], 
                                           identifier = "ZiziphusModel",
                                           type = "Model",
                                           title = 'Species Distribution Model of the Ziziphus juazeiro', 
                                           wasAttributedTo = ag_daniel)


### Provenance Record - ENM Activity
act_dataModeling <- createActivityProvenance(bundle = bundle[1], 
                                             uri = 'http://bioprov.poli.usp.br/analysing', 
                                             type = 'Analysis', 
                                             title = 'Species Distribution Modeling with the Bioclim Algorithm', 
                                             used = list(e_dataset, e_environmentalLayers, e_enmAlgorithm), 
                                             generated = e_resultModeling)


#plot(bio.ziziphus)
#View(zizi.coord)

#detach("package:stats")
#map.ziziphus <- predict(bio.ziziphus, predictors)
#plot(map.ziziphus)
#map(add=T)

### Provenance Record - Input Data/ Input Parameters and Output Data (Entities)
e_MapresultModeling <- createEntityProvenance(bundle = bundle[1],
                                              identifier = "ZiziphusModelProjection",
                                              type = 'rasterLayer',
                                              title = 'Species Distribution Model Projection',
                                              description = 'Species Distribution Model projected on the map',
                                              wasAttributedTo = ag_daniel, 
                                              wasDerivedFrom = e_resultModeling)

e_plotFunction <- createEntityProvenance(bundle = bundle[1], 
                                             identifier = "Plot",
                                             type = "Software",
                                             uri = "http://cran.r-project.org/web/packages/raster#plot",
                                             title = "Plot function of the RASTER package from R Programming Language",
                                             hasVersion = '2.5-2',
                                             source = "http://cran.r-project.org/src/contrib/raster_2.5-2.tar.gz",
                                             wasAttributedTo = ag_robertjhijmans,
                                             seeAlso ='http://cran.r-project.org/web/packages/raster/raster.pdf')

### Provenance Record - Data Model Projecting Activity
act_dataPlotting <- createActivityProvenance(bundle = bundle[1],
                                          uri = 'http://bioprov.poli.usp.br/projecting', 
                                          type = 'Projecting', 
                                          title = 'Projecting model on a map',
                                          used = list(e_plotFunction, e_resultModeling), 
                                          generated = e_MapresultModeling)



#biozizi.rec<-reclassify(map.ziziphus,c(0,0.05,0.25, 0.051,0.1,0.5, 0.11,0.4,1))
#plot(biozizi.rec)
#map(add=T)

### Provenance Record - Input Data/ Input Parameters and Output Data (Entities)
e_FinalresultModeling <- createEntityProvenance(bundle = bundle[1],
                                                uri = 'http://bioprov.poli.usp.br/models/ziziphusJuazeiro',
                                                identifier = 'http://bioprov.poli.usp.br/models/ziziphusJuazeiro',
                                                type = 'rasterLayer',
                                                title = 'Map with the final result of SDM experiment',
                                                source = 'https://gitlab.com/daniellins/R_functions/blob/master/ENM_result_ziziphus.jpg',
                                                wasAttributedTo = list(ag_daniel, ag_andre),
                                                wasDerivedFrom = e_MapresultModeling)

### Provenance Record - Map Improvement Activity
act_dataImprovement <- createActivityProvenance(bundle = bundle[1],
                                              uri = 'http://bioprov.poli.usp.br/Improvement', 
                                              type = 'Improvement', 
                                              title = 'Map Improvement using Reclassify function of RASTER package',
                                              seeAlso = 'https://www.rdocumentation.org/packages/raster/versions/2.5-2/topics/reclassify',
                                              used = e_MapresultModeling, 
                                              generated = e_FinalresultModeling)

current_working_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(current_working_dir)

print(current_working_dir)

getProvenanceOfEntityNew(uri = e_FinalresultModeling[1], folder = current_working_dir, format = 'png')
getProvenanceOfEntityNew(uri = e_FinalresultModeling[1], folder = current_working_dir, format = 'rdf')
getProvenanceOfEntityNew(uri = e_FinalresultModeling[1], folder = current_working_dir, format = 'svg')

getProvenanceOfBundle(uri = "http://bioprov.poli.usp.br/bundle/2", folder = current_working_dir, format = 'png')
getProvenanceOfBundle(uri = "http://bioprov.poli.usp.br/bundle/2", folder = current_working_dir, format = 'svg')
getProvenanceOfBundle(uri = "http://bioprov.poli.usp.br/bundle/2", folder = current_working_dir, format = 'rdf')
getProvenanceOfBundle(uri = "http://bioprov.poli.usp.br/bundle/2", folder = current_working_dir, format = 'json')
getProvenanceOfBundle(uri = "http://bioprov.poli.usp.br/bundle/2", folder = current_working_dir, format = 'report')