# =============================================================
#		module: copernicus
# =============================================================
module copernicus

using GeoDataFrames, Dates, SentinelExplorer, CSV

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : SENTINEL_DATA
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	function SENTINEL_DATA(; 🎏_DownloadTwiceMonth=false, Authenticate_Password="Joseph.pollacco1", Authenticate_Username="joseph.pollacco@teagasc.ie", CloudMax=100, Coordinate_LowerRight, Coordinate_UpperLeft, CopernicusDate_End, CopernicusDate_Start, Path_Sentinel, Product="L2A", Satelite="SENTINEL-2")

		CopernicusDate_StartDate = Dates.Date(CopernicusDate_Start[1], CopernicusDate_Start[2], CopernicusDate_Start[3])
		CopernicusDate_EndDate = Dates.Date(CopernicusDate_End[1], CopernicusDate_End[2], CopernicusDate_End[3])

		# Preparing metdata
			Date_Scene = []
			Name_Scene = []
			CloudCover_Scene = []

		# authenticate
			SentinelExplorer.authenticate(Authenticate_Username, Authenticate_Password)

		# Area of data
			Box = SentinelExplorer.BoundingBox(Coordinate_UpperLeft, Coordinate_LowerRight)

		# Dates for search
			if 🎏_DownloadTwiceMonth
				Nsplit = 2
			else
				Nsplit = 1
			end


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
function SENTINEL_SEARCH(; Box, CloudMax, CloudCover_Scene, Date_Scene, DateSearch, Name_Scene, Path_Sentinel, Product, Satelite)

	🎏_DataAvailable = true
	try
   	SearchMap = search(Satelite, dates=DateSearch, geom=Box, clouds=CloudMax, product=Product)
	catch
		🎏_DataAvailable = false
		printstyled("   ==== DATA NOT AVAILABLE for $DateSearch ==== /n"; color=:red)
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
		Date_Scene = push!(Date_Scene, Date_Scene₀)

   # OTHER METADATA
		Name_Scene = push!(Name_Scene, Scene.Name)
		CloudCover_Scene = append!(CloudCover_Scene, Scene.CloudCover)

   # DOWNLOAD FILE IF DOES NOT EXIST
		# Path to save removing the ".SAFE"
		PathFile = joinpath(Path_Sentinel, Scene.Name)
		iFind = findfirst(".SAFE", PathFile)
		PathFile = PathFile[1:(iFind[1]-1)]
		PathFile = PathFile * ".zip"

   if !(isfile(PathFile))
      printstyled(" ======  DOWNLOADING SENTINEL MAP: $(Date_Scene₀) ==== \n"; color=:green)
      # SentinelExplorer.download_scene(Scene.Name, Path_Sentinel; unzip=false, log_progress=false, access_token=nothing)
   else
      printstyled("      ==========  FILE ALREADY EXIST: $(PathFile) \n"; color=:yellow)
   end

   return Date_Scene, Name_Scene, CloudCover_Scene
end  # function: SENTINEL_SEARCH
# ------------------------------------------------------------------

end  # module: copernicus
# ............................................................