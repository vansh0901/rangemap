% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ranges_emaps.R
\name{ranges_emaps}
\alias{ranges_emaps}
\title{Species ranges on maps of environmental factors}
\usage{
ranges_emaps(ranges, add_occurrences = TRUE, variables, range_colors = NULL,
    variables_color = NULL, ranges_legend = TRUE, legend_position = "bottomright",
    legend_size = 0.7, scalebar = FALSE, scalebar_position = "bottomleft",
    scalebar_length = 100, zoom = 1.3, save_fig = FALSE, name = "ranges_emaps",
    format = "png", resolution = 300, width = 166)
}
\arguments{
\item{ranges}{(list) of SpatialPolygons or SpatialPolygonsDataFrame or a
list of objects produced with any of the following functions:
\code{\link{rangemap_buff}}, \code{\link{rangemap_bound}}, \code{\link{rangemap_hull}},
\code{\link{rangemap_enm}}, and \code{\link{rangemap_tsa}}. For visualization purposes,
using up to three ranges is recommended.}

\item{add_occurrences}{(logical) if TRUE, species occurrences contained in one of the
elements of the list \code{ranges} will be ploted in the figure. Default = TRUE. If the
none of the ranges contains occurrences (e.g. a list of one object created with the
\code{\link{rangemap_bound}} function in which occurrences were not used), this parameter
will be ignored.}

\item{variables}{a RasterStack object of environmental variables that will be used for
representing the environmental factors. Projection is assumed to be Geographic (longitude
and latitude). Consider that depending on the species range, more than 9 variables
may create a figure that does not fit in an A4 sheet of paper. A maximum of 21
variables is allowed, if this limit is surpassed, other variables will be ignored.}

\item{range_colors}{vector of colors of the range borders to be represented. If not
defined, default = NULL and default colors will be used. If more than 7 objects are
included in \code{ranges}, default colors will be recycled; therefore, defining colors
here is recommended in those cases.}

\item{variables_color}{a color palette like terrain.colors, heat.colors, topo.colors,
or your own. Default = NULL. If not provided, rev(terrain.colors(255)) is used.}

\item{ranges_legend}{(logical) if TRUE, a legend of the plotted ranges will be added
to the last panel at \code{legend_position}. Default = TRUE.}

\item{legend_position}{(numeric or character) site in the figure where the legend will
be placed. If numeric, vector of leght two indicating x and y coordinates to be used
to position the legend. See details for options of character indicators of position.
Default = "bottomright".}

\item{legend_size}{(numeric) size of the legend with respect to one of the panels.
Default = 0.7.}

\item{scalebar}{(logical) if TRUE, a simple scale bar will be inserted in the last panel
at \code{scalebar_position} with a length of \code{scalebar_length}. Default = FALSE.}

\item{scalebar_position}{(numeric or character) site in the figure where the scale bar
will be placed. If numeric, vector of leght two indicating x and y coordinates to be
used to position the scale bar. See details for options of character indicators of
position. Default = "bottomleft".}

\item{scalebar_length}{(numeric) length of the scale bar in km. Using entire numbers
divisble for two is recommended. Default = 100.}

\item{zoom}{(numeric) zoom factor when ploting the species range in a map based on the
biggest range. Default = 1.3. Lower #' values will zoom in into the species range and
bigger values will zoom out. A value of 2 will duplicate the area that the biggest range
is covering.}

\item{save_fig}{(logical) if TRUE, the figure will be written in the working directory.
Default = FALSE.}

\item{name}{(character) if \code{save_fig} = TRUE, name of the figure to be exported.
Default = "ranges_emaps".}

\item{format}{(character) if \code{save_fig} = TRUE, format in which the figure will be
written. Options include "bmp", "png", "jpeg", "tiff", and "pdf". Default = "png".}

\item{resolution}{(numeric) if \code{save_fig} = TRUE, resolution (ppi) in wich the figure
will be exported. Default = 300.}

\item{width}{(numeric) if \code{save_fig} = TRUE, width of the figure in mm. Default = 166.
Height will be adjusted considering the amount of variables that will be plotted.}
}
\value{
A figure showing species ranges on maps of environmental factors.
}
\description{
ranges_emaps represents one or more ranges of the same species on
various maps of environmental factors (e.g. climatic variables) to detect implications
of using one or other type of range regarding the environmental conditions in the areas.
}
\details{
Ranges should be generated with any of the functions: \code{\link{rangemap_buff}},
\code{\link{rangemap_bound}}, \code{\link{rangemap_hull}}, \code{\link{rangemap_enm}}, and
\code{\link{rangemap_tsa}}.

Position of distinct elements depend on the spatial configuration of the species range.
Therefore, their position may need to be changed if the elements are needed. Position
options are: "bottomright", "bottomleft", "topleft", and "topright". Numerical descriptions
of positions are also allowed.

Scale bar is ploted using a modification of the "scalebar" function developed by
Tanimura et al. (2007) \url{http://hdl.handle.net/10.18637/jss.v019.c01}.
}
\examples{
suppressWarnings({if(!require(spocc)){
  install.packages("spocc")
  library(spocc)
}})

# getting the data from GBIF
occs <- occ(query = "Dasypus kappleri", from = "gbif",
            limit = 1000)$gbif$data[[1]]

# keeping only georeferenced records
occ_g <- occs[!is.na(occs$latitude) & !is.na(occs$longitude),
              c("name", "longitude", "latitude")]


# range based on buffers
dist <- 500000

buff <- rangemap_buff(occurrences = occ_g, buffer_distance = dist)


# range based on concave hulls
dist1 <- 250000
hull1 <- "concave"

concave <- rangemap_hull(occurrences = occ_g, hull_type = hull1, buffer_distance = dist1)


# range based on convex disjunct hulls
split <- TRUE
hull2 <- "convex"

convex <- rangemap_hull(occurrences = occ_g, hull_type = hull2, buffer_distance = dist1,
                         split = split, cluster_method = "k-means", n_k_means = 3)

# ranges representation on environmental factor maps
## list of ranges
ranges <- list(buff, concave, convex)
names(ranges) <- c("buff", "concave", "convex")

## other data for environmental comparisson
suppressWarnings({if(!require(raster)){
  install.packages("raster")
  library(raster)
}
if(!require(maps)){
  install.packages("maps")
  library(maps)
}
if(!require(maptools)){
  install.packages("maptools")
  library(maptools)
}})

## geting bioclimatic variables (some of them)
vars <- getData("worldclim", var = "bio", res = 5)[[c("bio1", "bio7", "bio12", "bio15")]]
## after the first view try with distinct or more variables

## mask variables to region of interest
WGS84 <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
w_map <- map(database = "world", regions = c("Ecuador", "Peru", "Bolivia", "Colombia",
                                             "Venezuela", "Suriname", "Guyana",
                                             "French Guyana", "Brazil"),
             fill = TRUE, plot = FALSE) # map of the world

w_po <- sapply(strsplit(w_map$names, ":"), function(x) x[1]) # preparing data to create polygon
reg <- map2SpatialPolygons(w_map, IDs = w_po, proj4string = WGS84) # map to polygon

e <- extent(reg)
mask <- as(e, 'SpatialPolygons')

variables <- crop(vars, mask)
save <- TRUE
name <- "test"

## ranges on evironmental factor maps
ranges_emaps(ranges = ranges, variables = variables,
             save_fig = save, name = name)

#dev.off() # for returning to default par settings
}
