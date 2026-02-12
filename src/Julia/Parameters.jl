
# =========================================
# 					PARAMETERS
# =========================================

   🎏_CatchmentName = "Timoleague" # <"Timoleague">; <"Ballycanew">; <"Castledockerell">; <"Corduff">; <"Dunleer">; <"Cregduff">

   # DATES
   Base.@kwdef mutable struct DATES
      Start_Year  = 2020 :: Int64
      Start_Month = 3 :: Int64
      Start_Day   = 6 :: Int64
      Start_Hour  = 0 :: Int64

      End_Year    = 2024:: Int64
      End_Month   = 12 :: Int64
      End_Day     = 31 :: Int64
      End_Hour    = 23 :: Int64
   end # struct METADATA

   Forcing_ΔT = "Daily" # <"Hourly"> or <"Daily">

   # Flags: plots
      🎏_Plots                 = true
      🎏_Plot_TimeSeries       = false
      🎏_Plot_FlowAccumulation = true
      🎏_Plot_NetCDF           = true

   # ======= PATHS =======
      Path_Root_Data   = "D:\\JOE\\MAIN\\MODELS\\WFLOW\\DATA"
      Path_Root        = joinpath(Path_Root_Data, "$🎏_CatchmentName")
      Path_Root_NetCDF = joinpath(raw"D:\JOE\MAIN\MODELS\WFLOW\Wflow.jl\Wflow\Data\input", "$🎏_CatchmentName")
      Path_Root_LookupTable = raw"DATA\Lookuptable"

      Path_Forcing₀         = "InputTimeSeries\\TimeSeries_Process"
      Path_Forcing                  = joinpath(Path_Forcing₀, Forcing_ΔT)
      Path_Gis              = "InputGis"
      Path_Julia            = "OutputJulia"
      Path_Lookuptable      = "LookupTable"
      Path_NetCDF           = "OutputNetCDF"
      Path_ObservationPoint = "InputObservationPoint"
      Path_Python           = "OutputPython"
      Path_River            = "RIVERS\\SHAPEFILE"
      Path_TimeSeriesWflow  = "InputTimeSeries/TimeSeries_Wflow"
      Path_Wflow            = "OutputWflow"

   # ======= INPUT =======
      # === Input  Forcing ===
         Filename_Input_Forcing = "Forcing_" * Forcing_ΔT * "_" * "$🎏_CatchmentName" * ".csv"

      # === Shape file ===
         Filename_Gauge_Shp                          = "Gauge_Hydro.shp"
         Filename_Input_SoilMap                      = "SoilMap.tiff" # Obsolete
         Filename_LandUseMap_Shp                     = "NationalLandCoverMap.gdb"
         Filename_Landuse_Shp                        = "Landuse.shp"
         Filename_Mask_Shp                           = "Crop.shp"
         Filename_Output_ObservationEcologyPoint_Shp = "ObservationEcologyPoint.shp"
         Filename_River_Shp                          = "RiversIreland.shp"
         Filename_Roads_Shp                          = "Roads.shp"
         Filename_SoilMap_Shp                        = "Soils//SoilMap.shp"

      # === Input from Python ===
         Filename_Python_CatchmentSubcatchment = "CatchmentSubcatchment.tiff"
         Filename_Python_Dtm2Rivers            = "Dtm2Rivers.tiff"
         Filename_Python_DtmCorrected          = "DtmCorrected.tiff"
         Filename_Python_Ldd                   = "Ldd.tiff"
         Filename_Python_RiverLength           = "RiverLength.tiff"
         Filename_Python_RiverOrder            = "RiverOrder.tiff"
         Filename_Python_Slope                 = "Slope.tiff"

      # === Input csv ===
         Filename_Csv_ObservationPoint = "ObservationPoint.csv"
         Filename_Csv_GaugePoint       = "Gauges_grdc.csv"

      # === Lookup tables ===
         Filename_Lookuptable_Hydro   = "LookupTable_Hydro.csv"
         Filename_Lookuptable_LandUse = "LookupTable_Veg_NLCM.csv"
         Filename_Lookuptable_River   = "LookupTable_River.csv"

   # ======= OUTPUT =======
      # === Output Julia ===
         Filename_Coastline          = "Coastline.tiff"
         Filename_Julia_Dtm          = "Ireland_DEM_Croped.tiff"
         Filename_Julia_DtmCorrected = "DEM_Corrected.tiff"
         Filename_Julia_Gauge        = "Gauge.tiff"
         Filename_Julia_Pits         = "Pits.tiff"
         Filename_Julia_RiverOrder   = "RiverOrder.tiff"

      # === Output wflow ===
         Filename_Dtm                     = "Dtm.tiff"
         Filename_Gauge                   = "Gauges_grdc.tiff"
         Filename_Ldd                     = "Ldd.tiff"
         Filename_ObservationEcologyPoint = "ObservationEcologyPoint.tiff"
         Filename_RiverLength             = "RiverLength.tiff"
         Filename_RiverSlope              = "RiverSlope.tiff"
         Filename_Rivers                  = "River.tiff"
         Filename_Slope                   = "Slope.tiff"
         Filename_Subcatchment            = "Subcatchment.tiff"

      # === Output netCDF ===
         Filename_NetCDF_Forcing  = "forcing-" * 🎏_CatchmentName # on purpose remove the .nc
         Filename_NetCDF_Instates = "staticmaps-" * 🎏_CatchmentName * ".nc"


   #  ======= PARAMETERS =======
      # Coordinate reference system
         Param_Crs             = 29902    # [-] This is the default projection TM65 / Irish Grid

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Ballycanew
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   if 🎏_CatchmentName == "Ballycanew"
      # Flags: processing inputs
         # Dtm derived from Mosaic
         🎏_Mosaic                = false
         🎏_DtmFromMosaic         = false # Gis stored
         🎏_MaskFromDtm           = false

         @assert(!(🎏_Mosaic && 🎏_DtmFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDtm          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_LandUseMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dtm        = "Ballycanew_DTM_5m.tif"

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

         # LANDUSE MAPS
            Layer_LandUse = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Castledockerell
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Castledockerell"
      # Flags: processing inputs
         # Dtm derived from Mosaic
         🎏_Mosaic                = false
         🎏_DtmFromMosaic         = false # Gis stored
         🎏_MaskFromDtm           = false

         @assert(!(🎏_Mosaic && 🎏_DtmFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDtm          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_LandUseMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = false

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dtm        = "Castledockerell_DTM_5m.tif"

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

         # LANDUSE MAPS
            Layer_LandUse = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Corduff
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Corduff"
      # Flags: processing inputs
         # Dtm derived from Mosaic
         🎏_Mosaic                = false
         🎏_DtmFromMosaic         = false # Gis stored
         🎏_MaskFromDtm           = false

         @assert(!(🎏_Mosaic && 🎏_DtmFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDtm          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_LandUseMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dtm        = "Corduff_DTM_5m.tif"

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

         # LANDUSE MAPS
            Layer_LandUse = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Cregduff
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Cregduff"
            # Flags: processing inputs
         # Dtm derived from Mosaic
         🎏_Mosaic                = false
         🎏_DtmFromMosaic         = false # Gis stored
         🎏_MaskFromDtm           = false

         @assert(!(🎏_Mosaic && 🎏_DtmFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDtm          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_LandUseMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dtm        = "Cregduff_DTM_5m.tif"

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

         # LANDUSE MAPS
            Layer_LandUse = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   #                 Dunleer
   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
   elseif 🎏_CatchmentName == "Dunleer"
               # Flags: processing inputs
         # Dtm derived from Mosaic
         🎏_Mosaic                = false
         🎏_DtmFromMosaic         = false # Gis stored
         🎏_MaskFromDtm           = false

         @assert(!(🎏_Mosaic && 🎏_DtmFromMosaic))

         # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDtm          = true

         # Flags: outputs of interest
         🎏_ImpermeableMap        = false

         # Flags: LookupTables
         🎏_SoilMap               = true
         🎏_LandUseMap         = true

         # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # ======= PATHS =======
         Path_Root_Mosaic      = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

         # === Raster input file ===
            Filename_Input_Dtm        = "Dunleer_DTM_5m.tif"

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

         # LANDUSE MAPS
            Layer_LandUse = :CROP_00

   # ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
#                 Timoleague
# ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
elseif 🎏_CatchmentName == "Timoleague"
   # Flags: processing inputs
      # Dtm derived from Mosaic
         🎏_Mosaic                = false
         🎏_DtmFromMosaic         = false # Gis stored
         🎏_MaskFromDtm           = true

         @assert(!(🎏_Mosaic && 🎏_DtmFromMosaic))

      # Flags: Options
         🎏_Fix_Cyclic            = false # obsolete
         🎏_RiverFromDtm          = true

      # Flags: outputs of interest
         🎏_ImpermeableMap        = false

      # Flags: LookupTables
         🎏_RiverMap   = true
         🎏_SoilMap    = true
         🎏_LandUseMap = true

      # Flags: NetCDF
         🎏_NetCDF                = true
         🎏_Forcing_2_NetCDF      = true

      # Flags: Potential Evapotranspiration

   # ======= PATHS =======
      Path_Root_Mosaic = raw"C:\OSGeo4W\Gis\DEM\FABDEM\IRELAND_MOSAIC"

      # === Raster input file ===
         Filename_Input_Dtm = "Timoleague_DTM_Intermap_EPSG29902.tif"

      # Resampling method of DEM in 2 steps:
         Param_ResampleMethod₁ = :average
         Param_ΔX₁      = 4 # [m]  resampling, Gridded spatial resolution
         Param_ResampleMethod₂ = :cubicspline
         Param_ΔX₂      = -1 # [m]  if >0 then resampling, Gridded spatial resolution should be a multiple of Param_ΔX₁

      # RIVER PARAMETERS
         Param_RiverWidth   = 1.7::Float64 # [m]
         Param_RiverDepth   = 0.17::Float64;  # must be an integer [m]
         Param_RiverManning = 0.033::Float64

      # GAUGE COORDINATES
         # Param_GaugeCoordinate =[146702.538,42182.544]
         Param_GaugeCoordinate = [146697.99,42140.78]

      # SOILS PARAMETERS
         Layer_Soil = :DRAINAGEid
         soil_layer__thickness = [100, 300, 800]

      # LANDUSE MAPS
         Layer_LandUse = :LEVEL_2_ID
   end
