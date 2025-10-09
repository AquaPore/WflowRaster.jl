
# =========================================
# 					PARAMETERS
# =========================================

   🎏_CatchmentName = "Timoleague" # <"Timoleague">; <"Ballycanew">; <"Castledockerell">; <"Corduff">; <"Dunleer">; <"Cregduff">

   # DATES
   Base.@kwdef mutable struct DATES
      Start_Year  = 2010 :: Int64
      Start_Month = 1 :: Int64
      Start_Day   = 10 :: Int64
      Start_Hour  = 0 :: Int64

      End_Year    = 2024 :: Int64
      End_Month   = 12 :: Int64
      End_Day     = 30 :: Int64
      End_Hour    = 23 :: Int64
   end # struct METADATA

   # Flags: plots
      🎏_Plots                 = false
      🎏_Plot_TimeSeries       = false
      🎏_Plot_FlowAccumulation = false
      🎏_Plot_NetCDF           = false

   # ======= PATHS =======
      Path_Root             = joinpath(raw"d:\JOE\MAIN\MODELS\WFLOW\DATA", "$🎏_CatchmentName")
      Path_Root_NetCDF      = joinpath(raw"D:\JOE\MAIN\MODELS\WFLOW\Wflow.jl\Wflow\Data\input", "$🎏_CatchmentName")
      Path_Root_LookupTable = raw"DATA\Lookuptable"

      Path_Forcing         = "InputTimeSeries/TimeSeries_Process"
      Path_Gis             = "InputGis"
      Path_Julia           = "OutputJulia"
      Path_Lookuptable     = "LookupTables"
      Path_NetCDF          = "OutputNetCDF"
      Path_Python          = "OutputPython"
      Path_TimeSeriesWflow = "InputTimeSeries/TimeSeries_Wflow"
      Path_Wflow           = "OutputWflow"

   # ======= INPUT =======
      # === Input  Forcing ===
         Filename_Input_Forcing = "forcing." * "$🎏_CatchmentName" * ".csv"

      # === Shape file ===
         Filename_Gauge_Shp         = "Gauge_Hydro.shp"
         Filename_Landuse_Shp       = "Landuse.shp"
         Filename_Mask_Shp          = "Crop.shp"
         Filename_River_Shp         = "Rivers.shp"
         Filename_Roads_Shp         = "Roads.shp"
         Filename_SoilMap_Shp       = "SoilMap.shp"
         Filename_VegetationMap_Shp = "VegetationMap.shp"
         Filename_VegetationMap_Shp = "NATIONAL_LAND_COVER_MAP.gdb"

         Filename_Input_SoilMap    = "SoilMap.tiff" # Obsolete

      # === Input from Python ===
         Filename_Python_CatchmentSubcatchment = "CatchmentSubcatchment.tiff"
         Filename_Python_Dem2Rivers            = "Dem2Rivers.tiff"
         Filename_Python_DemCorrected          = "DemCorrected.tiff"
         Filename_Python_Ldd                   = "Ldd.tiff"
         Filename_Python_RiverLength           = "RiverLength.tiff"
         Filename_Python_Slope                 = "Slope.tiff"

   # ======= OUTPUT =======
      # === Output Julia ===
         Filename_Coastline          = "Coastline.tiff"
         Filename_Julia_Dem          = "Ireland_DEM_Croped.tiff"
         Filename_Julia_DemCorrected = "DEM_Corrected.tiff"
         Filename_Julia_Gauge        = "Gauge.tiff"
         Filename_Julia_Pits         = "Pits.tiff"

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

      # === Output netCDF ===
         Filename_NetCDF_Instates = "staticmaps-" * 🎏_CatchmentName * ".nc"
         Filename_NetCDF_Forcing  = "forcing-" * 🎏_CatchmentName # on purpose remove the .nc

   # === Lookup tables ===
      Filename_Lookuptable_Hydro      = "LookupTable_Hydro.csv"
      Filename_Lookuptable_Vegetation = "LookupTable_Veg_NLCM.csv"

   #  ======= PARAMETERS =======
      # Coordinate reference system
         Param_Crs             = 29902    # [-] This is the default projection TM65 / Irish Grid


   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Ballycanew
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   if 🎏_CatchmentName == "Ballycanew"
      # Flags: processing inputs
         # Dem derived from Mosaic
         🎏_Mosaic                = false
         🎏_DemFromMosaic         = false # Gis stored
         🎏_MaskFromDem           = false
         🎏_Coastline             = false

         @assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDem          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_VegetationMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dem        = "Ballycanew_DTM_5m.tif"

         # Resampling method of DEM in 2 steps:
            Param_ResampleMethod₁ = :min
            Param_ΔX₁             = 5 # [m] Gridded spatial resolution
            Param_ResampleMethod₂ = :cubicspline
            Param_ΔX₂             = 5 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

         # RIVER PARAMETERS
            Param_RiverWidth = 5.0::Float64 # [m]
            Param_RiverDepth = 5.0::Float64;  # must be an integer [m]

         # GAUGE COORDINATES=
            Param_GaugeCoordinate = [314165.67568,153248.90881]

         # SOILS PARAMETERS
            Layer_Soil = :Drainage_C
            soil_layer__thickness = [100, 300, 800]

         # VEGETATION MAPS
            Layer_Vegetation = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Castledockerell
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Castledockerell"
      # Flags: processing inputs
         # Dem derived from Mosaic
         🎏_Mosaic                = false
         🎏_DemFromMosaic         = false # Gis stored
         🎏_MaskFromDem           = false
         🎏_Coastline             = false

         @assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDem          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_VegetationMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = false

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dem        = "Castledockerell_DTM_5m.tif"

         # Resampling method of DEM in 2 steps:
            Param_ResampleMethod₁ = :min
            Param_ΔX₁             = 5 # [m] Gridded spatial resolution
            Param_ResampleMethod₂ = :cubicspline
            Param_ΔX₂             = 5 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

         # RIVER PARAMETERS
            Param_RiverWidth = 5.0::Float64 # [m]
            Param_RiverDepth = 5.0::Float64;  # must be an integer [m]

         # GAUGE COORDINATES=
            Param_GaugeCoordinate = [296106.903 , 147242.896]

         # SOILS PARAMETERS
            Layer_Soil = :Drainage_C
            soil_layer__thickness = [100, 300, 800]

         # VEGETATION MAPS
            Layer_Vegetation = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Corduff
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Corduff"
      # Flags: processing inputs
         # Dem derived from Mosaic
         🎏_Mosaic                = false
         🎏_DemFromMosaic         = false # Gis stored
         🎏_MaskFromDem           = false
         🎏_Coastline             = false

         @assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDem          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_VegetationMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dem        = "Corduff_DTM_5m.tif"

         # Resampling method of DEM in 2 steps:
            Param_ResampleMethod₁ = :min
            Param_ΔX₁             = 5 # [m] Gridded spatial resolution
            Param_ResampleMethod₂ = :cubicspline
            Param_ΔX₂             = 5 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

         # RIVER PARAMETERS
            Param_RiverWidth = 5.0::Float64 # [m]
            Param_RiverDepth = 5.0::Float64;  # must be an integer [m]

         # GAUGE COORDINATES=
            Param_GaugeCoordinate = [275322.532,309582.511]

         # SOILS PARAMETERS
            Layer_Soil = :Drainage_C
            soil_layer__thickness = [100, 300, 800]

         # VEGETATION MAPS
            Layer_Vegetation = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Cregduff
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Cregduff"
            # Flags: processing inputs
         # Dem derived from Mosaic
         🎏_Mosaic                = false
         🎏_DemFromMosaic         = false # Gis stored
         🎏_MaskFromDem           = false
         🎏_Coastline             = false

         @assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDem          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_VegetationMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dem        = "Cregduff_DTM_5m.tif"

         # Resampling method of DEM in 2 steps:
            Param_ResampleMethod₁ = :min
            Param_ΔX₁             = 5 # [m] Gridded spatial resolution
            Param_ResampleMethod₂ = :cubicspline
            Param_ΔX₂             = 5 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

         # RIVER PARAMETERS
            Param_RiverWidth = 5.0::Float64 # [m]
            Param_RiverDepth = 5.0::Float64;  # must be an integer [m]

         # GAUGE COORDINATES=
            Param_GaugeCoordinate = [122323.408,263251.260]

         # SOILS PARAMETERS
            Layer_Soil = :Drainage_C
            soil_layer__thickness = [100, 300, 800]

         # VEGETATION MAPS
            Layer_Vegetation = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Dunleer
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Dunleer"
               # Flags: processing inputs
         # Dem derived from Mosaic
         🎏_Mosaic                = false
         🎏_DemFromMosaic         = false # Gis stored
         🎏_MaskFromDem           = false
         🎏_Coastline             = false

         @assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDem          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_VegetationMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dem        = "Dunleer_DTM_5m.tif"

         # Resampling method of DEM in 2 steps:
            Param_ResampleMethod₁ = :min
            Param_ΔX₁             = 5 # [m] Gridded spatial resolution
            Param_ResampleMethod₂ = :cubicspline
            Param_ΔX₂             = 5 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

         # RIVER PARAMETERS
            Param_RiverWidth = 5.0::Float64 # [m]
            Param_RiverDepth = 5.0::Float64;  # must be an integer [m]

         # GAUGE COORDINATES=
            Param_GaugeCoordinate = [304378.946,288471.125]

         # SOILS PARAMETERS
            Layer_Soil = :Drainage_C
            soil_layer__thickness = [100, 300, 800]

         # VEGETATION MAPS
            Layer_Vegetation = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
#                 Timoleague
# ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
elseif 🎏_CatchmentName == "Timoleague"
   # Flags: processing inputs
      # Dem derived from Mosaic
         🎏_Mosaic                = false
         🎏_DemFromMosaic         = true # Gis stored
         🎏_MaskFromDem           = true
         🎏_Coastline             = false

         @assert(!(🎏_Mosaic && 🎏_DemFromMosaic))

      # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDem          = true

      # Flags: outputs of interest
         🎏_ImpermeableMap        = false

      # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_VegetationMap         = false

      # Flags: NetCDF
         🎏_NetCDF                = false
         🎏_Forcing_2_NetCDF      = false

   # ======= PATHS =======
      Path_Root_Mosaic = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

      # === Raster input file ===
         Filename_Input_Dem = "Ireland_FABDEM.tif"

      # Resampling method of DEM in 2 steps:
         Param_ResampleMethod₁ = :min
         Param_ΔX₁             = 20 # [m] Gridded spatial resolution
         Param_ResampleMethod₂ = :cubicspline
         Param_ΔX₂             = 20 # [m] Gridded spatial resolution should be a multiple of Param_ΔX₁

      # RIVER PARAMETERS
         Param_RiverWidth = 5.0::Float64 # [m]
         Param_RiverDepth = 10.0::Float64;  # must be an integer [m]

      # GAUGE COORDINATES
         Param_GaugeCoordinate =[146702.538,42182.544]

      # SOILS PARAMETERS
         Layer_Soil = :DRAINAGE
         soil_layer__thickness = [100, 300, 800]

      # VEGETATION MAPS
         Layer_Vegetation = :LEVEL_2_ID
   end
