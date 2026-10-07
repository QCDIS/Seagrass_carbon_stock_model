# Predict carbon density at point locations using a saved GPR model.
#
# Set the paths below, then run this file from the R kernel in
# predict_gpr_at_points.ipynb or with `Rscript predict_gpr_at_points.R`.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg) > 0L) {
  sub("^--file=", "", script_arg[[1L]])
} else {
  source_files <- unlist(lapply(sys.frames(), function(frame) {
    ofile <- get0("ofile", envir = frame, inherits = FALSE)
    if (is.character(ofile) && length(ofile) == 1L && nzchar(ofile)) ofile
  }), use.names = FALSE)
  if (length(source_files) > 0L) tail(source_files, 1L) else NA_character_
}

find_project_root <- function(start_dir) {
  current_dir <- normalizePath(start_dir, winslash = "/", mustWork = FALSE)
  for (i in seq_len(40L)) {
    if (file.exists(file.path(current_dir, "modelling", "R", "init_repo.R"))) {
      return(current_dir)
    }
    nested_root <- file.path(current_dir, "codebase", "v2", "src")
    if (file.exists(file.path(nested_root, "modelling", "R", "init_repo.R"))) {
      return(normalizePath(nested_root, winslash = "/", mustWork = TRUE))
    }
    parent_dir <- dirname(current_dir)
    if (identical(parent_dir, current_dir)) break
    current_dir <- parent_dir
  }
  NA_character_
}

start_dirs <- getwd()
if (!is.na(script_path)) {
  start_dirs <- c(start_dirs, dirname(script_path))
}
project_root <- NA_character_
for (start_dir in unique(start_dirs)) {
  project_root <- find_project_root(start_dir)
  if (!is.na(project_root)) break
}
if (is.na(project_root)) {
  stop(
    "Cannot find the v2 project root. Run from codebase/v2/src or its parent ",
    "directory, or source this file from the project.",
    call. = FALSE
  )
}

sys.source(
  file.path(project_root, "modelling", "R", "init_repo.R"),
  envir = .GlobalEnv
)
project_root <- seagrass_init_repo(
  packages = c("dplyr", "readr", "readxl"),
  source_files = c("modelling/R/extract_covariates_from_rasters.R"),
  include_helpers = TRUE,
  require_core_inputs = FALSE,
  check_renv = FALSE
)

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
raster_covars <- setdiff(
  predictor_vars,
  c("seagrass_species", "longitude", "latitude")
)
missing_input_predictors <- setdiff(
  tolower(predictor_vars),
  tolower(c(names(input_data), raster_covars))
)
if (length(missing_input_predictors) > 0L) {
  stop(
    "Input is missing non-raster model predictor(s): ",
    paste(missing_input_predictors, collapse = ", "),
    call. = FALSE
  )
}

missing_rasters <- setdiff(tolower(raster_covars), tolower(raster_covariates))
if (length(missing_rasters) > 0L) {
  stop(
    "Model requires raster covariate(s) not found under data/env_rasters: ",
    paste(missing_rasters, collapse = ", "),
    call. = FALSE
  )
}

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
