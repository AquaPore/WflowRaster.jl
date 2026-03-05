# WflowRaster

[![Build Status](https://github.com/AquaPore/WflowRaster.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/AquaPore/WflowRaster.jl/actions/workflows/CI.yml?query=branch%3Amaster)

# PROCESSING WFLOW MODEL INPUT FILES TO RASTERS NETCDF FORMAT FOR SMALL AGRICULTURE CATCHMENTS

## Warning: Work in progress

[WFLOW](https://deltares.github.io/Wflow.jl/v0.8/) (*make sure you are viewing the latest version of the documentation, you can also refer to the dev website*). Wflow is Deltares’ solution for modelling hydrological processes, allowing users to account for precipitation, interception, snow accumulation and melt, evapotranspiration, soil water, surface water, groundwater recharge, and water demand and allocation in a fully distributed environment.

## WflowRaster.jl

Building an automatic workflow in Jupyter Notebook to process time series and GIS data into Wflow model by  combining geo packages in Julia and Python
language.

*WflowRaster.jl* is written in Julia by using *Jupyter Notebook* and is a tool for processing Wflow model input data coming from *.tiff* and shape format. It converts raster format into **NetCDF **format and also time series meteorological maps into NetCDF format. and fixed input data.

It also has tools to Visalise the output data.

The processing of the DEM data is performed in a Python package [WflowRasterPython](https://github.com/AquaPore/WflowRasterPython.py)
