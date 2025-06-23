
# =========================================
# 					PARAMETERS
# =========================================

# FLAGS
   🎏_Plots                 = true
   🎏_Plot_TimeSeries       = true
   🎏_Plot_FlowAccumulation = true
   🎏_Plot_NetCDF           = false

   🎏_TimeSeries    = true
   🎏_NetCDF        = true
   🎏_SoilMap       = true
   🎏_VegetationMap = true
   🎏_RoadMap       = true

# ======= PATHS =======
   Path_Root             = raw"d:\JOE\MAIN\MODELS\WFLOW\DATA\Timoleague"
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
      Outlet_Shp        = "Timoleague_Outlet_Hydro.shp"
      River_Shp         = "Timoleague_River.shp"
      Roads_Shp         = "Roads2.shp"
      SoilMap_Shp       = "SoilMap.shp"
      VegetationMap_Shp = "Landuse.shp"

	# === Raster file ===
      Dem_Input      = "Timoleague_DTM_1m.tif"
      SoilMap_Raster = "SoilMap_Raster.tif"
      Temporary_Dem  = "Temporary_DEM.tif"

# === Input  Forcing ===
	Forcing_Input = "forcing.Timoleague.csv"

# === Input from Python ===
   Ldd_Python         = "Ldd.tiff"
   RiverLength_Python = "RiverLength.tiff"
   Slope_Python       = "Slope.tiff"
   Subcatch_Python    = "Subcatchment.tiff"

# === Output Julia ===
	Dem_Julia        = "Timoleague_DEM.tiff"
	Dem_Julia_Mask   = "Timoleague_DEM_Mask.tiff"
	Outlet_Julia     = "Timololeague_Outlet.tiff"

# === Output wflow ===
   Ldd_Wflow         = "wflow_ldd.tiff"
   RiverDepth_Wflow  = "wflow_riverdepth.tiff"
   RiverLength_Wflow = "wflow_riverlength.tiff"
   RiverSlope_Wflow  = "RiverSlope.tiff"
   RiverWidth_Wflow  = "wflow_riverwidth.tiff"
   River_Wflow       = "wflow_river.tiff"
   Slope_Wflow       = "Slope.tiff"
   Subcatch_Wflow    = "wflow_subcatch.tiff"
	Impermable_Wflow  = "Wflow_Impermeable.tiff"

# === Lookup tables ===
   Lookup_Hydro      = "LookupTable_Hydro.csv"
   Lookup_Vegetation = "LookupTable_Veg.csv"

# === Output netCDF ===
	NetCDF_Instates  = "instates-Timoleague.nc"
	NetCDF_Forcing  = "forcing-Timoleague.nc"


# -----------------------------------------------------------------------------------------

	# Coordinate reference system
		Crs             = 29902    # [-] This is the default projection TM65 / Irish Grid

	# Resampling method of DEM in 2 steps:
		ResampleMethod₁ = :min
		ΔX₁             = 5 # [m] Gridded spatial resolution
		ResampleMethod₂ = :cubicspline
		ΔX₂             = 10; # [m] Gridded spatial resolution should be a multiple of ΔX₁

	# RIVER PARAMETERS
		P_RiverWidth = 5.0::Float64 # [m]
		P_RiverDepth = 10.0::Float64;  # must be an integer [m]

	# OUTLETS COORDINATES
		# OutletCoordinate = [146707.700, 42167.995]
		# OutletCoordinate = [146709.504,42170.157]

		OutletCoordinate = [146708.9364,42168.9515]

	# DATES
	Base.@kwdef mutable struct DATES
      Start_Year  = 2010 :: Int64
      Start_Month = 1 :: Int64
      Start_Day   = 1 :: Int64
      Start_Hour  = 0 :: Int64

      End_Year    = 2010 :: Int64
      End_Month   = 2 :: Int64
      End_Day     = 1 :: Int64
      End_Hour    = 0 :: Int64
   end # struct METADATA


