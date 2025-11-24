# Seagrass_carbon_stock_model

![documentation/images/workflow_flowchart.png](documentation/images/workflow_flowchart.png)

**Author** Natalya D. Gallo
**Reference**

_TO Add **Short explanation of the aim of the workflow**_

## Introduction

The seagrass carbon stock model was developed to bring in relevant environmental data for modeling carbon stock as a function of environmental co-variates from remote sensing and Copernicus data products.

To run the model, it contains two steps: 
1. Extract closest values of the matching sites.
2. Predicet carbon stock in the upper 30 and 100 cm of a seagrass bed at the sites.

## Data preparation

### The European seagrasses.

* Cymodocea nodosa  
* Halophila stipulacea  
* Posidonia oceanica  
* Zostera marina  
* Zostera noltei  
* Zostera marina and Cymodocea nodosa  
* Zostera marina and Zostera noltei  

### The list of input datasets

* 95th percentile of bottom temperature (°C), 
* Eastward seawater velocity (m s-1), 
* Northward seawater velocity (m s-1), 
* Phosphate at sub surface depth 1.5 m (mmol m-3), 
* PH at sub surface depth 1.5 m (1), 
* Sea surface wave significant height (m), 
* Surface downward flux of total CO2 (molC m-2 yr-1), 
* Diffuse attenuation coefficient at 490 nm, 
* Remote sensing reflectance at 443 nm,

Example of 95th percentile of bottom temperature data

![Bottom Temperature](documentation/images/Eample-Data_bottom.png)

## Results

### Summary of carbon stock

Example of carbon stock summary

<div style="display: inline-block">

```
For the seagrass bed at latitude 56.0953 and longitude 14.2785
The species identity Posidonia oceanica
The predicted carbon stock in the upper 
  - upper 30cm  of the sediment is 45.157 Mg/ha
  - upper 100cm of the sediment is 160.465 Mg/ha
```

</div>

### CSV file

Example of carbon stock table

<div style="display: inline-block">

| latitude | longitude | seagrass_species   | ... | carbon_stock_Mg_ha_upper30cm | carbon_stock_Mg_ha_upper100cm |
| -------- | --------- | ------------------ | --- | ---------------------------- | ----------------------------- |
| 56.0953  | 14.2785   | Posidonia oceanica | ... | 45.157343393228              | 160.46545898523               |

</div>
