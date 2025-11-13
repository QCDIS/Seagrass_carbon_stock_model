# This script was developed to bring in relevant environmental data for modeling carbon 
# stock as a function of environmental co-variates from remote sensing and Copernicus data products

# Script author Natalya D. Gallo
# Script modified from the original "Environmental_covariates_matching.R" script on 30 Oct 2024
# to make it targeted for the LifeWatch VRE product
# Part of MARCO-BOLO Task 5.3

#Note: The first function (extract_values) extracts values of matching sites, however this gives NAs for sites
#that appear over land given the lower resolution data products. The second function extract_closest_values()
#provides the closest match for any sites that received an NA. 

# Refresh working directory
rm(list = ls())

## Open needed packages
library(here)
library(tidyverse)
library(RNetCDF) 
#library(ggplot2)
#library(gridExtra)
#library(rnaturalearth)
#library(rnaturalearthdata)
#library(tidyr)
#library(terra)
#library(viridis)
#library(sf)

# Set working directory
setwd(here::here())

#Open datafile with seagrass site data
Seagrass_site <- readxl::read_excel(here(
  "data/Seagrass_site_data.xlsx"),
  sheet = 1, 
  col_types = c("numeric", "numeric", "text"))

# Convert seagrass_species to a factor variable
Seagrass_site$seagrass_species <- as.factor(Seagrass_site$seagrass_species)
summary(Seagrass_site)

#### Open relevant netcdf files, calculate appropriate summary statistic, extract spatially-matched value ####
#### Need Bottom_T_p95, Vo_p90, Uo_mean, Phosphate_mean, pH_mean, VHMO_p95, fgCO2_p95, KD490, RRS443 

#Bottom_T_p95, Vo_p90, and Uo_mean come from the Global Ocean Physics Reanalysis
#I used the daily product for bottom_T and the monthly product for the current data
#https://data.marine.copernicus.eu/product/GLOBAL_MULTIYEAR_PHY_001_030/services

#Phospate_mean and pH_mean come from the Global Ocean Biogeochemistry Hindcast monthly product
##https://data.marine.copernicus.eu/product/GLOBAL_MULTIYEAR_BGC_001_029/services

#VHM0_p95 comes from the Global Ocean Waves Reanalysis product
#https://data.marine.copernicus.eu/product/GLOBAL_MULTIYEAR_WAV_001_032/download?dataset=cmems_mod_glo_wav_my_0.2deg_PT3H-i_202411

#fgCO2_p95 comes from the Surface ocean carbon fields product
#https://data.marine.copernicus.eu/product/MULTIOBS_GLO_BIO_CARBON_SURFACE_MYNRT_015_008/services

#KD490 and RRS443 were downloaded from https://oceandata.sci.gsfc.nasa.gov/l3/order/ on March 11, 2025
#(Entire mission composite) (4km) (Standard) (S3A-OLCI)

#### Bottom_T_p95 ####
#GLOBAL_MULTIYEAR_PHY_001_030
#"bottomT" is Sea water potential temperature at sea floorbottomT [°C]
#cmems_mod_glo_phy_my_0.083deg_P1D-m

#bottomT_daily <- open.nc("data/cmems_mod_glo_phy_my_0.083deg_P1D-m_bottomT_10.00W-34.00E_34.00N-61.00N_1993-01-01-2021-06-30.nc")
#print.nc(bottomT_daily) # Print report

## Load NetCDF as SpatRaster
# bottomT_daily_raster <- rast("data/cmems_mod_glo_phy_my_0.083deg_P1D-m_bottomT_10.00W-34.00E_34.00N-61.00N_1993-01-01-2021-06-30.nc", subds = "bottomT")
## Calculate the 95th percentile of bottom temperature at each location from the daily physics product
# p95_bottomT_daily_C <- app(bottomT_daily_raster, fun = function(x) unname(quantile(x, probs = 0.95, na.rm = TRUE)))
# plot(p95_bottomT_daily_C)
## Write this to a NetCDF for future use
# writeCDF(p95_bottomT_daily_C, "bottomT_p95_daily_C.nc", varname = "p95_bottomT_daily_C", overwrite = TRUE)

## Open bottomT_p95_daily_C
## bottomT_p95_daily_C.nc = 95th percentile of bottom temperature at each location from daily physics product
bottomT_p95 <- open.nc("data/bottomT_p95_daily_C.nc")
# print.nc(bottomT_p95) # Print report
## Open data
bottomT_p95.value <- var.get.nc(bottomT_p95, 'p95_bottomT_daily_C', unpack=TRUE)
bottomT_p95.lat <- var.get.nc(bottomT_p95, 'latitude')
bottomT_p95.lon <- var.get.nc(bottomT_p95, 'longitude')
close.nc(bottomT_p95) #close file

## Extract closest matching value based on location
## This first function (extract_values) extracts values of matching sites, however this gives NAs for sites
## that appear over land given that the data product is at 0.083deg

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(bottomT_p95.lat - lat_value))
  lon_index <- which.min(abs(bottomT_p95.lon - lon_value))
  return(bottomT_p95.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site %>%
  rowwise() %>%
  mutate(bottomT_p95_C = extract_values(latitude, longitude))

## Only select non-NA points
## This second function (extract_closest_values) extracts values of the closest sites, excluding the matching
## sites that were NAs, and instead inputing the closest available value for these

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in bottomT_p95.value
  valid_indices <- which(!is.na(bottomT_p95.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- bottomT_p95.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- bottomT_p95.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value from bottomT_p95.value
  value_at_closest <- bottomT_p95.value[closest_valid_index[1], closest_valid_index[2]]
  
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(bottomT_p95_C_closest = extract_closest_values(latitude, longitude))

## Now work with monthly product of the Global Ocean Physics Reanalysis for other variables
## cmems_mod_glo_phy_my_0.083deg_P1M-m
# physics_monthly <- open.nc("data/cmems_mod_glo_phy_my_0.083deg_P1M-m_multi-vars_9.00W-34.00E_34.00N-61.00N_0.49-47.37m_1993-01-01-2021-06-01.nc")
# print.nc(physics_monthly) # Print report

#### Uo_mean ####
## Eastward seawater velocity (m s-1)
##  uo         (time, depth, latitude, longitude) float64 8GB dask.array<chunksize=(68, 2, 64, 64), meta=np.ndarray>
# uo_monthly <- rast("data/cmems_mod_glo_phy_my_0.083deg_P1M-m_multi-vars_9.00W-34.00E_34.00N-61.00N_0.49-47.37m_1993-01-01-2021-06-01.nc", subds = "uo")
# uo_monthly_1.5m <- uo_monthly[[grep("1.54", names(uo_monthly))]]
## calculate mean across time
# uo_mean_1.5m <- app(uo_monthly_1.5m, fun = mean, na.rm = TRUE)
# plot(uo_mean_1.5m)
# writeCDF(uo_mean_1.5m, "uo_mean_1.5m_m_s.nc", varname = "uo_mean_1.5m_m_s", overwrite = TRUE)

uo_mean_1.5m_m_s <- open.nc("data/uo_mean_1.5m_m_s.nc")
## print.nc(uo_mean_1.5m_m_s) # Print report
## Open data
uo_mean_1.5m.value <- var.get.nc(uo_mean_1.5m_m_s, 'uo_mean_1.5m_m_s', unpack=TRUE)
uo_mean_1.5m.lat <- var.get.nc(uo_mean_1.5m_m_s, 'latitude')
uo_mean_1.5m.lon <- var.get.nc(uo_mean_1.5m_m_s, 'longitude')
close.nc(uo_mean_1.5m_m_s) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(uo_mean_1.5m.lat - lat_value))
  lon_index <- which.min(abs(uo_mean_1.5m.lon - lon_value))
  return(uo_mean_1.5m.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(uo_mean_1.5m_m_s = extract_values(latitude, longitude))

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in uo_mean_1.5m.value
  valid_indices <- which(!is.na(uo_mean_1.5m.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- uo_mean_1.5m.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- uo_mean_1.5m.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- uo_mean_1.5m.value[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(uo_mean_1.5m_m_s_closest = extract_closest_values(latitude, longitude))

#### Vo_p90 ####
## Northward seawater velocity (m s-1)
##  vo         (time, depth, latitude, longitude) float64 8GB dask.array<chunksize=(68, 2, 64, 64), meta=np.ndarray>
# vo_monthly <- rast("data/cmems_mod_glo_phy_my_0.083deg_P1M-m_multi-vars_9.00W-34.00E_34.00N-61.00N_0.49-47.37m_1993-01-01-2021-06-01.nc", subds = "vo")
# vo_monthly_1.5m <- vo_monthly[[grep("1.54", names(vo_monthly))]]
## Now apply the 90th percentile across time (i.e., across these layers)
# vo_p90_1.5m <- app(vo_monthly_1.5m, fun = function(x) unname(quantile(x, probs = 0.90, na.rm = TRUE)))
# plot(vo_p90_1.5m)
# writeCDF(vo_p90_1.5m, "vo_p90_1.5m_m_s.nc", varname = "vo_p90_1.5m_m_s", overwrite = TRUE)

vo_p90_1.5m_m_s <- open.nc("data/vo_p90_1.5m_m_s.nc")
vo_p90_1.5m.value <- var.get.nc(vo_p90_1.5m_m_s, 'vo_p90_1.5m_m_s', unpack=TRUE)
vo_p90_1.5m.lat <- var.get.nc(vo_p90_1.5m_m_s, 'latitude')
vo_p90_1.5m.lon <- var.get.nc(vo_p90_1.5m_m_s, 'longitude')
close.nc(vo_p90_1.5m_m_s) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(vo_p90_1.5m.lat - lat_value))
  lon_index <- which.min(abs(vo_p90_1.5m.lon - lon_value))
  return(vo_p90_1.5m.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(vo_p90_1.5m_m_s = extract_values(latitude, longitude))

#Only select non-NA points
#This second function (extract_closest_values) extracts values of the closest sites, excluding the matching
#sites that were NAs, and instead inputing the closest available value for these

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in vo_p90_1.5m.value
  valid_indices <- which(!is.na(vo_p90_1.5m.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- vo_p90_1.5m.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- vo_p90_1.5m.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- vo_p90_1.5m.value[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(vo_p90_1.5m_m_s_closest = extract_closest_values(latitude, longitude))

# close.nc(physics_monthly) 

### Phosphate_mean ####
## Global Ocean Biogeochemistry Hindcast
## cmems_mod_glo_bgc_my_0.25deg_P1M-m
# BGC_monthly <- open.nc("data/cmems_mod_glo_bgc_my_0.25deg_P1M-m_multi-vars_9.00W-34.00E_34.00N-61.00N_0.51-1.56m_1993-01-01-2022-12-01.nc")
# print.nc(BGC_monthly) # Print report
## From this data product I want mean phosphate (po4) and pH (mean)
## Will select the sub surface depth 1.55585503578186 m

## NC_FLOAT po4(longitude, latitude, depth, time) ;
## NC_CHAR po4:long_name = "Phosphate" ;
## NC_CHAR po4:units = "mmol m-3" 

# po4_monthly <- rast("data/cmems_mod_glo_bgc_my_0.25deg_P1M-m_multi-vars_9.00W-34.00E_34.00N-61.00N_0.51-1.56m_1993-01-01-2022-12-01.nc", subds = "po4")
# po4_monthly_1.5m <- po4_monthly[[grep("1.5558", names(po4_monthly))]]
## calculate mean across time
# po4_mean_1.5m <- app(po4_monthly_1.5m, fun = mean, na.rm = TRUE)
# plot(po4_mean_1.5m)
# writeCDF(po4_mean_1.5m, "po4_mean_monthly_1.5m_mmol_m3.nc", varname = "po4_mean_1.5m_mmol_m3", overwrite = TRUE)

po4_mean_1.5m_mmol_m3 <- open.nc("data/po4_mean_monthly_1.5m_mmol_m3.nc")
# print.nc(po4_mean_1.5m_mmol_m3) # Print report

## Open data
po4_mean.value <- var.get.nc(po4_mean_1.5m_mmol_m3, 'po4_mean_1.5m_mmol_m3', unpack=TRUE)
po4_mean.lat <- var.get.nc(po4_mean_1.5m_mmol_m3, 'latitude')
po4_mean.lon <- var.get.nc(po4_mean_1.5m_mmol_m3, 'longitude')
close.nc(po4_mean_1.5m_mmol_m3) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(po4_mean.lat - lat_value))
  lon_index <- which.min(abs(po4_mean.lon - lon_value))
  return(po4_mean.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(po4_mean_1.5m_mmol_m3 = extract_values(latitude, longitude))

#Only select non-NA points
#This second function (extract_closest_values) extracts values of the closest sites, excluding the matching
#sites that were NAs, and instead inputing the closest available value for these

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in po4_mean.value
  valid_indices <- which(!is.na(po4_mean.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- po4_mean.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- po4_mean.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- po4_mean.value[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(po4_mean_1.5m_mmol_m3_closest = extract_closest_values(latitude, longitude))

#### pH_mean ####

## NC_FLOAT ph(longitude, latitude, depth, time) ;
## NC_CHAR ph:long_name = "PH" ;
## NC_CHAR ph:units = "1" ;

# pH_monthly <- rast("data/cmems_mod_glo_bgc_my_0.25deg_P1M-m_multi-vars_9.00W-34.00E_34.00N-61.00N_0.51-1.56m_1993-01-01-2022-12-01.nc", subds = "ph")
# pH_monthly_1.5m <- pH_monthly[[grep("1.5558", names(pH_monthly))]]
## calculate mean across time
# pH_mean_1.5m <- app(pH_monthly_1.5m, fun = mean, na.rm = TRUE)
# plot(pH_mean_1.5m)
# writeCDF(pH_mean_1.5m, "pH_mean_monthly_1.5m.nc", varname = "pH_mean_1.5m", overwrite = TRUE)

pH_mean_1.5m <- open.nc("data/pH_mean_monthly_1.5m.nc")
# print.nc(pH_mean_1.5m) # Print report
## Open data
pH_mean.value <- var.get.nc(pH_mean_1.5m, 'pH_mean_1.5m', unpack=TRUE)
pH_mean.lat <- var.get.nc(pH_mean_1.5m, 'latitude')
pH_mean.lon <- var.get.nc(pH_mean_1.5m, 'longitude')
close.nc(pH_mean_1.5m) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(pH_mean.lat - lat_value))
  lon_index <- which.min(abs(pH_mean.lon - lon_value))
  return(pH_mean.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(pH_mean_1.5m = extract_values(latitude, longitude))

## Only select non-NA points
## This second function (extract_closest_values) extracts values of the closest sites, excluding the matching
## sites that were NAs, and instead inputing the closest available value for these

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in pH_mean.value
  valid_indices <- which(!is.na(pH_mean.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- pH_mean.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- pH_mean.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- pH_mean.value[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(pH_mean_1.5m_closest = extract_closest_values(latitude, longitude))

# close.nc(BGC_monthly) #close file

#### VHM0_p95 ####
## Global Ocean Waves Reanalysis
## 3-hour product, 0.2 degrees, only selecting Sea surface wave significant height VHM0 [m] (1980-2023)
## https://data.marine.copernicus.eu/product/GLOBAL_MULTIYEAR_WAV_001_032/download?dataset=cmems_mod_glo_wav_my_0.2deg_PT3H-i_202411
## cmems_mod_glo_wav_my_0.2deg_PT3H-i
# Wave_height <- open.nc("data/cmems_mod_glo_wav_my_0.2deg_PT3H-i_VHM0_9.00W-34.00E_34.00N-61.00N_1980-01-01-2023-04-30.nc")
# print.nc(Wave_height) # Print report
# close.nc(Wave_height) #close file

# Wave_height_rast <- rast("data/cmems_mod_glo_wav_my_0.2deg_PT3H-i_VHM0_9.00W-34.00E_34.00N-61.00N_1980-01-01-2023-04-30.nc")

## calculate the 95th percentile  across time (This is a slow step)
# VHM0_p95_m <- app(Wave_height_rast, fun = function(x) unname(quantile(x, probs = 0.95, na.rm = TRUE)))
# plot(VHM0_p95_m)
# writeCDF(VHM0_p95_m, "wave_height_p95_m.nc", varname = "wave_height_VHM0_p95_m", overwrite = TRUE)

## Open data
wave_height_VHM0_p95_m <- open.nc("data/wave_height_p95_m.nc")
# print.nc(wave_height_VHM0_p95_m) # Print report
VHM0_p95_m.value <- var.get.nc(wave_height_VHM0_p95_m, 'wave_height_VHM0_p95_m', unpack=TRUE)
VHM0_p95_m.lat <- var.get.nc(wave_height_VHM0_p95_m, 'latitude')
VHM0_p95_m.lon <- var.get.nc(wave_height_VHM0_p95_m, 'longitude')
close.nc(wave_height_VHM0_p95_m) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(VHM0_p95_m.lat - lat_value))
  lon_index <- which.min(abs(VHM0_p95_m.lon - lon_value))
  return(VHM0_p95_m.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(wave_height_VHM0_p95_m = extract_values(latitude, longitude))

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in VHM0_p95_m.value
  valid_indices <- which(!is.na(VHM0_p95_m.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- VHM0_p95_m.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- VHM0_p95_m.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- VHM0_p95_m.value[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(wave_height_VHM0_p95_m_closest = extract_closest_values(latitude, longitude))

#### fgCO2_p95 ####
## Surface ocean carbon fields
## https://data.marine.copernicus.eu/product/MULTIOBS_GLO_BIO_CARBON_SURFACE_MYNRT_015_008/services
## 1985-2023 (there is also a near-real time 2024-2025 product)
## monthly product
## cmems_obs-mob_glo_bgc-car_my_irr-i
# Carbon <- open.nc("data/cmems_obs-mob_glo_bgc-car_my_irr-i_multi-vars_8.88W-33.88E_34.12N-60.88N_1985-01-01-2023-12-01.nc")
# print.nc(Carbon) # Print report

##	NC_FLOAT fgco2(longitude, latitude, time) ;
## NC_FLOAT fgco2:_FillValue = 9.96920996838687e+36 ;
## NC_STRING fgco2:long_name = "Surface downward flux of total CO2" ;
## NC_STRING fgco2:units = "molC m-2 yr-1" ;
## NC_STRING fgco2:standard_name = "surface_downward_mass_flux_of_carbon_dioxide_expressed_as_carbon" ;

# Surf_fgco2_rast <- rast("data/cmems_obs-mob_glo_bgc-car_my_irr-i_multi-vars_8.88W-33.88E_34.12N-60.88N_1985-01-01-2023-12-01.nc", subds = "fgco2")

## calculate the 95th percentile  across time
# Surf_fgco2_p95_molC_m2_yr <- app(Surf_fgco2_rast, fun = function(x) unname(quantile(x, probs = 0.95, na.rm = TRUE)))
# writeCDF(Surf_fgco2_p95_molC_m2_yr, "Surf_fgco2_p95_molC_m2_yr.nc", varname = "Surf_fgco2_p95_molC_m2_yr", overwrite = TRUE)

## Open data
Surf_fgco2_p95_molC_m2_yr <- open.nc("data/Surf_fgco2_p95_molC_m2_yr.nc")
# print.nc(Surf_fgco2_p95_molC_m2_yr) # Print report

Surf_fgco2_p95.value <- var.get.nc(Surf_fgco2_p95_molC_m2_yr, 'Surf_fgco2_p95_molC_m2_yr', unpack=TRUE)
Surf_fgco2_p95.lat <- var.get.nc(Surf_fgco2_p95_molC_m2_yr, 'latitude')
Surf_fgco2_p95.lon <- var.get.nc(Surf_fgco2_p95_molC_m2_yr, 'longitude')
close.nc(Surf_fgco2_p95_molC_m2_yr) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(Surf_fgco2_p95.lat - lat_value))
  lon_index <- which.min(abs(Surf_fgco2_p95.lon - lon_value))
  return(Surf_fgco2_p95.value[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(Surf_fgco2_p95_molC_m2_yr = extract_values(latitude, longitude))

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in Surf_fgco2_p95.value
  valid_indices <- which(!is.na(Surf_fgco2_p95.value), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- Surf_fgco2_p95.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- Surf_fgco2_p95.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- Surf_fgco2_p95.value[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(Surf_fgco2_p95_molC_m2_yr_closest = extract_closest_values(latitude, longitude))

#### KD490 ####
## KD = Diffuse attenuation coefficient at 490 nm (Entire mission composite) (4km) (Standard) (S3A-OLCI)
## Downloaded from https://oceandata.sci.gsfc.nasa.gov/l3/order/ on March 11, 2025
## This parameter is widely used in oceanography to assess water clarity and the presence of 
  #particles in the water column. A lower Kd490 value indicates clearer water, as light can 
  #penetrate deeper. Conversely, a higher value suggests more turbidity due to particles like 
  #phytoplankton, sediments, or organic matter.
## Note that The S3A-OLCI satellite offers high-resolution data (300 m spatial resolution), but these 
## data products are 4km
KD <- open.nc("data/S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.KD.Kd_490.4km.nc")
# print.nc(KD) # Print report
# Open data
KD.Kd490 <- var.get.nc(KD, 'Kd490', unpack=TRUE)
KD.lat <- var.get.nc(KD, 'lat')
KD.lon <- var.get.nc(KD, 'lon')
close.nc(KD) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(KD.lat - lat_value))
  lon_index <- which.min(abs(KD.lon - lon_value))
  return(KD.Kd490[lon_index, lat_index])
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(KD = extract_values(latitude, longitude))

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in KD.Kd490
  valid_indices <- which(!is.na(KD.Kd490), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- KD.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- KD.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value from KD.Kd490
  value_at_closest <- KD.Kd490[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(KD_closest = extract_closest_values(latitude, longitude))

#### RRS443 ####
## RRS443 = Remote sensing reflectance at 443 nm (Entire mission composite) (4km) (Standard) (S3A-OLCI)
## Downloaded from https://oceandata.sci.gsfc.nasa.gov/l3/order/ on March 11, 2025
## Generally close to chla product
## Note that The S3A-OLCI satellite offers high-resolution data (300 m spatial resolution), but these 
## data products are 4km
RRS443 <- open.nc("data/S3A_OLCI_ERRNT.20160425_20241231.L3m.CU.RRS.Rrs_443.4km.nc")
## print.nc(RRS443) # Print report
## Open data
RRS443.Rrs_443 <- var.get.nc(RRS443, 'Rrs_443', unpack=TRUE)
RRS443.lat <- var.get.nc(RRS443, 'lat')
RRS443.lon <- var.get.nc(RRS443, 'lon')
close.nc(RRS443) #close file

extract_values <- function(lat_value, lon_value) {
  lat_index <- which.min(abs(RRS443.lat - lat_value))
  lon_index <- which.min(abs(RRS443.lon - lon_value))
  return(RRS443.Rrs_443[lon_index, lat_index])  # Adjust index order if needed
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(RRS443 = extract_values(latitude, longitude))

extract_closest_values <- function(lat_value, lon_value) {
  # Get indices of valid (non-NA) points in RRS443.Rrs_443
  valid_indices <- which(!is.na(RRS443.Rrs_443), arr.ind = TRUE)
  
  # Extract the corresponding valid latitude and longitude values
  valid_Lat <- RRS443.lat[valid_indices[, 2]]  # lat corresponds to columns
  valid_Lon <- RRS443.lon[valid_indices[, 1]]  # lon corresponds to rows
  
  # Calculate distances to the target point for valid locations
  distances <- sqrt((valid_Lat - lat_value)^2 + (valid_Lon - lon_value)^2)
  
  # Find the index of the closest valid point
  closest_valid_index <- valid_indices[which.min(distances), ]
  
  # Retrieve the corresponding value
  value_at_closest <- RRS443.Rrs_443[closest_valid_index[1], closest_valid_index[2]]
  return(value_at_closest)
}

Seagrass_site_withEnv <- Seagrass_site_withEnv %>%
  rowwise() %>%
  mutate(RRS443_closest = extract_closest_values(latitude, longitude))

# Remove extra columns (should only retain the env. covariates with "_closest")
Seagrass_site_withEnv <- Seagrass_site_withEnv %>% select(-c("bottomT_p95_C", "uo_mean_1.5m_m_s",
      "vo_p90_1.5m_m_s", "po4_mean_1.5m_mmol_m3", "pH_mean_1.5m", "wave_height_VHM0_p95_m",
      "Surf_fgco2_p95_molC_m2_yr", "KD", "RRS443"))

## Some of the remote sensing variables can still have negative values even though they should not. 
## Set these to zero if this is the case.
Seagrass_site_withEnv$KD_closest[Seagrass_site_withEnv$KD_closest < 0] <- 0
Seagrass_site_withEnv$RRS443_closest[Seagrass_site_withEnv$RRS443_closest < 0] <- 0

## Add a variable for sediment mean depth
## For each row in the current dataframe, expand to 10 rows (with the same values), and add a new column called
## "sediment_mean_depth_cm" with the following entries "5, 15, 25, 35, 45, 55, 65, 75, 85, 95"
depths <- c(5, 15, 25, 35, 45, 55, 65, 75, 85, 95)
Seagrass_site_expanded <- Seagrass_site_withEnv[rep(1:nrow(Seagrass_site_withEnv), each = length(depths)), ]
Seagrass_site_expanded$sediment_mean_depth_cm <- rep(depths, times = nrow(Seagrass_site_withEnv))

summary(Seagrass_site_expanded)
str(Seagrass_site_expanded) #all should be numeric, except for the seagrass_species factor variable

#Save dataframe to use for model prediction
write.csv(Seagrass_site_expanded, "data/SG_modeling_dataframe.csv", row.names = FALSE)
