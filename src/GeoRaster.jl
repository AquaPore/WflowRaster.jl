
module geoRaster
	 using Revise
	 using ArchGDAL
		  const AG = ArchGDAL
	 using Rasters, GeoTIFF, Extents, Geomorphometry
	 using Base
	using NCDatasets

	 # using PythonCall

	 Base.@kwdef mutable struct METADATA
		  N_Width        :: Int64
		  N_Height       :: Int64
		  ΔX             :: Int64
		  ΔY             :: Int64
		  Coord_X_Left   :: Float64
		  Coord_X_Right  :: Float64
		  Coord_Y_Top    :: Float64
		  Coord_Y_Bottom :: Float64
		  Crs            :: Int64
		  Crs_GeoFormat
		  Bands          :: Int64
		  Extent
	 end # struct METADATA


	 """
		  Deriving metadata from the GeoTiff file
	 """
	 # ================================================================
	 #		FUNCTION : RASTER_METADATA
	 # ================================================================

	 	 include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\Parameters.jl")

		  function RASTER_METADATA(Path; Verbose=true)
				Grid = Rasters.Raster(Path, lazy=true)
					 N_Width = size(Grid, X)
					 N_Height = size(Grid, Y)
					 ΔX =  step(dims(Grid, X)) |> abs
					 ΔY =  step(dims(Grid, Y)) |> abs
					 Crs_Rasters = Rasters.crs(Grid)

					 Coord_X_Left   = first(dims(Grid, X))
					 Coord_X_Right  = last(dims(Grid, X))
					 Coord_Y_Top    = first(dims(Grid ,Y))
					 Coord_Y_Bottom = last(dims(Grid,Y))

						Extent = Extents.Extent(X=(Coord_X_Left, Coord_X_Right), Y=(Coord_Y_Bottom, Coord_Y_Top))

				# Grid_GeoTIFF = GeoTIFF.load(Path)
				#     Grid_GeoTIFF_Metadata = GeoTIFF.metadata(Grid_GeoTIFF)
						  #  Crs = GeoTIFF.epsgcode(Grid_GeoTIFF_Metadata) |>Int

				#  Crs=29902

				Crs_GeoFormat = GeoFormatTypes.convert(WellKnownText, EPSG(Crs))

				Grid_Ag = AG.readraster(Path)
					 Bands = AG.nraster(Grid_Ag)

				if Verbose
					 println(Path)
					 println("Bands = $Bands")
					 println("Crs = $Crs")
					 println("ΔX = $ΔX")
					 println("ΔY = $ΔY")
					 println("N_Width  = $N_Width")
					 println("N_Height = $N_Height")
					 println("Coord_X_Left = $Coord_X_Left, Coord_X_Right = $Coord_X_Right")
					 println("Coord_Y_Top = $Coord_Y_Top, Coord_Y_Bottom = $Coord_Y_Bottom")
				end

				Metadata = METADATA(N_Width, N_Height, ΔX, ΔY, Coord_X_Left, Coord_X_Right,Coord_Y_Top, Coord_Y_Bottom, Crs, Crs_GeoFormat, Bands, Extent)

		  return Metadata
		  end # function RASTER_METADATA
	 # ----------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LAT_LONG_2_iCOORD
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		using Rasters

		function LAT_LONG_2_iCOORD(;Map, OutletCoordinate)
         Longitude_X = OutletCoordinate[1]
         Latitude_Y  = OutletCoordinate[2]

         Longitude   = Rasters.lookup(Map, X)
         Latitude    = Rasters.lookup(Map, Y)

         Longitude_Sort = sort(Longitude)
         # println(Longitude_Sort[1:10])

			Latitude_Sort  = sort(Latitude)
         # println(Latitude_Sort[1:10])

         Nlongitude     = length(Longitude_Sort)
         Nlatitude      = length(Latitude_Sort)

			@assert Longitude_Sort[1] < Longitude_X < Longitude_Sort[end]
			@assert Latitude_Sort[1] < Latitude_Y <  Latitude_Sort[end]

			# Longitude
				iLong = 0
				for i=1:Nlongitude
					iLong += 1
					if Longitude_Sort[i] > Longitude_X
						break
					end
				end # for i=1:Nlongitude
				iLong -= 1

			# Latitude
				iLat = 0
				for i=1:Nlatitude
					iLat += 1
					if Latitude_Sort[iLat] > Latitude_Y
						break
					end # if Latitude_Sort[iLat] ≥ Lat_Y
				end # i=1:Nlatitude
				iLat -= 1

			return iLat, iLong, Latitude, Longitude
		  end
	 # ----------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : CONVERT_2_NETCDF(
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\Parameters.jl")
	 using NCDatasets

	 function TIFF_2_NETCDF(Ldd_Mask, Metadatas, River_Mask, River_Wflow, RiverDepth, RiverDepth_Wflow, RiverLength_Mask, RiverSlope, RiverSlope_Wflow, RiverWidth, RiverWidth_Wflow, Slope_Mask, Subcatch_Wflow, Subcatchment)

		  Path_NetCDF_Full  = joinpath(Path_Root, Path_NetCDF, NetCDF_Instates)

		  isfile(Path_NetCDF_Full) && rm(Path_NetCDF_Full, force=true)
		  println(Path_NetCDF_Full)

		  # Create a NetCDF file
				NetCDF = NCDatasets.NCDataset(Path_NetCDF_Full,"c")

		  # Define the dimension "x" and "y"
				NCDatasets.defDim(NetCDF,"x", Metadatas.N_Width)
				NCDatasets.defDim(NetCDF,"y", Metadatas.N_Height)

		  # Define a global attribute
				NetCDF.attrib["title"]   = "Timoleague instates dataset"
				NetCDF.attrib["creator"] = "Joseph A.P. POLLACCO"


		  # == LDD input ==========================================
				Keys = splitext(Ldd_Wflow)[1]
				Ldd_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

				Ldd_NetCDF .= Array(Ldd_Mask)

				Ldd_NetCDF.attrib["units"] = "1-9"
				Ldd_NetCDF.attrib["comments"] = "Derived from hydromt.flw.d8_from_dem"
				println(Keys)

		  # == SUBCATCHMENT input ==========================================
				Keys = splitext(Subcatch_Wflow)[1]
				Subcatchment_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int64, ("x","y"))

				Subcatchment_NetCDF .= Array(Subcatchment)

				Subcatchment_NetCDF.attrib["units"] = "true/false"
				Subcatchment_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


		  # == SLOPE input ==========================================
				Keys = splitext(Slope_Wflow)[1]
				Slope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

				Slope_NetCDF .= Array(Slope_Mask)

				Slope_NetCDF.attrib["units"] = "deg"
				Slope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


		  # == RIVER input ==========================================
				Keys = splitext(River_Wflow)[1]
				River_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

				River_NetCDF .= Array(River_Mask)

				River_NetCDF.attrib["units"] = "0/1"
				River_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


		  # == RIVER-SLOPE input ==========================================
		  		Keys = splitext(RiverSlope_Wflow)[1]

				  RiverSlope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

				  RiverSlope_NetCDF.= Array(RiverSlope)

				  RiverSlope_NetCDF.attrib["units"] = "Slope"
				  RiverSlope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


		  # == RIVER-LENGTH input ==========================================
		  		Keys = splitext(RiverLength_Wflow)[1]

				RiverLength_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

				RiverLength_NetCDF .= Array(RiverLength_Mask)

				RiverLength_NetCDF.attrib["units"] = "m"
				RiverLength_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


		# == RIVER-WIDTH input ==========================================
			Keys = splitext(RiverWidth_Wflow)[1]

			RiverWidth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

			RiverWidth_NetCDF .= Array(RiverWidth)

			RiverWidth_NetCDF.attrib["units"] = "m"
			RiverWidth_NetCDF.attrib["comments"] = "Derived from hydromt"
			println(Keys)


		# == RIVER-DEPTH input ==========================================
			Keys = splitext(RiverDepth_Wflow)[1]

			RiverDepth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"))

			RiverDepth_NetCDF .= Array(RiverDepth)

			RiverDepth_NetCDF.attrib["units"] = "m"
			RiverDepth_NetCDF.attrib["comments"] = "Derived from hydromt"
			println(Keys)

	 close(NetCDF)
	 return NetCDF, Path_NetCDF_Full
	 end  # function: TIFF_2_NETCDF
	 # ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIMESERIES_2_NetCDFmeteo
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\Parameters.jl")
		using NCDatasets, Dates, CSV, Tables

		function TIMESERIES_2_NETCDF(Metadatas, Subcatchment)

			# Reading dates
				Datewflow = DATES()
				Start_DateTime = Dates.DateTime.(Datewflow.Start_Year, Datewflow.Start_Month, Datewflow.Start_Day, Datewflow.Start_Hour)
				End_DateTime = Dates.DateTime.(Datewflow.End_Year, Datewflow.End_Month, Datewflow.End_Day, Datewflow.End_Hour)

				printstyled("Starting Dates = $Start_DateTime \n"; color=:green)
				printstyled("Ending Dates = $End_DateTime \n"; color =:green)

			# Read the CSV file
				Path_Input = joinpath(Path_Root, Path_InputForcing, Forcing_Input)
				println(Path_Input)

				Data₀      = CSV.File(Path_Input, header=true)

				Year       = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
				Month      = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
				Day        = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
				Hour       = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

				Time_Array = Dates.DateTime.(Year, Month, Day, Hour) #  <"standard"> "proleptic_gregorian" calendar

				# Selecting time which is between Start_DateTime and End_DateTime
					Nit  = length(Year)
					True = fill(false::Bool, Nit)
					for iT=1:Nit
						if (Start_DateTime ≤ Time_Array[iT] ≤ End_DateTime)
							True[iT] = true
						end
						if Time_Array[iT] > End_DateTime
							break
						end
					end # for iT=1:Nit

					Nit  = count(True[:])
					# println(Nit)
					printstyled("Number of time steps = $Nit \n"; color =:green)

					Precip     = convert(Vector{Float64}, Tables.getcolumn(Data₀, :precip))
					Pet        = convert(Vector{Float64}, Tables.getcolumn(Data₀, :pet))
					Temp       = convert(Vector{Float64}, Tables.getcolumn(Data₀, :temp))

				# Reducing the size of the time series
					Precip = Precip[True[:]]
					Pet = Pet[True[:]]
					Temp = Temp[True[:]]
					Time_Array = Time_Array[True[:]]

				# Create a 3D array for the time series
					 Precip_Array = fill(NaN::Float64, Metadatas.N_Width, Metadatas.N_Height, Nit)
					 Pet_Array    = fill(NaN::Float64, Metadatas.N_Width, Metadatas.N_Height, Nit)
					 Temp_Array   = fill(NaN::Float64, Metadatas.N_Width, Metadatas.N_Height, Nit)

					 # Transform the data to a 3D array
						Threads.@threads for iX=1:Metadatas.N_Width
							Threads.@threads for iY=1:Metadatas.N_Height

								if Subcatchment[iX,iY] == 1

									# Need to correct for upside down maps
									iYcor = Metadatas.N_Height - iY + 1

									Threads.@threads for iT=1:Nit
											Precip_Array[iX,iYcor,iT] = Precip[iT]
											Pet_Array[iX,iYcor,iT]    = Pet[iT]
											Temp_Array[iX,iYcor,iT]   = Temp[iT]
									end # Threads.@threads for iT=1:Nit

								end # if Subcatchment[iX,iY] == 1
							end # for iY=1:Metadatas.N_Height
						end # for iX=1:Metadatas.N_Width

		  # NETCDF
				Path_NetCDFmeteo_Output  = joinpath(Path_Root, Path_OutputTimeSeriesWflow, NetCDF_Forcing)
				isfile(Path_NetCDFmeteo_Output) && rm(Path_NetCDFmeteo_Output, force=true)
				println(Path_NetCDFmeteo_Output)

		  # Create a NetCDFmeteo file
				NetCDFmeteo = NCDatasets.NCDataset(Path_NetCDFmeteo_Output,"c")

		  # Define the dimension "x" and "y" and time
				NCDatasets.defDim(NetCDFmeteo,"x", Metadatas.N_Width)
				NCDatasets.defDim(NetCDFmeteo,"y", Metadatas.N_Height)
				NCDatasets.defDim(NetCDFmeteo,"time", Nit)

		  # Define a global attribute
				NetCDFmeteo.attrib["title"]   = "Timoleague climate dataset"
				NetCDFmeteo.attrib["creator"] = "Joseph A.P. POLLACCO"
				NetCDFmeteo.attrib["unit"]   = "mm"


		  # == time input ==========================================
		  	Keys = "time"
				println(Keys)

				Time_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Time_Array[1:Nit], ("time",), deflatelevel=9, shuffle=true)

				# Time_NetCDF[:] = Time_Array[1:Nit]

				# Time_NetCDF.attrib["units"] = "Dates.DateTime({Int64})"
				Time_NetCDF.attrib["calendar"] = "proleptic_gregorian"

		  # == Precipitation input ==========================================
				Keys = "precip"
				println(Keys)

				Precip_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Float64, ("x", "y", "time"))
				Precip_NetCDF[:,:,:] = Precip_Array

				Precip_NetCDF.attrib["units"] = "mm"
				Precip_NetCDF.attrib["comments"] = "precipitation"


		  # == Potential evapotranspiration input ==========================================
				Keys = "pet"
				println(Keys)

				Pet_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Float64, ("x", "y", "time"))
				Pet_NetCDF[:,:,:] = Pet_Array

				Pet_NetCDF.attrib["units"] = "mm"
				Pet_NetCDF.attrib["comments"] = "potential evapotranspiration"

		  # == Potential temperature input ==========================================
				Keys = "temp"
				println(Keys)

				Temp_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Float64, ("x", "y", "time"))
				Temp_NetCDF[:,:,:] = Temp_Array

				Temp_NetCDF.attrib["units"] = "mm"
				Temp_NetCDF.attrib["comments"] = "potential evapotranspiration"

		close(NetCDFmeteo)
		return NetCDFmeteo, Path_NetCDFmeteo_Output
		end  # function: TIMESERIES_2_NETCDF
	# ------------------------------------------------------------------



end #module geoRaster