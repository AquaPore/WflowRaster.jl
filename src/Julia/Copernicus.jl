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
   function SENTINEL_DATA(;🎏_DownloadTwiceMonth=false, Authenticate_Password="Joseph.pollacco1", Authenticate_Username="joseph.pollacco@teagasc.ie", CloudMax=50, Coordinate_LowerRight, Coordinate_UpperLeft, CopernicusDate_End, CopernicusDate_Start, Path_SentinelDownload₁, Path_SentinelMetadata₁, Product="L2A", Satelite="SENTINEL-2", Filename_SentinelMetadata, FirstSecond=1)

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

                  🎏_Sucessfull, CloudCover_Scene, Date_Scene, Name_Scene = copernicus.SENTINEL_SEARCH(;🎏_Sucessfull, Box, CloudCover_Scene, CloudMax, Date_Scene, DateSearch, FirstSecond, Name_Scene, Path_SentinelDownload₁, Product, Satelite)

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
      try
         SearchMap = SentinelExplorer.search(Satelite, dates=DateSearch, geom=Box, clouds=CloudMax, product=Product)
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
               YearSentinel  = Dates.year(DateSentinel[i])
               MonthSentinel = Dates.month(DateSentinel[i])
               DaySentinel   = Dates.day(DateSentinel[i])
               DateFormat    = YearSentinel * 10000 + MonthSentinel * 100 + DaySentinel

            # Paths of output
               NameOutput_Lai₁   = string(DateFormat) * "_" * NameOutput_Lai * ".tif"
               PathOutput_Lai₁   = Path_SentinelBiophysical₁ * "/" * "LAI" * "/" *  NameOutput_Lai₁

               NameOutput_Fapar₁ = string(DateFormat) * "_" * NameOutput_Fapar * ".tif"
               PathOutput_Fapar₁ = Path_SentinelBiophysical₁ * "/" * "FAPAR"  * "/" * NameOutput_Fapar₁

               NameOutput_Ndvi₁  = string(DateFormat) * "_" * NameOutput_Ndvi * ".tif"
               PathOutput_Ndvi₁  = Path_SentinelBiophysical₁ * "/" * "NDVI" * "/" *  NameOutput_Ndvi₁

               NameOutput_Fvc₁   = string(DateFormat) * "_" * NameOutput_Fvc * ".tif"
               PathOutput_Fvc₁   = Path_SentinelBiophysical₁  * "/" * "FVC"  * "/" * NameOutput_Fvc₁

            # Naming of output in javascript format
               NameSentinel₁ = NameSentinel[i]
               iFind         = findfirst(".SAFE",NameSentinel₁)
               NameSentinel₁ = NameSentinel₁[1:(iFind[1]-1)]
               NameSentinel₁ = NameSentinel₁ * ".zip"
               println(NameSentinel₁)

               PathInput =  Path_SentinelDownload₁ * "/" * NameSentinel₁
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
      function WFLOW_LAI_FREECLOUD(;Path_SentinelMetadata₁, Dtm, Latitude, Longitude, Metadatas, NameOutput_Fapar="FAPAR", NameOutput_Fvc="FVC", NameOutput_Lai="LAI", NameOutput_Ndvi="NDVI", Path_SentinelBiophysical₁, Path_SentinelBiophysicalRemoveCloud, Subcatchment)

         MetaData      = CSV.read(Path_SentinelMetadata₁, DataFrame; header=true)
            🎏_Sucessfull = convert(Vector{Bool}, Tables.getcolumn(MetaData, :🎏_Sucessfull))
            DateSentinel  = convert(Vector{DateTime}, Tables.getcolumn(MetaData, :Date))
            CloudCover    = convert(Vector{Float64}, Tables.getcolumn(MetaData, :Cloud))

         # Selecting data
            N = sum(🎏_Sucessfull)
            DateSentinel = DateSentinel[🎏_Sucessfull]
            CloudCover = CloudCover[🎏_Sucessfull]

         Path_Lai      = fill("", N)
         YearSentinel  = zeros(Int64,N)
         MonthSentinel = zeros(Int64,N)
         DaySentinel   = zeros(Int64,N)


         for i = 1:N
            # Dates of output
               YearSentinel[i]  = Dates.year(DateSentinel[i])
               MonthSentinel[i] = Dates.month(DateSentinel[i])
               DaySentinel[i]   = Dates.day(DateSentinel[i])
               DateFormat    = YearSentinel[i] * 10000 + MonthSentinel[i] * 100 + DaySentinel[i]

               YearSentinel[i]  = Dates.year(DateSentinel[i])
               MonthSentinel[i] = Dates.month(DateSentinel[i])
               DaySentinel[i]   = Dates.day(DateSentinel[i])

            # Paths of output
               NameOutput_Lai₁   = string(DateFormat) * "_" * NameOutput_Lai * ".tif"

               Path_Lai[i]   = joinpath(Path_SentinelBiophysical₁, "LAI",  NameOutput_Lai₁)
               @assert isfile(Path_Lai[i])
         end # for iiSentinelData ∈ AllSentinelData

         ΔDays_21 = zeros(Int64,N)
         ΔDays_32 = zeros(Int64,N)

         for i = 2:N-1
            ΔDays_21[i] = Dates.days(DateSentinel[i] - DateSentinel[i-1])
            ΔDays_32[i] = Dates.days(DateSentinel[i+1] - DateSentinel[i])
         end


      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      #		FUNCTION : DISCRZETZATION
      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      function DISCRZETZATION(;Dtm, i, Latitude, Longitude, Metadatas, Method=:average, Path, Subcatchment, CloudCover)
         Lai₀ = Rasters.Raster(Path)

         Lai = Lai₀[Band(1)]
         Lai = Rasters.resample(Lai; to=Dtm, missingval=NaN, method=Method)
         Lai = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Lai, Latitude, Longitude, Mask=Subcatchment)

         Lai_CloudTrue =  Lai₀[Band(2)]
         Lai_CloudTrue = Rasters.resample(Lai_CloudTrue; to=Dtm, missingval=NaN, method=Method)
         Lai_CloudTrue = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Lai_CloudTrue, Latitude, Longitude, Mask=Subcatchment)

         # Filtering Flag=1
          for iX=1:Metadatas.N_Width
            for iY=1:Metadatas.N_Height
               if Lai_CloudTrue[iX,iY] == 1
                  Lai_CloudTrue[iX,iY] = 1::Int64
               else
                  Lai_CloudTrue[iX,iY] = NaN
               end
            end # for iY=1:Metadatas.N_Height
          end # for iX=1:Metadatas.N_Width

      return Lai, Lai_CloudTrue
      end  # function: DISCRZETZATION
      # ------------------------------------------------------------------

      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      #		FUNCTION : CORRECTION_CLOUD Lai_2
      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      function CORRECTION_CLOUD(;Lai_1, LaiCloudTrue_1, Lai_2, LaiCloudTrue_2, Lai_3, LaiCloudTrue_3)

      return
      end  # function: CORRECTION_CLOUD
      # ------------------------------------------------------------------


      Lai_1, LaiCloudTrue_1 = DISCRZETZATION(;Dtm, i=1, Latitude, Longitude, Metadatas, Path=Path_Lai[1], Subcatchment, CloudCover)
      Lai_2, LaiCloudTrue_2 = DISCRZETZATION(;Dtm, i=2, Latitude, Longitude, Metadatas, Path=Path_Lai[2], Subcatchment, CloudCover)

      for i = 2:10
         # Dates of output

         Lai_3, LaiCloudTrue_3 = DISCRZETZATION(;Dtm, i=i+1, Latitude, Longitude, Metadatas, Path=Path_Lai[i+1], Subcatchment, CloudCover)

         ΔLai_21 = Rasters.Raster((Longitude, Latitude); crs=Metadatas.Crs_GeoFormat, missingval=NaN)
         ΔLai_32 = Rasters.Raster((Longitude, Latitude); crs=Metadatas.Crs_GeoFormat, missingval=NaN)

         ΔLai_Treshold = 2
         for iX=1:Metadatas.N_Width
            for iY=1:Metadatas.N_Height
               if LaiCloudTrue_2[iX,iY] == 1
                  ΔLai_21[iX,iY] = abs(Lai_2[iX,iY] - Lai_1[iX,iY])
                  ΔLai_32[iX,iY] = abs(Lai_3[iX,iY] - Lai_2[iX,iY])

                  if ΔLai_21[iX,iY] < ΔLai_Treshold
                     ΔLai_21[iX,iY] = NaN
                  else
                     Lai_2[iX,iY] = Lai_1[iX,iY]
                  end

                  if ΔLai_32[iX,iY] < ΔLai_Treshold
                     ΔLai_32[iX,iY] = NaN
                  end
               else
                  ΔLai_21[iX,iY] = NaN
                  ΔLai_32[iX,iY] = NaN
               end
            end # for iY=1:Metadatas.N_Height
         end # for iX=1:Metadatas.N_Width



         if 🎏_Plots
            geoPlot.HEATMAP(;🎏_Colorbar=true, Input=Lai_2, Title="LAI Year=$(YearSentinel[i]) Month=$(MonthSentinel[i]), Cloud=$(CloudCover[i])", Label="Lai", colormap=:avocado, ColorReverse=true, Categorical=false)

            geoPlot.HEATMAP(;🎏_Colorbar=true, Input=LaiCloudTrue_2, Title="LaiCloudTrue Year=$(YearSentinel[i]) Month=$(MonthSentinel[i]), Cloud=$(CloudCover[i])", Label="Lai", colormap=:lighttest, ColorReverse=false, MinValue=0, MaxValue=1, Categorical=true)

            geoPlot.HEATMAP(;🎏_Colorbar=true, Input=ΔLai_21, Title="ΔLai_12 Year=$(YearSentinel[i]) Month=$(MonthSentinel[i]), Cloud=$(CloudCover[i])", Label="ΔLai_21", colormap=:avocado, ColorReverse=true, Categorical=false)

            geoPlot.HEATMAP(;🎏_Colorbar=true, Input=ΔLai_32, Title="ΔLai_23 Year=$(YearSentinel[i]) Month=$(MonthSentinel[i]), Cloud=$(CloudCover[i])", Label="ΔLai_32", colormap=:avocado, ColorReverse=true, Categorical=false)
         end

         # Perfornming the cycle
            Lai_1 = deepcopy(Lai_2)
            LaiCloudTrue_1 = deepcopy(LaiCloudTrue_2)

            Lai_2 = deepcopy(Lai_3)
            LaiCloudTrue_2 = deepcopy(LaiCloudTrue_3)

      end # for iiSentinelData ∈ AllSentinelData

   return nothing
   end  # function: REMOVING_CLOUDS
   # ------------------------------------------------------------------

end  # module: copernicus
# ............................................................