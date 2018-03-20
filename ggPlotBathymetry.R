library("marmap")
library("mapdata")
library("ggplot2")
get.bathymetry <- function(lon1 = 4, lon2 = 30,
                           lat1 = 53, lat2 = 67,
                           bathy.breaks = 8, keep = TRUE){
    bathymetry <- getNOAA.bathy(lon1 = lon1, lon2 = lon2,
                                lat1 = lat1, lat2 = lat2,
                                resolution = 1, keep = keep) # keep = TRUE saves downloaded data as csv-File
    fortyfied.bathy <- fortify(bathymetry) # make a df out of bathy so ggplot can fully use the data
    fortyfied.bathy <- subset(fortyfied.bathy, z <= 0) # limit to values below sea surface
    fortyfied.bathy$z <- -fortyfied.bathy$z # make depths positive values
    names(fortyfied.bathy) <- c("Longitude", "Latitude", "Depth_m")
    fortyfied.bathy$Depthsteps_m <- cut(fortyfied.bathy$Depth_m,
                                        breaks = bathy.breaks,
                                        dig.lab = 10) # generate depth intervals for contour plot
    ## 'cut()' returns intervals in unpleasant format. Thus, cumbersome renaming for nice legend:
    fortyfied.bathy <- subset(fortyfied.bathy, !is.na(fortyfied.bathy$Depthsteps_m))
    levels(fortyfied.bathy$Depthsteps_m) <- sub(",", " - ", levels(fortyfied.bathy$Depthsteps_m))
    levels(fortyfied.bathy$Depthsteps_m) <- sub("\\(", "", levels(fortyfied.bathy$Depthsteps_m))
    levels(fortyfied.bathy$Depthsteps_m) <- sub("\\]", "", levels(fortyfied.bathy$Depthsteps_m))
    levels(fortyfied.bathy$Depthsteps_m) <- sub("(.*) - Inf", ">\\1", levels(fortyfied.bathy$Depthsteps_m))
    return(fortyfied.bathy)
}


plot.bathymetry <- function(lon.min = 4, lon.max = 30,
                     lat.min = 53, lat.max = 67,
                     bathy.breaks = c(seq(0, 50, length.out = 6),
                                      seq(100, 300, length.out = 3),
                                      +Inf),
                     land.colour = NA, border.colour = "black",
                     keep = TRUE){
    bathy <- get.bathymetry(lon1 = lon.min, lon2 = lon.max, 
                            lat1 = lat.min, lat2 = lat.max,
                            bathy.breaks = bathy.breaks, keep = keep)
    coastlines <- map_data('worldHires', xlim = c(lon.min, lon.max), ylim = c(lat.min, lat.max))
    
    ggplot() +
        coord_quickmap(#projection= "azequalarea",
            xlim=c(lon.min, lon.max), ylim=c(lat.min, lat.max)) +
        geom_tile(data = bathy, aes(x=Longitude, y=Latitude, fill=Depthsteps_m)) +
        scale_fill_brewer(palette = "Blues", name = "Water depth [m]") +
        geom_polygon(data=coastlines, aes(x=long, y=lat, group=group),
                     fill=land.colour, colour = border.colour, lwd=.2) +
        scale_y_continuous(expand = c(0,0)) + scale_x_continuous(expand = c(0,0)) + # so that the whole plot area is filled with bathy and coastlines.
        theme_minimal()
}