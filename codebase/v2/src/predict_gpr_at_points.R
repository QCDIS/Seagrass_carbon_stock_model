# Predict carbon density at point locations using a saved GPR model.
#
# This script includes the functions it needs from the v2 project, so it can be
# run or sourced without sourcing the modelling helper scripts.

# User configuration (paths are relative to the v2 project root).
INPUT_FILE <- file.path("data", "review", "PercOC_only_unique_reduced_df_predictions.csv")
MODEL_FILE <- file.path("data", "review", "GPR_final.rds")
OUTPUT_FILE <- file.path(
  "output", "review",
  "PercOC_only_unique_reduced_df_predictions_gpr_predictions.csv"
)
RASTER_DIR <- file.path("data", "env_rasters")
POINT_COLUMNS <- c("longitude", "latitude", "seagrass_species")
USE_CLOSEST_RASTER_VALUE <- TRUE
RASTER_METHOD <- "nearest"
RETURN_PREDICTION_SE <- TRUE
PREDICTION_MEAN_COLUMN <- "predicted_carbon_density"
PREDICTION_SE_COLUMN <- "predicted_se"
RS_COVARIATES <- c(
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.CHL.chlor_a.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.IOP.adg_443.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.IOP.bbp_443.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.KD.Kd_490.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.RRS.Rrs_443.4km",
  "S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.RRS.Rrs_620.4km"
)

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
    return(variable$name)
  }
  NULL
}

build_covariate_config_from_dir <- function(raster_dir, covariates) {
  requested <- unique(tolower(covariates))
  if (length(requested) == 0L) return(list())
  base <- file.path(PROJECT_ROOT, raster_dir)
  if (!dir.exists(base)) stop("Raster directory not found: ", base)
  files <- list.files(base, pattern = "[.]nc$", full.names = TRUE, ignore.case = TRUE)
  file_names <- tolower(gsub(
    "-", "_", sub("[.]nc$", "", basename(files), ignore.case = TRUE), fixed = TRUE
  ))
  if (anyDuplicated(file_names)) {
    stop("Raster filenames are ambiguous after normalization in: ", base, call. = FALSE)
  }
  missing <- setdiff(requested, file_names)
  if (length(missing) > 0L) {
    stop(
      "No NetCDF raster found for required covariate(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  out <- list()
  for (covariate in requested) {
    file <- files[match(covariate, file_names)]
    info <- tryCatch(
      inspect_nc_file(file),
      error = function(e) {
        stop(
          "Could not inspect raster for ", covariate, ": ",
          conditionMessage(e),
          call. = FALSE
        )
      }
    )
    if (is.null(info)) {
      stop(
        "No 2D latitude/longitude variable found in raster: ", basename(file),
        call. = FALSE
      )
    }
    out[[covariate]] <- list(
      file = file.path(raster_dir, basename(file)),
      varname = info
    )
  }
  out
}

extract_from_nc <- function(nc_file, varname, coords,
                            use_closest = USE_CLOSEST_RASTER_VALUE,
                            method = RASTER_METHOD) {
  nc_path <- file.path(PROJECT_ROOT, nc_file)
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
  terra_method <- if (identical(tolower(method), "bilinear")) "bilinear" else "simple"
  values <- as.numeric(terra::extract(raster, coords, method = terra_method)[, 1L])
  if (use_closest && anyNA(values) && requireNamespace("FNN", quietly = TRUE)) {
    missing <- which(is.na(values))
    raster_values <- terra::values(raster, mat = FALSE)
    valid_cells <- which(!is.na(raster_values))
    if (length(valid_cells) > 0L) {
      valid_values <- raster_values[valid_cells]
      nearest <- FNN::get.knnx(
        data = terra::xyFromCell(raster, valid_cells),
        query = coords[missing, , drop = FALSE],
        k = 1L
      )$nn.index[, 1L]
      values[missing] <- valid_values[nearest]
    }
  }
  values
}

extract_covariates_at_points <- function(points, covariates,
                                         use_closest = USE_CLOSEST_RASTER_VALUE,
                                         method = RASTER_METHOD) {
  if (length(covariates) == 0L) return(points)
  if (!all(c("latitude", "longitude") %in% names(points))) {
    stop("points must have 'latitude' and 'longitude' columns")
  }
  coords <- as.matrix(points[, c("longitude", "latitude"), drop = FALSE])
  result <- points
  for (covariate in covariates) {
    config <- RASTER_CONFIG[[tolower(covariate)]]
    if (is.null(config)) {
      stop("Raster configuration not found for covariate: ", covariate)
    }
    result[[covariate]] <- extract_from_nc(
      nc_file = config$file,
      varname = config$varname,
      coords = coords,
      use_closest = use_closest,
      method = method
    )
  }
  result
}

process_rs_covariates <- function(dat) {
  existing_vars <- intersect(RS_COVARIATES, colnames(dat))
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

apply_scaling <- function(data, scale_params) {
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

predict_model <- function(obj, newdata, se = RETURN_PREDICTION_SE) {
  if (!identical(obj$model_type, "GPR") && !inherits(obj$model, "GauPro")) {
    stop("predict_model in this script only supports GPR models.", call. = FALSE)
  }
  predictor_vars <- obj$predictor_vars
  if (is.null(predictor_vars) || length(predictor_vars) == 0L) {
    stop("The GPR model does not contain predictor_vars.", call. = FALSE)
  }
  missing_predictors <- setdiff(predictor_vars, names(newdata))
  if (length(missing_predictors) > 0L) {
    stop(
      "Prediction data is missing model predictor(s): ",
      paste(missing_predictors, collapse = ", "),
      call. = FALSE
    )
  }
  X <- newdata[, predictor_vars, drop = FALSE]
  model_cols <- obj$encoded_names %||% predictor_vars
  encoding <- obj$encoding
  encoding_type <- encoding$type %||% NA_character_
  if (identical(encoding_type, "one_hot") &&
      !is.null(obj$species_means) &&
      !is.null(encoding$kernel_predictor_vars)) {
    encoding_type <- "gpr_species_adjusted"
  }
  if (identical(encoding_type, "gpr_species_adjusted")) {
    kernel_vars <- encoding$kernel_predictor_vars %||%
      setdiff(predictor_vars, "seagrass_species")
    X <- prepare_predictors_new_onehot(
      newdata[, kernel_vars, drop = FALSE], encoding, model_cols
    )
  } else if (identical(encoding_type, "one_hot")) {
    X <- prepare_predictors_new_onehot(X, encoding, model_cols)
  } else if (!is.null(encoding)) {
    X <- apply_categorical_encoding(X, encoding, predictor_vars)
  }
  scale_params <- normalize_scale_params(obj$scale_params)
  if (!is.null(scale_params) && length(scale_params$means) > 0L) {
    X <- apply_scaling(X, scale_params)
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
  species_var <- encoding$species_var %||% NULL
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
    out$mean <- exp(out$mean)
    if (!is.null(out$se)) out$se <- out$se * out$mean
  }
  out
}

PROJECT_ROOT <- seagrass_find_v2_root()

REQUIRED_PACKAGES <- c("GauPro", "readr")
missing_packages <- REQUIRED_PACKAGES[
  !vapply(REQUIRED_PACKAGES, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required package(s): ", paste(missing_packages, collapse = ", "),
    ". Restore the v2 renv environment or install these packages.",
    call. = FALSE
  )
}

INPUT_PATH <- file.path(PROJECT_ROOT, INPUT_FILE)
MODEL_PATH <- file.path(PROJECT_ROOT, MODEL_FILE)
OUTPUT_PATH <- file.path(PROJECT_ROOT, OUTPUT_FILE)
if (!file.exists(INPUT_PATH)) stop("Input file not found: ", INPUT_PATH, call. = FALSE)
if (!file.exists(MODEL_PATH)) stop("GPR model file not found: ", MODEL_PATH, call. = FALSE)

if (grepl("\\.xlsx?$", INPUT_PATH, ignore.case = TRUE)) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required for Excel input.", call. = FALSE)
  }
  input_data <- readxl::read_excel(INPUT_PATH, sheet = 1)
} else if (grepl("\\.csv$", INPUT_PATH, ignore.case = TRUE)) {
  input_data <- readr::read_csv(INPUT_PATH, show_col_types = FALSE)
} else {
  stop("Input must be a .csv, .xls, or .xlsx file: ", INPUT_PATH, call. = FALSE)
}

model <- readRDS(MODEL_PATH)
if (!identical(model$model_type, "GPR") && !inherits(model$model, "GauPro")) {
  stop("The model file does not contain a GPR model: ", MODEL_PATH, call. = FALSE)
}
PREDICTOR_VARS <- model$predictor_vars
if (is.null(PREDICTOR_VARS) || length(PREDICTOR_VARS) == 0L) {
  stop("The GPR model does not contain predictor_vars.", call. = FALSE)
}

missing_columns <- setdiff(POINT_COLUMNS, names(input_data))
if (length(missing_columns) > 0L) {
  stop(
    "Input data is missing required column(s): ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

POINT_DATA_COLUMNS <- unique(c(
  POINT_COLUMNS,
  intersect(PREDICTOR_VARS, names(input_data))
))
POINT_DATA <- input_data[, POINT_DATA_COLUMNS, drop = FALSE]
RASTER_COVARIATES <- setdiff(PREDICTOR_VARS, names(POINT_DATA))
if (length(RASTER_COVARIATES) > 0L) {
  RASTER_PACKAGES <- c("RNetCDF", "terra")
  missing_packages <- RASTER_PACKAGES[
    !vapply(RASTER_PACKAGES, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing_packages) > 0L) {
    stop(
      "Missing required package(s) for raster extraction: ",
      paste(missing_packages, collapse = ", "),
      ". Restore the v2 renv environment or install these packages.",
      call. = FALSE
    )
  }
}
RASTER_CONFIG <- build_covariate_config_from_dir(RASTER_DIR, RASTER_COVARIATES)

cat("Extracting environmental covariates for", nrow(input_data), "point(s)...\n")
PREDICTION_DATA <- extract_covariates_at_points(
  points = POINT_DATA,
  covariates = RASTER_COVARIATES
)
PREDICTION_DATA <- process_rs_covariates(PREDICTION_DATA)

missing_values <- RASTER_COVARIATES[
  vapply(
    RASTER_COVARIATES,
    function(variable) any(is.na(PREDICTION_DATA[[variable]])),
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
PREDICTIONS <- predict_model(model, PREDICTION_DATA)
if (length(PREDICTIONS$mean) != nrow(input_data)) {
  stop("GPR prediction count does not match the number of input rows.", call. = FALSE)
}
input_data[[PREDICTION_MEAN_COLUMN]] <- PREDICTIONS$mean
if (!is.null(PREDICTIONS$se)) {
  input_data[[PREDICTION_SE_COLUMN]] <- PREDICTIONS$se
}

OUTPUT_DIR <- dirname(OUTPUT_PATH)
if (!dir.exists(OUTPUT_DIR) &&
    !dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)) {
  stop("Could not create output directory: ", OUTPUT_DIR, call. = FALSE)
}
readr::write_csv(input_data, OUTPUT_PATH)
cat("Wrote GPR predictions to", OUTPUT_PATH, "\n")
