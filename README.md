
<!-- README.md is generated from README.Rmd. Please edit that file -->
reversegeocoder
===============

`reversegeocoder` allows for a fast(er) solution to a common problem: you have a large set of spatial points and would like to find out in which polygon (e.g. country) each point is located. Although several R libraries implement spatial joins, these generally do not use a spatial index on the polygons and can thus be relatively show in this particular use case. `reversegeocoder` uses the fast R-tree index as implemented in Vladimir Agafonkin's [rbush](https://github.com/mourner/rbush) package. This provides a significant performance improvement, especially for real-time or streaming scenarios where the set of polygons does not change but new points are coming in continuously. With reversegeocoder the spatial index will be re-used for every new lookup.

Installation
------------

You can install reversegeocoder from github with:

``` r
# install.packages("devtools")
devtools::install_github("atepoorthuis/reversegeocoder")
```

Example
-------

This is a basic example which shows you how to solve a common problem:

``` r
library(sf)
library(geojsonio)
library(tidyverse)
library(rnaturalearth)
library(purrr)
library(microbenchmark)
library(reversegeocoder)

countries <- ne_countries(returnclass = "sf") %>% 
  select(adm0_a3)
countries_json <- geojson_list(countries) %>% unclass()

points_sf <- st_sample(countries, size = rep(50, nrow(countries)))
print(length(points_sf))
#> [1] 8662

points_mat <- points_sf %>% 
  st_sfc() %>% 
  st_coordinates()

ctx <- rg_load_polygons(countries_json)

print(microbenchmark(
  rg_query = map_chr(split(points_mat, 1:nrow(points_mat)), function(point) rg_query(ctx, point, "adm0_a3")),
  rg_batch_query = rg_batch_query(ctx, points_mat, "adm0_a3"),
  single_point_st_join = map_chr(split(points_mat, 1:nrow(points_mat)), function(point) st_join(st_sf(st_sfc(st_point(point)), crs = 4326), countries) %>% pull(adm0_a3)),
  batch_st_join = st_join(points_sf %>% st_sf, countries),
  times = 1)
)
#> Unit: milliseconds
#>                  expr         min          lq        mean      median
#>              rg_query   490.28872   490.28872   490.28872   490.28872
#>        rg_batch_query    79.69626    79.69626    79.69626    79.69626
#>  single_point_st_join 65601.87603 65601.87603 65601.87603 65601.87603
#>         batch_st_join   265.67882   265.67882   265.67882   265.67882
#>           uq         max neval
#>    490.28872   490.28872     1
#>     79.69626    79.69626     1
#>  65601.87603 65601.87603     1
#>    265.67882   265.67882     1
```
