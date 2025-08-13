
# =========================================
# 					PARAMETERS
# =========================================

# FLAGS

   🎏_Mosaic     = false
   🎏_Coastline  = true
   🎏_Fix_Cyclic = false


   🎏_Forcing_2_NetCDF = true
   🎏_ImpermeableMap   = false
   🎏_NetCDF           = true
   🎏_SoilMap          = true
   🎏_VegetationMap    = true

   🎏_Plots                 = true
   🎏_Plot_TimeSeries       = true
   🎏_Plot_FlowAccumulation = false
   🎏_Plot_NetCDF           = false


# ======= PATHS =======
   Path_Root             = raw"d:\JOE\MAIN\MODELS\WFLOW\DATA\TimoleagueCrop"
   Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\FABDEM\IRELAND_MOSAIC"
   Path_Root_NetCDF      = raw"D:\JOE\MAIN\MODELS\WFLOW\Wflow.jl\Wflow\Data\input\Timoleague"
   Path_Root_LookupTable = "DATA//Lookuptable"

	Path_InputForcing          = "InputTimeSeries/TimeSeries_Process"
   Path_InputGis              = "InputGis"
   Path_InputLookuptable      = "LookupTables"
   Path_NetCDF                = "OutputNetCDF"
   Path_OutputJulia           = "OutputJulia"
   Path_OutputPython          = "OutputPython"
   Path_OutputTimeSeriesWflow = "InputTimeSeries/TimeSeries_Wflow"
   Path_OutputWflow           = "OutputWflow"

# ======= INPUT GIS =======
	# === Shape file ===
      Landuse_Shp       = "Landuse.shp"
      Gauge_Shp         = "Timoleague_Gauge_Hydro.shp"
      River_Shp         = "Timoleague_River3.shp"
      Roads_Shp         = "Roads2.shp"
      SoilMap_Shp       = "SoilMap.shp"
      VegetationMap_Shp = "Landuse.shp"
      # Mask_Shp          = "Ireland_Coastline.shp"
      Mask_Shp          = "Crop_Timoleague.shp"


	# === Raster file ===
      # Dem_Input_Qgis = "Timoleague_DTM_5m_Clipped.tif"
      Dem_Input_Qgis = "Ireland_FABDEM.tif"
      SoilMap_Raster = "SoilMap_Raster.tif"
      Temporary_Dem  = "Temporary_DEM.tif"

# === Input  Forcing ===
	Forcing_Input = "forcing.Timoleague.csv"

# === Input from Python ===
   Dem_Input_Python   = "DemCorrected.tiff"
   Ldd_Python         = "Ldd.tiff"
   RiverLength_Python = "RiverLength.tiff"
   Slope_Python       = "Slope.tiff"
   Subcatch_Python    = "Subcatchment.tiff"
   # Subcatch_Python    = "Basins.tiff"

# === Output Julia ===
   Dem_Julia           = "Ireland_DEM_Croped.tiff"
   Dem_Julia_Corrected = "Timoleague_DEM_Corrected.tiff"
   Dem_Julia_Mask      = "Timoleague_DEM_Mask.tiff"
   Gauge_Julia         = "Timololeague_Gauge.tiff"
   Pits_Julia          = "Timoleague_Pits.tiff"

# === Output wflow ===
   Ldd_Wflow         = "wflow_ldd.tiff"
   RiverDepth_Wflow  = "wflow_riverdepth.tiff"
   RiverLength_Wflow = "wflow_riverlength.tiff"
   RiverSlope_Wflow  = "RiverSlope.tiff"
   RiverWidth_Wflow  = "wflow_riverwidth.tiff"
   River_Wflow       = "wflow_river.tiff"
   Slope_Wflow       = "Slope.tiff"
   Subcatch_Wflow    = "wflow_subcatch.tiff"
   Impermable_Wflow  = "PathFrac.tiff"
   Gauge_Wflow       = "wflow_gauges_grdc.tiff"

# === Lookup tables ===
   Lookup_Hydro      = "LookupTable_Hydro.csv"
   Lookup_Vegetation = "LookupTable_Veg.csv"

# === Output netCDF ===
	NetCDF_Instates  = "staticmaps-Timoleague.nc"
	NetCDF_Forcing  = "forcing-Timoleague.nc"


# -----------------------------------------------------------------------------------------

	# Coordinate reference system
		Param_Crs             = 29902    # [-] This is the default projection TM65 / Irish Grid

	# Resampling method of DEM in 2 steps:
		ResampleMethod₁ = :min
		ΔX₁             = 10 # [m] Gridded spatial resolution
		ResampleMethod₂ = :cubicspline
		ΔX₂             = 20 # [m] Gridded spatial resolution should be a multiple of ΔX₁

	# RIVER PARAMETERS
		P_RiverWidth = 5.0::Float64 # [m]
		P_RiverDepth = 10.0::Float64;  # must be an integer [m]

	# GAUGE COORDINATES
      # Param_GaugeCoordinate =  [146700.2167,42159.7300]
      # Param_GaugeCoordinate = [146690.673,42139.540]
      Param_GaugeCoordinate =[146681.976,42127.854]
      Dem_PitGaugeReduced = 10.00

   # LAYERS
      soil_layer__thickness = [100, 300, 800]

	# DATES
	Base.@kwdef mutable struct DATES
      Start_Year  = 2010 :: Int64
      Start_Month = 1 :: Int64
      Start_Day   = 1 :: Int64
      Start_Hour  = 0 :: Int64

      End_Year    = 2010 :: Int64
      End_Month   = 3 :: Int64
      End_Day     = 1 :: Int64
      End_Hour    = 0 :: Int64
   end # struct METADATA


