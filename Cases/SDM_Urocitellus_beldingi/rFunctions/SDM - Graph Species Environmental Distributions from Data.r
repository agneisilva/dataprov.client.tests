graphEnvDistributions <- function( speciesList=NULL, allSpeciesData, geogRedundancyRaster, namesOfLongLatFields=c('LONG_WGS84', 'LAT_WGS84'), nameOfSpeciesField='SPECIES', minNumPoints=15, minMapScaleRange=1, backgroundEnvData, overlayPolygonsFilePathAndNames, targetDir, univariatePlotPredictors, bivariatePlotPredictors ) {
# graphEnvDistributionsReduced  Makes dot maps of species' geographic locations and plots in environmental space.  This function is the same as graphEnvDistributions, but it only makes 3 plots (dot map plus two environmental plots)
#
# ARGUMENTS
# speciesList
# list of species for which to make graphs... leave as NULL to do all species with >= minNumPoints geographically unique points in data frame
#
# allSpeciesData
# data frame with species' data... must have columns with species' names, latitude and longitude, and variables with values for plotting
#
# geogRedundancyRaster
# raster with which to thin each species' data points so there is <= oe per cell
#
# namesOfLongLatFields
# character list of the name of the field in the species' data frame that contain longitude and latitude (in that order!) values in WGS84 decimal degrees format
#
# nameOfSpeciesField
# name of field with species' names... these should correspond to names in speciesList
#
# minNumPoints
# minimum number of points needed to graph/map a species
#
# minMapScaleRange
# minimum range of latitude and longitude on dot maps in the units of the datum of the species' data file and polygon overlays (e.g., degrees for WGS84, meters for Teale Albers, etc.)... this is used to overcome the problem of being zoomed in too far to ascertain where a species is located in maps
#
# backgroundEnvData
# data frame of environmental values for randomly located background sites in study region... columns must have same names as variables named in univariatePlotPredictors and bivariatePlotPredictors
#
# overlayPolygonsFilePathAndNames
# character list of names and directories of polygon shapefiles (sans extension) to overlay on each map (e.g., map of States or geographic provinces)... first one in list will be plotted on dot map with solid lines, second dashed, etc.
#
# targetDir
# firectory to which PNG files will be saved
#
# univariatePlotPredictors
# character list of predictors for which to generate univariate plots... NOTE: the total number of plots (values in univariatePlotPredictors and rows in bivariatePlotPredictors) must not exceed 2... leave as NULL to skip univariate plots
#
# bivariatePlotPredictors
# list with structure (A=c('~1', '~2', etc.), B=c('~1', '~2', etc.)) where '~' is the name of a predictor in backgroundEnvData and the file pointed to in allSpeciesData... each row of predictors will get its own bivariate plot (e.g., so A's ~1 will be plotted against B's ~1, A's ~2 will be plotted against B's ~2, etc.)... NOTE: the total number of plots (values in univariatePlotPredictors and rows in bivariatePlotPredictors) must not exceed 2... leave as NULL to skip bivariate plots
#
# VALUES
# one PNG per species displaying a map of the species' presences and univariate cumulative frequency and bivariate plots for selected environmental variables
#
# BAUHAUS
#
# EXAMPLE
# graphEnvDistributions( speciesList, allSpeciesData, namesOfLongLatFields=c('LONG_WGS84', 'LAT_WGS84'), nameOfSpeciesField='SPECIES', minNumPoints=1, minMapScaleRange=1, backgroundEnvData, overlayPolygonFilePathAndName, targetDir, univariatePlotPredictors, bivariatePlotPredictors )
#
# SOURCE	source('C:/Work/Code/SDM - Graph Species Environmental Distributions from Data.r')
#
# LICENSE
# This document is copyright ©2011 by Adam B. Smith.  This document is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3, or (at your option) any later version.  This document is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. Copies of the GNU General Public License versions are available at http://www.R-project.org/Licenses/
#
# AUTHOR	Adam B. Smith | Missouri Botanical Garden, St. Louis, Missouri | adamDOTsmithATmobotDOTorg
# DATE		2012-11
# REVISIONS 2011-12 Added 2*SD, 3*SD, and 4*SD vertical lines to univariate plots
#					Now doesn't remove target species from background sites (speeds process)
#					Fixed problem for variables with negative values plotting cumulative frequencies <0 and/or >1
# FORK		2012-01 Forked from deluxe version of this function, this version makes only three graphs
#			2012-06-08	Species' data must now be data frame (not shapefile or CSV path and file name)
#			2012-06-12  Genericized geographic redundancy filtering

print('')
print('===========================================================================================')
print('Graph dot maps and uni/bivariate environmental plots for each species: Reduced plot version')
print('===========================================================================================')
print('')

#############################
## libraries and functions ##
#############################

require(rgdal)
source('C:/Work/Code/Utility - Eliminate Species Records in Same Cell of a Raster.r')

##########################
## initialize variables ##
##########################

	# test to see if more plots are called for than can be accomodated
	if ( length(univariatePlotPredictors) + length(bivariatePlotPredictors$A) > 2 ) {
	
		print('The total number of plots (values in univariatePlotPredictors and rows in bivariatePlotPredictors) must not exceed 2.')
		print(ERROR)
	
	}

	# create target directory
	dir.create( targetDir, showWarnings=FALSE, recursive=TRUE )
	
	# collect names of all predictors
	allPredictors <- unique( c( univariatePlotPredictors, bivariatePlotPredictors$A, bivariatePlotPredictors$B ) )
	allPredictors <- sort( allPredictors[ !is.null(allPredictors) ] )
	
	###########################
	## import overlay shapes ##
	###########################
	
	overlayPolygons <- list()
	
	for (countPoly in 1:length(overlayPolygonsFilePathAndNames)) { # load each polygon
	
		overlayPolygons[[countPoly]] <- readOGR( dsn=dirname(overlayPolygonsFilePathAndNames[countPoly]), layer=basename(overlayPolygonsFilePathAndNames[countPoly]), verbose=FALSE ) # overlay shapefile
	
	}

	# ######################################
	# ## get and pre-process species data ##
	# ######################################

	# if (class(allSpeciesData)=='character') { # if species' data is CSV or shapefile
		
		# # load species data if in CSV format
		# if ( length( grep( x=allSpeciesData, pattern='.csv', ignore.case=TRUE, value=TRUE) ) > 0 ) allSpeciesData <- read.csv( allSpeciesData, header=TRUE )

		# # load species data if in shapefile format
		# if ( length( grep( x=allSpeciesData, pattern='.csv', ignore.case=TRUE, value=TRUE) )==0 ) {

			# require(PBSmapping)
			# allSpeciesData <- as.data.frame( importShapefile(allSpeciesData) )

		# }
		
	# }

	############################
	## thin all species' data ##
	############################
	
	print('Thinning all species\' data...')

	# allSpeciesDataThinned <- allSpeciesData # for testing
	# allSpeciesDataThinned <- sdmEliminateGeographicDuplicates(theseSpeciesRecords=allSpeciesData, minDist=minDist, namesOfLongLatVariables=c('LONG_WGS84', 'LAT_WGS84')) # thin all species' data (for use as BG)

	allSpeciesDataThinned <- sdmEliminateGeographicDuplicatesInSameCellOfARaster(pointsFrame=allSpeciesData, namesOfLongLatVariables=namesOfLongLatFields, baseRaster=geogRedundancyRaster, Priority=NULL ) # thin all species' data (for use as BG)

	for (thisPredictor in allPredictors) { # for each predictor calculate cumulative frequencies
	
		thisCumSum <- c(
			cumsum(
				sort( allSpeciesDataThinned[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) + ifelse( max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) )
			) /
			sum(
				allSpeciesDataThinned[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) + ifelse( max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ), na.rm=TRUE
			),
			rep( NA, nrow(allSpeciesDataThinned) - length( cumsum(
				sort( allSpeciesDataThinned[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) + ifelse( max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) )
			) ) )
		)

		thisEnvValues <- c( sort( allSpeciesDataThinned[ , thisPredictor] ), rep( NA, nrow(allSpeciesDataThinned) - length( cumsum( sort( allSpeciesDataThinned[ , thisPredictor] ) ) / sum( allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE ) ) ) )
		
		if (exists('cumFreqAllSpecies')) cumFreqAllSpecies <- cbind(cumFreqAllSpecies, thisEnvValues, thisCumSum)
		if (!exists('cumFreqAllSpecies')) cumFreqAllSpecies <- data.frame(thisEnvValues, thisCumSum)
		names(cumFreqAllSpecies)[(ncol(cumFreqAllSpecies) - 1):ncol(cumFreqAllSpecies)] <- c( thisPredictor, paste( thisPredictor, '_cumFreq', sep='') )
		
	}

	#########################################################################################################
	## calculate cumulative frequencies for each predictor of interest in background and all species' data ##
	#########################################################################################################
	
	# calculate cumul freq for each variable of interest in BG points
	for (thisPredictor in allPredictors) { # for each predictor

		thisCumSum <- c(
			cumsum(
				sort( backgroundEnvData[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) + ifelse( max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 )
				)
			) /
			sum(backgroundEnvData[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) + ifelse( max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ), na.rm=TRUE ),
			rep( NA, nrow(backgroundEnvData) - length( cumsum( sort( backgroundEnvData[ , thisPredictor] ) ) / sum( backgroundEnvData[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) + ifelse( max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(max(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ), na.rm=TRUE ) ) )
		)
		
		thisEnvValues <- c(
			sort( backgroundEnvData[ , thisPredictor] ),
			rep( NA, nrow(backgroundEnvData) - length( cumsum( sort( backgroundEnvData[ , thisPredictor] ) ) / sum( backgroundEnvData[ , thisPredictor], na.rm=TRUE ) ) )
		)
		
		if (exists('cumFreqBackground')) cumFreqBackground <- cbind(cumFreqBackground, thisEnvValues, thisCumSum)
		if (!exists('cumFreqBackground')) cumFreqBackground <- data.frame(thisEnvValues, thisCumSum)
		names(cumFreqBackground)[(ncol(cumFreqBackground) - 1):ncol(cumFreqBackground)] <- c( thisPredictor, paste( thisPredictor, '_cumFreq', sep='') )
		
	}

##########
## MAIN ##
##########

print('')

for (thisSpecies in speciesList) { # for each species

	# get this species' data
	thisSpeciesData <- subset( allSpeciesData, allSpeciesData[ , nameOfSpeciesField]==thisSpecies )
	
	print( paste( 'Making plots for ', thisSpecies, ' (', nrow(thisSpeciesData), ' total sites)...', sep='' ) )

	# if this species has any points
	if (nrow(thisSpeciesData) >= minNumPoints) {
	
		# eliminate geographically redundant points
		thisSpeciesDataThinned <- sdmEliminateGeographicDuplicatesInSameCellOfARaster(pointsFrame=thisSpeciesData, namesOfLongLatVariables=namesOfLongLatFields, baseRaster=geogRedundancyRaster, Priority=NULL )
		
		#########
		## map ##
		#########

		png( filename=paste( targetDir, '/', thisSpecies, ' - Dot Map and Environmental Plots.png', sep='' ), height=1000, width=800 * 3) # initiate PNG
		
		par( mfrow=c(1, 3) )
		
		## dot map
		
		par(
			pty='s',
			bty='o',
			cex=1,
			cex.lab=1.5,
			cex.main=1.6,
			cex.lab=1.2
		)
		
		# set map axes' ranges
		thisSpeciesRangeX <- max( minMapScaleRange, abs( max(thisSpeciesData[ , namesOfLongLatFields[1]], na.rm=T) -  min(thisSpeciesData[ , namesOfLongLatFields[1]], na.rm=T) ) )
		thisSpeciesRangeY <- max( minMapScaleRange, abs( max(thisSpeciesData[ , namesOfLongLatFields[2]], na.rm=T) -  min(thisSpeciesData[ , namesOfLongLatFields[2]], na.rm=T) ) )
		
		thisSpeciesRangeCenterX <- mean( range(thisSpeciesData[ , namesOfLongLatFields[1]], na.rm=T ) )
		thisSpeciesRangeCenterY <- mean( range(thisSpeciesData[ , namesOfLongLatFields[2]], na.rm=T ) )
		
		mapMinX <- thisSpeciesRangeCenterX - 0.6 * max(thisSpeciesRangeX, thisSpeciesRangeY)
		mapMaxX <- thisSpeciesRangeCenterX + 0.6 * max(thisSpeciesRangeX, thisSpeciesRangeY)
		
		mapMinY <- thisSpeciesRangeCenterY - 0.6 * max(thisSpeciesRangeX, thisSpeciesRangeY)
		mapMaxY <- thisSpeciesRangeCenterY + 0.6 * max(thisSpeciesRangeX, thisSpeciesRangeY)
			
		# first overlay polygon
		plot(
			overlayPolygons[[1]],
			main=paste( nrow(thisSpeciesData), ' total presences (red circles); ', nrow(thisSpeciesDataThinned), ' presences >= 1 km apart (dark rings)', sep='' ),
			xlim=c(mapMinX, mapMaxX),
			ylim=c(mapMinY, mapMaxY),
			lty='solid',
			lwd=2,
			plot=T
		)

		# remaining overlay polygon
		for (countPolys in 2:length(overlayPolygons)) {

			plot(
				overlayPolygons[[countPolys]],
				lty=countPolys,
				add=TRUE
			)

		}

		# all species' data (thinned)
		points(
			x=allSpeciesDataThinned[ , namesOfLongLatFields[1]],
			y=allSpeciesDataThinned[ , namesOfLongLatFields[2]],
			pch=16,
			cex=1,
			col='darkolivegreen3'
		)
		
		# this species' data (all points)
		points(
			x=thisSpeciesData[ , namesOfLongLatFields[1]],
			y=thisSpeciesData[ , namesOfLongLatFields[2]],
			pch=16,
			cex=2,
			col='brown1'
		)
			
		
		# this species' data (thinned)
		points(
			x=thisSpeciesDataThinned[ , namesOfLongLatFields[1]],
			y=thisSpeciesDataThinned[ , namesOfLongLatFields[2]],
			pch=1,
			cex=2,
			col='black'
		)
		
		legend(
			x=thisSpeciesRangeCenterX,
			y=thisSpeciesRangeCenterY - 0.7 * max(thisSpeciesRangeX, thisSpeciesRangeY),
			legend=c(thisSpecies, 'All species'),
			col=c('brown1', 'darkolivegreen3'),
			cex=2,
			pt.cex=c(2, 2),
			pch=c(16, 16),
			xpd=NA,
			xjust=0.5,
			yjust=1,
			ncol=1,
			bty='n'
		)
		
		######################
		## univariate plots ##
		######################
		
		if (!is.null(univariatePlotPredictors)) { # if univaruiate plots are desired
		
			for (thisPredictor in univariatePlotPredictors) { # for each univariate plot

				# calculate cumulative frequency distributtion for presence points of this species
				thisSpeciesCumulFreq <- c( cumsum( sort( thisSpeciesDataThinned[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ) ) ) / sum( thisSpeciesDataThinned[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ), na.rm=TRUE ), rep( NA, nrow(thisSpeciesDataThinned) - length( cumsum( sort( thisSpeciesDataThinned[ , thisPredictor] ) ) / sum( thisSpeciesDataThinned[ , thisPredictor] + ifelse( min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE) < 0, abs(min(allSpeciesDataThinned[ , thisPredictor], na.rm=TRUE)), 0 ), na.rm=TRUE ) ) ) )
			
				# get environmental values
				thisSpeciesEnvValues <- c( sort( thisSpeciesDataThinned[ , thisPredictor] ), rep( NA, nrow(thisSpeciesDataThinned) - length( cumsum( sort( thisSpeciesDataThinned[ , thisPredictor] ) ) / sum( thisSpeciesDataThinned[ , thisPredictor], na.rm=TRUE ) ) ) )

				par(
					pty='s',
					cex=1,
					cex.lab=1.5,
					cex.main=1.6,
					cex.axis=1.2
				)
				
				# plot cumulative frequency of background
				plot(
					x=cumFreqBackground[ , thisPredictor ],
					y=cumFreqBackground[ , paste( thisPredictor, '_cumFreq', sep='') ],
					pch=NA,
					type='l',
					lwd=2,
					col='lightskyblue',
					main=thisPredictor,
					xlab=thisPredictor,
					ylab='Cumulative frequency',
					xlim=c( min(cumFreqAllSpecies[ , thisPredictor], na.rm=TRUE), max(cumFreqAllSpecies[ , thisPredictor], na.rm=TRUE) ),
					ylim=c( min(cumFreqAllSpecies[ , paste( thisPredictor, '_cumFreq', sep='') ], na.rm=TRUE), max(cumFreqAllSpecies[ , paste( thisPredictor, '_cumFreq', sep='') ], na.rm=TRUE) )
				)
				
				# plot all species' frequency
				points(
					x=cumFreqAllSpecies[ , thisPredictor],
					y=cumFreqAllSpecies[ , paste( thisPredictor, '_cumFreq', sep='') ],
					type='l',
					lwd=3,
					col='darkolivegreen3'
				)
					
				# mean
				lines(
					x=rep( mean(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='solid',
					col='brown1'
				)
				
				# 2 * SD lines
				lines(
					x=rep( mean(thisSpeciesEnvValues) + 2 * sd(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='dotted',
					col='brown1'
				)
				
				lines(
					x=rep( mean(thisSpeciesEnvValues) - 2 * sd(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='dotted',
					col='brown1'
				)
				
				# 3 * SD lines
				lines(
					x=rep( mean(thisSpeciesEnvValues) + 3 * sd(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='dotdash',
					col='brown1'
				)
				
				lines(
					x=rep( mean(thisSpeciesEnvValues) - 3 * sd(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='dotdash',
					col='brown1'
				)
				
				# 4 * SD lines
				lines(
					x=rep( mean(thisSpeciesEnvValues) + 4 * sd(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='dashed',
					col='brown1'
				)
				
				lines(
					x=rep( mean(thisSpeciesEnvValues) - 4 * sd(thisSpeciesEnvValues), 2),
					y=c(0, 1),
					lty='dashed',
					col='brown1'
				)
				
				# plot this species' frequency
				lines(
					x=thisSpeciesEnvValues,
					y=thisSpeciesCumulFreq,
					type='b',
					cex=2,
					pch=16,
					lty='solid',
					lwd=3,
					col='brown1'
				)

				points(
					x=thisSpeciesEnvValues,
					y=thisSpeciesCumulFreq,
					pch=1,
					cex=2,
					col='brown4'
				)

				## Kolgomorov-Smirnov test on BG vs this species and on all species vs this species
				ksTestVsBg <- ks.test( x=cumFreqBackground[ , thisPredictor ], y=thisSpeciesEnvValues )
				ksTestVsAllSpp <- ks.test( x=cumFreqAllSpecies[ , thisPredictor], y=thisSpeciesEnvValues )
				text(
					x=min(cumFreqAllSpecies[ , thisPredictor], na.rm=TRUE),
					y=max(cumFreqAllSpecies[ , paste( thisPredictor, '_cumFreq', sep='') ], na.rm=TRUE),
					adj=c(0, 1),
					cex=1.4,
					labels=paste( 'K-S Test vs BG: P=', format(ksTestVsBg$p.value, digits=2), '\nK-S Test vs all: P= ', format(ksTestVsAllSpp$p.value, digits=2), sep='' )
				)
			
				legend(
					x=mean( c( min(cumFreqAllSpecies[ , thisPredictor], na.rm=TRUE), max(cumFreqAllSpecies[ , thisPredictor], na.rm=TRUE) ) ),
					y=-0.15,
					legend=c(thisSpecies, 'All species', 'Random background', '±2SD', '±3SD', '±4SD'),
					col=c('brown1', 'darkolivegreen3', 'lightskyblue', 'brown1', 'brown1', 'brown1'),
					cex=1.4,
					pt.cex=c(2, NA, NA, NA, NA, NA),
					pch=c(16, NA, NA, NA, NA, NA),
					lty=c('solid', 'solid', 'solid', 'dotted', 'dotdash', 'dashed'),
					xpd=NA,
					xjust=0.5,
					yjust=1,
					ncol=2,
					bty='n'
				)
				

			} # for each univariate plot
			
		}  # if univaruiate plots are desired
		
		#####################
		## bivariate plots ##
		#####################

		if (!is.null(bivariatePlotPredictors$A)) { # if bivariate plots are desired
			
			for (countPlots in 1:length(bivariatePlotPredictors$A)) { # for each bivariate plot

				par(
					pty='s',
					cex=1,
					cex.lab=1.5,
					cex.main=1.6,
					cex.axis=1.2
				)
				
				# background
				smoothScatter(
					x=backgroundEnvData[ , bivariatePlotPredictors$A[countPlots] ],
					y=backgroundEnvData[ , bivariatePlotPredictors$B[countPlots] ],
					nbin=64,
					pch=16,
					col='lightblue',
					pty='s',
					xlab=bivariatePlotPredictors$A[countPlots],
					ylab=bivariatePlotPredictors$B[countPlots],
					main=paste( bivariatePlotPredictors$A[countPlots], ' vs ', bivariatePlotPredictors$B[countPlots] ),
					xlim=c(min(allSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ], na.rm=TRUE), max(allSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ], na.rm=TRUE) ),
					ylim=c(min(allSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ], na.rm=TRUE), max(allSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ], na.rm=TRUE) )
					
				)

				# all species data
				points(
					x=allSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ],
					y=allSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ],
					pch=16,
					cex=1,
					col='darkolivegreen1'
				)
					
				# 2 * SD lines for X axis (vertical lines)
				lines(
					x=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]) + 2 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]), 2),
					y=c( -10^10, 10^10 ),
					lty='dotted',
					col='brown1'
				)
				
				lines(
					x=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]) - 2 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]), 2),
					y=c( -10^10, 10^10 ),
					lty='dotted',
					col='brown1'
				)
				
				# 3 * SD lines for X axis (vertical lines)
				lines(
					x=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]) + 3 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]), 2),
					y=c( -10^10, 10^10 ),
					lty='dotdash',
					col='brown1'
				)
				
				lines(
					x=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]) - 3 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]), 2),
					y=c( -10^10, 10^10 ),
					lty='dotdash',
					col='brown1'
				)
				
				# 4 * SD lines for X axis (vertical lines)
				lines(
					x=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]) + 4 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]), 2),
					y=c( -10^10, 10^10 ),
					lty='dashed',
					col='brown1'
				)
				
				lines(
					x=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]) - 4 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ]), 2),
					y=c( -10^10, 10^10 ),
					lty='dashed',
					col='brown1'
				)
				

				# 2 * SD lines for Y axis (horizontal lines)
				lines(
					x=c(-10^10, 10^10),
					y=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]) + 2 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]), 2),
					lty='dotted',
					col='brown1'
				)
				
				lines(
					x=c(-10^10, 10^10),
					y=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]) - 2 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]), 2),
					lty='dotted',
					col='brown1'
				)
				
				# 3 * SD lines for Y axis (horizontal lines)
				lines(
					x=c(-10^10, 10^10),
					y=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]) + 3 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]), 2),
					lty='dotdash',
					col='brown1'
				)
				
				lines(
					x=c(-10^10, 10^10),
					y=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]) - 3 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]), 2),
					lty='dotdash',
					col='brown1'
				)
				
				# 4 * SD lines for Y axis (horizontal lines)
				lines(
					x=c(-10^10, 10^10),
					y=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]) + 4 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]), 2),
					lty='dashed',
					col='brown1'
				)
				
				lines(
					x=c(-10^10, 10^10),
					y=rep( mean(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]) - 4 * sd(thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ]), 2),
					lty='dashed',
					col='brown1'
				)
				
				# this species data (solid circles)
				points(
					x=thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ],
					y=thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ],
					pch=16,
					cex=2,
					col='brown1'
				)
			
				# this species data (discs)
				points(
					x=thisSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ],
					y=thisSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ],
					pch=1,
					cex=2,
					col='brown4'
				)

				legend(
					x=mean( c(min(allSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ], na.rm=TRUE), max(allSpeciesDataThinned[ , bivariatePlotPredictors$A[countPlots] ], na.rm=TRUE) ) ),
					y=min(allSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ], na.rm=T) - 0.15 * abs(max(allSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ], na.rm=T) - min(allSpeciesDataThinned[ , bivariatePlotPredictors$B[countPlots] ], na.rm=T)),
					legend=c(thisSpecies, 'All species', 'Random background', '±2SD', '±3SD', '±4SD'),
					col=c('brown1', 'darkolivegreen3', 'lightskyblue', 'brown1', 'brown1', 'brown1'),
					cex=1.4,
					pt.cex=c(2, 2, 2, NA, NA, NA),
					pch=c(16, 16, 15, NA, NA, NA),
					lty=c(NA, NA, NA, 'dotted', 'dotdash', 'dashed'),
					xpd=NA,
					xjust=0.5,
					yjust=1,
					ncol=2,
					bty='n'
				)
				
			} # for each bivariate plot

		}  # if bivariate plots are desired
			
		title(
			main=thisSpecies,
			outer=TRUE,
			line=-2,
			cex.main=2.6
		)
		
		title(
			main=paste( nrow(thisSpeciesData), ' total presences; ', nrow(thisSpeciesDataThinned), ' geographically unique presences (', date(), ')', sep='' ),
			outer=TRUE,
			line=-5,
			cex.main=2
		)
		
		# title(
			# main=paste( thisSpecies, ' (red) --- all species (green) --- background (blue)... mean (solid line) --- 2 SD from this species\' mean (dotted) --- 3 SD from mean (dot-dash) --- 4 SD from mean (dashed)... Values in univariate plots represent P values for Kolgomorov-Smirnov tests vs background sites and vs all other species.', sep='' ),
			# outer=TRUE,
			# line=-4,
			# cex.main=1.3
		# )
		
		dev.off() # turn off PNG device

	} # if this species has any points
		
} # for each species

print('')
print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
print('++++++++++++++++++++++++++++++ DONE +++++++++++++++++++++++++++++++++')
print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')

}

