# =============================================================
#		module: copernicus
# =============================================================
module copernicus

using GeoDataFrames, Dates, SentinelExplorer, CSV, Rasters
using ZipFile

include("Parameters.jl")
include("GeoPlot.jl")
include("PlotParameter.jl")
include("GeoRaster.jl")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : SENTINEL_DATA
# ~~~~~~~~~~~`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function SENTINEL_DATA(; 🎏_DownloadTwiceMonth=false, Authenticate_Password="Joseph.pollacco1", Authenticate_Username="joseph.pollacco@teagasc.ie", CloudMax=50, Coordinate_LowerRight, Coordinate_UpperLeft, CopernicusDate_End, CopernicusDate_Start, Path_SentinelDownload₁, Path_SentinelMetadata₁, Product="L2A", Satelite="SENTINEL-2", Filename_SentinelMetadata, FirstSecond=1)

   CopernicusDate_StartDate = Dates.Date(CopernicusDate_Start[1], CopernicusDate_Start[2], CopernicusDate_Start[3])
   CopernicusDate_EndDate = Dates.Date(CopernicusDate_End[1], CopernicusDate_End[2], CopernicusDate_End[3])

   # Preparing metdata
   Date_Scene = []
   Name_Scene = []
   CloudCover_Scene = []
   🎏_Sucessfull = []

   # authenticate
   SentinelExplorer.authenticate(Authenticate_Username, Authenticate_Password)

   # Area of data
   Box = SentinelExplorer.BoundingBox(Coordinate_UpperLeft, Coordinate_LowerRight)
   # Box = GeoDataFrames.read(Path_SentinelBoundary₁).geometry |> first

   # Dates for search
   if 🎏_DownloadTwiceMonth
      Nsplit = 2
   else
      Nsplit = 1
   end

   # DATES SEARCHING FOR THE BEST CLOUDLESS DATA
   for iiYear = CopernicusDate_Start[1]:CopernicusDate_End[1]
      for iiMonth = 1:12
         for iSplit = 1:Nsplit

            if 🎏_DownloadTwiceMonth
               DaysMonthHalf = floor(Dates.daysinmonth(Dates.Date(iiYear, iiMonth)) / 2)

               if iSplit == 1
                  Day_Start = 1
                  Day_End = DaysMonthHalf
               else
                  Day_Start = DaysMonthHalf + 1
                  Day_End = Dates.daysinmonth(Dates.Date(iiYear, iiMonth))
               end
            else
               Day_Start = 1
               Day_End = Dates.daysinmonth(Dates.Date(iiYear, iiMonth))
            end

            DateSearch_Start = Dates.DateTime(iiYear, iiMonth, Day_Start)
            DateSearch_End = Dates.DateTime(iiYear, iiMonth, Day_End)

            DateSearch = (DateSearch_Start, DateSearch_End)

            # If dates are good
            if CopernicusDate_StartDate ≤ DateSearch_Start ≤ DateSearch_End ≤ CopernicusDate_EndDate

               🎏_Sucessfull, CloudCover_Scene, Date_Scene, Name_Scene = copernicus.SENTINEL_SEARCH(; 🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, FirstSecond, Name_Scene, Path_SentinelDownload₁, Product, Satelite)

               # Write to CSV
               Path_Sentinel₁ = joinpath(Path_SentinelMetadata₁, Filename_SentinelMetadata)
               Header = ["Date", "Cloud", "Name", "🎏_Sucessfull"]
               CSV.write(Path_Sentinel₁, Tables.table([Date_Scene CloudCover_Scene Name_Scene 🎏_Sucessfull]), writeheader=true, header=Header, bom=true)
            end
         end # for iSplit = 1:2
      end # for iiMonth=1:12
   end # for iiYear = CopernicusDate_Start[1]::CopernicusDate_End[1]

   printstyled(" ======  FINISHED ==== \n"; color=:red)

   return nothing
end  # function: SENTINEL_DATA
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : SENTINEL_SEARCH
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function SENTINEL_SEARCH(; 🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, FirstSecond, Name_Scene, Path_SentinelDownload₁, Product, Satelite)

   🎏_DataAvailable = true
   SearchMap = []
   # try
      SearchMap = SentinelExplorer.search(Satelite, dates=DateSearch, geom=Box, clouds=CloudMax, product=Product)
   # catch
   #    🎏_DataAvailable = false
   #    printstyled("   ==== DATA NOT AVAILABLE for $DateSearch ==== \n"; color=:red)
   # end

   Scene = []
   if 🎏_DataAvailable
      # Scene = sort(SearchMap, :CloudCover) |> first
      Scene₀ = sort(SearchMap, :CloudCover)
      Nsize = size(Scene₀)[1]
      Scene = Scene₀[min(FirstSecond, Nsize), :]

      # METADATA
      # Date:
      Year_Scene = Scene.AcquisitionDate[1:4]
      Year_Scene = parse(Int64, Year_Scene)

      Month_Scene = Scene.AcquisitionDate[6:7]
      Month_Scene = parse(Int64, Month_Scene)

      Day_Scene = Scene.AcquisitionDate[9:10]
      Day_Scene = parse(Int64, Day_Scene)

      Hour_Scene = Scene.AcquisitionDate[12:13]
      Hour_Scene = parse(Int64, Hour_Scene)

      Date_Scene₀ = Dates.DateTime(Year_Scene, Month_Scene, Day_Scene, Hour_Scene)

      # DOWNLOAD FILE IF DOES NOT EXIST
      # Path to save removing the ".SAFE"
      PathFile = joinpath(Path_SentinelDownload₁, Scene.Name)
      iFind = findfirst(".SAFE", PathFile)
      PathFile = PathFile[1:(iFind[1]-1)]
      PathFile = PathFile * ".zip"

      if !(isfile(PathFile))
         try
            printstyled(" ======  DOWNLOADING SENTINEL MAP: $(Date_Scene₀) ==== \n"; color=:green)
            SentinelExplorer.download_scene(Scene.Name, Path_SentinelDownload₁; unzip=false, log_progress=false, access_token=nothing)

            # METADATA
            Date_Scene = push!(Date_Scene, Date_Scene₀)
            Name_Scene = push!(Name_Scene, Scene.Name)
            CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)
         catch
            # Try again
            try
               SentinelExplorer.download_scene(Scene.Name, Path_SentinelDownload₁; unzip=false, log_progress=false, access_token=nothing)
               printstyled(" ======  2nd ATTEPT SUCESSFULL ==== \n"; color=:green)

               # METADATA
               Date_Scene = push!(Date_Scene, Date_Scene₀)
               Name_Scene = push!(Name_Scene, Scene.Name)
               CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)
            catch
               printstyled(" ======  NOT SUCSSFULL TO DOWNLOAD MAP ==== \n"; color=:red)
               Date_Scene = push!(Date_Scene, DateSearch[1])
               Name_Scene = push!(Name_Scene, Scene.Name)
               CloudCover_Scene = append!(CloudCover_Scene, -1111)
            end
         end
      else
         printstyled("      ==========  FILE ALREADY EXIST: $(PathFile) \n"; color=:yellow)

         # METADATA
         Date_Scene = push!(Date_Scene, Date_Scene₀)
         Name_Scene = push!(Name_Scene, Scene.Name)
         CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)
      end

      # No data available
   else
      Date_Scene = push!(Date_Scene, DateSearch[1])
      Name_Scene = push!(Name_Scene, Scene.Name)
      CloudCover_Scene = append!(CloudCover_Scene, -9999)
   end # if 🎏_DataAvailable

   # Deriving the 🎏_Sucessfull
   if CloudCover_Scene[end] ≥ 0
      🎏_Sucessfull = append!(🎏_Sucessfull, 1)
   else
      🎏_Sucessfull = append!(🎏_Sucessfull, 0)
   end

   return 🎏_Sucessfull, CloudCover_Scene, Date_Scene, Name_Scene
end  # function: SENTINEL_SEARCH
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : RUN_SNAP
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
""" SNAP_LAI_FAPAR_NDVI_FVC

   OUTPUT:
      Derives batch processing from sentinel data by using SNAP modules:
      * Mask to the area of interest
      * Lai,
      * FAPAR,
      * NDVI,
      * FVC

   INPUT:
      * PathInput: path of all the .zip file of the .SAFE sentinel data
      * Path_SentinelBiophysical₁: path of the output of Lai, FAPAR, NDVI, FVC
      * Path_CatchmentBoundary: path of the shape file were the delimitation of the catchment
      * PathXml: path of the .xml file derived from SNAP software
      * PathProperties: this is a temporary path
"""
function SNAP_BATCH_LAI_FAPAR_NDVI_FVC(; Path_SentinelDownload₁, Path_SentinelBiophysical₁, Path_CatchmentBoundary₁, Path_SentinelXml₁, PathProperties, Path_SentinelMetadata₁, Name_CatchmentBoundary, NameOutput_Lai="LAI", NameOutput_Fapar="FAPAR", NameOutput_Ndvi="NDVI", NameOutput_Fvc="FVC")

   MetaData = CSV.read(Path_SentinelMetadata₁, DataFrame; header=true)
   🎏_Sucessfull = convert(Vector{Bool}, Tables.getcolumn(MetaData, :🎏_Sucessfull))
   NameSentinel = convert(Vector{String}, Tables.getcolumn(MetaData, :Name))
   DateSentinel = convert(Vector{DateTime}, Tables.getcolumn(MetaData, :Date))

   # For every scene
   for (i, iiSentinelData) = enumerate(NameSentinel)
      if 🎏_Sucessfull[i]

         # Dates of output
         YearSentinel = Dates.year(DateSentinel[i])
         MonthSentinel = Dates.month(DateSentinel[i])
         DaySentinel = Dates.day(DateSentinel[i])
         DateFormat = YearSentinel * 10000 + MonthSentinel * 100 + DaySentinel

         # Paths of output
         NameOutput_Lai₁ = string(DateFormat) * "_" * NameOutput_Lai * ".tif"
         PathOutput_Lai₁ = Path_SentinelBiophysical₁ * "/" * "LAI" * "/" * NameOutput_Lai₁

         NameOutput_Fapar₁ = string(DateFormat) * "_" * NameOutput_Fapar * ".tif"
         PathOutput_Fapar₁ = Path_SentinelBiophysical₁ * "/" * "FAPAR" * "/" * NameOutput_Fapar₁

         NameOutput_Ndvi₁ = string(DateFormat) * "_" * NameOutput_Ndvi * ".tif"
         PathOutput_Ndvi₁ = Path_SentinelBiophysical₁ * "/" * "NDVI" * "/" * NameOutput_Ndvi₁

         NameOutput_Fvc₁ = string(DateFormat) * "_" * NameOutput_Fvc * ".tif"
         PathOutput_Fvc₁ = Path_SentinelBiophysical₁ * "/" * "FVC" * "/" * NameOutput_Fvc₁

         # Naming of output in javascript format
         NameSentinel₁ = NameSentinel[i]
         iFind = findfirst(".SAFE", NameSentinel₁)
         NameSentinel₁ = NameSentinel₁[1:(iFind[1]-1)]
         NameSentinel₁ = NameSentinel₁ * ".zip"
         println(NameSentinel₁)

         PathInput = Path_SentinelDownload₁ * "/" * NameSentinel₁
         @assert isfile(PathInput)

         # Saving the paths into .properties so gpt software can pick it up
         open(PathProperties, "w") do io
            println(io, "PathInput        = $PathInput")
            println(io, "PathOutput_Lai   = $PathOutput_Lai₁")
            println(io, "PathOutput_Ndvi  = $PathOutput_Ndvi₁")
            println(io, "PathOutput_Fvc   = $PathOutput_Fvc₁")
            println(io, "PathOutput_Fapar = $PathOutput_Fapar₁")
            println(io, "PathBoundary     = $Path_CatchmentBoundary₁")
            println(io, "NameBoundary     = $Name_CatchmentBoundary")
         end

         # Run the command line
         if !(isfile(PathOutput_Lai₁))
            try
               RunSnap = `gpt $Path_SentinelXml₁ -e -p $PathProperties`
               run(RunSnap)
               printstyled("	======================= SUCESSFULL= $iiSentinelData =================== \n", color=:green)
            catch
               printstyled("	======================= NOT SUCESSFULL= $iiSentinelData =================== \n", color=:red)
            end
         else
            printstyled("      ==========  FILE ALREADY EXIST: $(PathOutput_Lai₁) \n"; color=:yellow)
         end

      end # if 🎏_Sucessfull[i]
   end # for iiSentinelData ∈ AllSentinelData
end # function RUN_SNAP()
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : REMOVING_CLOUDS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function WFLOW_REMOVING_CLOUDS(; ΔLai_CloudTreshold, Path_SentinelMetadata₁, Dtm, Latitude, Longitude, Metadatas, NamePath_Fapar="FAPAR", NamePath_Fvc="FVC", NamePath_Lai="LAI", NamePath_Ndvi="NDVI", Path_SentinelBiophysical₁, Path_SentinelBiophysicalRemoveCloud, Subcatchment, ΔMaxIncrease=0.2)

   MetaData = CSV.read(Path_SentinelMetadata₁, DataFrame; header=true)
   🎏_Sucessfull = convert(Vector{Bool}, Tables.getcolumn(MetaData, :🎏_Sucessfull))
   DateSentinel = convert(Vector{DateTime}, Tables.getcolumn(MetaData, :Date))
   CloudCover = convert(Vector{Float64}, Tables.getcolumn(MetaData, :Cloud))
   # Selecting data
   N = sum(🎏_Sucessfull)
   DateSentinel = DateSentinel[🎏_Sucessfull]
   CloudCover = CloudCover[🎏_Sucessfull]

   # Putting in memory
   Path_Lai = fill("", N)
   Path_Ndvi = fill("", N)
   Path_Fvc = fill("", N)
   Path_Fapar = fill("", N)
   NameOutput_Lai₁ = fill("", N)
   NameOutput_Ndvi₁ = fill("", N)
   NameOutput_Fvc₁ = fill("", N)
   NameOutput_Fapar₁ = fill("", N)
   NameOutput_Plot₁ = fill("", N)
   YearSentinel = zeros(Int64, N)
   MonthSentinel = zeros(Int64, N)
   DaySentinel = zeros(Int64, N)

   # Deriving the paths
   for i = 1:N
      # Dates of output
      YearSentinel[i] = Dates.year(DateSentinel[i])
      MonthSentinel[i] = Dates.month(DateSentinel[i])
      DaySentinel[i] = Dates.day(DateSentinel[i])
      DateFormat = YearSentinel[i] * 10000 + MonthSentinel[i] * 100 + DaySentinel[i]

      # Paths of output
      NameOutput_Lai₁[i] = string(DateFormat) * "_" * NamePath_Lai * ".tif"
      Path_Lai[i] = joinpath(Path_SentinelBiophysical₁, NamePath_Lai, NameOutput_Lai₁[i])
      @assert isfile(Path_Lai[i])

      NameOutput_Ndvi₁[i] = string(DateFormat) * "_" * NamePath_Ndvi * ".tif"
      Path_Ndvi[i] = joinpath(Path_SentinelBiophysical₁, NamePath_Ndvi, NameOutput_Ndvi₁[i])
      @assert isfile(Path_Ndvi[i])

      NameOutput_Fvc₁[i] = string(DateFormat) * "_" * NamePath_Fvc * ".tif"
      Path_Fvc[i] = joinpath(Path_SentinelBiophysical₁, NamePath_Fvc, NameOutput_Fvc₁[i])
      @assert isfile(Path_Fvc[i])

      NameOutput_Fapar₁[i] = string(DateFormat) * "_" * NamePath_Fapar * ".tif"
      Path_Fapar[i] = joinpath(Path_SentinelBiophysical₁, NamePath_Fapar, NameOutput_Fapar₁[i])
      @assert isfile(Path_Fapar[i])

      NameOutput_Plot₁[i] = "PLOT_" * string(DateFormat) * ".pdf"
   end # for i = 1:N

   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #		FUNCTION : CORRECT_CLOUDS
   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   """
   There is a better corelation with Clouds and Fapar
   """
   # Initializing
   Lai_1, LaiCloudTrue_1 = copernicus.DISCRZETZATION(; Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Lai[1], Subcatchment)
   Fapar_1, ~            = copernicus.DISCRZETZATION(;Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Fapar[1], Subcatchment)
   Ndvi_1, ~             = copernicus.DISCRZETZATION(;Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Ndvi[1], Subcatchment)
   Fvc_1, ~              = copernicus.DISCRZETZATION(;Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Fvc[1], Subcatchment)

   Lai_2, LaiCloudTrue_2 = copernicus.DISCRZETZATION(; Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Lai[2], Subcatchment)
   Fapar_2, ~            = copernicus.DISCRZETZATION(;Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Fapar[2], Subcatchment)
   Ndvi_2, ~             = copernicus.DISCRZETZATION(;Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Ndvi[2], Subcatchment)
   Fvc_2, ~              = copernicus.DISCRZETZATION(;Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Fvc[2], Subcatchment)

   # Lai_Uncorrected, ~ = copernicus.DISCRZETZATION(;Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Lai[2], Subcatchment)

   # For every satelite image
   for i = 2:2
   # for i = 2:N-1
      Lai_3, LaiCloudTrue_3 = copernicus.DISCRZETZATION(; Dtm, iCount=i + 1, Latitude, Longitude, Metadatas, Path=Path_Lai[i+1], Subcatchment)
      Fapar_3, ~            = copernicus.DISCRZETZATION(;Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Fapar[i+1], Subcatchment)
      Ndvi_3, ~             = copernicus.DISCRZETZATION(;Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Ndvi[i+1], Subcatchment)
      Fvc_3, ~              = copernicus.DISCRZETZATION(;Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Fvc[i+1], Subcatchment)

      Lai_Raw   = deepcopy(Lai_2)
      Fapar_Raw = deepcopy(Fapar_2)
      Ndvi_Raw  = deepcopy(Ndvi_2)
      Fvc_Raw   = deepcopy(Fvc_2)

      # Days between different events
      ΔDays_21 = Dates.days(DateSentinel[i] - DateSentinel[i-1])
      ΔDays_32 = Dates.days(DateSentinel[i+1] - DateSentinel[i])

      # For every image
      for iX = 1:Metadatas.N_Width
         for iY = 1:Metadatas.N_Height
            # Variation of Lai
            ΔLai_21 = abs(Lai_2[iX, iY] - Lai_1[iX, iY])
            ΔLai_31 = abs(Lai_3[iX, iY] - Lai_1[iX, iY])

            # The LaiCloudTrue does not always pick up clouds but also uncertainty, therefore we determine if there is issue if there is a significan change in ΔLai
            if (LaiCloudTrue_2[iX, iY] == 1) && (ΔLai_21 > ΔLai_CloudTreshold)
               # Assume that at [iX,iY] Lai_3 is free cloud
               if (LaiCloudTrue_3[iX, iY] ≠ 1) || (ΔLai_31 ≤ ΔLai_CloudTreshold)

                  Lai_2[iX, iY] = (ΔDays_21 * Lai_1[iX, iY] + ΔDays_32 * Lai_3[iX, iY]) / (ΔDays_21 + ΔDays_32)
                  Fapar_2[iX,iY] = (ΔDays_21 * Fapar_1[iX,iY] + ΔDays_32 * Fapar_3[iX,iY]) / (ΔDays_21 + ΔDays_32)
                  Ndvi_2[iX,iY]  = (ΔDays_21 * Ndvi_1[iX,iY] + ΔDays_32 * Ndvi_3[iX,iY]) / (ΔDays_21 + ΔDays_32)
                  Fvc_2[iX,iY]   = (ΔDays_21 * Fvc_1[iX,iY] + ΔDays_32 * Fvc_3[iX,iY]) / (ΔDays_21 + ΔDays_32)

                  LaiCloudTrue_3[iX, iY] = NaN
               else
                  Lai_2[iX, iY] = Lai_1[iX, iY]
                  Fapar_2[iX,iY] = Fapar_1[iX,iY]
                  Ndvi_2[iX,iY]  = Ndvi_1[iX,iY]
                  Fvc_2[iX,iY]   = Fvc_1[iX,iY]
               end
            else
               LaiCloudTrue_2[iX, iY] = NaN
            end # LaiCloudTrue_2[iX,iY] == 1 && ΔLai_21[iX,iY] > ΔLai_CloudTreshold

            # Maximum allowed variation of Lai
               Lai_2[iX, iY]  = max(min(max(Lai_1[iX, iY] * (1.0 - ΔMaxIncrease), Lai_2[iX, iY]), Lai_1[iX, iY] * (1.0 + ΔMaxIncrease)), 0.0)
               Fapar_2[iX,iY] = min(min(max(Fapar_1[iX,iY] * (1.0 - ΔMaxIncrease), Fapar_2[iX,iY]), Fapar_1[iX,iY] * (1.0 + ΔMaxIncrease)), 1.0)
               Ndvi_2[iX,iY]  = min(min(max(Ndvi_1[iX,iY] * (1.0 - ΔMaxIncrease), Ndvi_2[iX,iY]), Ndvi_1[iX,iY] * (1.0 + ΔMaxIncrease)) ,1)
               Fvc_2[iX,iY]   = min( min(max(Fvc_1[iX,iY] * (1.0 - ΔMaxIncrease), Fvc_2[iX,iY]), Fvc_1[iX,iY] * (1.0 + ΔMaxIncrease)), 1.0)

         end # for iY=1:Metadatas.N_Height
      end # for iX=1:Metadatas.N_Width

      # WRITTING OUTPUT
      Path_Julia_Lai = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Lai, NameOutput_Lai₁[i])
      Path_Julia_Fapar = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Fapar, NameOutput_Fapar₁[i])
      Path_Julia_Ndvi = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Ndvi, NameOutput_Ndvi₁[i])
      Path_Julia_Fvc = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Fvc, NameOutput_Fvc₁[i])

      Rasters.write(Path_Julia_Lai, Lai_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
      Rasters.write(Path_Julia_Fapar, Fapar_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
      Rasters.write(Path_Julia_Ndvi, Ndvi_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
      Rasters.write(Path_Julia_Fvc, Fvc_2; ext=".tiff", missingval=NaN, force=true, verbose=true)

      if 🎏_Plots
         Path_Plot = joinpath(Path_SentinelBiophysicalRemoveCloud, "PLOTS", NameOutput_Plot₁[i] )


         geoPlot.HEATMAP_LAI(;colormap=:avocado, DaySentinel₁=DaySentinel[i], Fapar_2, Fvc_2, Lai_2, MonthSentinel₁=MonthSentinel[i], Ndvi_2, Path_Plot, titlecolor=titlecolor, titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, YearSentinel₁=YearSentinel[i], ylabelsize=ylabelsize, yticksize=yticksize, Lai_Raw, Fapar_Raw, Ndvi_Raw, Fvc_Raw
         )
      end # if 🎏_Plots

      # Perfornming the cycle
      Lai_1 = deepcopy(Lai_2)
      Lai_2 = deepcopy(Lai_3)
      LaiCloudTrue_1 = deepcopy(LaiCloudTrue_2)
      LaiCloudTrue_2 = deepcopy(LaiCloudTrue_3)

      Fapar_1 = deepcopy(Fapar_2)
      Fapar_2 = deepcopy(Fapar_3)

      Ndvi_1 = deepcopy(Ndvi_2)
      Ndvi_2 = deepcopy(Ndvi_3)

      Fvc_1 = deepcopy(Fvc_2)
      Fvc_2 = deepcopy(Fvc_3)
   end # for iiSentinelData ∈ AllSentinelData

   return nothing
end  # function WFLOW_REMOVING_CLOUDS()
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : DISCRZETZATION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function DISCRZETZATION(; Dtm, iCount, Latitude, Longitude, Metadatas, Method=:near, Path, Subcatchment)
   Data₀ = Rasters.Raster(Path)

   Data = Data₀[Band(1)]
   Data = Rasters.resample(Data; to=Dtm, missingval=NaN, method=Method)
   Data = geoRaster.MASK(; Param_Crs=Metadatas.Crs_GeoFormat, Input=Data, Latitude, Longitude, Mask=Subcatchment)

   Data_CloudTrue = Data₀[Band(2)]
   Data_CloudTrue = Rasters.resample(Data_CloudTrue; to=Dtm, missingval=NaN, method=Method)
   Data_CloudTrue = geoRaster.MASK(; Param_Crs=Metadatas.Crs_GeoFormat, Input=Data_CloudTrue, Latitude, Longitude, Mask=Subcatchment)

   # Filtering Flag=1 only && (CloudCover[i] > CloudCoverFreeThreshold)
   for iX = 1:Metadatas.N_Width
      for iY = 1:Metadatas.N_Height
         if Data_CloudTrue[iX, iY] ≠ 1
            Data_CloudTrue[iX, iY] = NaN
         end
      end # for iY=1:Metadatas.N_Height
   end # for iX=1:Metadatas.N_Width

   return Data, Data_CloudTrue
end  # function: DISCRZETZATION
# ------------------------------------------------------------------

end  # module: copernicus
# ............................................................