#' Create Javascript/V8 context
#'
#' Creates the initial V8 context and loads the which-polygon library
#' @return V8 context
#'
rg_ctx <- function() {
  ctx <- V8::v8()
  ctx$source(system.file("js/which-polygon-browserify.min.js",
                         package = packageName()))
  ctx
}

#' Load polygons
#'
#' Creates a V8 context and loads the polygons, creating a spatial index
#'
#' @param data R list object containing the polygons to be indexed
#'
#' @return V8 context with spatial polygons loaded/indexed
#' @export
#'
#' @examples
rg_load_polygons <- function(data) {
  ctx <- rg_ctx()
  ctx$assign("geojson", data)
  ctx$eval("var query = whichPolygon(geojson);")
  ctx$assign("batch", V8::JS("function(points, field){var results = []; for (var i = 0; i < points.length; i++) {var result = query(points[i])  == null ? null : query(points[i])[field]; results.push(result);} return results;}"))
  ctx
}

#' Look up single point
#'
#' @param ctx V8 context created by rg_load_polygons
#' @param point vector with x/y coordinates for point
#' @param field name of the field that should be returned for the matching polygon
#'
#' @return value of the field chosen in `field` for the matching polygon
#' @export
#'
#' @examples
rg_query <- function(ctx, point, field) {
  q <- sprintf("var result = query([%s, %s]); (result == null) ? null : result[%s]", point[1], point[2], paste0("'", field, "'"))
  ctx$eval(q)
}

#' Look up vector of points
#'
#' @param ctx V8 context created by rg_load_polygons
#' @param points list of points
#' @param field name of the field that should be returned for the matching polygon
#'
#' @return vector of values of the field chosen in `field` for the matching polygon for each point
#' @export
#'
#' @examples
rg_batch_query <- function(ctx, points, field) {
  ctx$assign("points", points)
  q <- sprintf("batch(points, %s)", paste0("'", field, "'"))
  ctx$assign("out", V8::JS(q))
  ctx$get("out")
}
