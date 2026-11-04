# Predict sediment carbon stocks for mapped European seagrass meadows with GPR.
# Uses saved-model preprocessing from modelling/R/ml.R; does not refit models.
# Usage: Rscript predict_gpr_at_maps.R MODEL.rds MEADOWS.csv|gpkg OUTPUT_DIR [DEPTH_CM]

prepare_meadow_input <- function(meadow_path, output_dir) {
  if (!grepl("\\.csv$", meadow_path, ignore.case = TRUE)) {
    return(normalizePath(meadow_path, mustWork = TRUE))
  }
  cache_path <- file.path(output_dir, "seagrass_meadows_gpr.gpkg")
  if (file.exists(cache_path)) {
    cat("Using cached meadow polygons:", cache_path, "\n")
    return(normalizePath(cache_path, mustWork = TRUE))
  }

  required <- c("habsubtype", "eunis_code", "anxi_name", "geom")
  header <- readr::read_csv(
    meadow_path, n_max = 0, show_col_types = FALSE, progress = FALSE
  )
  missing_columns <- setdiff(required, names(header))
  if (length(missing_columns)) {
    stop(
      "EOV polygon CSV is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  temporary_path <- tempfile(
    pattern = "seagrass_meadows_gpr_", tmpdir = output_dir, fileext = ".gpkg"
  )
  on.exit(if (file.exists(temporary_path)) unlink(temporary_path), add = TRUE)
  layer_created <- FALSE
  callback <- readr::SideEffectChunkCallback$new(function(chunk, position) {
    habsubtype <- as.character(chunk$habsubtype)
    eunis_code <- as.character(chunk$eunis_code)
    anxi_name <- as.character(chunk$anxi_name)
    species <- rep("Other", nrow(chunk))
    species[habsubtype %in% c("Cymodocea beds", "Cymodocea nodosa")] <-
      "Cymodocea nodosa"
    species[habsubtype %in% c("Dead mattes of Posidonia oceanica", "Posidonia oceanica")] <-
      "Posidonia oceanica"
    species[habsubtype %in% c(
      "Zostera beds", "Zostera marina", "Zostera marina beds",
      "Zostera marina/angustifolia beds"
    )] <- "Zostera marina"
    species[habsubtype %in% c("Zostera noltii", "Zostera noltii beds")] <-
      "Zostera noltei"
    species[habsubtype %in% "Unknown"] <- "Unspecified"
    species[habsubtype %in% "Ruppia beds"] <- "Remove"
    species[eunis_code %in% c("A5.531", "A5.5312", "A5.5313", "A5.53131", "A5.53132")] <-
      "Cymodocea nodosa"
    species[eunis_code %in% c("A5.535", "A5.5352", "A5.5353", "A5.5354", "MB252")] <-
      "Posidonia oceanica"
    species[eunis_code %in% c("A5.5331", "A5.533", "A5.5333")] <-
      "Zostera marina"
    species[eunis_code %in% c("A2.61", "A2.611", "A2.6111", "A5.5332")] <-
      "Zostera noltei"
    species[eunis_code %in% c("A5.53", "MB522")] <- "Unspecified"
    species[eunis_code %in% c("A5.529", "A5.5343", "A6.61")] <- "Remove"
    species[anxi_name %in% c("Posidonia beds", "Posidonia oceanica beds")] <-
      "Posidonia oceanica"

    supported <- species %in% c(
      "Cymodocea nodosa", "Posidonia oceanica", "Zostera marina",
      "Zostera noltei", "Unspecified"
    ) & !is.na(chunk$geom) & nzchar(chunk$geom)
    if (!any(supported)) return(invisible(NULL))

    chunk <- chunk[supported, , drop = FALSE]
    geometries <- sf::st_as_sfc(as.character(chunk$geom), crs = 3857)
    attributes <- data.frame(
      seagrass_species = species[supported],
      stringsAsFactors = FALSE
    )
    for (column in intersect(c("FID", "id", "habsubtype", "eunis_code", "anxi_name"),
                             names(chunk))) {
      attributes[[column]] <- chunk[[column]]
    }
    meadows <- sf::st_sf(attributes, geometry = geometries)
    meadows <- sf::st_transform(meadows, 4326)
    meadows <- sf::st_crop(
      meadows,
      xmin = -8.85, ymin = 34.65, xmax = 33.30, ymax = 60.11
    )
    meadows <- meadows[
      !sf::st_is_empty(meadows) &
        sf::st_geometry_type(meadows) %in% c("POLYGON", "MULTIPOLYGON"),
      ,
      drop = FALSE
    ]
    if (!nrow(meadows)) return(invisible(NULL))

    if (!layer_created) {
      sf::st_write(
        meadows, temporary_path, layer = "meadows", delete_dsn = TRUE, quiet = TRUE
      )
      layer_created <<- TRUE
    } else {
      sf::st_write(
        meadows, temporary_path, layer = "meadows", append = TRUE, quiet = TRUE
      )
    }
    cat("Prepared", nrow(meadows), "European meadow polygon(s) from CSV chunk.\n")
    invisible(NULL)
  })

  readr::read_csv_chunked(
    meadow_path,
    callback = callback,
    chunk_size = 10000L,
    col_select = tidyselect::all_of(required),
    show_col_types = FALSE,
    progress = FALSE
  )
  if (!layer_created) {
    stop("No supported seagrass polygons were found in the European study area.")
  }
  if (!file.rename(temporary_path, cache_path)) {
    stop("Could not save prepared meadow polygons to: ", cache_path, call. = FALSE)
  }
  cat("Cached prepared meadow polygons at:", cache_path, "\n")
  normalizePath(cache_path, mustWork = TRUE)
}

predict_gpr_at_maps <- function(args = commandArgs(trailingOnly = TRUE)) {
  usage <- paste(
    "Usage: Rscript predict_gpr_at_maps.R MODEL.rds MEADOWS.csv|gpkg OUTPUT_DIR [DEPTH_CM]",
    "MODEL.rds: trusted GPR final-model bundle produced by modelling/R/fit_final_models.R.",
    "MEADOWS.csv: seagrass EOV polygon CSV with geom WKT (EPSG:3857);",
    "MEADOWS.gpkg: polygon layer with a CRS and model category columns",
    "(e.g. seagrass_species, using training labels; region can be assigned from MEOW).",
    "Environmental NetCDF inputs must be in codebase/v2/src/data/env_rasters/.",
    "DEPTH_CM defaults to 100; it must match the depth represented by the model target.",
    "Outputs: carbon_stock_map.png, carbon_stock_predictions.gpkg and .csv.",
    sep = "\n"
  )
  if (identical(args, "--help")) {
    cat(usage, "\n")
    return(invisible(NULL))
  }
  if (!length(args) %in% c(3L, 4L)) stop(usage, call. = FALSE)
  model_path <- normalizePath(args[[1]], mustWork = TRUE)
  meadow_path <- normalizePath(args[[2]], mustWork = TRUE)
  output_dir <- if (grepl("^([A-Za-z]:[/\\\\]|[/\\\\]{2})", args[[3]]) ||
                    startsWith(args[[3]], "/")) {
    args[[3]]
  } else {
    file.path(getwd(), args[[3]])
  }
  output_dir <- normalizePath(output_dir, mustWork = FALSE)
  depth_cm <- if (length(args) == 4L) suppressWarnings(as.numeric(args[[4]])) else 100
  if (!is.finite(depth_cm) || depth_cm <= 0) {
    stop("DEPTH_CM must be a finite positive number.", call. = FALSE)
  }

  init_path <- file.path("modelling", "R", "init_repo.R")
  if (!file.exists(init_path)) {
    script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (!length(script_arg)) stop("Run from codebase/v2/src or use an absolute script path.")
    script_path <- normalizePath(sub("^--file=", "", script_arg[[1]]), mustWork = TRUE)
    init_path <- file.path(dirname(script_path), "modelling", "R", "init_repo.R")
  }
  source(init_path)
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  project_root <- dirname(dirname(dirname(normalizePath(init_path, mustWork = TRUE))))
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("Package 'renv' is required; restore the codebase/v2/src/renv.lock environment first.")
  }
  setwd(project_root)
  renv::load(project = project_root)
  seagrass_init_repo(
    packages = c("sf", "ggplot2", "readr"),
    include_helpers = TRUE,
    source_files = c(
      "modelling/R/extract_covariates_from_rasters.R",
      "modelling/R/assign_region_from_latlon.R"
    ),
    require_core_inputs = FALSE,
    check_renv = TRUE
  )

  obj <- readRDS(model_path)
  if (!is.list(obj) || is.null(obj$model)) stop("MODEL.rds must contain a fitted model bundle.")
  model_type <- infer_model_type(obj)
  if (!identical(model_type, "GPR")) {
    stop("The model file does not contain a GPR model: ", model_path, call. = FALSE)
  }
  pvars <- obj$predictor_vars
  if (!is.character(pvars) || !length(pvars) || anyNA(pvars) ||
      any(!nzchar(pvars)) || anyDuplicated(pvars)) {
    stop("The model bundle must contain unique predictor_vars.")
  }
  obj$predictor_vars <- pvars
  cat("Predictor variables for raster covariates:\n")
  print(pvars)

  if (!dir.exists(output_dir) &&
      !dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)) {
    stop("Could not create output directory: ", output_dir, call. = FALSE)
  }
  meadow_path <- prepare_meadow_input(meadow_path, output_dir)
  meadows <- sf::st_read(meadow_path, quiet = TRUE)
  if (!nrow(meadows) || is.na(sf::st_crs(meadows))) {
    stop("MEADOWS must contain features with a defined CRS.")
  }
  meadows <- sf::st_make_valid(meadows)
  if (any(sf::st_is_empty(meadows)) ||
      any(!sf::st_geometry_type(meadows) %in% c("POLYGON", "MULTIPOLYGON"))) {
    stop("MEADOWS must contain non-empty polygon or multipolygon geometries.")
  }
  meadows <- sf::st_transform(meadows, 4326)
  equal_area <- sf::st_transform(meadows, 3035)
  area_m2 <- as.numeric(sf::st_area(equal_area))
  if (any(!is.finite(area_m2) | area_m2 <= 0)) stop("All meadow areas must be positive.")
  # One representative point per meadow; use a projected CRS to keep it inside.
  points <- sf::st_transform(sf::st_point_on_surface(sf::st_geometry(equal_area)), 4326)
  xy <- sf::st_coordinates(points)
  newdata <- as.data.frame(sf::st_drop_geometry(meadows))
  newdata$longitude <- xy[, 1]
  newdata$latitude <- xy[, 2]

  raster_vars <- intersect(pvars, names(RASTER_CONFIG))
  missing_vars <- setdiff(pvars, c(raster_vars, names(newdata), "region"))
  if (length(missing_vars)) {
    stop("Missing model predictors (supply meadow attributes or NetCDF rasters): ",
         paste(missing_vars, collapse = ", "))
  }
  if ("region" %in% pvars) newdata <- assign_region_from_latlon(newdata)
  if (length(raster_vars)) {
    newdata <- extract_covariates_at_points(
      newdata, covariates = raster_vars, use_closest = FALSE
    )
  }
  newdata <- process_rs_covariates(newdata)
  valid <- complete.cases(newdata[, pvars, drop = FALSE])
  for (v in pvars) {
    if (is.numeric(newdata[[v]])) valid <- valid & is.finite(newdata[[v]])
  }
  status <- ifelse(valid, "predicted", "missing_covariates")
  category_levels <- obj$encoding$levels
  category_levels <- category_levels %||% list()
  for (v in intersect(names(category_levels), pvars)) {
    unknown <- !is.na(newdata[[v]]) & !as.character(newdata[[v]]) %in% category_levels[[v]]
    status[unknown] <- "unknown_category"
    valid[unknown] <- FALSE
  }
  if (!any(valid)) stop("No meadows have complete, supported model predictors.")

  density <- density_se <- rep(NA_real_, nrow(newdata))
  rows <- which(valid)
  for (start in seq.int(1L, length(rows), by = 1000L)) {
    ix <- rows[seq.int(start, min(start + 999L, length(rows)))]
    prediction <- predict_model(obj, newdata[ix, , drop = FALSE], se = TRUE)
    if (length(prediction$mean) != length(ix)) stop("Model returned an unexpected prediction length.")
    density[ix] <- prediction$mean
    if (!is.null(prediction$se)) {
      if (length(prediction$se) != length(ix)) stop("Model returned an unexpected SE length.")
      density_se[ix] <- prediction$se
    }
  }
  invalid_prediction <- valid & (!is.finite(density) | density < 0)
  status[invalid_prediction] <- "invalid_prediction"
  density[invalid_prediction] <- NA_real_
  density_se[!is.finite(density_se) | density_se < 0 | is.na(density)] <- NA_real_
  if (!any(is.finite(density))) stop("No finite non-negative carbon density predictions were produced.")

  meadows$prediction_status <- status
  meadows$longitude <- newdata$longitude
  meadows$latitude <- newdata$latitude
  meadows$area_m2 <- area_m2
  meadows$depth_cm <- depth_cm
  meadows$carbon_density_g_cm3 <- density
  meadows$carbon_density_se_g_cm3 <- density_se
  # g C/cm3 * depth cm * 10^4 cm2/m2; convert grams to kg or Gg.
  meadows$stock_kg_ha <- density * depth_cm * 1e5
  meadows$stock_se_kg_ha <- density_se * depth_cm * 1e5
  meadows$stock_Gg <- density * depth_cm * 1e4 * area_m2 / 1e9
  meadows$stock_se_Gg <- density_se * depth_cm * 1e4 * area_m2 / 1e9
  meadows$source_model <- basename(model_path)

  sf::st_write(
    meadows, file.path(output_dir, "carbon_stock_predictions.gpkg"),
    layer = "carbon_stock", delete_layer = TRUE, quiet = TRUE
  )
  write.csv(
    sf::st_drop_geometry(meadows),
    file.path(output_dir, "carbon_stock_predictions.csv"), row.names = FALSE
  )
  map <- ggplot2::ggplot(meadows) +
    ggplot2::geom_sf(ggplot2::aes(fill = stock_kg_ha), colour = NA) +
    ggplot2::scale_fill_viridis_c(name = "Sediment carbon\n(kg C/ha)", na.value = "grey80") +
    ggplot2::coord_sf(crs = sf::st_crs(4326)) +
    ggplot2::labs(
      title = "Predicted seagrass sediment carbon stock",
      subtitle = paste(basename(model_path), "| sediment depth:", depth_cm, "cm"),
      x = NULL, y = NULL
    ) +
    ggplot2::theme_minimal()
  ggplot2::ggsave(
    file.path(output_dir, "carbon_stock_map.png"), map,
    width = 10, height = 8, dpi = 300
  )
  cat("Prediction status:\n")
  print(table(status))
  cat("Outputs saved to:", output_dir, "\n")
  invisible(meadows)
}

if (sys.nframe() == 0L) predict_gpr_at_maps()
