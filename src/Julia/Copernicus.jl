# =============================================================
#		module: copernicus
# =============================================================
module copernicus

using GeoDataFrames, Dates, SentinelExplorer, CSV
using ZipFile


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : SENTINEL_DATA
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	function SENTINEL_DATA(; 🎏_DownloadTwiceMonth=false, Authenticate_Password="Joseph.pollacco1", Authenticate_Username="joseph.pollacco@teagasc.ie", CloudMax=50, Coordinate_LowerRight, Coordinate_UpperLeft, CopernicusDate_End, CopernicusDate_Start, Path_Sentinel, Product="L2A", Satelite="SENTINEL-2", PathBoundary)

		CopernicusDate_StartDate = Dates.Date(CopernicusDate_Start[1], CopernicusDate_Start[2], CopernicusDate_Start[3])
		CopernicusDate_EndDate = Dates.Date(CopernicusDate_End[1], CopernicusDate_End[2], CopernicusDate_End[3])

		# Preparing metdata
         Date_Scene       = []
         Name_Scene       = []
         CloudCover_Scene = []

		# authenticate
			SentinelExplorer.authenticate(Authenticate_Username, Authenticate_Password)

		# Area of data
			Box = SentinelExplorer.BoundingBox(Coordinate_UpperLeft, Coordinate_LowerRight)
			# Box = GeoDataFrames.read(PathBoundary).geometry |> first

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
                  DateSearch_End   = Dates.DateTime(iiYear, iiMonth, Day_End)

                  DateSearch       = (DateSearch_Start, DateSearch_End)

						# If dates are good
						if CopernicusDate_StartDate ≤ DateSearch_Start ≤ DateSearch_End ≤ CopernicusDate_EndDate

							Date_Scene, Name_Scene, CloudCover_Scene = copernicus.SENTINEL_SEARCH(; Box, CloudMax, CloudCover_Scene, Date_Scene, DateSearch, Name_Scene, Path_Sentinel, Product, Satelite)

							# Write to CSV
								Path_Sentinel₁ = joinpath(Path_Sentinel, "Metadata", "SentinelMetadata.csv")
								Header = ["Date", "Cloud", "Name"]
								CSV.write(Path_Sentinel₁, Tables.table([Date_Scene CloudCover_Scene Name_Scene]), writeheader=true, header=Header, bom=true)
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
	function SENTINEL_SEARCH(;Box, CloudMax, CloudCover_Scene, Date_Scene, DateSearch, Name_Scene, Path_Sentinel, Product, Satelite)

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
               PathFile = joinpath(Path_Sentinel, Scene.Name)
               iFind    = findfirst(".SAFE", PathFile)
               PathFile = PathFile[1:(iFind[1]-1)]
               PathFile = PathFile * ".zip"

			if !(isfile(PathFile))
				try
					printstyled(" ======  DOWNLOADING SENTINEL MAP: $(Date_Scene₀) ==== \n"; color=:green)
					SentinelExplorer.download_scene(Scene.Name, Path_Sentinel; unzip=false, log_progress=false, access_token=nothing)

					# # Test that the zip file is not corrupted
					# 	TestZipFile = ZipFile.Reader(Path_Sentinel)

					# METADATA
						Date_Scene = push!(Date_Scene, Date_Scene₀)
						Name_Scene = push!(Name_Scene, Scene.Name)
						CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)
				catch
					# Try again
					try
						SentinelExplorer.download_scene(Scene.Name, Path_Sentinel; unzip=false, log_progress=false, access_token=nothing)
						printstyled(" ======  2nd ATTEPT SUCESSFULL ==== \n"; color=:green)

						# METADATA
							Date_Scene = push!(Date_Scene, Date_Scene₀)
							Name_Scene = push!(Name_Scene, Scene.Name)
							CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)
					catch
						printstyled(" ======  NOT SUCSSFULL TO DOWNLOAD MAP ==== \n"; color=:red)
							Date_Scene = push!(Date_Scene, DateSearch[1])
							Name_Scene = push!(Name_Scene, -1111)
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
			Name_Scene = push!(Name_Scene, -9999)
			CloudCover_Scene = append!(CloudCover_Scene, -9999)
		end # if 🎏_DataAvailable

	return Date_Scene, Name_Scene, CloudCover_Scene
	end  # function: SENTINEL_SEARCH
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : RUN_SNAP
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	""" SNAP_LAI_FAPAR_NDVI_FVC

		Derives batch processing for deriving Lai, FAPAR, NDVI, FVC from sentinel data by using SNAP sofware
		* PathInput: path of all the .zip file of the .SAFE sentinel data
		* PathOutput: path of the output of Lai, FAPAR, NDVI, FVC
		* PathShapeFile: path of the shape file were the delimitation of the catchment
		* PathXml: path of the .xml file derived from SNAP software
		* PathProperties: this is a temporary path
	"""
	function SNAP_BATCH_LAI_FAPAR_NDVI_FVC(;PathInput, PathOutput, PathShapeFile, PathXml, PathProperties, NameOutput_Lai="LAI",NameOutput_Fapar="FAPAR",NameOutput_Ndvi="NDVI", NameOutput_Fvc="FVC")

      AllSentinelData = readdir(PathInput)
      AllSentinelData = sort!(AllSentinelData)

		# For every scene
	 for iiSentinelData ∈ AllSentinelData

			# Deriving dates from sentinel file name
            iFind        = findfirst("_", iiSentinelData)
            DateSentinel = iiSentinelData[iFind[1]+1:end]
            iFind        = findfirst("_", DateSentinel)
            DateSentinel = DateSentinel[iFind[1]+1:end]

            Year_Scene   = parse(Int64, DateSentinel[1:4])
            Month_Scene  = parse(Int64, DateSentinel[5:6])
            Day_Scene    = parse(Int64, DateSentinel[7:8])
            Hour_Scene   = parse(Int64, DateSentinel[10:11])
            DateFormat   = Year_Scene * 10000 + Month_Scene * 100 + Day_Scene

			# Paths of output
            NameOutput_Lai₁   = string(DateFormat) * "_" * NameOutput_Lai * ".tif"
            PathOutput_Lai₁   = joinpath(PathOutput, NameOutput_Lai₁)

            NameOutput_Fapar₁ = string(DateFormat) * "_" * NameOutput_Fapar * ".tif"
            PathOutput_Fapar₁ = joinpath(PathOutput, NameOutput_Fapar₁)

            NameOutput_Ndvi₁  = string(DateFormat) * "_" * NameOutput_Ndvi * ".tif"
            PathOutput_Ndvi₁  = joinpath(PathOutput, NameOutput_Ndvi₁)

            NameOutput_Fvc₁   = string(DateFormat) * "_" * NameOutput_Fvc * ".tif"
            PathOutput_Fvc₁   = joinpath(PathOutput, NameOutput_Fvc₁)

            PathInput₁        = joinpath(PathInput, iiSentinelData)

            PathProperties₁   = joinpath(PathProperties, "Parameters_" * string(DateFormat) * ".properties")

			# Saving the paths into .properties so gpt software can pick it up
				open(PathProperties₁,"w") do io
					println(io, "PathInput =  $PathInput₁")
					println(io, "PathOutput_Lai =  $PathOutput_Lai₁" )
					println(io, "PathOutput_Ndvi = $PathOutput_Ndvi₁" )
					println(io, "PathOutput_Fvc = $PathOutput_Fvc₁")
					println(io, "PathOutput_Fapar = $PathOutput_Fapar₁")
					println(io, "PathShapeFile =  $PathShapeFile")
				end

			# Run the command line
				try
					RunSnap = `gpt $PathXml -e -p $PathProperties₁`
					run(RunSnap)
					printstyled("	======================= SUCESSFULL= $iiSentinelData =================== \n", color=:green  )
				catch
					printstyled("	======================= NOT SUCESSFULL= $iiSentinelData =================== \n", color=:red  )
				end

			# The .properties is no longer needed
				rm(PathProperties₁)

		end # for iiSentinelData ∈ AllSentinelData
	end # function RUN_SNAP()
	# ------------------------------------------------------------------

end  # module: copernicus
# ............................................................