
install.packages(c('raster', 'dismo')) # packages created by Robert Hijmans for handling rasters and species distribution modeling
install.packages("rgdal")
install.packages("XML")
install.packages("maps")
install.packages("rgbif")
install.packages("devtools")

#devtools::install_git('https://gitlab.com/master-degree-thesis/bioprov_client.git') #package created by Daniel Lins for recording and retrieving provenance metadata
devtools::install_local("BioProv_0.1.tar.gz")

library(raster)
library(dismo)
library(rJava)
library(rgdal)
library(BioProv)
library(jsonlite)
library(httr)
library(XML)
library(maps)


### INIT Global Variables
set_server_url("http://localhost:5000")


### PROVENANCE - INITIAL METADATA (RESEARCH PROJECT AND EXPERIMENT DOCUMENTATION)

ag_smith <- createAgentProvenance(uri = 'http://orcid.org/0000-0002-6420-1659', 
                                  name = 'Adam B. Smith', 
                                  identifier = 'Smith', 
                                  mbox = 'mailto:adam@earthskysea.org',
                                  seeAlso = 'http://www.earthskysea.org/')

research_project <-createEntityProvenance(uri = 'http://bioprov.poli.usp.br/projects/5', title = 'Testing methods for predicting mammalian species responses to 20th century climate change in California',
                                          entityType='ResearchProject', studyAreaDescription='Biodiversity', taxonomicCoverage = 'Mammalian species', spatial='Western United States',
                                          wasAttributedTo = ag_smith)

e_projectReport <-createEntityProvenance(uri = 'http://www.uc-ciee.org/Grinnellresurvey', title = 'Testing methods for predicting mammalian species responses to 20th century climate change in California',
                                         entityType='Publication', source='http://www.uc-ciee.org/downloads/Grinnellresurvey.Smith.pdf', created = '2011-03-31',
                                         wasDerivedFrom=research_project)

ag_daniel <- createAgentProvenance(uri = 'http://orcid.org/0000-0002-1244-9126', 
                                   name = 'Daniel Lins da Silva', 
                                   identifier = 'daniellins', 
                                   mbox = 'mailto:daniellins@usp.br',
                                   seeAlso = 'http://bioprov.poli.usp.br/students/6613529')

ag_andre <- createAgentProvenance(uri = 'http://orcid.org/0000-0003-4627-0244', 
                                  name = 'Andre Filipe de Moraes Batista', 
                                  identifier = 'andrefilipe', 
                                  mbox = 'mailto:andrefmb@usp.br',
                                  seeAlso = 'http://bioprov.poli.usp.br/students/8788438')

experiment <- createProvenanceBundle(uri = 'http://bioprov.poli.usp.br/bundle/31', 
                                     type='Experiment',
                                     title = 'Species Distribution Modeling of Urocitellus beldingi ',
                                     description = 'This work aims to show the relationship between physical aspects and the occurrences of Urocitellus beldingi in the Western US. We use the R programming language and DISMO Package to execute this experiment.',
                                     wasDerivedFrom = e_projectReport, 
                                     wasAttributedTo = list(ag_daniel,ag_andre), 
                                     date = date(), 
                                     creator = ag_daniel)

experiment = experiment[1]

#allSpeciesData <- read.csv('speciesRecords/Urocitellus_beldingi_training_modern_xy.csv', header=T)

#oBeech <- subset(allSpeciesData, SPECIES=='Urocitellus beldingi')


### PROVENANCE - ORIGIN OF OCCURRENCE DATASET (DATA PORTALS, SEARCH PARAMETERS, PARTIAL DATASETS AND DATA CLEANING ACTIVITIES)

e_arctos <- createEntityProvenance(experiment = experiment,
                                   uri = 'http://arctos.database.museum/', 
                                   identifier = 'ARCTOS',
                                   entityType = 'Software',
                                   title = 'Collaborative Collection Management Solution', 
                                   source = 'http://arctos.database.museum/', 
                                   description = 'Arctos is both a community and a comprehensive collection management information system. ')


e_manis <- createEntityProvenance(experiment = experiment,
                                  uri = 'http://manisnet.org/', 
                                  identifier = 'MANIS', 
                                  entityType = 'Software',
                                  title = 'Mammal Networked Information System', 
                                  source = 'http://manisnet.org/', 
                                  description = 'Information System developed by seventeen North American institutions with support from NSF.')


e_param_species <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/species', identifier = "species", entityType = 'InputParameter', type = "Text", value = "Urocitellus beldingi")
e_param_startdate <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/sdate', identifier = "startDate", entityType = 'InputParameter', type = "Text", value = "1970")
e_param_enddate <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/edate', identifier = "endDate", entityType = 'InputParameter', type = "Text", value = "2009")

e_occ_ARCTOS <- createEntityProvenance(experiment = experiment, 
                                       uri = 'http://bioprov.poli.usp.br/dataset/Urocitellus_beldingi_arctos', 
                                       identifier = 'occ_modern_arctos', 
                                       entityType = 'Dataset',
                                       scientificName = 'Urocitellus beldingi',
                                       title = 'Occurrence file of the Urocitellus_beldingi species',
                                       numberOfRecords = '111',
                                       source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/speciesRecords/Urocitellus_beldingi_Arctos.csv')

e_occ_MANIS <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/dataset/Urocitellus_beldingi_manis',  
                                      identifier = 'occ_modern_manis', 
                                      entityType = 'Dataset',
                                      scientificName = 'Urocitellus beldingi',
                                      title = 'Occurrence file of the Urocitellus_beldingi species',
                                      numberOfRecords = '174',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/speciesRecords/Urocitellus_beldingi_Manis.txt')

act_dataRetrieving1 <- createActivityProvenance(experiment = experiment, 
                                                uri = 'http://bioprov.poli.usp.br/step1_retrieving', 
                                                activityType = 'Acquisition',
                                                title = 'Retrieving Occurrence Records from ARCTOS Portal',
                                                decisions = 'Used presence-only records',
                                                used = list(e_arctos, e_param_species, e_param_startdate, e_param_enddate), 
                                                generated = e_occ_ARCTOS)

act_dataRetrieving2 <- createActivityProvenance(experiment = experiment, 
                                                uri = 'http://bioprov.poli.usp.br/step2_retrieving', 
                                                activityType = 'Acquisition',
                                                title = 'Retrieving Occurrence Records from MANIS Portal', 
                                                decisions = 'Used presence-only records',
                                                used = list(e_manis, e_param_species, e_param_startdate, e_param_enddate), 
                                                generated = e_occ_MANIS)


e_occ_ready <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/dataset/Urocitellus_beldingi_xy',  
                                      identifier = 'occ_modern_training', 
                                      activityType = 'Dataset',
                                      scientificName = 'Urocitellus beldingi',
                                      title = 'Occurrence file of the Urocitellus_beldingi species.',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/speciesRecords/Urocitellus_beldingi_training_modern_xy.csv',
                                      numberOfRecords = '32',
                                      wasDerivedFrom = list(e_occ_MANIS, e_occ_ARCTOS))


act_dataMerging <- createActivityProvenance(experiment = experiment,
                                            uri = 'http://bioprov.poli.usp.br/step3_merging', 
                                            activityType = 'Combination',
                                            title = 'Merging Occurrence Records from ARCTOS and MANIS', 
                                            used = list(e_occ_ARCTOS, e_occ_MANIS))


act_dataCleaning <- createActivityProvenance(experiment = experiment, 
                                             uri = 'http://bioprov.poli.usp.br/step4_cleaning', 
                                             activityType = 'Preparation',
                                             title = 'Cleaning Occurrence Records based on criteria described in the file.',
                                             description = 'Cleaning Criteria: https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/ex1_oBeech_modern_randomBg_r/data_cleaning_criteria.txt',
                                             wasInformedBy = act_dataMerging,
                                             generated = e_occ_ready)


#predStackModern <- stack(
#	raster('westernUsClimate_modern/BIO02.asc'),
#	raster('westernUsClimate_modern/BIO05.asc'),
#	raster('westernUsClimate_modern/BIO06.asc'),
#	raster('westernUsClimate_modern/BIO07.asc'),
#	raster('westernUsClimate_modern/BIO03.asc'),
#	raster('westernUsClimate_modern/BIO13.asc'),
#	raster('westernUsClimate_modern/BIO14.asc'),
#	raster('westernUsClimate_modern/BIO18.asc'),
#	raster('westernUsClimate_modern/BIO15.asc')
#)

#projection(predStackModern) <- CRS('+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0') # coodinate reference system for WGS84

#plot(predStackModern) # plot predictors


### PROVENANCE - ORIGIN OF ENVIRONMENTAL LAYERS (PREDICTORS AND PRISM DATA PORTAL)

ag_prism <- createAgentProvenance(experiment = experiment,
                                  uri = 'http://www.prism.oregonstate.edu/', 
                                  name = 'PRISM Climate Group', 
                                  identifier = 'PRISM', 
                                  homepage = 'http://www.prism.oregonstate.edu/',
                                  seeAlso = 'http://www.cefa.dri.edu/Westmap/Westmap_home.php?page=Prism101.php')

e_env_bio02 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio02',
                                      identifier = 'bioclim_bio02', 
                                      type = 'StillImage',
                                      entityType = 'Map',
                                      title = 'Mean diurnal temperature range',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO02.asc',
                                      description = 'Resolution=800m',  
                                      wasAttributedTo = ag_prism)

e_env_bio05 <- createEntityProvenance(experiment = experiment, 
                                      identifier = 'bioclim_bio05', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio05',
                                      title = 'Maximum temperature of the warmest month',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO05.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)


e_env_bio06 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio06',
                                      identifier = 'bioclim_bio06', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Minimum temperature of the coldest month',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO06.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)

e_env_bio07 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio07',
                                      identifier = 'bioclim_bi07', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Temperature annual range (BIO05-BIO06)',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO07.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)

e_env_bio03 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio03',
                                      identifier = 'bioclim_bi03', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Isothermality (BIO2/BIO07)',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO03.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)

e_env_bio13 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio13',
                                      identifier = 'bioclim_bi13', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Precipitation of Wettest Month',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO13.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)

e_env_bio14 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio14',
                                      identifier = 'bioclim_bi14', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Precipitation of Driest Month',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO14.asc',
                                      wasAttributedTo = ag_prism)

e_env_bio18 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio18',
                                      identifier = 'bioclim_bi18', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Precipitation of Warmest Quarter',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO18.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)

e_env_bio15 <- createEntityProvenance(experiment = experiment, 
                                      uri = 'http://bioprov.poli.usp.br/map_bioclim_bio15',
                                      identifier = 'bioclim_bi15', 
                                      entityType = 'DataResource',
                                      entityFormat = 'RasterFile',
                                      title = 'Precipitation Seasonality (Coefficient of Variation)',
                                      source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/westernUsClimate_modern/BIO15.asc',
                                      description = 'Resolution=800m', 
                                      wasAttributedTo = ag_prism)


#dir.create('ex1_oBeech_modern_randomBg_r', recursive=TRUE) 

start.time <- Sys.time()
Sys.sleep(2)
#modelBasic <- maxent(
#	x=predStackModern,
#	p=oBeech[ , c('LONG_WGS84', 'LAT_WGS84')],
#	path=paste(getwd(), '/ex1_oBeech_modern_randomBg_r', sep=''),
#	args=c(
#		'randomtestpoints=30',
#		'betamultiplier=1',
#		'linear=true',
#		'quadratic=true',
#		'product=true',
#		'threshold=true',
#		'hinge=true',
#		'threads=2',
#		'responsecurves=true',
#		'jackknife=true',
#		'askoverwrite=false'
#	)
#)
end.time <- Sys.time()
time.taken <- end.time - start.time

# look at model output (HTML page)
#modelBasic # note that unlike running Maxent from the program the prediction raster is not automatically created, so we have to do that in the next step


### PROVENANCE - DATA ANALYSIS (SOFTWARES, MAXENT PARAMETERS, MODEL)

e_param_maxent1 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/rtp', identifier = "randomtestpoints", entityType = "InputParameter", value = "30")
e_param_maxent2 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/bm', identifier = "betamultiplier", entityType = "InputParameter", value = "1")
e_param_maxent3 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/linear', identifier = "linear", entityType = "InputParameter", value = "true")
e_param_maxent4 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/quad', identifier = "quadratic", entityType = "InputParameter", value = "true")
e_param_maxent5 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/product', identifier = "product", entityType = "InputParameter", value = "true")
e_param_maxent6 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/thld', identifier = "threshold", entityType = "InputParameter", value = "true")
e_param_maxent7 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/hinge', identifier = "hinge", entityType = "InputParameter", value = "true")
e_param_maxent8 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/threads', identifier = "threads", entityType = "InputParameter", value = "2")
e_param_maxent9 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/rc', identifier = "responsecurves", entityType = "InputParameter", value = "true")
e_param_maxent10 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/jn', identifier = "jackknife", entityType = "InputParameter", value = "true")
e_param_maxent11 <- createEntityProvenance(experiment = experiment, uri = 'http://bioprov.poli.usp.br/param/aow', identifier = "askoverwrite", entityType = "InputParameter", value = "false")


### Provenance Record - Agents
ag_robertschapire <- createAgentProvenance(uri = 'http://dbpedia.org/resource/Robert_Schapire', 
                                      type = 'Institution',
                                      name = 'Robert Schapire', 
                                      identifier = 'Robert_Schapire', 
                                      homepage = 'http://dbpedia.org/resource/Robert_Schapire', 
                                      description = 'Robert Elias Schapire is an American computer scientist, former David M. Siegel 83 Professor in the computer science department at Princeton University, and has recently moved to Microsoft Research. His primary specialty is theoretical and applied machine learning. His work led to the development of the boosting ensemble algorithm used in machine learning. Together with Yoav Freund, he invented the AdaBoost algorithm in 1996. They both received the prize in 2003 for this work.')


### Provenance Record - Agents
ag_robertjhijmans <- createAgentProvenance(uri = 'http://desp.ucdavis.edu/people/robert-j-hijmans', 
                                           type = 'Institution',
                                           name = 'Environmental Science & Policy', 
                                           identifier = 'worldclim', 
                                           homepage = 'http://desp.ucdavis.edu/people/robert-j-hijmans', 
                                           description = 'International Agricultural Development Robert Hijmans studies international agricultural development and human health. He is particularly interested in the role of biodiversity in agriculture, and in climate change. He specializes in spatial analysis, ecological modeling and geo-informatics.')


e_dismo <- createEntityProvenance(experiment = experiment, 
                                  uri = 'https://cran.r-project.org/web/packages/dismo/', 
                                  identifier = 'DISMO', 
                                  entityType = 'software',
                                  title = 'dismo: Species Distribution Modeling',
                                  description = 'Functions for species distribution modeling, that is, predicting entire geographic distributions form occurrences at a number of sites and the environment at these sites.',
                                  source = 'https://cran.r-project.org/src/contrib/dismo_1.1-1.tar.gz',
                                  wasAttributedTo = ag_robertjhijmans)

e_maxent <- createEntityProvenance(experiment = experiment, 
                                   uri = 'https://www.cs.princeton.edu/~schapire/maxent/',
                                   identifier = 'MAXENT', 
                                   entityType = 'Software',
                                   title = 'MAXENT Software',
                                   isVersionOf = '3.3.3',
                                   source = 'https://www.cs.princeton.edu/~schapire/maxent/',
                                   description = 'http://homepages.inf.ed.ac.uk/lzhang10/maxent.html',
                                   wasAttributedTo = ag_robertschapire)

e_rstudio <- createEntityProvenance(experiment = experiment, 
                                   uri = 'http://www.rstudio.com/products/rstudio/',
                                   identifier = 'RSTUDIO', 
                                   entityType = 'Software',
                                   title = 'RStudio Software',
                                   isVersionOf = '0.99.893',
                                   source = 'http://www.rstudio.com/products/rstudio/download/',
                                   description = 'http://www.rstudio.com/products/rstudio/')

e_model <- createEntityProvenance(experiment = experiment, 
                                       uri = 'http://bioprov.poli.usp.br/model/Urocitellus_beldingi',                                   
                                       identifier = 'SDMModel', 
                                       entityType = 'DataResource',
                                       entityFormat = 'Archive',  
                                       title = 'Resulting Model from MAXENT',
                                       source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/tree/master/ex1_oBeech_modern_randomBg_r/',
                                       wasAttributedTo = ag_daniel, ag_andre)


act_dataAnalysing <- createActivityProvenance(experiment = experiment, 
                                             uri = 'http://bioprov.poli.usp.br/step5_analysing', 
                                             activityType = 'Analysis',
                                             title = 'Species Distribution Modeling',
                                             decisions = 'From 19 BIOCLIM variables, were kept those are expected to be biologically meaningful to the species and that had cross-correlations >-0.7 and <0.7 (Tingley and Herman 2009)',
                                             #startedAtTime = as.character.Date(start.time),
                                             #endedAtTime = as.character.Date(end.time),
                                             hasDuration = as.character.Date(time.taken),
                                             computationalArchitectureUsed = 'notebook core i5, 8Gb RAM, SSD 256Gb',
                                             used = list(e_dismo, e_maxent, e_rstudio, e_occ_ready, 
                                                        e_env_bio02, e_env_bio03, e_env_bio05, e_env_bio06, e_env_bio07, e_env_bio13, e_env_bio14, e_env_bio15, e_env_bio18,
                                                        e_param_maxent1, e_param_maxent2, e_param_maxent3, e_param_maxent4, e_param_maxent5, e_param_maxent6, e_param_maxent7, 
                                                        e_param_maxent8, e_param_maxent9, e_param_maxent10, e_param_maxent11),
                                             generated = e_model)
                                                        
start.time <- Sys.time()
Sys.sleep(2)
#mapModernBasic <- predict(
#	object=modelBasic,
#	x=predStackModern,
#	filename=paste(getwd(), '/ex1_oBeech_modern_randomBg_r/Urocitellus_beldingi_map_modern', sep=''),
#	na.rm=TRUE,
#	format='GTiff',
#	overwrite=TRUE,
#	progress='text'
#)
end.time <- Sys.time()
time.taken <- end.time - start.time

# look at map
#plot(mapModernBasic, main='Modern')

# add species' records
#points(oBeech[ , c('LONG_WGS84', 'LAT_WGS84')])

# overlay a shapefile of western states
#library(rgdal)
#states <- readOGR('shapefiles', 'westernUs_wgs84') 
#plot(states, add=TRUE)


### PROVENANCE - DATA PREDICTION AND VISUALIZATION (SOFTWARES, MAXENT PARAMETERS, MODEL)

e_modelmap <- createEntityProvenance(experiment = experiment, 
                                     uri = 'http://bioprov.poli.usp.br/mapmodels/Urocitellus_beldingi',  
                                     identifier = 'SDM_Map', 
                                     type = 'StillImage',
                                     entityType = 'DataResource',
                                     entityFormat = 'RasterFile',
                                     source = 'https://gitlab.com/daniellins/SDM_Urocitellus_beldingi/raw/master/ex1_oBeech_modern_randomBg_r/Urocitellus_beldingi_map_modern.tif',
                                     title = 'Raster Map of Species Distribution Modeling',
                                     wasDerivedFrom = e_model,
                                     wasAttributedTo = list(ag_daniel, ag_andre))

e_modelmap = e_modelmap[1]

act_dataPrediction <- createActivityProvenance(experiment = experiment, 
                                               uri = 'http://bioprov.poli.usp.br/step6_prediction', 
                                               activityType = 'Prediction',
                                               description = 'Prediction based on the Distribution Modeling and modern scenario',
                                               title = 'Prediction based on the Distribuion Modeling and ', 
                                               #startedAtTime = as.character.Date(start.time),
                                               #endedAtTime = as.character.Date(end.time),
                                               hasDuration = as.character.Date(time.taken),
                                               computationalArchitectureUsed = 'notebook core i5, 8Gb RAM, SSD 256Gb',
                                               used = e_model,
                                               generated = e_modelmap)

current_working_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(current_working_dir)

current_working_dir

getProvenanceOfEntityNew(uri = experiment, folder = current_working_dir, format = 'png')
getProvenanceOfEntityNew(uri = experiment, folder = current_working_dir, format = 'svg')
getProvenanceOfEntityNew(uri = experiment, folder = current_working_dir, format = 'rdf')

getProvenanceOfEntityNew(uri = e_modelmap, folder = current_working_dir, format = 'png')
getProvenanceOfEntityNew(uri = e_modelmap, folder = current_working_dir, format = 'svg')
getProvenanceOfEntityNew(uri = e_modelmap, folder = current_working_dir, format = 'rdf')

getProvenanceOfBundle(uri = experiment, folder = current_working_dir, format = 'png')
getProvenanceOfBundle(uri = experiment, folder = current_working_dir, format = 'svg')
getProvenanceOfBundle(uri = experiment, folder = current_working_dir, format = 'rdf')
getProvenanceOfBundle(uri = experiment, folder = current_working_dir, format = 'json')
getProvenanceOfBundle(uri = experiment, folder = current_working_dir, format = 'report')