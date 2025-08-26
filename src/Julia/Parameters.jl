
# =========================================
# 					PARAMETERS
# =========================================

# Flags: processing inputs
   🎏_Coastline      = false
   🎏_DemFromMosaic  = false # Gis stored
   🎏_Fix_Cyclic     = false # obsolete
   🎏_MaskFromDem    = true
   🎏_Mosaic         = true
   🎏_RiverFromDem   = true

   # Flags: outputs of interest
      🎏_ImpermeableMap = false

   # Flags: LookupTables
      🎏_SoilMap               = true
      🎏_VegetationMap         = true
      🎏_LookupTable_Shp_SoilMap = false # <true> If soilmap is shp; <false> if soilmap is tiff
      🎏_LookupTable_Shp_Vegetation = false # <true> If soilmap is shp; <false> if soilmap is tiff

   # Flags: plots
      🎏_Plots                 = true
      🎏_Plot_TimeSeries       = true
      🎏_Plot_FlowAccumulation = false
      🎏_Plot_NetCDF           = false

   # Flags: NetCDF
      🎏_NetCDF                = true
      🎏_Forcing_2_NetCDF      = true

@assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

# ======= PATHS =======
   Path_Root             = raw"d:\JOE\MAIN\MODELS\WFLOW\DATA\TimoleagueCrop"
   Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\FABDEM\IRELAND_MOSAIC"
   Path_Root_NetCDF      = raw"D:\JOE\MAIN\MODELS\WFLOW\Wflow.jl\Wflow\Data\input\Timoleague"
   Path_Root_LookupTable = raw"DATA\Lookuptable"

   Path_Forcing         = "InputTimeSeries/TimeSeries_Process"
   Path_Gis             = "InputGis"
   Path_Julia           = "OutputJulia"
   Path_Lookuptable     = "LookupTables"
   Path_NetCDF          = "OutputNetCDF"
   Path_Python          = "OutputPython"
   Path_TimeSeriesWflow = "InputTimeSeries/TimeSeries_Wflow"
   Path_Wflow           = "OutputWflow"

# ======= INPUT GIS =======
	# === Shape file ===
      Filename_Gauge_Shp         = "Timoleague_Gauge_Hydro.shp"
      Filename_Landuse_Shp       = "Landuse.shp"
      Filename_Mask_Shp          = "Crop_Timoleague.shp"
      Filename_River_Shp         = "Timoleague_River3.shp"
      Filename_Roads_Shp         = "Roads2.shp"
      Filename_SoilMap_Shp       = "SoilMap.shp"
      Filename_VegetationMap_Shp = "VegetationMap.shp"

	# === Raster input file ===
      Filename_Input_Dem        = "Ireland_FABDEM.tif"
      Filename_Input_SoilMap    = "SoilMap.tiff"

# === Input  Forcing ===
	Filename_Input_Forcing = "forcing.Timoleague.csv"

# === Input from Python ===
   Filename_Python_DemCorrected          = "DemCorrected.tiff"
   Filename_Python_Ldd                   = "Ldd.tiff"
   Filename_Python_RiverLength           = "RiverLength.tiff"
   Filename_Python_Slope                 = "Slope.tiff"
   Filename_Python_CatchmentSubcatchment = "CatchmentSubcatchment.tiff"
   Filename_Python_Dem2Rivers            = "Dem2Rivers.tiff"

# === Output Julia ===
   Filename_Julia_Dem          = "Ireland_DEM_Croped.tiff"
   Filename_Julia_DemCorrected = "Timoleague_DEM_Corrected.tiff"
   Filename_Julia_Gauge        = "Timololeague_Gauge.tiff"
   Filename_Julia_Pits         = "Timoleague_Pits.tiff"
   Filename_Coastline          = "Coastline.tiff"

# === Output wflow ===
   Filename_Wflow_Ldd          = "Wflow_Ldd.tiff"
   Filename_Wflow_RiverDepth   = "Wflow_Riverdepth.tiff"
   Filename_Wflow_RiverLength  = "Wflow_Riverlength.tiff"
   Filename_Wflow_RiverSlope   = "Wflow_RiverSlope.tiff"
   Filename_Wflow_RiverWidth   = "Wflow_Riverwidth.tiff"
   Filename_Wflow_Rivers       = "Wflow_River.tiff"
   Filename_Wflow_Slope        = "Wflow_Slope.tiff"
   Filename_Wflow_Subcatchment = "Wflow_Subcatchment.tiff"
   Filename_Wflow_Impermable   = "Wflow_PathFrac.tiff"
   Filename_Wflow_Gauge        = "Wflow_Gauges_grdc.tiff"

# === Lookup tables ===
   Filename_Lookuptable_Hydro      = "LookupTable_Hydro.csv"
   Filename_Lookuptable_Vegetation = "LookupTable_Veg.csv"

# === Output netCDF ===
   Filename_NetCDF_Instates = "staticmaps-Timoleague.nc"
   Filename_NetCDF_Forcing  = "forcing-Timoleague.nc"


# -----------------------------------------------------------------------------------------

	# Coordinate reference system
		Param_Crs             = 29902    # [-] This is the default projection TM65 / Irish Grid

	# Resampling method of DEM in 2 steps:
		Param_ResampleMethod₁ = :min
		Param_ΔX₁             = 20 # [m] Gridded spatial resolution
		Param_ResampleMethod₂ = :cubicspline
		Param_ΔX₂             = 20 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

	# RIVER PARAMETERS
		Param_RiverWidth = 5.0::Float64 # [m]
		Param_RiverDepth = 10.0::Float64;  # must be an integer [m]

	# GAUGE COORDINATES
      # Param_GaugeCoordinate =  [146700.2167,42159.7300]
      # Param_GaugeCoordinate = [146690.673,42139.540]
      Param_GaugeCoordinate =[146701.41,42082.39]

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
