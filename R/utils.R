rg_ctx <- function() {
  ctx <- V8::v8()
  ctx$source(system.file("js/which-polygon-browserify.min.js",
                         package = packageName()))
  ctx
}

rg_load_polygons <- function(data) {
  ctx <- rg_ctx()
  ctx$assign("geojson", data)
  ctx$eval("var query = whichPolygon(geojson);")
  ctx$assign("batch", V8::JS("function(points, field){var results = []; for (var i = 0; i < points.length; i++) {results.push(query(points[i])[field]);} return results;}"))
  ctx
}

rg_query <- function(ctx, point, field) {
  # query([30.5, 50.5])['field']
  #q <- sprintf("var result = query([%s, %s]); result = (result == null) ? null : result[%s]", point[1], point[2], paste0("'", field, "'"))
  q <- sprintf("var result = query([%s, %s]); (result == null) ? '' : result[%s]", point[1], point[2], paste0("'", field, "'"))
  ctx$eval(q)
}

rg_batch_query <- function(ctx, points, field) {
  # query([30.5, 50.5])['field']
  ctx$assign("points", points)
  q <- sprintf("batch(points, %s)", paste0("'", field, "'"))
  ctx$assign("out", V8::JS(q))
  ctx$get("out")
}
