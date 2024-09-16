install.packages("raster")
install.packages("rgdal")
install.packages("dismo")
install.packages("XML")
install.packages("maps")
install.packages("rgbif")
install.packages("devtools")
install.packages("mondate")
#devtools::install_git("https://gitlab.com/master-degree-thesis/bioprov_client.git", branch = "master")
#detach("package:BioProv", unload=TRUE)
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
library(mondate)


### Initial Records - Researchers involved, and Provenance Bundle (used to describe this simulation)

current_working_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(current_working_dir)
set_server_url("http://localhost:5000")


### Provenance Record - Agents

ag_daniel <- createAgentProvenance(uri = 'http://poli.usp.br/student/6613529', 
                                   type = 'Researcher',
                                   name = 'Daniel Lins da Silva', 
                                   identifier = 'daniellins', 
                                   mbox = 'mailto:daniellins@usp.br',
                                   seeAlso = 'http://lattes.cnpq.br/6502450550040226')

ag_andre <- createAgentProvenance(uri = 'http://poli.usp.br/student/8788438',
                                  type = 'Researcher',
                                  name = 'Andre Filipe de Moraes Batista', 
                                  identifier = 'andrefilipe', 
                                  mbox = 'mailto:andrefmb@usp.br',
                                  seeAlso = 'http://lattes.cnpq.br/2015345575533420')


### Provenance Record - Bundle of Monitoring Simulation
bundle <- createProvenanceBundle(uri = 'http://bioprov.org/bundle/DS-IoT_1', 
                                 title = 'Simulation of Environmental Monitoring Process',
                                 description = 'This work aims to show the use of a provenance-based approach to record the provenance of data and process involved in this simulation.', 
                                 wasAttributedTo = list(ag_daniel,ag_andre), 
                                 date = date(), 
                                 creator = ag_daniel)[1]

### Beginning Simulation


#rawData <- DataCapture(EletronicEquipment, Settings)


### Provenance Record - Institution


a_poli <- createAgentProvenance(bundle = bundle,
                               uri = 'http://usp.br/poli', 
                               name = 'Escola Politecnica da USP', 
                               type = 'Institution',
                               identifier = 'poliusp', 
                               homepage = 'http://poli.usp.br/', 
                               description = 'Engineering Departament of University of Sao Paulo.')


### Provenance Record - Sensors / Input Parameters and Captured Data (Raw Data)
e_eletronicEquipment <- createEntityProvenance(bundle = bundle, 
                                 identifier = 'EnvSensor', 
                                 type = 'Sensor', 
                                 uri = 'http://sensor.com/environmentalsensor/env200',
                                 source = 'http://sensor.com/environmentalsensor/env200',
                                 title = 'Environmental Sensor Model ENV 200')
                                 
e_settings <- createEntityProvenance(bundle = bundle, 
                                 identifier = 'Settings', 
                                 type = 'InputParams',
                                 description = 'Parameter of data capture interval, in minutes.',
                                 uri = 'http://bioprov.org/input_params/interval',
                                 value = '60')

e_rawData <- createEntityProvenance(bundle = bundle, 
                                    identifier = 'rawData',
                                    type = 'Raw Dataset',
                                    uri = 'http://poli.usp.br/datasets/30',
                                    source = 'http://poli.usp.br/datasets/30',
                                    title = 'Environmental Monitoring Raw Data',
                                    wasAttributedTo = a_poli)

### Provenance Record - Data Capture Activity 

act_dataSearching <- createActivityProvenance(bundle = bundle, 
                                              identifier = 'Collect01',
                                              type = 'DataCapturing', 
                                              title = 'Environment Data Capture by Sensors', 
                                              uri = 'http://poli.usp.br/activities/capture',
                                              used = list(e_eletronicEquipment, e_settings), 
                                              generated = e_rawData,
                                              wasAssociatedWith = a_poli)


                             
#PublishedDataset <- DataProcessing(Tool, Algorithm, inputParams, rawData)


### Provenance Record - Software Tool / Algorithm / Input Parameters / Institution

a_ib_usp <- createAgentProvenance(uri = 'http://ib.usp.br/ecologia', 
                               name = 'Departamento de Ecologia do Instituto de Biociencias da USP', 
                               identifier = 'Ecologia IB-USP', 
                               homepage = 'http://ib.usp.br/ecologia', 
                               description = 'Ecology Department - Bioscience Instituty of University of Sao Paulo')

e_softwareTool <- createEntityProvenance(bundle = bundle, 
                                               identifier = "Tool", 
                                               type = "SoftwareTool", 
                                               uri = 'http://tools.com/software/xyz',
                                               title = 'Software Tool XYZ',
                                               hasVersion = '1.4')

e_param1 <- createEntityProvenance(bundle = bundle,
                                   identifier = "acceptErrors", 
                                   type = "InputParams",
                                   description = 'Set whether the errors are discarded or maintained',
                                   uri = 'http://bioprov.org/input_params/acceptErrors',
                                   value = "FALSE")

e_param2 <- createEntityProvenance(bundle = bundle,
                                   identifier = "validateRanges",
                                   type = "InputParams",
                                   description = 'Set wether the validation of data ranges are considered.',
                                   uri = 'http://bioprov.org/input_params/validateRanges',
                                   value = "TRUE")

e_algorithm <- createEntityProvenance(bundle = bundle, 
                                    identifier = "algorithm1", 
                                    uri = 'http://poli.usp.br/datascience/algol/10',
                                    title = 'Algorithm for environmental processing',
                                    source = 'http://github.com/poli-usp/environAlgol',
                                    hasVersion = '3.4')


e_publishedData <- createEntityProvenance(bundle = bundle, 
                                    identifier = "publishedData", 
                                    type = 'Processed Dataset',
                                    uri = 'http://ib.usp.br/data_products/150',
                                    source = 'http://ib.usp.br/data_products/150',
                                    title = 'Environmental Monitoring Published Data',
                                    wasAttributedTo = a_ib_usp)

### Provenance Record - Data Processing Activity

act_dataProcessing <- createActivityProvenance(bundle = bundle, 
                                              type = 'DataProcessing',
                                              uri = 'http://ib.usp.br/activities/processing',
                                              title = 'Environment Data Processing using Software Tool',
                                              used = list(e_softwareTool, e_algorithm, e_param1, e_param2, e_rawData), 
                                              generated = e_publishedData,
                                              wasAssociatedWith = a_ib_usp)
                                 

getProvenanceOfEntityNew(uri = e_publishedData, folder = current_working_dir, format = 'png')
getProvenanceOfEntityNew(uri = e_publishedData, folder = current_working_dir, format = 'rdf')                                 
getProvenanceOfEntityNew(uri = e_publishedData, folder = current_working_dir, format = 'svg')                                 
