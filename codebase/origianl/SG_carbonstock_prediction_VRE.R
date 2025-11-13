# This script was developed to predict carbon stock in the upper 30 and 100 cm of the sediment of a seagrass
# bed based on the dataset produced in the script "Environmental_covariates_matching_VRE.R",
# called "SG_modeling_dataframe.csv"

# Script author Natalya D. Gallo
# Script developed on 30 Oct 2024 and targeted for the LifeWatch VRE product as
# part of MARCO-BOLO Task 5.3

# Refresh working directory
rm(list = ls())

## Open needed packages
library(here)
library(tidyverse)
library(RNetCDF) 
library(mgcv)
#library(ggplot2)
#library(gridExtra)
#library(rnaturalearth)
#library(rnaturalearthdata)
#library(tidyr)
#library(terra)
#library(viridis)
#library(sf)
library(dplyr)
library(stringr)

# Set working directory
setwd(here::here())

# Open SG_modeling_dataframe.csv
SG_modeling_dataframe <- read.csv("data/SG_modeling_dataframe.csv")
#check that structure is correct (all should be numeric, except for seagrass_species which should be a factor)
str(SG_modeling_dataframe)

SG_modeling_dataframe <- SG_modeling_dataframe %>%
  mutate(seagrass_species = str_trim(seagrass_species),  # remove leading/trailing spaces
         seagrass_species = str_squish(seagrass_species))  # remove extra internal spaces
#SG_modeling_dataframe$seagrass_species <- as.factor(SG_modeling_dataframe$seagrass_species)
SG_modeling_dataframe$sediment_mean_depth_cm <- as.numeric(SG_modeling_dataframe$sediment_mean_depth_cm)
str(SG_modeling_dataframe)

For_modeling_df_shallow_carbon_density <- read_rds("data/For_modeling_df_shallow_carbon_density.rds")
str(For_modeling_df_shallow_carbon_density$random_core_variable) #382 levels (from 461 cores in full dataset, down to 382 unique cores)

"Zostera marina and Zostera noltei" %in% levels(For_modeling_df_shallow_carbon_density$seagrass_species)
setdiff(unique(SG_modeling_dataframe$seagrass_species), levels(For_modeling_df_shallow_carbon_density$seagrass_species))
# From SG_modeling_dataframe
raw_SG <- charToRaw(as.character(SG_modeling_dataframe$seagrass_species[SG_modeling_dataframe$seagrass_species == "Zostera marina/Zostera noltei"][1]))
# From For_modeling_df_shallow_carbon_density
raw_training <- charToRaw(as.character(For_modeling_df_shallow_carbon_density$seagrass_species[For_modeling_df_shallow_carbon_density$seagrass_species == "Zostera marina/Zostera noltei"][1]))
identical(raw_SG, raw_training)

# Match factor levels for seagrass_species
SG_modeling_dataframe$seagrass_species <- factor(
  SG_modeling_dataframe$seagrass_species,
  levels = levels(For_modeling_df_shallow_carbon_density$seagrass_species)
)

# Use an existing placeholder level from the training data for random_core_variable
# Doesn't matter which one you use because this will be excluded in the model prediction, so I have just picked one
SG_modeling_dataframe$random_core_variable <- 
  factor(rep("Baltic Sea_Furumon_NA_2021_NA_NA_56.0953_14.7202_1.5", nrow(SG_modeling_dataframe)), 
         levels = levels(For_modeling_df_shallow_carbon_density$random_core_variable))
summary(SG_modeling_dataframe)

# Open carbon density prediction model (prepared in script: SG_carbonstock_model.R)
GAM_top_reduced_SGstock <- readRDS("GAM_top_reduced_model_SGstock.rds")
summary(GAM_top_reduced_SGstock)

#Predict carbon density for new samples based on input variables in the "SG_modeling_dataframe.csv" spreadsheet
predicted_carbon_density <- predict(GAM_top_reduced_SGstock, newdata = SG_modeling_dataframe, type = "response",
                                           exclude = "s(random_core_variable)")
#predicted_carbon_density_coreID_notexcluded <- predict(GAM_top_reduced_SGstock, newdata = SG_modeling_dataframe, type = "response")
#predicted_carbon_density_nocoreID <- predict(GAM_top_reduced_SGstock_nocoreID, newdata = SG_modeling_dataframe, type = "response")

#Add predictions to dataframe
SG_modeling_dataframe$predicted_carbon_density <- predicted_carbon_density
summary(SG_modeling_dataframe)

#calculate carbon stock
#Carbon stock = Carbon density (gC/cm3) x Depth (cm) x 10,000
# 1 hectare = 10,000 square metres (m²), Equivalent to 2.471 acres
# Carbon stocks are often expressed as: tonnes of carbon per hectare (t C/ha) OR
# megagrams of carbon per hectare (Mg C/ha) (1 Mg = 1 tonne)
#Carbon density is in: gC cm-3

SG_modeling_dataframe$predicted_carbon_stock_per_10cm = 
  SG_modeling_dataframe$predicted_carbon_density*10*100000000*(1/1000000)
# Carbon stock (MgC/ha)=Carbon density (gC/cm³) × Depth (cm) × 100,000,000 (cm2/ha) ÷ 1,000,000 (g/Mg)
# Where: 1 hectare = 10,000 m² = 100,000,000 cm²
# 1 Mg = 1,000,000 g

#Create sample_ID column
SG_modeling_dataframe$sample_ID <- rep(1:(nrow(SG_modeling_dataframe)/10), each = 10)

#Calculate carbon stock in the upper 30 and 100 cm
SG_modeling_dataframe <- SG_modeling_dataframe %>%
  group_by(sample_ID) %>%
  mutate(
    carbon_stock_Mg_ha_upper30cm = sum(predicted_carbon_stock_per_10cm[1:3]),
    carbon_stock_Mg_ha_upper100cm = sum(predicted_carbon_stock_per_10cm)
  ) %>%
  ungroup()

#Create response prompt with answers
library(dplyr)

# Create summary sentences
summary_sentences <- SG_modeling_dataframe %>%
  group_by(sample_ID) %>%
  slice(1) %>%  # take one row per sample
  mutate(summary = paste0(
    "For the seagrass bed at latitude ", latitude,  # replace with actual column name
    " and longitude ", longitude,  # replace with actual column name
    " with species identity ", seagrass_species, 
    ", the predicted carbon stock in the upper 30cm of the sediment is ", format(carbon_stock_Mg_ha_upper30cm, digits=3, nsmall=3), " Mg/ha",
    " and the predicted carbon stock in the upper 100cm of the sediment is ", format(carbon_stock_Mg_ha_upper100cm, digits=3, nsmall=3), " Mg/ha."
  )) %>%
  pull(summary)

# Print the summaries
cat(summary_sentences, sep = "\n\n")

