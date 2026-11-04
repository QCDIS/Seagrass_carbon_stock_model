# Graph Report - src  (2026-10-08)

## Corpus Check
- 54 files · ~130,195 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 10 file(s) not represented in the graph (top: (none) 2, .rds 2, .csv 2)

## Summary
- 1786 nodes · 2296 edges · 114 communities (63 shown, 51 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 59 edges (avg confidence: 0.84)
- Token cost: 273,414 input · 0 output

## Community Hubs (Navigation)
- Supplement & Correlation Plots
- Sensitivity Suite Analysis
- Tuning Seed Sweep Runner
- Model vs Baseline Comparison
- Multiseed Pipeline Driver
- Spatial Prediction Maps
- Final Model Fitting
- ML Core: Fit, Predict, CV
- Robust Multiseed Evaluation
- Robust Hyperparameter Tuning
- Fold Sensitivity Check
- Performance Summary Compilation
- Raster Covariate Extraction
- Additional Sample Comparison
- Train/Test Fraction Diagnostic
- Robust SHAP Covariate Pruning
- Partial Dependence Plots
- Sensitivity Suite Plots
- Core Data Build & Regions
- Python Data Processing
- Python Map Panels
- Python Stock Bar Charts
- R Helper Utilities
- Species Encoding Showcase
- Paper Plot Theme Helpers
- Tuning Sweep Plots
- GPR Point Prediction Script
- Robust SHAP Importance Plots
- CV Stage Runner Helpers
- Model Comparison Plots
- renv Bootstrap Utilities
- Carbon Density from Points
- Env vs Training Comparison
- Modelling Workflow Flowchart
- Python Species Assignment
- renv Paths & Profiles
- renv Bootstrap Install
- Architecture Diagram Stages
- Registry Merge & Plot Helpers
- Plot Config Constants
- Spatial CV Folds & Regions
- renv Bootstrap Downloads
- Carbon Calculation Flowchart
- Seed Registry Policy
- Sweep Registry Helpers
- Model Fitters: GPR, GAM, XGB, LR
- Python National Stock Metrics
- Repo Init & Bootstrap
- Covariate Pruning Concepts
- PDP Plot Helpers
- renv JSON Reader
- renv Platform Detection
- README & Seed Handoff Docs
- Pipeline Config
- NetCDF Grid Writer
- Python Carbon Stock Conversion
- Species Legend Patches
- Linear Slope Fit Helpers
- renv Bootstrap Load/Run
- Multiseed Robustness Concepts
- Fold Stats Helpers
- XGB Grid Builder
- Model Vars Loaders
- Patchwork Plot Combiners
- Robust Eval Dir Resolvers
- Prediction Map Dependencies
- Python Notebook & Helpers
- Notebook Data Sources
- Tidyverse Packages
- Map Limits Helpers
- R Requirements & renv
- NetCDF Packages
- Spatial Packages: sf / geopandas
- digest package
- FNN package
- ggtext package
- here package
- patchwork package
- progress package
- randomForest package
- readr package
- readxl package
- RNetCDF package
- scales package
- tibble package
- tidyr package
- ipykernel package
- matplotlib package
- numpy package
- pandas package
- pyarrow package
- pyogrio package
- shapely package
- tqdm package
- xarray package

## God Nodes (most connected - your core abstractions)
1. `compare_prediction_env_to_training()` - 31 edges
2. `plot_model_comparison_outputs()` - 27 edges
3. `plot_tuning_seed_sweep_summary()` - 20 edges
4. `predict_model()` - 16 edges
5. `run_species_encoding_showcase()` - 14 edges
6. `make_spatial_panel()` - 14 edges
7. `plot_applicability_domain()` - 13 edges
8. `fit_gpr()` - 12 edges
9. `make_model_plot()` - 12 edges
10. `apply_scaling()` - 11 edges

## Surprising Connections (you probably didn't know these)
- `fit_final_models (fit_final_models.R)` --calls--> `load_model_vars()`  [INFERRED]
  README.md → modelling/R/_README.md
- `terra` --conceptually_related_to--> `create_prediction_grid_from_rasters()`  [INFERRED]
  r-requirements.txt → modelling/R/_README.md
- `pixel_grouped CV Regime` --conceptually_related_to--> `blockCV`  [AMBIGUOUS]
  modelling/multiseed/_README.md → r-requirements.txt
- `Seagrass carbon mapping README` --references--> `R helpers and core logic README`  [EXTRACTED]
  README.md → modelling/R/_README.md
- `log_transform_target` --references--> `transform_response() / inverse_response_transform()`  [INFERRED]
  README.md → modelling/R/_README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Robust multiseed pipeline: config -> tune -> SHAP prune -> evaluate -> final fit** — modelling_run_multiseed_pixel_grouped, modelling_pipeline_config_get_pipeline_config, modelling_r_helpers_get_cached_spatial_folds, modelling_r_helpers_compute_shap_importance, modelling_r_fit_final_models_fit_final_models, readme_run_scoped_output_folder [EXTRACTED 1.00]
- **Tuning seed sweep -> chosen_seeds_latest.rds -> multiseed driver seed override** — modelling_analysis_run_tuning_seed_sweep, modelling__seed_registry_chosen_seeds_latest, modelling_pipeline_config_use_robust_seeds_from_tuning_sweep, modelling_run_multiseed_pixel_grouped, modelling_pipeline_config_seed_registry [EXTRACTED 1.00]
- **Cross-validation fold construction strategies (leakage-conservativeness ladder)** — readme_random_split_cv, readme_location_grouped_cv, readme_pixel_grouped_cv, readme_spatial_block_cv, readme_region_stratified_cv [EXTRACTED 1.00]
- **End-to-end seagrass carbon stock modelling pipeline (bootstrap through predict & report)** — architecture_bootstrap, architecture_inputs, architecture_extract, architecture_configure, architecture_selection, architecture_evaluation, architecture_final_fit, architecture_predict_and_report [EXTRACTED 1.00]
- **Reproducible cross-validation design (seed registry + pixel-grouped folds + across-seed evaluation)** — architecture_seed_registry, architecture_pixel_grouped_folds, architecture_evaluation [INFERRED 0.85]
- **Seagrass Carbon Stock Calculation Pipeline** — report_carbon_calculation_flowchart_emodnet_seagrass_polygons, report_carbon_calculation_flowchart_assign_species_via_eunis_code, report_carbon_calculation_flowchart_assign_polygons_to_eezs, report_carbon_calculation_flowchart_assign_inferred_carbon_density, report_carbon_calculation_flowchart_national_areal_extent, report_carbon_calculation_flowchart_unit_area_carbon_density, report_carbon_calculation_flowchart_aggregated_carbon_stock [EXTRACTED 1.00]
- **External Inputs to Carbon Stock Calculation** — report_carbon_calculation_flowchart_emodnet_seagrass_polygons, report_carbon_calculation_flowchart_marine_eez_regions_polygons, report_carbon_calculation_flowchart_trained_model_outputs [EXTRACTED 1.00]
- **Sequential seagrass carbon stock modelling workflow (steps 0-7)** — report_modelling_flowchart_data, report_modelling_flowchart_hyperparameter_tuning_and_feature_importance, report_modelling_flowchart_covariate_pruning, report_modelling_flowchart_hyperparameter_tuning_with_selected_covariates, report_modelling_flowchart_robust_evaluation, report_modelling_flowchart_sensitivity_analysis, report_modelling_flowchart_final_models, report_modelling_flowchart_supplement [EXTRACTED 1.00]
- **Steps implemented in the cv_pipeline/ directory** — report_modelling_flowchart_covariate_pruning, report_modelling_flowchart_hyperparameter_tuning_with_selected_covariates, report_modelling_flowchart_robust_evaluation, report_modelling_flowchart_sensitivity_analysis, report_modelling_flowchart_cv_pipeline_dir [EXTRACTED 1.00]
- **Multi-seed robust tuning/pruning/evaluation workflow** — modelling_run_multiseed_pixel_grouped, modelling_multiseed_robust_hyperparameter_tuning, modelling_multiseed_robust_shap_covariate_pruning, modelling_multiseed_robust_evaluation, modelling_pipeline_config [EXTRACTED 1.00]
- **Tuning seed-count sweep run and plotting flow** — modelling_analysis_run_tuning_seed_sweep, modelling_analysis_sensitivity_suite, modelling_plots_plot_sensitivity_suite, modelling_plots_plot_tuning_seed_sweep, modelling_plots_plot_tuning_seed_sweep_plot_tuning_seed_sweep_summary [EXTRACTED 1.00]
- **Final-model figure generation sharing final_models and output/cache** — modelling_plots_plot_partial_dependence, modelling_plots_plot_spatial_prediction_maps, modelling_plots_supplement, modelling_plots__readme_prediction_grid_cache, modelling_r_extract_covariates_from_rasters_create_prediction_grid_from_rasters [INFERRED 0.85]

## Communities (114 total, 51 thin omitted)

### Community 0 - "Supplement & Correlation Plots"
Cohesion: 0.02
Nodes (101): MEOW Marine Ecoregions, all_models_pruned_variables, all_pred_vars, base_map, bbox, C, C_df, C_long (+93 more)

### Community 1 - "Sensitivity Suite Analysis"
Cohesion: 0.02
Nodes (78): allowed_cv_types, by_comp, by_env, by_fold, by_pooled, cfg, comp, comp_rows (+70 more)

### Community 2 - "Tuning Seed Sweep Runner"
Cohesion: 0.03
Nodes (67): cfg, chosen_payload, cv_regime_name, cv_type_label, do_tuning_seed_sweep_refined_tuning, done_tbl, effective_sweep_cfg, eval_fold_seed_list (+59 more)

### Community 3 - "Model vs Baseline Comparison"
Cohesion: 0.03
Nodes (66): Species-mean Baseline Comparison, active_run_output_dir, baseline_metrics, by_fold, cfg, cfg_model, config_dir, core_data (+58 more)

### Community 4 - "Multiseed Pipeline Driver"
Cohesion: 0.03
Nodes (51): cfg, ch, chosen_seeds_rds, config_vars, correlation_filter_threshold, cv_blocksize, cv_output_dir, cv_regime_name (+43 more)

### Community 5 - "Spatial Prediction Maps"
Cohesion: 0.03
Nodes (59): Bathymetry Filter for Prediction Domain, Cached Prediction Grid (output/cache/), plot_gpr_spatial_maps.R (retired), bathy_col, bathy_covariate, bathy_vals, cfg, cv_out (+51 more)

### Community 6 - "Final Model Fitting"
Cohesion: 0.03
Nodes (61): best_gam_hp, best_gpr_hp, best_xgb_hp, cfg, config_dir, core_data, cov_dir, cv_fold_info (+53 more)

### Community 7 - "ML Core: Fit, Predict, CV"
Cohesion: 0.06
Nodes (48): log_transform_target, make_predictor(), pred_fun(), compute_shap_importance(), pred_fun(), run_cv(), calculate_metrics(), infer_model_type() (+40 more)

### Community 8 - "Robust Multiseed Evaluation"
Cohesion: 0.04
Nodes (55): across_seeds_summary, by_seed_detailed, by_seed_detailed_all, by_seed_detailed_list, by_seed_summary, by_seed_summary_all, by_seed_summary_list, cfg (+47 more)

### Community 9 - "Robust Hyperparameter Tuning"
Cohesion: 0.04
Nodes (55): baseline_row, best_idx, best_k, best_row, candidate_sets, cfg, colsample_bytree_grid, complete_dat (+47 more)

### Community 10 - "Fold Sensitivity Check"
Cohesion: 0.04
Nodes (50): allowed_cv_types, by_fold, by_fold_rows, cfg, complete_dat, config_dir, coords_to_keep, core_data (+42 more)

### Community 11 - "Performance Summary Compilation"
Cohesion: 0.04
Nodes (42): Analysis Scripts README, base_dir, cv_regime_name, det_path, dir_info, ff, init_path, methods_tbl (+34 more)

### Community 12 - "Raster Covariate Extraction"
Cohesion: 0.06
Nodes (17): safe_quantile(), build_covariate_na_count_grid(), progress_callback(), build_covariate_config_from_dir(), create_prediction_grid_from_rasters(), progress_callback(), extract_covariates_at_points(), extract_from_nc() (+9 more)

### Community 13 - "Additional Sample Comparison"
Cohesion: 0.05
Nodes (41): additional_species, comparison_colors, dat_fp, df_raw, distribution_colors, distribution_mean_lines, distribution_plot_data, env_cmp (+33 more)

### Community 14 - "Train/Test Fraction Diagnostic"
Cohesion: 0.05
Nodes (41): cfg, complete_dat, core_data, cv_regime_name, cv_type, cv_type_glob, cv_type_hash, cv_type_label (+33 more)

### Community 15 - "Robust SHAP Covariate Pruning"
Cohesion: 0.05
Nodes (41): candidate_sets, cfg, complete_dat, cor_predictor_vars, cv_type_hash, dat, dfm, fold_indices (+33 more)

### Community 16 - "Partial Dependence Plots"
Cohesion: 0.05
Nodes (39): Partial Dependence via iml Predictor/FeatureEffect, all_vars_by_model, cfg, combined_shared, core_data, cv_out, dat, dpi (+31 more)

### Community 17 - "Sensitivity Suite Plots"
Cohesion: 0.05
Nodes (39): by_fold_df, cfg, cv_pipeline_dir, cv_regime_name, env_by_fold_df, env_dist_df, env_dist_long, env_effect_df (+31 more)

### Community 18 - "Core Data Build & Regions"
Cohesion: 0.06
Nodes (36): cv_regime_name / cv_output_dir, cv_type (random | location_grouped | pixel_grouped | spatial), exclude_regions spatial filter, assign_region_from_latlon(), meow_region_shapes(), all_extracted, all_extracted_new, all_extracted_path (+28 more)

### Community 19 - "Python Data Processing"
Cohesion: 0.10
Nodes (12): attribute_geometries_from_prediction_grid(), build_comparison_dataframe(), build_or_load_eez_joins(), _coerce_arrow_compatible(), load_gomis_table(), load_or_build_attributed_geometries(), load_or_prepare_eov_geometries(), prepare_european_stock_tables() (+4 more)

### Community 20 - "Python Map Panels"
Cohesion: 0.08
Nodes (12): add_panel_label(), auto_buffer_distance(), auto_simplify_tolerance(), choose_tick_step(), clean_geoms(), draw_geom_panel(), dynamic_point_size(), extent_grid_ticks() (+4 more)

### Community 21 - "Python Stock Bar Charts"
Cohesion: 0.17
Nodes (14): _aggregate_stock_se(), plot_comparison_bars(), _plot_grouped_species_bars_on_ax(), _plot_species_segment_errorbars(), _plot_stacked_species_bars_on_ax(), plot_territory_species_grouped_all(), plot_territory_species_grouped_split(), plot_territory_species_stacked_all() (+6 more)

### Community 22 - "R Helper Utilities"
Cohesion: 0.09
Nodes (16): build_hyperparams_by_model(), build_robust_candidate_predictor_sets(), calculate_metrics(), init_candidates, init_path, is_species_var(), load_best_model_config(), model_hyperparams_from_config() (+8 more)

### Community 23 - "Species Encoding Showcase"
Cohesion: 0.12
Nodes (24): ALL_PREDICTORS, cfg, compute_train_species_means(), CV_SEED, describe_species_encoding(), ensure_model_response(), ensure_species_factor(), ENV_PREDICTORS (+16 more)

### Community 24 - "Paper Plot Theme Helpers"
Cohesion: 0.13
Nodes (5): theme_paper(), make_model_plot(), make_spatial_panel(), scale_fill_prediction(), plot_applicability_domain()

### Community 25 - "Tuning Sweep Plots"
Cohesion: 0.11
Nodes (17): args, cfg, disable_autorun, dpi, ff, init_path, plot_log_tss(), plot_tuning_seed_sweep() (+9 more)

### Community 26 - "GPR Point Prediction Script"
Cohesion: 0.09
Nodes (21): seagrass_init_repo() (init_repo.R bootstrap), predict_gpr_at_points.ipynb (R kernel notebook), input_data, input_path, missing_columns, missing_input_predictors, missing_rasters, missing_values (+13 more)

### Community 27 - "Robust SHAP Importance Plots"
Cohesion: 0.09
Nodes (19): cfg, combined, imp, imp_top, in_summary, legend_row, models, out_combined (+11 more)

### Community 28 - "CV Stage Runner Helpers"
Cohesion: 0.12
Nodes (8): collect_eval_table(), run_one_subset(), fold_composition_stats(), get_fold_indices_for_seed(), robust_rmse_stats(), summarise_by_repeat(), compare_covariates_between_models(), run_cv()

### Community 29 - "Model Comparison Plots"
Cohesion: 0.12
Nodes (19): args, boot, bootstrap_plot_model_comparison(), cfg, disable_autorun, dpi_arg, MODEL_COMPARISON_OUTPUT_PNGS, MODEL_COMPARISON_REQUIRED_CSVS (+11 more)

### Community 30 - "renv Bootstrap Utilities"
Cohesion: 0.12
Nodes (17): ansify(), cfg, diagnostics, elapsed, enabled, heredoc(), libpath, prefix (+9 more)

### Community 31 - "Carbon Density from Points"
Cohesion: 0.10
Nodes (20): dat_fp, df_raw, env_cmp, env_comparison_output_dir, missing_cols, missing_rasters, model, model_fp (+12 more)

### Community 32 - "Env vs Training Comparison"
Cohesion: 0.12
Nodes (5): prepare_core_data(), compare_prediction_env_to_training(), clamp_plot_inches(), plot_height_for_n_points(), plot_width_for_n_vars()

### Community 33 - "Modelling Workflow Flowchart"
Cohesion: 0.17
Nodes (14): Modelling Workflow Flowchart, Step 2: Covariate pruning (remove correlated variables, SHAP-based selection), covariate_selection/ directory, cv_pipeline/ directory, Step 0: Data (extract covariates from environmental rasters), Step 6: Final models (fit, save, compare with species-mean baseline, prediction maps), final_models/ directory, Step 1: Hyperparameter tuning and feature importance (+6 more)

### Community 34 - "Python Species Assignment"
Cohesion: 0.19
Nodes (6): assign_points_seagrass_species(), assign_species_anxi(), assign_species_eunis(), assign_species_habsubtype(), process_points_df_species(), process_poly_df_species()

### Community 35 - "renv Paths & Profiles"
Cohesion: 0.14
Nodes (14): renv_bootstrap_hash_text(), renv_bootstrap_library_root(), renv_bootstrap_library_root_impl(), renv_bootstrap_library_root_name(), renv_bootstrap_path_absolute(), renv_bootstrap_paths_renv(), renv_bootstrap_profile_get(), renv_bootstrap_profile_load() (+6 more)

### Community 36 - "renv Bootstrap Install"
Cohesion: 0.15
Nodes (15): bootstrap(), catf(), header(), renv_bootstrap_cache_version(), renv_bootstrap_cache_version_previous(), renv_bootstrap_download(), renv_bootstrap_download_tarball(), renv_bootstrap_find() (+7 more)

### Community 37 - "Architecture Diagram Stages"
Cohesion: 0.16
Nodes (10): Bootstrap (Rscript -> find root -> check renv -> load shared helpers), Configure (central config/seed registry -> pixel-grouped fold construction), Evaluation (held-out seeds -> across-seed metrics/diagnostics), Extract (point extraction -> cleaned modelling RDS -> covariates/target), Final fit (train final model -> save predictor/scaler/encoding metadata), Inputs (core survey data + environmental rasters + region polygons), Seagrass Carbon Stock Modelling Pipeline Architecture Diagram, Predict & report (cached prediction grid -> maps/PDP/supplement; Python stock tables) (+2 more)

### Community 38 - "Registry Merge & Plot Helpers"
Cohesion: 0.16
Nodes (4): merge_registry(), compute_fold_environment_stats(), plot_model_comparison_outputs(), collapse_approach_plot()

### Community 39 - "Plot Config Constants"
Cohesion: 0.15
Nodes (11): cv_pipeline.R, Plot Scripts README, label_vars(), EUROPE_LAT_RANGE, EUROPE_LON_RANGE, METRIC_LINESTYLES, MODEL_COLOURS, REGION_COLOURS (+3 more)

### Community 40 - "Spatial CV Folds & Regions"
Cohesion: 0.15
Nodes (8): assign_region_from_latlon(), meow_region_shapes, get_cached_spatial_folds(), make_cv_folds(), make_pixel_grouped_folds(), progress_bar(), resolve_fold_indices(), tune_gpr_cv()

### Community 41 - "renv Bootstrap Downloads"
Cohesion: 0.22
Nodes (10): renv_bootstrap_download_augment(), renv_bootstrap_download_cran_archive(), renv_bootstrap_download_cran_latest(), renv_bootstrap_download_cran_latest_find(), renv_bootstrap_download_custom_headers(), renv_bootstrap_download_github(), renv_bootstrap_download_impl(), renv_bootstrap_git_extract_sha1_tar() (+2 more)

### Community 42 - "Carbon Calculation Flowchart"
Cohesion: 0.24
Nodes (7): Carbon Calculation Flowchart, Aggregated Carbon Stock C_N = sum_N A_N x rho_A, EMODnet Seagrass Polygons (input), Marine EEZ Regions Polygons (input), National Areal Extent A_N, Outputs of Trained Model (input), Unit-Area Carbon Density rho_A = rho_V x depth

### Community 43 - "Seed Registry Policy"
Cohesion: 0.24
Nodes (8): seed_registry$active_robust_fold_seed_list, eval_fold_seed_list (held-out evaluation seeds), get_pipeline_config(), seed_registry$paper_robust_fold_seed_list (frozen paper seeds), robust_fold_seed_list (derived seed field), seed_registry (pipeline_config.R), use_paper_seed_registry toggle, Run-scoped output folder output/pixel_grouped_<seeds>/

### Community 44 - "Sweep Registry Helpers"
Cohesion: 0.27
Nodes (8): find_matching_sweep_dir(), list_sweep_dirs(), load_subset_registry(), manifest_core(), next_sequential_sweep_id(), read_registry_file(), registry_from_manifest_run(), same_manifest_plan()

### Community 45 - "Model Fitters: GPR, GAM, XGB, LR"
Cohesion: 0.24
Nodes (10): fit_final_models (fit_final_models.R), tune_gpr_cv(), tune_xgboost(), fit_gam(), fit_gpr(), fit_xgboost(), Gaussian Process Regressor (GPR), Generalised Additive Model (GAM) (+2 more)

### Community 46 - "Python National Stock Metrics"
Cohesion: 0.24
Nodes (5): aggregate_error_bounds(), build_national_metrics(), dynamic_buffer_distance(), safe_weighted_average(), weighted_mean_standard_error()

### Community 47 - "Repo Init & Bootstrap"
Cohesion: 0.36
Nodes (6): build_core_data(), load_packages(), seagrass_check_renv(), seagrass_init_repo(), seagrass_require_core_inputs(), seagrass_source_project_root()

### Community 48 - "Covariate Pruning Concepts"
Cohesion: 0.25
Nodes (7): do_shap_refined_tuning (Step 3 re-tune toggle), pruned_model_variables_perm.csv / pruned_model_variables_shap.csv, compute_shap_importance(), load_model_vars(), permutation_importance_cv(), prune_by_correlation(), Robust SHAP pruning (Step 2)

### Community 49 - "PDP Plot Helpers"
Cohesion: 0.25
Nodes (4): compute_pdp_plots(), get_pdp_vars_for_model(), plot_pdp_for_model(), save_and_show_plot()

### Community 50 - "renv JSON Reader"
Cohesion: 0.25
Nodes (7): renv_bootstrap_repos_lockfile(), renv_json_read(), renv_json_read_default(), renv_json_read_envir(), renv_json_read_jsonlite(), renv_json_read_patterns(), renv_json_read_remap()

### Community 51 - "renv Platform Detection"
Cohesion: 0.25
Nodes (7): renv_bootstrap_platform_os(), renv_bootstrap_platform_os_via_os_release(), renv_bootstrap_platform_os_via_redhat_release(), renv_bootstrap_platform_prefix(), renv_bootstrap_platform_prefix_auto(), renv_bootstrap_platform_prefix_default(), renv_bootstrap_platform_prefix_impl()

### Community 52 - "README & Seed Handoff Docs"
Cohesion: 0.29
Nodes (6): Seed Registry and Source of Truth, output/tuning_seed_sweep_runs/chosen_seeds_latest.rds, use_robust_seeds_from_tuning_sweep toggle, R helpers and core logic README, Seagrass carbon mapping README, Gallo and Timmerman et al. (2026) - Oceanographic drivers of carbon storage in European seagrass beds

### Community 53 - "Pipeline Config"
Cohesion: 0.38
Nodes (4): Multi-seed Robustness Scripts README, seagrass_confirm_same_config(), seagrass_find_matching_configs(), seagrass_strip_config_keys()

### Community 55 - "Python Carbon Stock Conversion"
Cohesion: 0.33
Nodes (3): add_stock_columns(), convert_carbon_density_to_carbon_areal_stock(), convert_carbon_density_to_carbon_stock()

### Community 58 - "renv Bootstrap Load/Run"
Cohesion: 0.50
Nodes (4): renv_bootstrap_exec(), renv_bootstrap_load(), renv_bootstrap_run(), renv_bootstrap_run_impl()

### Community 60 - "Fold Stats Helpers"
Cohesion: 0.50
Nodes (3): compute_fold_y_stats(), compute_pooled_ss(), compute_seed_convergence()

### Community 62 - "Model Vars Loaders"
Cohesion: 0.50
Nodes (4): get_per_model_vars(), load_model_vars(), load_model_vars_with_fallback(), read_model_vars()

### Community 64 - "Robust Eval Dir Resolvers"
Cohesion: 0.67
Nodes (3): filter_models_required(), plot_log_sp(), resolve_robust_eval_dir()

### Community 65 - "Prediction Map Dependencies"
Cohesion: 0.67
Nodes (3): plot_prediction_map(), maps, cartopy

### Community 66 - "Python Notebook & Helpers"
Cohesion: 0.67
Nodes (3): prediction_maps.ipynb, python_helpers, Python Requirements

### Community 67 - "Notebook Data Sources"
Cohesion: 1.00
Nodes (3): prediction_maps.ipynb (Python carbon stock maps), Exclusive Economic Zones (World EEZ v12, Marine Regions), Seagrass Essential Ocean Variable (EMODnet Seabed Habitats)

### Community 68 - "Tidyverse Packages"
Cohesion: 0.67
Nodes (3): dplyr, ggplot2, tidyverse

## Ambiguous Edges - Review These
- `ml.R` → `calculate_metrics()`  [AMBIGUOUS]
  modelling/R/_README.md · relation: implements
- `pixel_grouped CV Regime` → `blockCV`  [AMBIGUOUS]
  modelling/multiseed/_README.md · relation: conceptually_related_to

## Knowledge Gaps
- **1066 isolated node(s):** `meow_region_shapes`, `init_candidates`, `source_files`, `init_path`, `project_root` (+1061 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1286 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **51 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `ml.R` and `calculate_metrics()`?**
  _Edge tagged AMBIGUOUS (relation: implements) - confidence is low._
- **Why does `save_and_show_plot()` connect `PDP Plot Helpers` to `Additional Sample Comparison`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **What connects `meow_region_shapes`, `init_candidates`, `source_files` to the rest of the system?**
  _1066 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Supplement & Correlation Plots` be split into smaller, more focused modules?**
  _Cohesion score 0.019230769230769232 - nodes in this community are weakly interconnected._
- **What is the exact relationship between `pixel_grouped CV Regime` and `blockCV`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Analysis Scripts README` connect `Performance Summary Compilation` to `Tuning Seed Sweep Runner`, `Sensitivity Suite Analysis`, `Fold Sensitivity Check`, `Model vs Baseline Comparison`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Should `Sensitivity Suite Analysis` be split into smaller, more focused modules?**
  _Cohesion score 0.024691358024691357 - nodes in this community are weakly interconnected._