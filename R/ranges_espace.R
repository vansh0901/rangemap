#' Comparison of species ranges in environmental space
#'
#' @description ranges_espace generates a three dimensional comparison of a species'
#' ranges created using distinct algortihms, to visualize implications of selecting
#' one of them if environmental conditions are considered.
#'
#' @param ranges object or list of objects produced with any of the following functions:
#' \code{\link{rangemap_buff}}, \code{\link{rangemap_bound}}, \code{\link{rangemap_hull}},
#' \code{\link{rangemap_enm}}, and \code{\link{rangemap_tsa}}. For visualization purposes,
#' using up to three ranges is recommended.
#' @param add_occurrences (logical) if TRUE, species occurrences contained in one of
#' the elements of the list \code{ranges} will be ploted in the figure. Default = TRUE.
#' If the none of the ranges contains occurrences (e.g. a list of one object created
#' with the \code{\link{rangemap_bound}} function in which occurrences were not used),
#' this parameter will be ignored.
#' @param variables a RasterStack object of environmental variables that will be used
#' for creating the principal components to represent the environmental space. Projection
#' is assumed to be Geographic (longitude and latitude).
#' @param max_background (numeric) maximum number of data from variables to be used for
#' representation of the environmental space. Default = 25000. Increasing this number
#' results in more detailed views of the available environment but preforming analyses
#' will take longer.
#' @param ranges_representation (character) form in which the environmental space
#' withing the ranges will be represented. Options are "clouds" and "ellipsoids".
#' Default = "clouds".
#' @param background_color color of the background to be ploted. Default = "darkolivegreen".
#' Since transparency is used for representing most of components of the plot, colors may
#' look different.
#' @param range_colors vector of colors of the ranges to be represented. If not defined,
#' default = NULL and default colors will be used. Since transparency is used for
#' representing most of components of the plot, colors may look different.
#' @param alpha (numeric) degree of opacity with which the species ranges will be
#' represented in the plot. Default = 0.03.
#' @param eye_camera (numeric) vector of values to be passed to eye in the list of
#' arguments of the parameter camera in layour of \code{\link[plotly]{plotly}}. This
#' values control how the figur is seen in the plot.
#'
#' @return A figure showing, in the environmental space, the species ranges generated with
#' any of the functions: \code{\link{rangemap_buff}}, \code{\link{rangemap_bound}},
#' \code{\link{rangemap_hull}}, \code{\link{rangemap_enm}}, and \code{\link{rangemap_tsa}}.
#'
#' @usage
#' ranges_espace(ranges, add_occurrences = TRUE, variables, max_background = 25000,
#'     ranges_representation = "clouds", background_color = "darkolivegreen",
#'     range_colors = NULL, alpha = 0.03, eye_camera = c(x = 1.95, y = 1.25, z = 1.35))
#'
#' @export
#'
#' @importFrom sp CRS SpatialPointsDataFrame spTransform
#' @importFrom raster rasterToPoints extract
#' @importFrom plotly plot_ly add_trace layout
#' @importFrom rgl ellipse3d
#'
#' @examples
#' suppressWarnings({if(!require(spocc)){
#'   install.packages("spocc")
#'   library(spocc)
#' }})
#'
#' # getting the data from GBIF
#' occs <- occ(query = "Dasypus kappleri", from = "gbif",
#'             limit = 1000)$gbif$data[[1]]
#'
#' # keeping only georeferenced records
#' occ_g <- occs[!is.na(occs$latitude) & !is.na(occs$longitude),
#'               c("name", "longitude", "latitude")]
#'
#'
#' # range based on buffers
#' dist <- 500000
#'
#' buff <- rangemap_buff(occurrences = occ_g, buffer_distance = dist)
#'
#'
#' # range based on concave hulls
#' dist1 <- 250000
#' hull1 <- "concave"
#'
#' concave <- rangemap_hull(occurrences = occ_g, hull_type = hull1, buffer_distance = dist1)
#'
#'
#' # ranges comparison in environmental space
#' ## list of ranges
#' ranges <- list(buff, concave)
#' names(ranges) <- c("buff", "concave")
#'
#' ## other data for environmental comparisson
#' suppressWarnings({if(!require(raster)){
#'   install.packages("raster")
#'   library(raster)
#' }
#' if(!require(maps)){
#'   install.packages("maps")
#'   library(maps)
#' }
#' if(!require(maptools)){
#'   install.packages("maptools")
#'   library(maptools)
#' }})
#'
#' vars <- getData("worldclim", var = "bio", res = 5)
#'
#' ## mask variables to region of interest
#' WGS84 <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
#' w_map <- map(database = "world", regions = c("Ecuador", "Peru", "Bolivia", "Colombia", "Venezuela",
#'                                              "Suriname", "Guyana", "French Guyana", "Brazil"),
#'              fill = TRUE, plot = FALSE) # map of the world
#' w_po <- sapply(strsplit(w_map$names, ":"), function(x) x[1]) # preparing data to create polygon
#' reg <- map2SpatialPolygons(w_map, IDs = w_po, proj4string = WGS84) # map to polygon
#'
#' e <- extent(reg)
#' mask <- as(e, 'SpatialPolygons')
#'
#' variables <- crop(vars, mask)
#'
#' ## comparison
#' occur <- TRUE
#' env_comp <- ranges_espace(ranges = ranges, add_occurrences = occur, variables = variables)
#'
#'
#' # now play around, zoom in and rotate the figure
#'
#' # saving this figure may be challenging, try using
#' # the following lines of code and check your download directory
#'
#' op <- options() # save default options
#' options(viewer = NULL) # Set viewer to web browser
#' name <- "ranges_space" # name for figure
#'
#' # using web browser to save image
#' env_comp %>% htmlwidgets::onRender(
#'   paste("function(el, x)
#'           {var gd = document.getElementById(el.id);
#'           Plotly.downloadImage(gd, {format: 'svg', width: ", 1000, ", height: ",
#'         800, ", filename: ", paste("\'", name, "\'", sep = ""), "});
#'           }", sep = "")
#' )
#'
#' Sys.sleep(2) # wait for the execution
#' options(viewer = op$viewer) # restore viewer to old setting (e.g. RStudio)

ranges_espace <- function(ranges, add_occurrences = TRUE, variables, max_background = 25000,
                          ranges_representation = "clouds", background_color = "darkolivegreen",
                          range_colors = NULL, alpha = 0.03, eye_camera = c(x = 1.95, y = 1.25, z = 1.35)) {

  # testing potential issues
  if (missing(ranges)) {
    stop("ranges must exist. See the function's help for more details.")
  }

  # preparing data
  ## plain projection
  WGS84 <- sp::CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

  ## unlist nested lists
  r <- lapply(ranges, unlist)

  ## extracting data
  if (add_occurrences == TRUE) {
    lranges <- sapply(ranges, length)

    if (any(lranges > 2)){
      n <- which(lranges > 2)[1]
      ## occurrences
      if (isnested(r)) {
        sp_rec <- ranges[[n]]$Species_unique_records
      }else {
        sp_rec <- ranges$Species_unique_records
      }
      occ_sp <- sp::spTransform(sp_rec, WGS84)
      occ <- as.data.frame(occ_sp@data)[, 1:3]
      colnames(occ) <- c("Species", "Longitude", "Latitude")

      occ1 <- occ[, 2:3]
      colnames(occ1) <- c("x", "y")

      ## varaible data in occurrences
      pdata <- na.omit(cbind(occ1, raster::extract(variables, occ1)))

    }else {
      warning("None of the objects in \"range\" contain occurrences, \"add_occurrences = TRUE\" ignored.")
      add_occurrences <- FALSE
    }
  }

  ## raster to varaibles data
  idata <- raster::rasterToPoints(variables)

  if (add_occurrences == TRUE) {
      ## combining these data
      vdata <- rbind(idata, pdata)
  }else {
    vdata <- idata
  }

  # pca
  ## pca with vdata
  pcav <- prcomp(na.omit(vdata[, 3:dim(vdata)[2]]), center = TRUE,
                 scale = TRUE)

  ## getting the data of components in points
  pca_scores = pcav$x
  pc3 <- data.frame(vdata[, 1:2], pca_scores[, 1:3])

  if (add_occurrences == TRUE) {
    pc_occ <- pc3[(length(pc3[, 1]) - length(pdata[, 1]) + 1):length(pc3[, 1]), ]
    pc_points <- sp::SpatialPointsDataFrame(coords = pc_occ[, 1:2], data = pc_occ[, 3:dim(pc3)[2]],
                                            proj4string = WGS84)
  }

  if (dim(pc3)[1] > max_background) {
    pc3 <- pc3[sample(row.names(pc3), max_background), ]
  }

  pc_var <- sp::SpatialPointsDataFrame(coords = pc3[, 1:2], data = pc3[, 3:dim(pc3)[2]],
                                       proj4string = WGS84)

  # getting the species ranges from objects in ranges, and
  # getting environmental (PCs) data in ranges
  if (isnested(r)) {
    cat("\nGetting environmental conditions inside ranges, please wait...\n")
    env_ranges <- list()
    for (i in 1:length(ranges)) {
      sp_ranges <- sp::spTransform(ranges[[i]]$Species_range, WGS84)
      env_ranges[[i]] <- pc_var[sp_ranges, ]
      cat("Progress: ", i, "of", length(ranges) ,"\n")
    }
  }else {
    sp_ranges <- sp::spTransform(ranges$Species_range, WGS84)
    cat("\nGetting environmental conditions inside range, please wait...\n")
    env_ranges <- pc_var[sp_ranges, ]
  }

  rnames <- names(ranges)

  # range colors
  if (is.null(range_colors)) {
    colors <- c("darkorange", "mediumblue", "pink", "turquoise1", "black", "purple", "green")
  }else {
    colors <- range_colors
  }

  # plot
  cat("\nCreating an interactive visualization...\n")
  if (ranges_representation == "clouds") {
    opa <- 0.06
    opa1 <- alpha
  }
  if (ranges_representation == "ellipsoids") {
    opa <- 0.06
    opa1 <- alpha
  }

  p <- plotly::plot_ly()
  p <- plotly::add_trace(p, x = pc_var$PC1, y = pc_var$PC2, z = pc_var$PC3, mode = "markers", type = "scatter3d",
                         marker = list(size = 3, color = background_color, opacity = opa, symbol = 104),
                         name = "Available space") %>%
    plotly::layout(scene = list(xaxis = list(title = "PC 1", backgroundcolor="white", showbackground=TRUE,
                                     titlefont = list(color = "black", family = "Arial", size = 15)),
                        yaxis = list(title = "PC 2", backgroundcolor="white", showbackground=TRUE,
                                     titlefont = list(color = "black", family = "Arial", size = 15)),
                        zaxis = list(title = "PC 3", backgroundcolor="white", showbackground=TRUE,
                                     titlefont = list(color = "black", family = "Arial", size = 15)),
                        camera = list(eye = list(x = eye_camera[1], y = eye_camera[2], z = eye_camera[3]))),
                   legend = list(orientation = "h"))

  if (ranges_representation == "clouds") {
    for(i in 1:length(env_ranges)) {
      env <- env_ranges[[i]]@data
      p <- plotly::add_trace(p, x = env$PC1, y = env$PC2, z = env$PC3,
                             type = "scatter3d", mode = "markers",
                             marker = list(size = 4, color = colors[i],
                                           opacity = opa1, symbol = 104), name = paste("Range", rnames[i]))
    }
  }
  if (ranges_representation == "ellipsoids") {
    for(i in 1:length(env_ranges)) {
      ell <- rgl::ellipse3d(cov(env_ranges[[i]]@data))
      p <- plotly::add_trace(p, x = ell$vb[1, ], y = ell$vb[2, ], z = ell$vb[3, ],
                             type = "scatter3d", size = 1,
                             mode = "markers",
                             marker = list(color = colors[i],
                                           opacity = opa1), name = paste("Range", rnames[i]))
    }
  }
  if (add_occurrences == TRUE) {
    points <- pc_points@data
    p <- plotly::add_trace(p, x = points$PC1, y = points$PC2, z = points$PC3, mode = "markers", type = "scatter3d",
                           marker = list(size = 5, color = "black", symbol = 104), name = "Occurrences")
  }

  # present the figure
  print(p)

  cat("\nFor further work with the figure use the object created with the function.\n")

  # return results
  return(p)
}

#' Helper function to test if lists are nested.
#' @param l list to be tested.
#' @export
isnested <- function(l) {
  stopifnot(is.list(l))
  for (i in l) {
    if (is.list(i)) return(TRUE)
  }
  return(FALSE)
}
