#' get_utm_crs returns the crs for a UTM in the northern hemisphere.  Example:    Montreal is in UTM zone 18, thus crs 32618
#'
#' @param longitude
#'
#' @return
#' @export
#'
#' @examples
get_utm_crs <- function(longitude){ 32600 + ceiling((longitude - -180)/ 6)} #  pour calculer des buffers ronds en mètres comme dans le day 5 de https://gitlab.com/dickoa/30daymapchallenge/-/blob/master/day5/day5-blue.R
#  la UTM zone (genre 19N pour québec à longitude -71   se trouve en comptant combien de zones de 6 degrés de longitude tu es à partir de -180 degrés... le CRS c'est 32600 + numéro de zone)


#' get_circle returns a circle of radius "radius" kilometers around lat/lon
#'
#' @param lat
#' @param lon
#' @param radius
#'
#' @return
#' @export
#'
#' @examples
get_circle  <- function(lat, lon, radius){
  dplyr::tibble(lat = lat, lon = lon) %>%
    sf::st_as_sf(coords = c("lon","lat"), crs = 4326) %>%
    sf::st_transform( crs = get_utm_crs(lon)) %>%
    sf::st_buffer(dist = units::set_units(radius, km))  %>%
    sf::st_transform(4326)
}

#' get_populations_from_polygon   returns the canadian population within a polygon
#'
#' @param sf_tibble
#'
#' @return
#' @export
#'
#' @examples
get_populations_from_polygon <- function(sf_tibble,use_cancensus = FALSE){

  # no longer require cancensus to save on API calls.
  #Instead I included the shapefiles for CD, CSD and DAs to replace calling cancensus::get_census() and
  #created a custom get_intersecting_geos() function to replace calling cancensus::get_intersecting_geometries

  if(use_cancensus){
    intersecting_das <- cancensus::get_intersecting_geometries("CA16", level = "DA", geometry = sf_tibble, quiet= TRUE)
    census_data <- cancensus::get_census("CA16", regions = intersecting_das, geo_format ="sf", quiet = TRUE)
  } else {
  intersecting_das <- get_intersecting_geos(sf_tibble$geometry)$DA
  census_data <- shp_da %>% dplyr::filter(GeoUID %in% intersecting_das)
  }

  populations_in_geometry <- tongfen::tongfen_estimate(
    sf_tibble,
    census_data %>% dplyr::filter(!is.na(Population)),
    tongfen::meta_for_additive_variables("census_data", "Population")
  )
  return(populations_in_geometry)
}

#' get_populations_from_lat_lon_radius returns the canadian population within a circle defined by lat, lon and radius in kilometers
#'
#' @param lat
#' @param lon
#' @param radius
#'
#' @return
#' @export
#'
#' @examples
get_populations_from_lat_lon_radius <- function(lat,lon, radius){
  z <- get_circle(lat, lon, radius)
  get_populations_from_polygon(z)
}

#' get_populations_from_address_radius returns the canadian population within a circle defined by an address (without the postal code) and a radius in kilometers
#'
#' @param adresse
#' @param radius
#'
#' @return
#' @export
#'
#' @examples
get_populations_from_address_radius <- function(adresse, radius){

  geocoded <- tidygeocoder::geocode(dplyr::tibble(address = adresse), addr = address)

  z <- get_circle(geocoded$lat, geocoded$long, radius)
  get_populations_from_polygon(z)

}

#' get_intersecting_geos returns the CDs, CSDs and DAs that intersect with a geometry
#'
#' @param geometry
#'
#' @return
#' @export
#'
#' @examples
get_intersecting_geos <- function(geometry){
  intersecting_cd <- shp_cd[sf::st_intersects(geometry, shp_cd, sparse = FALSE),]$GeoUID

  potential_csd <- shp_csd %>% dplyr::filter(CD_UID %in% intersecting_cd)

  intersecting_csd <- potential_csd[sf::st_intersects(geometry, potential_csd, sparse = FALSE),]$GeoUID

  potential_da <- shp_da %>% dplyr::filter(CSD_UID %in% intersecting_csd)
  intersecting_da <- potential_da[sf::st_intersects(geometry, potential_da, sparse = FALSE),]$GeoUID
return(list("CD" = intersecting_cd, "CSD" = intersecting_csd, "DA" = intersecting_da))
}


