# =============================================================
#		module: copernicus
# =============================================================
module copernicus

using GeoDataFrames, Dates, SentinelExplorer, CSV
using ZipFile


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : SENTINEL_DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function SENTINEL_DATA(;🎏_DownloadTwiceMonth=false, Authenticate_Password="Joseph.pollacco1", Authenticate_Username="joseph.pollacco@teagasc.ie", CloudMax=50, Coordinate_LowerRight, Coordinate_UpperLeft, CopernicusDate_End, CopernicusDate_Start, Path_SentinelDownload₁, Path_SentinelMetadata₁, Product="L2A", Satelite="SENTINEL-2")

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

               🎏_Sucessfull, CloudCover_Scene, Date_Scene, Name_Scene = copernicus.SENTINEL_SEARCH(; 🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, Name_Scene, Path_SentinelDownload₁, Product, Satelite)

               # Write to CSV
               Path_Sentinel₁ = joinpath(Path_SentinelMetadata₁, "SentinelMetadata.csv")
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
function SENTINEL_SEARCH(; 🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, Name_Scene, Path_SentinelDownload₁, Product, Satelite)

   🎏_DataAvailable = true
   SearchMap = []
   try
      SearchMap = SentinelExplorer.search(Satelite, dates=DateSearch, geom=Box, clouds=CloudMax, product=Product)
   catch
      🎏_DataAvailable = false
      printstyled("   ==== DATA NOT AVAILABLE for $DateSearch ==== \n"; color=:red)
   end

   if 🎏_DataAvailable
      Scene = sort(SearchMap, :CloudCover) |> first

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
function SNAP_BATCH_LAI_FAPAR_NDVI_FVC(; Path_SentinelDownload₁, Path_SentinelBiophysical₁, Path_CatchmentBoundary₁, Path_SentinelXml₁, PathProperties, Path_SentinelMetadata₁, NameOutput_Lai="LAI", NameOutput_Fapar="FAPAR", NameOutput_Ndvi="NDVI", NameOutput_Fvc="FVC")

   # AllSentinelData = readdir(Path_SentinelDownload₁)
   # AllSentinelData = sort!(AllSentinelData)

      MetaData = CSV.read(Path_SentinelMetadata₁, DataFrame; header=true)
         🎏_Sucessfull = convert(Vector{Bool}, Tables.getcolumn(MetaData, :🎏_Sucessfull))
         NameSentinel = convert(Vector{String}, Tables.getcolumn(MetaData, :Name))
         DateSentinel = convert(Vector{DateTime}, Tables.getcolumn(MetaData, :Date))

   # For every scene
   for (iSentinelData, iiSentinelData) =enumerate(NameSentinel)
      if 🎏_Sucessfull[iSentinelData]

         # Dates
            YearSentinel = Dates.year(DateSentinel[iSentinelData])
            MonthSentinel = Dates.month(DateSentinel[iSentinelData])
            DaySentinel = Dates.day(DateSentinel[iSentinelData])
               DateFormat  = YearSentinel * 10000 + MonthSentinel * 100 + DaySentinel

         # Paths of output
            NameOutput_Lai₁ = string(DateFormat) * "_" * NameOutput_Lai * ".tif"
            PathOutput_Lai₁ = joinpath(Path_SentinelBiophysical₁, NameOutput_Lai₁)
            PathOutput_Lai₁ = "D:/JOE/MAIN/MODELS/WFLOW/DATA/Timoleague/Sentinel/Biophysical/" * NameOutput_Lai₁

            NameOutput_Fapar₁ = string(DateFormat) * "_" * NameOutput_Fapar * ".tif"
            PathOutput_Fapar₁ = joinpath(Path_SentinelBiophysical₁, NameOutput_Fapar₁)
            PathOutput_Fapar₁ =  "D:/JOE/MAIN/MODELS/WFLOW/DATA/Timoleague/Sentinel/Biophysical/" * NameOutput_Fapar₁

            NameOutput_Ndvi₁ = string(DateFormat) * "_" * NameOutput_Ndvi * ".tif"
            PathOutput_Ndvi₁ = joinpath(Path_SentinelBiophysical₁, NameOutput_Ndvi₁)
            PathOutput_Ndvi₁ ="D:/JOE/MAIN/MODELS/WFLOW/DATA/Timoleague/Sentinel/Biophysical/" * NameOutput_Ndvi₁

            NameOutput_Fvc₁ = string(DateFormat) * "_" * NameOutput_Fvc * ".tif"
            PathOutput_Fvc₁ = joinpath(Path_SentinelBiophysical₁, NameOutput_Fvc₁)
            PathOutput_Fvc₁ = "D:/JOE/MAIN/MODELS/WFLOW/DATA/Timoleague/Sentinel/Biophysical/" * NameOutput_Fvc₁

            Path_CatchmentBoundary₁ = "D:/JOE/MAIN/MODELS/WFLOW/DATA/Timoleague/Boundary/CatchmentBoundary3.shp"

         # Naming of output in javascript format
         NameSentinel₁ = NameSentinel[iSentinelData]
            iFind = findfirst(".SAFE",NameSentinel₁)
            NameSentinel₁ = NameSentinel₁[1:(iFind[1]-1)]
            NameSentinel₁ = NameSentinel₁ * ".zip"
            println(NameSentinel₁)

         PathInput = "D:/JOE/MAIN/MODELS/WFLOW/DATA/Timoleague/Sentinel/DownloadSentinel/" * NameSentinel₁
         @assert isfile(PathInput)

   
         # D:\JOE\MAIN\MODELS\WFLOW\DATA\Timoleague\Sentinel\DownloadSentinel\S2C_MSIL2A_20251225T114521_N0511_R123_T29UNT_20251225T132609.zip

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
         # try
            RunSnap = `gpt $Path_SentinelXml₁ -e -p $PathProperties`
            run(RunSnap)
            printstyled("	======================= SUCESSFULL= $iiSentinelData =================== \n", color=:green)
         # catch
         #    printstyled("	======================= NOT SUCESSFULL= $iiSentinelData =================== \n", color=:red)
         # end

         # The .properties is no longer needed
         # rm(PathProperties)
      end # if 🎏_Sucessfull[iSentinelData]
   end # for iiSentinelData ∈ AllSentinelData
end # function RUN_SNAP()
# ------------------------------------------------------------------

end  # module: copernicus
# ............................................................