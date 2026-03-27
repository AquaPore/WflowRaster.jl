# =============================================================
#		module: copernicus
# =============================================================
module copernicus

using GeoDataFrames, Dates, CSV, Rasters
using ZipFile, PDFmerger

# SentinelExplorer,

include("Parameters.jl")
include("GeoPlot.jl")
include("PlotParameter.jl")
include("GeoRaster.jl")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : SENTINEL_DATA
# ~~~~~~~~~~~`~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function SENTINEL_DATA(; 🎏_DownloadTwiceMonth=false, Authenticate_Password="Joseph.pollacco1", Authenticate_Username="joseph.pollacco@teagasc.ie", CloudMax=50, Coordinate_LowerRight, Coordinate_UpperLeft, CopernicusDate_End, CopernicusDate_Start, Path_SentinelDownload₁, Path_SentinelMetadata₁, Product="L2A", Satelite="SENTINEL-2", Filename_SentinelMetadata, FirstSecond=1, require_ssl_verification=true)

   CopernicusDate_StartDate = Dates.Date(CopernicusDate_Start[1], CopernicusDate_Start[2], CopernicusDate_Start[3])
   CopernicusDate_EndDate = Dates.Date(CopernicusDate_End[1], CopernicusDate_End[2], CopernicusDate_End[3])

   # Preparing metdata
   Date_Scene = []
   Name_Scene = []
   CloudCover_Scene = []
   🎏_Sucessfull = []

   # Authenticate
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

   # Derive the 1rst and second best day of the month with the least cloud
   for FirstSecond = 1:2
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

                  🎏_Sucessfull, CloudCover_Scene, Date_Scene, Name_Scene = copernicus.SENTINEL_SEARCH(; 🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, FirstSecond, Name_Scene, Path_SentinelDownload₁, Product, Satelite, require_ssl_verification)

                  # Write to CSV
                  Path_Sentinel₁ = joinpath(Path_SentinelMetadata₁, Filename_SentinelMetadata)
                  Header = ["Date", "Cloud", "Name", "🎏_Sucessfull"]
                  CSV.write(Path_Sentinel₁, Tables.table([Date_Scene CloudCover_Scene Name_Scene 🎏_Sucessfull]), writeheader=true, header=Header, bom=true)
               end
            end # for iSplit = 1:2
         end # for iiMonth=1:12
      end # for iiYear = CopernicusDate_Start[1]::CopernicusDate_End[1]
   end # for FirstSecond=1:2

   printstyled(" ======  FINISHED ==== \n"; color=:red)

   return nothing
end  # function: SENTINEL_DATA
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : SENTINEL_SEARCH
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function SENTINEL_SEARCH(; 🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, FirstSecond, Name_Scene, Path_SentinelDownload₁, Product, Satelite, require_ssl_verification)

   # #    using HTTP
   # # HTTP.get("https://catalogue.dataspace.copernicus.eu/odata/v1/Products?\$top=1"; require_ssl_verification=false)


   🎏_DataAvailable = true
   SearchMap = []
   try
      SearchMap = copernicus.SentinelExplorer.search(Satelite, dates=DateSearch, geom=Box, clouds=CloudMax, product=Product, require_ssl_verification=require_ssl_verification)
   catch
      🎏_DataAvailable = false
      printstyled("   ==== DATA NOT AVAILABLE for $DateSearch ==== \n"; color=:red)
   end

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
            copernicus.SentinelExplorer.download_scene(Scene.Name, Path_SentinelDownload₁; unzip=false, log_progress=false, access_token=nothing, require_ssl_verification=require_ssl_verification)

            # METADATA
            Date_Scene = push!(Date_Scene, Date_Scene₀)
            Name_Scene = push!(Name_Scene, Scene.Name)
            CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)
         catch
            # Try again
            try
               copernicus.SentinelExplorer.download_scene(Scene.Name, Path_SentinelDownload₁; unzip=false, log_progress=false, access_token=nothing, require_ssl_verification=require_ssl_verification)
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

   printstyled("	................ END ............... \n", color=:red)
end # function RUN_SNAP()
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : REMOVING_CLOUDS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function WFLOW_REMOVING_CLOUDS(; 🎏_Lai_CompilePdf, 🎏_Write=false, Dtm, Fapar_Max=0.94, Fapar_Min=0.0, Fvc_Max=1.0, Fvc_Min=0.0, Lai_Max=8.0, Lai_Min=0.0, Latitude, Longitude, Metadatas, NamePath_Fapar="FAPAR", NamePath_Fvc="FVC", NamePath_Lai="LAI", NamePath_Ndvi="NDVI", Path_SentinelBiophysical₁, Path_SentinelBiophysicalRemoveCloud, Path_SentinelMetadata₁, Subcatchment, ΔMaxIncrease=0.25, CloudCoverPercent_Max = 0.6)

   MetaData = CSV.read(Path_SentinelMetadata₁, DataFrame; header=true)
      DataFrames.sort!(MetaData, [:Date])
      🎏_Sucessfull = convert(Vector{Bool}, Tables.getcolumn(MetaData, :🎏_Sucessfull))
      DateSentinel  = convert(Vector{DateTime}, Tables.getcolumn(MetaData, :Date))
      CloudCover    = convert(Vector{Float64}, Tables.getcolumn(MetaData, :Cloud))

   # Selecting data
      N = sum(🎏_Sucessfull)
      DateSentinel = DateSentinel[🎏_Sucessfull]
      CloudCover = CloudCover[🎏_Sucessfull]

   # Putting in memory
      Path_Lai          = fill("", N)
      Path_Ndvi         = fill("", N)
      Path_Fvc          = fill("", N)
      Path_Fapar        = fill("", N)
      NameOutput_Lai₁   = fill("", N)
      NameOutput_Ndvi₁  = fill("", N)
      NameOutput_Fvc₁   = fill("", N)
      NameOutput_Fapar₁ = fill("", N)
      NameOutput_Plot₁  = fill("", N)
      YearSentinel      = zeros(Int64, N)
      MonthSentinel     = zeros(Int64, N)
      DaySentinel       = zeros(Int64, N)

   # Deriving the paths
   Threads.@threads for i = 1:N
      # Dates of output
         YearSentinel[i]  = Dates.year(DateSentinel[i])
         MonthSentinel[i] = Dates.month(DateSentinel[i])
         DaySentinel[i]   = Dates.day(DateSentinel[i])
         DateFormat       = YearSentinel[i] * 10000 + MonthSentinel[i] * 100 + DaySentinel[i]

      # Paths of output
         NameOutput_Lai₁[i] = string(DateFormat) * "_" * NamePath_Lai * ".tif"
         Path_Lai[i]        = joinpath(Path_SentinelBiophysical₁, NamePath_Lai, NameOutput_Lai₁[i])
         @assert isfile(Path_Lai[i])

         NameOutput_Ndvi₁[i] = string(DateFormat) * "_" * NamePath_Ndvi * ".tif"
         Path_Ndvi[i]        = joinpath(Path_SentinelBiophysical₁, NamePath_Ndvi, NameOutput_Ndvi₁[i])
         @assert isfile(Path_Ndvi[i])

         NameOutput_Fvc₁[i] = string(DateFormat) * "_" * NamePath_Fvc * ".tif"
         Path_Fvc[i]        = joinpath(Path_SentinelBiophysical₁, NamePath_Fvc, NameOutput_Fvc₁[i])
         @assert isfile(Path_Fvc[i])

         NameOutput_Fapar₁[i] = string(DateFormat) * "_" * NamePath_Fapar * ".tif"
         Path_Fapar[i]        = joinpath(Path_SentinelBiophysical₁, NamePath_Fapar, NameOutput_Fapar₁[i])
         @assert isfile(Path_Fapar[i])

         NameOutput_Plot₁[i] = string(DateFormat) * "_PLOT" * ".pdf"
   end # for i = 1:N

   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #		FUNCTION : CORRECT_CLOUDS
   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   # ~~~~~~~~ FUNCTIONS ~~~~~~~~~~
      """
      There is a better corelation with Clouds and Fapar
      """
      DaysInMonth = 365.0 / 12.0
      function PERCENTAGE_ΔDays(;ΔMaxIncrease₁, Obs₁, Obs₂, ΔDays_21)
         ΔMaxIncrease₂ = ΔDays_21 * ΔMaxIncrease₁ / DaysInMonth
      return min(max(Obs₁ * (1.0 - ΔMaxIncrease₂), Obs₂), Obs₁ * (1.0 + ΔMaxIncrease₂))
      end

      function INTERPOLATE(; Obs₁, Obs₂, ΔDays_21, ΔDays_32)
         W = ΔDays_32 / (ΔDays_21 + ΔDays_32)
      return W * Obs₁ + (1.0 - W) * Obs₂
      end

      """ Percentage converted to month"""
      function PERCENTAGE_MONTH(;Obs₁, Obs₂, ΔDay, Obs_Min, Obs_Max)
         return DaysInMonth * (abs(Obs₂ - Obs₁) / ΔDay) / (Obs_Max - Obs_Min)
      end

      function COUNT_NONAN(Obs₁, Metadatas)
         Count = 0
         for iX = 1:Metadatas.N_Width
            for iY = 1:Metadatas.N_Height
               if !isnan(Obs₁[iX, iY])
                  Count += 1
               end
            end
         end
      return Count
      end # function COUNT_NONAN(Obs₁, Metadatas)

   # Initializing
      Lai_1, ~   = copernicus.DISCRZETZATION(; Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Lai[1], Subcatchment)
      Fapar_1, ~ = copernicus.DISCRZETZATION(; Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Fapar[1], Subcatchment)
      Ndvi_1, ~  = copernicus.DISCRZETZATION(; Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Ndvi[1], Subcatchment)
      Fvc_1, ~   = copernicus.DISCRZETZATION(; Dtm, iCount=1, Latitude, Longitude, Metadatas, Path=Path_Fvc[1], Subcatchment)

      Lai_2, LaiCloudTrue_2     = copernicus.DISCRZETZATION(; Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Lai[2], Subcatchment)
      Fapar_2, FaparCloudTrue_2 = copernicus.DISCRZETZATION(; Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Fapar[2], Subcatchment)
      Ndvi_2, ~                 = copernicus.DISCRZETZATION(; Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Ndvi[2], Subcatchment)
      Fvc_2, FvcCloudTrue_2     = copernicus.DISCRZETZATION(; Dtm, iCount=2, Latitude, Longitude, Metadatas, Path=Path_Fvc[2], Subcatchment)

      # Cloud cover of FVC & Lai not reliable, could change in future release
         LaiCloudTrue_2 = deepcopy(FaparCloudTrue_2)
         FvcCloudTrue_2 = deepcopy(FaparCloudTrue_2)

      Count_LaiNoNan = COUNT_NONAN(Lai_2, Metadatas)

   # For every satelite image
   for i = 2:N-1
      println( " ==== $i : $(NameOutput_Lai₁[i]) ==== " )

      # Discretisation
         Fapar_3, FaparCloudTrue_3 = copernicus.DISCRZETZATION(; Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Fapar[i+1], Subcatchment)
         Lai_3, LaiCloudTrue_3     = copernicus.DISCRZETZATION(; Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Lai[i+1], Subcatchment)
         Ndvi_3, ~                 = copernicus.DISCRZETZATION(; Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Ndvi[i+1], Subcatchment)
         Fvc_3, FvcCloudTrue_3     = copernicus.DISCRZETZATION(; Dtm, iCount=i+1, Latitude, Longitude, Metadatas, Path=Path_Fvc[i+1], Subcatchment)

      # Cloud cover of FVC & Lai not reliable, could change in future release
         FvcCloudTrue_3 = deepcopy(FaparCloudTrue_3)
         LaiCloudTrue_3 = deepcopy(FaparCloudTrue_3)

      # For plotting
      if 🎏_Plots
         Lai_Raw   = deepcopy(Lai_2)
         Fapar_Raw = deepcopy(Fapar_2)
         Ndvi_Raw  = deepcopy(Ndvi_2)
         Fvc_Raw   = deepcopy(Fvc_2)
      end

      CloudCoverPercent_2 = COUNT_NONAN(FaparCloudTrue_2, Metadatas) / (Count_LaiNoNan + 1)
      CloudCoverPercent_3 = COUNT_NONAN(FaparCloudTrue_3, Metadatas) / (Count_LaiNoNan + 1)

      # Days between different events
         ΔDays_21 = Dates.days(DateSentinel[i] - DateSentinel[i-1])
         ΔDays_32 = Dates.days(DateSentinel[i+1] - DateSentinel[i])
         ΔDays_31 = Dates.days(DateSentinel[i+1] - DateSentinel[i-1])

      # For every image
      Threads.@threads for iX = 1:Metadatas.N_Width
         Threads.@threads for iY = 1:Metadatas.N_Height

            # Feasible range
               Lai_2[iX, iY]   = min(max(Lai_2[iX, iY], Lai_Min), Lai_Max)
               Fapar_2[iX, iY] = min(max(Fapar_2[iX, iY], Fapar_Min), Fapar_Max)
               Fvc_2[iX, iY]   = min(max(Fvc_2[iX, iY], Fvc_Min), Fvc_Max)

               if 🎏_Plots
                  Lai_Raw[iX, iY]   = min(max(Lai_Raw[iX, iY], Lai_Min), Lai_Max)
                  Fapar_Raw[iX, iY] = min(max(Fapar_Raw[iX, iY], Fapar_Min), Fapar_Max)
                  Fvc_Raw[iX, iY]   = min(max(Fvc_Raw[iX, iY], Fvc_Min), Fvc_Max)
               end

            # Variation of Lai
               ΔLai_21   = PERCENTAGE_MONTH(; Obs₁=Lai_1[iX, iY], Obs₂=Lai_2[iX, iY], ΔDay=ΔDays_21, Obs_Min=Lai_Min, Obs_Max=Lai_Max)
               ΔLai_31   = PERCENTAGE_MONTH(; Obs₁=Lai_1[iX, iY], Obs₂=Lai_3[iX, iY], ΔDay=ΔDays_31, Obs_Min=Lai_Min, Obs_Max=Lai_Max)

               ΔFapar_21 = PERCENTAGE_MONTH(; Obs₁=Fapar_1[iX, iY], Obs₂=Fapar_2[iX, iY], ΔDay=ΔDays_21, Obs_Min=Fapar_Min, Obs_Max=Fapar_Max)
               ΔFapar_31 = PERCENTAGE_MONTH(; Obs₁=Fapar_1[iX, iY], Obs₂=Fapar_3[iX, iY], ΔDay=ΔDays_31, Obs_Min=Fapar_Min, Obs_Max=Fapar_Max)

               ΔFvc_21   = PERCENTAGE_MONTH(; Obs₁=Fvc_1[iX, iY], Obs₂=Fvc_2[iX, iY], ΔDay=ΔDays_21, Obs_Min=Fvc_Min, Obs_Max=Fvc_Max)
               ΔFvc_31   = PERCENTAGE_MONTH(; Obs₁=Fvc_1[iX, iY], Obs₂=Fvc_3[iX, iY], ΔDay=ΔDays_31, Obs_Min=Fvc_Min, Obs_Max=Fvc_Max)

            #-------

            # The LaiCloudTrue does not always pick up clouds but also uncertainty, therefore we determine if there is issue if there is a significan change in ΔLai
            if ((LaiCloudTrue_2[iX, iY] == 1) && (ΔLai_21 > ΔMaxIncrease)) || (CloudCoverPercent_2 ≥ CloudCoverPercent_Max)
               # Assume that at [iX,iY] Lai_3 is free cloud
               if  (LaiCloudTrue_3[iX, iY] ≠ 1) && (ΔLai_31 ≤ ΔMaxIncrease) && CloudCoverPercent_3 < CloudCoverPercent_Max
                  Lai_2[iX, iY]  = INTERPOLATE(;Obs₁=Lai_1[iX, iY], Obs₂=Lai_3[iX, iY], ΔDays_21, ΔDays_32)
                  Ndvi_2[iX, iY] = INTERPOLATE(;Obs₁=Ndvi_1[iX, iY], Obs₂=Ndvi_3[iX, iY], ΔDays_21, ΔDays_32)
               else
                  Lai_2[iX, iY]  = Lai_1[iX, iY]
                  Ndvi_2[iX, iY] = Ndvi_1[iX, iY]
               end
            else
               LaiCloudTrue_2[iX, iY] = NaN
            end # LaiCloudTrue_2[iX,iY] == 1 && ΔLai_21[iX,iY]

            #-------

            # The LaiCloudTrue does not always pick up clouds but also uncertainty, therefore we determine if there is issue if there is a significan change in ΔLai
            if ((FaparCloudTrue_2[iX, iY] == 1) && (ΔFapar_21 > ΔMaxIncrease)) || (CloudCoverPercent_2  ≥ CloudCoverPercent_Max)
               # Assume that at [iX,iY] Lai_3 is free cloud
               if  (FaparCloudTrue_3[iX, iY] ≠ 1) && (ΔFapar_31 ≤ ΔMaxIncrease) && (CloudCoverPercent_3 < CloudCoverPercent_Max)
                  Fapar_2[iX, iY] = INTERPOLATE(; Obs₁=Fapar_1[iX, iY], Obs₂=Fapar_3[iX, iY], ΔDays_21, ΔDays_32)
               else
                  Fapar_2[iX, iY] = Fapar_1[iX, iY]
               end
            else
               FaparCloudTrue_2[iX, iY] = NaN
            end # LaiCloudTrue_2[iX,iY] == 1 && ΔLai_21[iX,iY]

            #-------

            # The LaiCloudTrue does not always pick up clouds but also uncertainty, therefore we determine if there is issue if there is a significan change in ΔLai
            if ((FvcCloudTrue_2[iX, iY] == 1) && (ΔFvc_21 > ΔMaxIncrease)) ||  (CloudCoverPercent_2 ≥ CloudCoverPercent_Max)
               # Assume that at [iX,iY] Lai_3 is free cloud
               if ((FvcCloudTrue_3[iX, iY] ≠ 1) && (ΔFvc_31 ≤ ΔMaxIncrease)) && (CloudCoverPercent_3 < CloudCoverPercent_Max)
                  Fvc_2[iX, iY] = INTERPOLATE(; Obs₁=Fvc_1[iX, iY], Obs₂=Fvc_3[iX, iY], ΔDays_21, ΔDays_32)
               else
                  Fvc_2[iX, iY] = Fvc_1[iX, iY]
               end
            else
               FvcCloudTrue_2[iX, iY] = NaN
            end # LaiCloudTrue_2[iX,iY] == 1 && ΔLai_21[iX,iY]

            #-------

            # Maximum allowed variation of Lai
               Lai_2[iX, iY]   = PERCENTAGE_ΔDays(; ΔMaxIncrease₁=ΔMaxIncrease, Obs₁=Lai_1[iX, iY], Obs₂=Lai_2[iX, iY], ΔDays_21)
               Fapar_2[iX, iY] = PERCENTAGE_ΔDays(; ΔMaxIncrease₁=ΔMaxIncrease, Obs₁=Fapar_1[iX, iY], Obs₂=Fapar_2[iX, iY], ΔDays_21)
               Ndvi_2[iX, iY]  = PERCENTAGE_ΔDays(; ΔMaxIncrease₁=ΔMaxIncrease, Obs₁=Ndvi_1[iX, iY], Obs₂=Ndvi_2[iX, iY], ΔDays_21)
               Fvc_2[iX, iY]   = PERCENTAGE_ΔDays(; ΔMaxIncrease₁=ΔMaxIncrease, Obs₁=Fvc_1[iX, iY], Obs₂=Fvc_2[iX, iY], ΔDays_21)

            # Correction of Lai with knowledge of Fvc & Lai
               if Fvc_2[iX, iY] ≤ 0.1 || Fapar_2[iX, iY] ≤ 0.1
                  Lai_2[iX, iY] = min(Fvc_2[iX, iY], Fvc_2[iX, iY], Lai_2[iX, iY])
               end
         end # for iY=1:Metadatas.N_Height
      end # for iX=1:Metadatas.N_Width

      # WRITTING OUTPUT
      if 🎏_Write
         Path_Julia_Lai   = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Lai, NameOutput_Lai₁[i])
         Path_Julia_Fapar = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Fapar, NameOutput_Fapar₁[i])
         Path_Julia_Ndvi  = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Ndvi, NameOutput_Ndvi₁[i])
         Path_Julia_Fvc   = joinpath(Path_SentinelBiophysicalRemoveCloud, NamePath_Fvc, NameOutput_Fvc₁[i])

         rm(Path_Julia_Lai, force=true)
         rm(Path_Julia_Fapar, force=true)
         rm(Path_Julia_Ndvi, force=true)
         rm(Path_Julia_Fvc, force=true)

         Rasters.write(Path_Julia_Lai, Lai_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
         Rasters.write(Path_Julia_Fapar, Fapar_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
         Rasters.write(Path_Julia_Ndvi, Ndvi_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
         Rasters.write(Path_Julia_Fvc, Fvc_2; ext=".tiff", missingval=NaN, force=true, verbose=true)
      end  #  if 🎏_Write

      if 🎏_Plots
         Path_Plot = joinpath(Path_SentinelBiophysicalRemoveCloud, "PLOTS", NameOutput_Plot₁[i])

         geoPlot.HEATMAP_LAI(; colormap=:avocado, DaySentinel₁=DaySentinel[i], Fapar_2, Fvc_2, Lai_2, MonthSentinel₁=MonthSentinel[i], Ndvi_2, Path_Plot, titlecolor=titlecolor, titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, YearSentinel₁=YearSentinel[i], ylabelsize=ylabelsize, yticksize=yticksize, Lai_Raw, Fapar_Raw, Ndvi_Raw, Fvc_Raw, LaiCloudTrue_2, FaparCloudTrue_2, FvcCloudTrue_2, ΔMaxIncrease, CloudCoverPercent=CloudCoverPercent_2)
      end # if 🎏_Plots

      # Perfornming the cycle
         Lai_1 = deepcopy(Lai_2)
         Lai_2 = deepcopy(Lai_3)
         LaiCloudTrue_2 = deepcopy(LaiCloudTrue_3)

         Fapar_1 = deepcopy(Fapar_2)
         Fapar_2 = deepcopy(Fapar_3)
         FaparCloudTrue_2 = deepcopy(FaparCloudTrue_3)

         Fvc_1 = deepcopy(Fvc_2)
         Fvc_2 = deepcopy(Fvc_3)
         FvcCloudTrue_2 = deepcopy(FvcCloudTrue_3)

         Ndvi_1 = deepcopy(Ndvi_2)
         Ndvi_2 = deepcopy(Ndvi_3)

   end # for iiSentinelData ∈ AllSentinelData

   # Combining plots into one pdf
   if 🎏_Lai_CompilePdf
      Path_Plot = joinpath(Path_SentinelBiophysicalRemoveCloud, "PLOTS")
      cd(Path_Plot)
      Folder_List = readdir(Path_Plot)
      Folder_List = sort(Folder_List)

      Path_Output_Pdf = joinpath(Path_SentinelBiophysicalRemoveCloud, "ALL_PLOTS_SENTINEL_" * string(ΔMaxIncrease) * ".pdf")
      PDFmerger.merge_pdfs(Folder_List, Path_Output_Pdf)
   end

   printstyled(" ================ FINISHED ===================", color=:red)

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
   Threads.@threads for iX = 1:Metadatas.N_Width
      Threads.@threads for iY = 1:Metadatas.N_Height
         if Data_CloudTrue[iX, iY] ≠ 1
            Data_CloudTrue[iX, iY] = NaN
         end
      end # for iY=1:Metadatas.N_Height
   end # for iX=1:Metadatas.N_Width

   return Data, Data_CloudTrue
end  # function: DISCRZETZATION
# ------------------------------------------------------------------


module SentinelExplorer

"""
Credit Joshua Billson
https://github.com/JoshuaBillson/SentinelExplorer.jl/blob/main/src/SentinelExplorer.jl
"""

using DataFrames, Dates, WellKnownGeometry, GeoFormatTypes
import HTTP, JSON, ZipFile
using Pipe: @pipe

"""
   Point(lat, lon)

Construct a point located at the provided latitude and longitude.

# Parameters
- `lat`: The latitude of the point.
- `lon`: The longitude of the point.

# Example
```julia
p = Point(52.0, -114.25)
```
"""
struct Point{T}
   lat::T
   lon::T
   Point(lat::T, lon::T) where {T} = new{T}(lat, lon)
end

"""
   BoundingBox(ul, lr)

Construct a bounding box defined by the corners `ul` and `lr`.

All coordinates should be provided in latitude and longitude.

# Parameters
- `ul`: The upper-left corner of the box as a `Tuple{T,T}` of latitude and longitude.
- `lr`: The lower-right corner of the box as a `Tuple{T,T}` of latitude and longitude.

# Example
```julia
bb = BoundingBox((52.1, -114.4), (51.9, -114.1))
```
"""
struct BoundingBox{T}
   ul::Tuple{T,T}
   lr::Tuple{T,T}
   BoundingBox(ul::Tuple{T,T}, lr::Tuple{T,T}) where {T} = new{T}(ul, lr)
end

"""
   authenticate(username, password)

Authenticate with your Copernicus Data Space credentials.

Sets the environment variables `SENTINEL_EXPLORER_USER` and `SENTINEL_EXPLORER_PASS`, which will
be used to authenticate future requests.

# Parameters
- `username`: Your Copernicus Data Space username.
- `password`: Your Copernicus Data Space password.

# Example
```julia
authenticate("my_username", "my_password")
token = get_access_token()
```
"""
function authenticate(username, password)
   ENV["SENTINEL_EXPLORER_USER"] = username
   ENV["SENTINEL_EXPLORER_PASS"] = password
end

"""
   get_access_token()
   get_access_token(username, password)

Receive a data access token with the provided credentials.

The username and password may be passed explicitly, or provided as a pair of environment variables.

In the case of the latter, `get_access_token()` expects your username and password to be provided as the
environment variables `SENTINEL_EXPLORER_USER` and `SENTINEL_EXPLORER_PASS`.

# Parameters
- `username`: Your Copernicus Data Space username.
- `password`: Your Copernicus Data Space password.

# Returns
An access token for downloading data.

# Example
```julia
token = get_access_token(ENV["SENTINEL_EXPLORER_USER"], ENV["SENTINEL_EXPLORER_PASS"])
token = get_access_token()  # Same as Above
```
"""
function get_access_token(username, password)
   data = Dict(
      "client_id" => "cdse-public",
      "username" => username,
      "password" => password,
      "grant_type" => "password")

   status_error = nothing
   try
      auth_url = "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token"
      response = HTTP.post(auth_url, body=data)
      return @pipe String(response.body) |> JSON.parse |> _["access_token"]
   catch e
      if e isa HTTP.Exceptions.StatusError
         status_error = e
      else
         throw(e)
      end
   end
   throw(ArgumentError("Authentication failed with response code $(status_error.status)!\n\n$(status_error.response)"))
end

function get_access_token()
   return get_access_token(ENV["SENTINEL_EXPLORER_USER"], ENV["SENTINEL_EXPLORER_PASS"])
end

"""
   search(satellite; product=nothing, dates=nothing, tile=nothing, clouds=nothing, geom=nothing, max_results=100)

Search for satellite images matching the provided filters.

# Parameters
- `satellite`: One of "SENTINEL-1", "SENTINEL-2", or "SENTINEL-3".

# Keywords
- `product`: The product type to search for such as "L2A", "L1C", "GRD", etc.
- `dates`: The date range for image acquisition. Should be a tuple of `DateTime` objects.
- `tile`: Restrict results to a given tile. Only available for Sentinel-2.
- `clouds`: The maximum allowable cloud cover as a percentage. Not available for Sentinel-1.
- `geom`: A geometry specifying the region of interest. Can be a `Point`, `BoundingBox`, or any other `GeoInterface` compatible geometry.
- `max_results`: The maximum number of results to return (default = 100).

# Returns
A `DataFrame` with the columns `:Name`, `:AcquisitionDate`, `:PublicationDate`, `:CloudCover`, and `:Id`.

# Example
```julia
julia> geom = GeoDataFrames.read("test/data/roi.geojson").geometry[1];

julia> dates = (DateTime(2020, 8, 4), DateTime(2020, 8, 5));

julia> search("SENTINEL-2",  geom=geom, dates=dates)
3×5 DataFrame
Row │ Name                               AcquisitionDate           Pub ⋯
   │ String                             String                    Str ⋯
─────┼───────────────────────────────────────────────────────────────────
   1 │ S2B_MSIL2A_20200804T183919_N0500…  2020-08-04T18:39:19.024Z  202 ⋯
   2 │ S2B_MSIL1C_20200804T183919_N0209…  2020-08-04T18:39:19.024Z  202
   3 │ S2B_MSIL1C_20200804T183919_N0500…  2020-08-04T18:39:19.024Z  202
                                                      3 columns omitted
```
"""
function search(satellite::String; product=nothing, dates=nothing, tile=nothing, clouds=nothing, geom=nothing, max_results=100, require_ssl_verification=false)
   # Product Filter
   satellites = ["SENTINEL-1", "SENTINEL-2", "SENTINEL-3"]
   !(satellite in satellites) && throw(ArgumentError("satellite must be one of $satellites"))
   filters = ["Collection/Name eq '$satellite'"]

   # product Filter
   if !isnothing(product)
      push!(filters, "contains(Name,'$product')")
   end

   # Dates Filter
   if !isnothing(dates)
      dates[1] > dates[2] && throw(ArgumentError("dates must ordered from oldest to newest!"))
      start_string = Dates.format(dates[1], "yyyy-mm-ddTHH:MM:SS.sssZ")
      end_string = Dates.format(dates[2], "yyyy-mm-ddTHH:MM:SS.sssZ")
      df = "ContentDate/Start gt $start_string and ContentDate/Start lt $end_string"
      push!(filters, df)
   end

   # Tile Filter
   if !isnothing(tile)
      satellite != "SENTINEL-2" && throw(ArgumentError("tile filter is only supported for SENTINEL-2!"))
      dtype = "OData.CSC.StringAttribute"
      tf = "Attributes/$dtype/any(att:att/Name eq 'tileId' and att/$dtype/Value eq '$tile')"
      push!(filters, tf)
   end

   # Cloud Filter
   if !isnothing(clouds)
      satellite == "SENTINEL-1" && throw(ArgumentError("cloud filter is not supported for SENTINEL-1!"))
      dtype = "OData.CSC.DoubleAttribute"
      cf = "Attributes/$dtype/any(att:att/Name eq 'cloudCover' and att/$dtype/Value lt $clouds)"
      push!(filters, cf)
   end

   # Geometry Filter
   if !isnothing(geom)
      wkt = _to_wkt(geom)
      gf = "OData.CSC.Intersects(area=geography'SRID=4326;$wkt')"
      push!(filters, gf)
   end

   # Construct Query
   query_string = join(filters, " and ")
   query = Dict(
      "\$filter" => query_string,
      "\$expand" => "Attributes",
      "\$top" => max_results,
      "\$orderby" => "ContentDate/Start asc")
   url = "https://catalogue.dataspace.copernicus.eu/odata/v1/Products"
   response = HTTP.get(url, query=query; require_ssl_verification=require_ssl_verification)

   # Process Results
   if response.status == 200
      # Read Results Into DataFrame
      df = @pipe response.body |> String |> JSON.parse |> _["value"] |> DataFrame

      # Throw Error if Results are Empty
      nrow(df) == 0 && throw(ErrorException("Search Returned Zero Results."))

      # Prepare DataFrame
      get_value(x) = isempty(x) ? missing : x[1]["Value"]
      get_clouds(xs) = filter(x -> x["Name"] == "cloudCover", xs) |> get_value

      @pipe df |>
            filter(:Online => identity, _) |>
            transform(_, :Attributes => ByRow(get_clouds) => :CloudCover) |>
            transform(_, :ContentDate => ByRow(x -> x["Start"]) => :AcquisitionDate) |>
            _[!, [:Name, :AcquisitionDate, :PublicationDate, :CloudCover, :Id]]
   else
      throw(ErrorException("Search Returned $(response.status)."))
   end
end

"""
   get_scene_id(scene)

Lookup the unique identifier for the provided scene.

# Parameters
- `scene`: The name of the Sentinel scene to lookup.

# Returns
The unique identifier for downloading the provided scene.

# Example
```julia
julia> scene = "S2B_MSIL2A_20200804T183919_N0500_R070_T11UPT_20230321T050221";

julia> get_scene_id(scene)
"29f0eaaf-0b15-412b-9597-16c16d4d79c6"
```
"""
function get_scene_id(scene)
   # Query Filters
   filters = String[]

   # Get Sensing Time
   m = match(r"(\d{8})T", scene)
   if !isnothing(m)
      sense_time = DateTime(m[1], "yyyymmdd")
      start_string = Dates.format(sense_time - Day(1), "yyyy-mm-ddTHH:MM:SS.sssZ")
      end_string = Dates.format(sense_time + Day(1), "yyyy-mm-ddTHH:MM:SS.sssZ")
      df = "ContentDate/Start gt $start_string and ContentDate/Start lt $end_string"
      push!(filters, df)
   end

   # Name Filter
   nf = "contains(Name,'$scene')"
   push!(filters, nf)

   # Prepare Query
   url = "https://catalogue.dataspace.copernicus.eu/odata/v1/Products"
   query = Dict("\$filter" => join(filters, " and "), "\$expand" => "Attributes",)

   # Post Query
   response = @pipe HTTP.get(url, query=query; require_ssl_verification).body |> String |> JSON.parse
   if isempty(response["value"])
      throw(ArgumentError("Could not locate any scene matching the provided name!"))
   end
   return response["value"][1]["Id"]
end

"""
   download_scene(scene, dir=pwd(); unzip=false, log_progress=true, access_token=nothing)

Download the requested Sentinel scene using the provided access token.

# Parameters
- `scene`: The name of the jentinel scene to download.
- `dir`: The destination directory of the downloaded scene (default = pwd()).

# Keywords
- `unzip`: If true, unzips and deletes the downloaded zip file (default = false).
- `log_progress`: If true, logs the download progress at 1-second intervals (default = true).
- `access_token`: A token to authenticate the request. Calls `get_access_token()` if `nothing` (default).
"""
function download_scene(scene, dir=pwd(); unzip=false, log_progress=true, access_token=nothing, require_ssl_verification=require_ssl_verification)
   # Lookup Scene ID
   id = get_scene_id(scene)

   # Prepare Headers
   access_token = isnothing(access_token) ? get_access_token() : access_token
   url = "https://zipper.dataspace.copernicus.eu/odata/v1/Products($id)/\$value"
   headers = Dict("Authorization" => "Bearer $access_token")

   # Download Scene
   update_period = log_progress ? 1 : Inf
   downloaded = HTTP.download(url, dir, headers=headers, update_period=update_period; require_ssl_verification=require_ssl_verification)
   if unzip
      # Unzip and Remove ZipFile
      _unzip(downloaded)
      rm(downloaded)

      # Return Path to Unzipped Filed
      name = match(r"^(.*)\.zip$", basename(downloaded))[1]
      filter(x -> !isnothing(match(Regex(name), x)), readdir(dir, join=true)) |> first
   else
      return downloaded
   end
end

"""
   download_scenes(scenes, dir=pwd(); unzip=false, access_token=nothing)

Download multiple scenes in parallel.

The number of parallel downloads is determined by `Threads.nthreads()`.

# Parameters
- `scenes`: A list of scenes to download.

# Keywords
- `dir`: The destination directory of the downloaded scene (default = pwd()).
- `unzip`: If true, unzips and deletes the downloaded zip file (default = false).
- `access_token`: A token to authenticate the request. Calls `get_access_token()` if `nothing` (default).
"""
function download_scenes(scenes, dir=pwd(); unzip=false, access_token=nothing, require_ssl_verification=true)
   files = ["", ""]
   access_token = isnothing(access_token) ? get_access_token() : access_token
   Threads.@threads for i in eachindex(scenes)
      file = download_scene(scenes[i], dir, unzip=unzip, log_progress=false, access_token=access_token, require_ssl_verification=require_ssl_verification)
      files[i] = file
   end
   return files
end

function _to_wkt(geom)
   return getwkt(geom) |> GeoFormatTypes.val |> _latlon_to_lonlat
end

function _to_wkt(geom::Point)
   return "POINT ($(geom.lon) $(geom.lat))"
end

function _to_wkt(geom::BoundingBox)
   lat_top = geom.ul[1]
   lat_bottom = geom.lr[1]
   lon_left = geom.ul[2]
   lon_right = geom.lr[2]
   points = [(lat_top, lon_left), (lat_top, lon_right), (lat_bottom, lon_right), (lat_bottom, lon_left), (lat_top, lon_left)]
   return @pipe points |> map(x -> join(reverse(x), " "), _) |> join(_, ",") |> "POLYGON (($_))"
end

function _latlon_to_lonlat(wkt::String)
   lon_lat = @pipe wkt |>
                   eachmatch(r"(-?\d+\.\d*\s-?\d+\.\d*)", _) |>  # Extract Lat/Lon Values
                   first.(collect(_)) |>                         # Extract Matches
                   split.(_, " ") |>                             # Split Lat/Lon at Space
                   reverse.(_) |>                                # Reverse Lat/Lon
                   join.(_, " ") |>                              # Join Lon/Lat With Space
                   join(_, ",")                                  # Join Coordinates With Commas

   shape, paren = match(r"([A-Z]+\s?\(+)[^)]*(\)+)", wkt) .|> string
   return join([shape, lon_lat, paren], "")
end

function _unzip(file, exdir="")
   fileFullPath = isabspath(file) ? file : joinpath(pwd(), file)
   basePath = dirname(fileFullPath)
   outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(), exdir)))
   isdir(outPath) ? "" : mkdir(outPath)
   zarchive = ZipFile.Reader(fileFullPath)
   for f in zarchive.files
      fullFilePath = joinpath(outPath, f.name)
      if (endswith(f.name, "/") || endswith(f.name, "\\"))
         mkdir(fullFilePath)
      else
         src = read(f)
         mkpath(dirname(fullFilePath))
         write(fullFilePath, src)
      end
   end
   close(zarchive)
end

export Point, BoundingBox, authenticate, get_access_token, search, get_scene_id, download_scene, download_scenes

end

end  # module: copernicus
# ............................................................