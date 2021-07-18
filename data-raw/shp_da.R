## code to prepare `shp_da` dataset goes here
library(cancensus)
library(sf)
shp_da <-  cancensus::get_census("CA16", regions = list(C = "1"),level = "DA", geo_format ="sf", quiet = TRUE)
shp_da <- shp_da %>% st_make_valid()
usethis::use_data(shp_da, overwrite = TRUE)


shp_cd <-  cancensus::get_census("CA16", regions = list(C = "1"),level = "CD", geo_format ="sf", quiet = TRUE)
shp_cd <- shp_cd %>% st_make_valid()
usethis::use_data(shp_cd, overwrite = TRUE)


shp_csd <-  cancensus::get_census("CA16", regions = list(C = "1"),level = "CSD", geo_format ="sf", quiet = TRUE)
shp_csd <- shp_csd %>% st_make_valid()
usethis::use_data(shp_csd, overwrite = TRUE)
