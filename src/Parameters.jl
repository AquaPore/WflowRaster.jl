
# =============================================================
#		MODULE: cst
# =============================================================

# PLOTTING
	Flag_Plots = true


# ======= PATHS =======
	Path_Root         = raw"d:\JOE\MAIN\MODELS\WFLOW\DATA\Timoleague"

   Path_InputForcing          = "InputTimeSeries/TimeSeries_Process"
   Path_InputGis              = "InputGis"
   Path_NetCDF                = "OutputNetCDF"
   Path_OutputJulia           = "OutputJulia"
   Path_OutputPython          = "OutputPython"
   Path_OutputTimeSeriesWflow = "InputTimeSeries/TimeSeries_Wflow"
   Path_OutputWflow           = "OutputWflow"

	# ====== FILES NAME =======
	# === Input  GIS ===
	Dem_Input     = "Timoleague_DTM_1m.tif"
	Outlet_Input  = "Timoleague_Outlet_Hydro.shp"
	River_Input   = "Timoleague_River.shp"
	Temporary_Dem = "Temporary_DEM.tif"


	# === Input from Python ===
   Ldd_Python         = "Ldd.tiff"
   RiverLength_Python = "RiverLength.tiff"
   Slope_Python       = "Slope.tiff"
   Subcatch_Python    = "Subcatchment.tiff"


	# === Output Julia ===
	Dem_Julia        = "Timoleague_DEM.tif"
	Dem_Julia_Mask   = "Timoleague_DEM_Mask.tif"
	Outlet_Julia     = "Timololeague_Outlet.tiff"

	# === Output wflow ===
	Ldd_Wflow   = "wflow_ldd.tiff"
	River_Wflow      = "wflow_river.tiff"
	Slope_Wflow      = "Slope.tiff"
	RiverSlope_Wflow = "RiverSlope.tiff"
	RiverWidth_Wflow = "wflow_riverwidth.tiff"
	RiverDepth_Wflow = "wflow_riverdepth.tiff"
	Subcatch_Wflow = "wflow_subcatch.tiff"

	# === Output netCDF ===
	NetCDF_Instates  = "instates-Timoleague.nc"
	NetCDF_Forcing  = "forcing-Timoleague.nc"

	# Coordinate reference system
	Crs             = 29902    # [-] This is the default projection TM65 / Irish Grid

	# Resampling method of DEM in 2 steps:
		ResampleMethod₁ = :min
		ΔX₁             = 3 # [m] Gridded spatial resolution
		ResampleMethod₂ = :cubicspline
		ΔX₂             = 5; # [m] Gridded spatial resolution

	# RIVER PARAMETERS
		P_RiverWidth = 2 # [m]
		P_RiverDepth = 5;  # must be an integer [m]

