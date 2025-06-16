
module geoRaster
	 using Revise
	 using ArchGDAL
		  const AG = ArchGDAL
	 using Rasters, GeoTIFF, Extents, Geomorphometry
	 using Base
	using NCDatasets
	using CSV, DataFrames, GeoDataFrames, Rasters
	using CairoMakie, Colors, ColorSchemes

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
	#		FUNCTION : MASK
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function MASK(;Crs, Input, Lat, Lon, Mask, N_Height, N_Width)

				Output_Mask = Rasters.Raster((Lon, Lat), crs=Crs)

				for iX=1:N_Width
					for iY=1:N_Height
						if Mask[iX,iY] > 0
							Output_Mask[iX,iY] = Input[iX,iY]
						else
							Output_Mask[iX,iY] = NaN
						end
					end # for iY=1:Metadatas.N_Height
				end # for iX=1:Metadatas.N_Width

			return Output_Mask
			end  # function: mask
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LAT_LONG_2_iCOORD
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		using Rasters
		function LAT_LONG_2_iCOORD(;Map, OutletCoordinate)
         Longitude_X = OutletCoordinate[1]
         Latitude_Y  = OutletCoordinate[2]

         Longitude   = Rasters.lookup(Map, X)
         Latitude    = Rasters.lookup(Map, Y)

         Nlongitude     = length(Longitude)
         Nlatitude      = length(Latitude)

			# Longitude
				iLong = 0
				for i=1:Nlongitude
					if Longitude_X ≤ Longitude[i]
						break
					end
					iLong = i
				end # for i=1:Nlongitude

			# Latitude
				iLat = 0
				for i=Nlatitude:-1:1
					if Latitude[i] ≥ Latitude_Y
						break
					end # if Latitude_Sort[iLat] ≥ Lat_Y
					iLat = i
				end # i=1:Nlatitude

				println( "LAT_LONG_2_iCOORD:  Nlongitude= $Nlongitude iLongitude= $iLong Nlatitude= $Nlatitude iLatitude= $iLat" )

			return iLat, iLong, Latitude, Longitude, Nlatitude, Nlongitude
		  end
	 # ----------------------------------------------------------------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : LOOKUPTABLE_2_MAPS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	function LOOKUPTABLE_2_MAPS(;🎏_Plots, Crs, Dem_Resample_Mask, LookupTable, Path_InputGis, Path_InputLookuptable, Path_Root, Map_Shp, ΔX)

		# READING THE LOOKUP TABLE
			Path_LookupHydro = joinpath(Path_Root, Path_InputLookuptable, LookupTable)
			println(Path_LookupHydro)

			LookupHydro = DataFrames.DataFrame(CSV.File(Path_LookupHydro, header=true))

			# Cleaning the headers with only the variables of interest
				Header₀ = DataFrames.names(LookupHydro)
				Remove = .!(occursin.("CODE_CLASS", Header₀))
				Header₁  =  Header₀[Remove]
				Remove = .!(occursin.("CLASS", Header₁))
				Header  =  Header₁[Remove]

			# Creating a dictionary
				N_Class = length(LookupHydro[!,:CLASS])
				Class_Vector = 1:1:N_Class

				Dict_Class_2_Index = Dict(LookupHydro[!,:CLASS] .=> Class_Vector)

				println(LookupHydro[!,:CLASS])

		# READING THE SHAPEFILE
			Path_InputSoils = joinpath(Path_Root, Path_InputGis, Map_Shp)
			println(Path_InputSoils)

			SoilMap_Shapefile= GeoDataFrames.read(Path_InputSoils)

			# Creating new columns from the Lookup table
				for iiHeader in Header
					# Initializing a new column
					SoilMap_Shapefile[!, Symbol(iiHeader)] .= 1.0

					for (i, iiDrainage) in enumerate(SoilMap_Shapefile[!, :Drainage_C])
						if ismissing(iiDrainage)
							iiDrainage = "missing"
						end
						iClass = Dict_Class_2_Index[iiDrainage]
						SoilMap_Shapefile[!, Symbol(iiHeader)][i] = LookupHydro[!,iiHeader][iClass]
					end
				end

		# SAVING MAPS
			for iiHeader in Header
				SoilMap = Rasters.rasterize(last, SoilMap_Shapefile;  fill =Symbol(iiHeader), res=ΔX, to=Dem_Resample_Mask, missingval=NaN, crs=Crs, boundary=:center, shape=:polygon, progress=true, verbose=true)

				Path_Output = joinpath(Path_Root, Path_OutputWflow, iiHeader * ".tiff")
				Rasters.write(Path_Output, SoilMap; ext=".tiff", force=true, verbose=true)
				println(Path_Output)

			# Plotting the maps
				if 🎏_Plots

					include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\GeoPlot.jl")

					CairoMakie.activate!()
					Fig_13 =  CairoMakie.Figure()
					Axis_13 = CairoMakie.Axis(Fig_13[1, 1], title="Soil Map: $iiHeader", xlabel= L"$Latitude$", ylabel=L"$Longitude$",  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor)

					Map_13 = CairoMakie.heatmap!(Axis_13, SoilMap, colormap=:viridis)

					CairoMakie.Colorbar(Fig_13[1, 2], Map_13, label = iiHeader , width = 15, ticksize = 15, tickalign = 0.5)
					display(Fig_13)
				end
			end # for iiHeader in Header
	return nothing
	end  # function: LOOKUPTABLE_2_MAPS
	# ------------------------------------------------------------------



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