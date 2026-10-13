# Predict carbon density at point locations using a saved GPR model.
#
# This script includes the functions it needs from the v2 project, so it can be
# run or sourced without sourcing the modelling helper scripts.

seagrass_find_v2_root <- function(start_dirs = getwd(),
                                  project_path = Sys.getenv("SEAGRASS_V2_ROOT", "")) {
  if (!is.character(project_path) || length(project_path) != 1L ||
      is.na(project_path)) {
    stop("SEAGRASS_V2_ROOT must be a single directory path.", call. = FALSE)
  }
  offsets <- c("", "src", file.path("codebase", "v2", "src"))
  checked <- character()
  check_directory <- function(directory) {
    for (offset in offsets) {
      candidate <- normalizePath(
        file.path(directory, offset), winslash = "/", mustWork = FALSE
      )
      checked <<- c(checked, candidate)
      markers <- file.path(candidate, c(
        "predict_gpr_at_points.R",
        file.path("modelling", "R", "init_repo.R"),
        file.path("modelling", "R", "project_root.R")
      ))
      if (all(file.exists(markers))) {
        return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
      }
    }
    NA_character_
  }
  if (nzchar(project_path)) {
    root <- check_directory(path.expand(project_path))
    if (!is.na(root)) return(root)
    stop(
      "Invalid SEAGRASS_V2_ROOT: ", project_path,
      "\nExpected the clone root, codebase/v2, or codebase/v2/src.",
      "\nWorking directory: ", getwd(),
      "\nChecked:\n  ", paste(unique(checked), collapse = "\n  "),
      call. = FALSE
    )
  }
  source_files <- unlist(lapply(sys.frames(), function(frame) {
    ofile <- get0("ofile", envir = frame, inherits = FALSE)
    if (is.character(ofile) && length(ofile) == 1L && nzchar(ofile)) ofile
  }), use.names = FALSE)
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  starts <- c(start_dirs, dirname(source_files))
  if (length(script_arg) > 0L) {
    starts <- c(starts, dirname(sub("^--file=", "", script_arg[[1L]])))
  }
  for (start in unique(starts)) {
    directory <- normalizePath(start, winslash = "/", mustWork = FALSE)
    for (i in seq_len(40L)) {
      root <- check_directory(directory)
      if (!is.na(root)) return(root)
      parent <- dirname(directory)
      if (identical(parent, directory)) break
      directory <- parent
    }
  }
  stop(
    "Cannot find the v2 project root. Set SEAGRASS_V2_ROOT to the clone root, ",
    "codebase/v2, or codebase/v2/src.",
    "\nChecked:\n  ", paste(unique(checked), collapse = "\n  "),
    call. = FALSE
  )
}

inspect_nc_file <- function(nc_path) {
  nc <- RNetCDF::open.nc(nc_path)
  on.exit(RNetCDF::close.nc(nc), add = TRUE)
  nvars <- RNetCDF::file.inq.nc(nc)$nvars
  for (j in seq_len(nvars) - 1L) {
    variable <- RNetCDF::var.inq.nc(nc, j)
    if (length(variable$dimids) != 2L) next
    dim_names <- vapply(
      variable$dimids,
      function(d) RNetCDF::dim.inq.nc(nc, d)$name,
      character(1L)
    )
    lat_dims <- grep("lat", dim_names, ignore.case = TRUE)
    lon_dims <- grep("lon", dim_names, ignore.case = TRUE)
    if (length(lat_dims) == 0L || length(lon_dims) == 0L) next
    return(list(
      varname = variable$name,
      lat_var = dim_names[lat_dims[1L]],
      lon_var = dim_names[lon_dims[1L]]
    ))
  }
  NULL
}

build_covariate_config_from_dir <- function(raster_dir = RASTER_DIR) {
  base <- file.path(project_root, raster_dir)
  if (!dir.exists(base)) stop("Raster directory not found: ", base)
  files <- list.files(base, pattern = "[.]nc$", full.names = FALSE)
  out <- list()
  for (file in files) {
    info <- tryCatch(
      inspect_nc_file(file.path(base, file)),
      error = function(e) {
        warning("Skipping ", file, ": ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(info)) next
    name <- tolower(gsub("-", "_", sub("[.]nc$", "", file), fixed = TRUE))
    out[[name]] <- list(
      file = file.path(raster_dir, file),
      varname = info$varname,
      lat_var = info$lat_var,
      lon_var = info$lon_var
    )
  }
  out
}

extract_from_nc <- function(nc_file, varname, points, use_closest = TRUE,
                            method = "nearest") {
  nc_path <- file.path(project_root, nc_file)
  if (!file.exists(nc_path)) stop("NetCDF file not found: ", nc_path)
  raster <- terra::rast(nc_path)
  if (!is.null(varname) && nzchar(varname) && varname %in% names(raster)) {
    raster <- raster[[varname]]
  } else if (terra::nlyr(raster) > 1L) {
    warning(
      "Variable '", varname, "' not found in ", nc_file,
      "; using first layer in file. Check the raster configuration."
    )
    raster <- raster[[1L]]
  }
  if (!all(c("longitude", "latitude") %in% names(points))) {
    stop("points must have 'latitude' and 'longitude' columns")
  }
  coords <- cbind(points$longitude, points$latitude)
  terra_method <- if (identical(tolower(method), "bilinear")) "bilinear" else "simple"
  values <- as.numeric(terra::extract(raster, coords, method = terra_method)[, 1L])
  if (use_closest && anyNA(values) && requireNamespace("FNN", quietly = TRUE)) {
    missing <- which(is.na(values))
    raster_values <- terra::values(raster, mat = FALSE)
    valid_cells <- which(!is.na(raster_values))
    if (length(valid_cells) > 0L) {
      valid_xy <- terra::xyFromCell(raster, valid_cells)
      nearest <- FNN::get.knnx(
        data = valid_xy,
        query = coords[missing, , drop = FALSE],
        k = 1L
      )$nn.index[, 1L]
      values[missing] <- raster_values[valid_cells][nearest]
    }
  }
  values
}

extract_covariates_at_points <- function(points, covariates = names(RASTER_CONFIG),
                                         use_closest = TRUE, method = "nearest") {
  if (!all(c("latitude", "longitude") %in% names(points))) {
    stop("points must have 'latitude' and 'longitude' columns")
  }
  result <- points
  for (covariate in tolower(covariates)) {
    config <- RASTER_CONFIG[[covariate]]
    if (is.null(config)) {
      stop("Raster configuration not found for covariate: ", covariate)
    }
    result[[covariate]] <- extract_from_nc(
      nc_file = config$file,
      varname = config$varname,
      points = points,
      use_closest = use_closest,
      method = method
    )
  }
  result
}

process_rs_covariates <- function(dat, rs_covariates = c(
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.CHL.chlor_a.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.IOP.adg_443.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.IOP.bbp_443.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.KD.Kd_490.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.RRS.Rrs_443.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.RRS.Rrs_620.4km"
)) {
  existing_vars <- intersect(rs_covariates, colnames(dat))
  if (length(existing_vars) == 0L) return(dat)
  dat <- as.data.frame(dat)
  for (variable in existing_vars) {
    if (is.numeric(dat[[variable]])) {
      dat[[variable]] <- pmax(dat[[variable]], 0, na.rm = FALSE)
    }
  }
  dat
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

normalize_scale_params <- function(sp) {
  if (is.null(sp)) return(NULL)
  if (!is.null(sp$means)) return(sp)
  if (!is.null(sp$x_center)) return(list(means = sp$x_center, sds = sp$x_scale))
  NULL
}

get_species_fixed_vars <- function(predictor_vars) {
  intersect(predictor_vars, "seagrass_species")
}

apply_scaling <- function(data, scale_params, predictor_vars = NULL) {
  data <- as.data.frame(data)
  for (variable in names(scale_params$means)) {
    if (variable %in% names(data)) {
      data[[variable]] <- (data[[variable]] - scale_params$means[variable]) /
        scale_params$sds[variable]
    }
  }
  data
}

apply_categorical_encoding <- function(data, encoding, predictor_vars) {
  if (is.null(encoding) || is.null(encoding$levels) ||
      length(encoding$levels) == 0L) {
    return(data[, predictor_vars, drop = FALSE])
  }
  result <- as.data.frame(data[, predictor_vars, drop = FALSE])
  for (variable in names(encoding$levels)) {
    if (!variable %in% names(result)) next
    levels <- encoding$levels[[variable]]
    result[[variable]] <- as.integer(factor(
      as.character(result[[variable]]),
      levels = levels
    ))
    result[[variable]][is.na(result[[variable]])] <- 1L
  }
  result
}

prepare_predictors_new_onehot <- function(data, encoding, encoded_names) {
  predictor_vars <- encoding$predictor_vars %||% names(data)
  result <- as.data.frame(data[, predictor_vars, drop = FALSE])
  if (!is.null(encoding$levels) && length(encoding$levels) > 0L) {
    for (variable in names(encoding$levels)) {
      if (variable %in% names(result)) {
        result[[variable]] <- factor(
          as.character(result[[variable]]),
          levels = encoding$levels[[variable]]
        )
      }
    }
  }
  matrix <- model.matrix(~ . - 1, data = result)
  result <- as.data.frame(matrix)
  missing <- setdiff(encoded_names, names(result))
  for (variable in missing) result[[variable]] <- 0
  result[, encoded_names, drop = FALSE]
}

lookup_species_means <- function(species_means, species_vec, fallback = 0) {
  if (is.null(species_means)) return(rep(fallback, length(species_vec)))
  result <- as.numeric(species_means[as.character(species_vec)])
  result[is.na(result)] <- fallback
  result
}

infer_model_type <- function(obj) {
  if (!is.null(obj$model_type)) return(obj$model_type)
  if (inherits(obj$model, "GauPro")) return("GPR")
  stop("Could not infer model type from object.")
}

inverse_response_transform <- function(pred, log = TRUE) {
  if (!log) return(pred)
  exp(pred)
}

predict_model <- function(obj, newdata, se = TRUE) {
  if (!identical(infer_model_type(obj), "GPR")) {
    stop("predict_model in this script only supports GPR models.", call. = FALSE)
  }
  predictor_vars <- obj$predictor_vars
  if (is.null(predictor_vars) || length(predictor_vars) == 0L) {
    stop("The GPR model does not contain predictor_vars.", call. = FALSE)
  }
  X <- newdata[, predictor_vars, drop = FALSE]
  model_cols <- obj$encoded_names %||% predictor_vars
  if (!is.null(obj$encoding)) {
    encoding_type <- obj$encoding$type %||% NA_character_
    if (identical(encoding_type, "one_hot") &&
        !is.null(obj$species_means) &&
        !is.null(obj$encoding$kernel_predictor_vars)) {
      encoding_type <- "gpr_species_adjusted"
    }
    if (identical(encoding_type, "gpr_species_adjusted")) {
      kernel_vars <- obj$encoding$kernel_predictor_vars %||%
        setdiff(predictor_vars, get_species_fixed_vars(predictor_vars))
      X <- newdata[, kernel_vars, drop = FALSE]
      X <- prepare_predictors_new_onehot(X, obj$encoding, model_cols)
      scale_params <- normalize_scale_params(obj$scale_params)
      if (!is.null(scale_params) && length(scale_params$means) > 0L) {
        X <- apply_scaling(X, scale_params, model_cols)
      }
    } else if (identical(encoding_type, "one_hot")) {
      X <- prepare_predictors_new_onehot(X, obj$encoding, model_cols)
      scale_params <- normalize_scale_params(obj$scale_params)
      if (!is.null(scale_params) && length(scale_params$means) > 0L) {
        X <- apply_scaling(X, scale_params, model_cols)
      }
    } else {
      X <- apply_categorical_encoding(X, obj$encoding, predictor_vars)
      scale_params <- normalize_scale_params(obj$scale_params)
      if (!is.null(scale_params) && length(scale_params$means) > 0L) {
        X <- apply_scaling(X, scale_params, model_cols)
      }
    }
  } else {
    scale_params <- normalize_scale_params(obj$scale_params)
    if (!is.null(scale_params) && length(scale_params$means) > 0L) {
      X <- apply_scaling(X, scale_params, model_cols)
    }
  }
  X_mat <- as.matrix(X[, model_cols, drop = FALSE])
  storage.mode(X_mat) <- "double"
  pred_out <- obj$model$pred(X_mat, se.fit = se, return_df = TRUE)
  if (is.list(pred_out) && !is.null(pred_out$mean)) {
    out <- list(
      mean = as.numeric(pred_out$mean),
      se = if (se) as.numeric(pred_out$se) else NULL
    )
  } else {
    out <- list(mean = as.numeric(pred_out), se = NULL)
  }
  species_var <- obj$encoding$species_var %||% NULL
  if (!is.null(obj$species_means) && !is.null(species_var) &&
      species_var %in% names(newdata)) {
    species_adjustment <- lookup_species_means(
      obj$species_means,
      newdata[[species_var]],
      obj$global_mean %||% 0
    )
    out$mean <- out$mean + species_adjustment
  }
  if (isTRUE(obj$log_response)) {
    out$mean <- inverse_response_transform(out$mean, log = TRUE)
    if (!is.null(out$se)) out$se <- out$se * out$mean
  }
  out
}

project_root <- seagrass_find_v2_root()
setwd(project_root)

required_packages <- c("GauPro", "RNetCDF", "readr", "terra")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required package(s): ", paste(missing_packages, collapse = ", "),
    ". Restore the v2 renv environment or install these packages.",
    call. = FALSE
  )
}
if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Package 'readxl' is required. Restore the v2 renv environment.", call. = FALSE)
}

RASTER_DIR <- file.path("data", "env_rasters")
RASTER_CONFIG <- build_covariate_config_from_dir(RASTER_DIR)
if (length(RASTER_CONFIG) == 0L) {
  stop("No NetCDF raster covariates were found in ", file.path(project_root, RASTER_DIR))
}

# Configure these project-root-relative paths before running the script.
input_path <- file.path("data", "review", "PercOC_only_unique_reduced_df_predictions.csv")
model_path <- file.path("data", "review", "GPR_final.rds")
output_path <- file.path(
  "output",
  "review",
  "PercOC_only_unique_reduced_df_predictions_gpr_predictions.csv"
)

input_path <- file.path(project_root, input_path)
model_path <- file.path(project_root, model_path)
output_path <- file.path(project_root, output_path)

if (!file.exists(input_path)) stop("Input file not found: ", input_path, call. = FALSE)
if (!file.exists(model_path)) stop("GPR model file not found: ", model_path, call. = FALSE)

if (grepl("\\.xlsx?$", input_path, ignore.case = TRUE)) {
  input_data <- readxl::read_excel(input_path, sheet = 1)
} else if (grepl("\\.csv$", input_path, ignore.case = TRUE)) {
  input_data <- readr::read_csv(input_path, show_col_types = FALSE)
} else {
  stop("Input must be a .csv, .xls, or .xlsx file: ", input_path, call. = FALSE)
}

required_columns <- c("longitude", "latitude", "seagrass_species")
missing_columns <- setdiff(required_columns, names(input_data))
if (length(missing_columns) > 0L) {
  stop(
    "Input data is missing required column(s): ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

model <- readRDS(model_path)
if (!identical(infer_model_type(model), "GPR")) {
  stop("The model file does not contain a GPR model: ", model_path, call. = FALSE)
}

predictor_vars <- model$predictor_vars
if (is.null(predictor_vars) || length(predictor_vars) == 0L) {
  stop("The GPR model does not contain predictor_vars.", call. = FALSE)
}
print("Predictor variables for raster covariates:")
print(predictor_vars)

raster_covars <- setdiff(
  predictor_vars,
  c("seagrass_species", "longitude", "latitude")
)
print("Raster covariates required by the model:")
print(raster_covars)

# missing_input_predictors <- setdiff(
#   tolower(predictor_vars),
#   tolower(c(names(input_data), raster_covars))
# )
# if (length(missing_input_predictors) > 0L) {
#   print("Missing input predictors:")
#   print(missing_input_predictors)
#   stop(
#     "Input is missing non-raster model predictor(s): ",
#     paste(missing_input_predictors, collapse = ", "),
#     call. = FALSE
#   )
# }

# missing_rasters <- setdiff(
#   tolower(raster_covars), 
#   tolower(raster_covariates)
# )
# if (length(missing_rasters) > 0L) {
#   print("Missing raster covariates:")
#   print(missing_rasters)
#   stop(
#     "Model requires raster covariate(s) not found under data/env_rasters: ",
#     paste(missing_rasters, collapse = ", "),
#     call. = FALSE
#   )
# }

cat("Extracting environmental covariates for", nrow(input_data), "point(s)...\n")
prediction_data <- extract_covariates_at_points(
  points = input_data[, required_columns, drop = FALSE],
  covariates = raster_covars,
  use_closest = TRUE
)
prediction_data <- process_rs_covariates(prediction_data)

missing_values <- raster_covars[
  vapply(
    raster_covars,
    function(variable) any(is.na(prediction_data[[variable]])),
    logical(1)
  )
]
if (length(missing_values) > 0L) {
  warning(
    "Missing extracted covariate values: ",
    paste(missing_values, collapse = ", "),
    call. = FALSE
  )
}

cat("Predicting carbon density for", nrow(input_data), "point(s)...\n")
predictions <- predict_model(model, prediction_data, se = TRUE)
if (length(predictions$mean) != nrow(input_data)) {
  stop("GPR prediction count does not match the number of input rows.", call. = FALSE)
}
input_data$predicted_carbon_density <- predictions$mean
input_data$predicted_se <- predictions$se

output_dir <- dirname(output_path)
if (!dir.exists(output_dir) &&
    !dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)) {
  stop("Could not create output directory: ", output_dir, call. = FALSE)
}
readr::write_csv(input_data, output_path)
cat("Wrote GPR predictions to", output_path, "\n")
