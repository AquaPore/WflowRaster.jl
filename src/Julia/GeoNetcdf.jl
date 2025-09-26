# =============================================================
#		module: geoNetcdf
# =============================================================
module geoNetcdf
	using NCDatasets, Dates, CSV, Tables
	include("Parameters.jl")
	include("PlotParameter.jl")

	using Rasters, GeoTIFF

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : CREATE_TRACKED_NETCDF
	#		DELTARES
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	"""
		For each netCDF file that will be opened for writing, store an entry in this Dict from the
		absolute path of the file to the NCDataset. This allows us to close the NCDataset if we try
		to create them twice in the same session, and thus providing a workaround for this issue:
		https://github.com/Alexander-Barth/NCDatasets.jl/issues/106

		Note that using this will prevent automatic garbage collection and thus closure of the
		NCDataset.
	"""
		const NC_HANDLES = Dict{String, NCDataset{Nothing}}()

		function CREATE_TRACKED_NETCDF(Path)
			abs_path = abspath(Path)
			# close existing NCDataset if it exists
			if haskey(NC_HANDLES, abs_path)
				# fine if it was already closed
				close(NC_HANDLES[abs_path])
			end
			# create directory if needed
			mkpath(dirname(Path))
			ds = NCDataset(Path, "c")
			NC_HANDLES[abs_path] = ds
			return ds
		end
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : NetCDF_2_GeoTIFF
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function NetCDF_2_GeoTIFF(Param_Crs, Data, iiKeys, Latitude, Longitude, Path_Output_GeoTIFF₀)

		Path_Output_GeoTIFF = joinpath(Path_Output_GeoTIFF₀, iiKeys ) *".tiff"
		println(Path_Output_GeoTIFF)

		N_Width, N_Height  = size(Data)
		@show N_Width, N_Height

		ΔX = (Longitude[end]- Longitude[1]) / (N_Width - 1)
		ΔY = (Latitude[end]- Latitude[1]) / (N_Height - 1)

		Longitude₁, Latitude₁ = Rasters.X(Longitude[1]:ΔX:Longitude[end], crs=Param_Crs), Rasters.Y(Latitude[1]:ΔY: Latitude[end],crs=Param_Crs)

		@show length(Longitude₁) length(Latitude₁)

		Map_GeoTIFF = Rasters.Raster((Longitude₁, Latitude₁), crs=Param_Crs)
		for iX=1:N_Width
			for iY=1:N_Height
			# println(Data[iX,iY])
				if !(ismissing(Data[iX,iY]))
					Map_GeoTIFF[iX,iY] = Data[iX,iY]
				else
					Map_GeoTIFF[iX,iY] = NaN
				end
			end # for iY=1:Metadatas.N_Height
		end # for iX=1:Metadatas.N_Width
		# return Output_Mask

		Rasters.write(Path_Output_GeoTIFF, Map_GeoTIFF ; ext = ".tiff" , missingval= NaN, force=true, verbose=true)

		return nothing
		end  # function: NetCDF_2_GeoTIFF
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIFF_2_NETCDF
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIFF_2_NETCDF(Gauge, Filename_Wflow_Impermable, Impermeable_Mask, Latitude, Ldd_Mask, Longitude, Metadatas, River_Mask, Filename_Wflow_Rivers, RiverDepth, Filename_Wflow_RiverDepth, RiverLength_Mask, RiverSlope, Filename_Wflow_RiverSlope, RiverWidth, Filename_Wflow_RiverWidth, Slope_Mask, Soil_Header, Soil_Maps, Filename_Wflow_Subcatchment, Subcatchment, Vegetation_Header, Vegetation_Maps; Float_type=Float32, Deflatelevel=0)

			# Path_NetCDF_Full  = joinpath(Path_Root_NetCDF, Filename_NetCDF_Instates)
			Path_NetCDF_Full  = joinpath(Path_Root, Path_NetCDF, Filename_NetCDF_Instates)

			isfile(Path_NetCDF_Full) && rm(Path_NetCDF_Full, force=true)
			println(Path_NetCDF_Full)

			# Create a NetCDF file
				# NetCDF = NCDatasets.NCDataset(Path_NetCDF_Full,"c")
				NetCDF = CREATE_TRACKED_NETCDF(Path_NetCDF_Full)

			# Define the dimension "x" and "y"
				NCDatasets.defDim(NetCDF,"x", Metadatas.N_Width)
				NCDatasets.defDim(NetCDF,"y", Metadatas.N_Height)

				N_soil_layer__thickness = length(soil_layer__thickness)
				NCDatasets.defDim(NetCDF,"layer", N_soil_layer__thickness + 1)

			# Define a global attribute
				NetCDF.attrib["title"]   = "Timoleague instates dataset"
				NetCDF.attrib["creator"] = "Joseph A.P. POLLACCO"

			# Fixing longitude and latitude
            Longitude₁ = Vector(Float64.(Longitude))
            Latitude₁  = Vector(Float64.(Latitude))

			# == LATITUDE_X input ==========================================
				Keys = "x"
				NCDatasets.defVar(NetCDF, "x", Longitude₁, ("x",); attrib = [
                "long_name" => "x coordinate of projection",
                "standard_name" => "projection_x_coordinate",
                "axis" => "X",
                "units" => "m",],
            deflatelevel = Deflatelevel, )
				println(Keys)

			# == lONGITUDE_Y input ==========================================
				Keys = "y"
				NCDatasets.defVar(NetCDF,"y", Latitude₁, ("y",);
            attrib = [
                "long_name" => "y coordinate of projection",
                "standard_name" => "projection_y_coordinate",
                "axis" => "Y",
                "units" => "m",],
            deflatelevel = Deflatelevel, )
				println(Keys)

			# == LAYER input ==========================================
				Keys = "layer"
				Layers = []
				for i=1:N_soil_layer__thickness + 1
					append!(Layers, i-1)
				end
				Layers = Int64.(Layers)
				Layer = NCDatasets.defVar(NetCDF, Keys, Layers, ("layer",), fillvalue=-1; deflatelevel = Deflatelevel, )

				Layer.attrib["units"] = "-"
				println(Keys)

			# == LDD input ==========================================
				Keys = splitext(Filename_Wflow_Ldd)[1]
				Ldd_NetCDF = NCDatasets.defVar(NetCDF, Keys, UInt8, ("x","y"), fillvalue=0; deflatelevel = Deflatelevel, )

				Ldd_NetCDF .= Array(Ldd_Mask)

				Ldd_NetCDF.attrib["units"] = "1-9"
				Ldd_NetCDF.attrib["comments"] = "Derived from hydromt.flw.d8_from_dem"
				Ldd_NetCDF.attrib["long_name"] = "ldd flow direction"
				println(Keys)

			# == SUBCATCHMENT input ==========================================
				Keys = splitext(Filename_Wflow_Subcatchment)[1]
				Subcatchment_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0; deflatelevel = Deflatelevel, )

				Subcatchment_NetCDF .= Array(Subcatchment)

				Subcatchment_NetCDF.attrib["units"] = "1/0"
				Subcatchment_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == GAUGES input ==========================================
				Keys = splitext(Filename_Wflow_Gauge)[1]
				Gauge_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0; deflatelevel = Deflatelevel, )

				Gauge_NetCDF .= Array(Gauge)

				Gauge_NetCDF.attrib["units"] = "1/0"
				Gauge_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == SLOPE input ==========================================
				Keys = splitext(Filename_Wflow_Slope)[1]
				Slope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

				Slope_NetCDF .= Array(Slope_Mask)

				Slope_NetCDF.attrib["units"] = "deg"
				Slope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER input ==========================================
				Keys = splitext(Filename_Wflow_Rivers)[1]
				River_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0; deflatelevel = Deflatelevel, )

				River_NetCDF .= Array(River_Mask)

				River_NetCDF.attrib["units"] = "0/1"
				River_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER-SLOPE input ==========================================
				Keys = splitext(Filename_Wflow_RiverSlope)[1]

				RiverSlope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

				RiverSlope_NetCDF.= Array(RiverSlope)

				RiverSlope_NetCDF.attrib["units"] = "Slope"
				RiverSlope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER-LENGTH input ==========================================
				Keys = splitext(Filename_Wflow_RiverLength)[1]

				RiverLength_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

				RiverLength_NetCDF .= Array(RiverLength_Mask)

				RiverLength_NetCDF.attrib["units"] = "m"
				RiverLength_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER-WIDTH input ==========================================
				Keys = splitext(Filename_Wflow_RiverWidth)[1]

				RiverWidth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

				RiverWidth_NetCDF .= Array(RiverWidth)

				RiverWidth_NetCDF.attrib["units"] = "m"
				RiverWidth_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER-DEPTH input ==========================================
				Keys = splitext(Filename_Wflow_RiverDepth)[1]

				RiverDepth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

				RiverDepth_NetCDF .= Array(RiverDepth)

				RiverDepth_NetCDF.attrib["units"] = "m"
				RiverDepth_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == IMPERMEABLE input ==========================================
				if 🎏_ImpermeableMap
					Keys = splitext(Filename_Wflow_Impermable)[1]
					Impermeable_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

					Impermeable_NetCDF .= Array(Impermeable_Mask)

					Impermeable_NetCDF.attrib["units"] = "Bool"
					Impermeable_NetCDF.attrib["comments"] = "Derived from roads"
					println(Keys)
				end

			# == SOIL MAPS input ==========================================
				if 🎏_SoilMap
				printstyled("==== SOIL MAPS ====\n"; color=:green)
					for (i, Keys) in enumerate(Soil_Header)

						Soil_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

						Soil_NetCDF .= Array(Soil_Maps[i])

						Soil_NetCDF.attrib["units"] = "$Keys"
						Soil_NetCDF.attrib["comments"] = "Derived from soil classification"
						println(Keys)
					end # for iiHeader in Soil_Header
				end

			# == VEGETATION MAPS input ==========================================
				if 🎏_VegetationMap
				printstyled("==== VEGETATION MAPS ====\n"; color=:green)
					for (i, Keys) in enumerate(Vegetation_Header)

						Vegetation_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN; deflatelevel = Deflatelevel, )

						Vegetation_NetCDF .= Array(Vegetation_Maps[i])

						Vegetation_NetCDF.attrib["units"] = "$Keys"
						Vegetation_NetCDF.attrib["comments"] = "Derived from vegetation classification"
						println(Keys)
					end # for iiHeader in Soil_Header
				end
		close(NetCDF)
		return NetCDF, Path_NetCDF_Full
		end  # function: TIFF_2_NETCDF
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIFF_2_NETCDF_B
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIFF_2_NETCDF_B(Gauge, Filename_Wflow_Impermable, Impermeable_Mask, Latitude, Ldd_Mask, Longitude, Metadatas, River_Mask, Filename_Wflow_Rivers, RiverDepth, Filename_Wflow_RiverDepth, RiverLength_Mask, RiverSlope, Filename_Wflow_RiverSlope, RiverWidth, Filename_Wflow_RiverWidth, Slope_Mask, Soil_Header, Soil_Maps, Filename_Wflow_Subcatchment, Subcatchment, Vegetation_Header, Vegetation_Maps)

			# Path_NetCDF_Full  = joinpath(Path_Root_NetCDF, Filename_NetCDF_Instates)
			Path_NetCDF_Full  = joinpath(Path_Root, Path_NetCDF, Filename_NetCDF_Instates)

			isfile(Path_NetCDF_Full) && rm(Path_NetCDF_Full, force=true)
			println(Path_NetCDF_Full)

			# Create a NetCDF file
				NetCDF = NCDatasets.NCDataset(Path_NetCDF_Full,"c")

			# Define the dimension "x" and "y"
				NCDatasets.defDim(NetCDF,"x", Metadatas.N_Width)
				NCDatasets.defDim(NetCDF,"y", Metadatas.N_Height)

				N_soil_layer__thickness = length(soil_layer__thickness)
				NCDatasets.defDim(NetCDF,"layer", N_soil_layer__thickness + 1)

			# Define a global attribute
				NetCDF.attrib["title"]   = "Timoleague instates dataset"
				NetCDF.attrib["creator"] = "Joseph A.P. POLLACCO"

			# Fixing longitude and latitude
            Longitude₁ = Vector(Float64.(Longitude))
            Latitude₁  = Vector(Float64.(Latitude))

			# == LONGITUDE input ==========================================
				Keys = "x"
				Longitude_NetCDF = NCDatasets.defVar(NetCDF, Keys, Longitude₁, ("x",))

				Longitude_NetCDF.attrib["units"] = "m"
				Longitude_NetCDF.attrib["comments"] = "lon"
				println(Keys)

			# == LATITUDE input ==========================================
				Keys = "y"
				Latitude_NetCDF = NCDatasets.defVar(NetCDF, Keys, Latitude₁,("y",), fillvalue=NaN)

				Latitude_NetCDF.attrib["units"] = "m"
				Latitude_NetCDF.attrib["comments"] = "lat"
				println(Keys)

			# == LATITUDE input ==========================================
				Keys = "lon"
				Longitude_NetCDF = NCDatasets.defVar(NetCDF, Keys, Longitude₁, ("x",), fillvalue=NaN)

				Longitude_NetCDF.attrib["units"] = "m"
				Longitude_NetCDF.attrib["comments"] = "lon"
				println(Keys)

			# == lONGITUDE input ==========================================
				Keys = "lat"
				Latitude_NetCDF = NCDatasets.defVar(NetCDF, Keys, Latitude₁,("y",), fillvalue=NaN)

				Latitude_NetCDF.attrib["units"] = "m"
				Latitude_NetCDF.attrib["comments"] = "lat"
				println(Keys)

			# == LAYER input ==========================================
				Keys = "layer"
				Layers = []
				for i=1:N_soil_layer__thickness + 1
					append!(Layers, i-1)
				end
				Layers = Int64.(Layers)
				Layer = NCDatasets.defVar(NetCDF, Keys, Layers, ("layer",), fillvalue=-1)

				Layer.attrib["units"] = "-"
				println(Keys)

			# == LDD input ==========================================
				Keys = splitext(Filename_Wflow_Ldd)[1]
				Ldd_NetCDF = NCDatasets.defVar(NetCDF, Keys, UInt8, ("x","y"), fillvalue=0)

				Ldd_NetCDF .= Array(Ldd_Mask)

				Ldd_NetCDF.attrib["units"] = "1-9"
				Ldd_NetCDF.attrib["comments"] = "Derived from hydromt.flw.d8_from_dem"
				Ldd_NetCDF.attrib["long_name"] = "ldd flow direction"
				println(Keys)

			# == SUBCATCHMENT input ==========================================
				Keys = splitext(Filename_Wflow_Subcatchment)[1]
				Subcatchment_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0)

				Subcatchment_NetCDF .= Array(Subcatchment)

				Subcatchment_NetCDF.attrib["units"] = "1/0"
				Subcatchment_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == GAUGES input ==========================================
				Keys = splitext(Filename_Wflow_Gauge)[1]
				Gauge_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0)

				Gauge_NetCDF .= Array(Gauge)

				Gauge_NetCDF.attrib["units"] = "1/0"
				Gauge_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == SLOPE input ==========================================
				Keys = splitext(Filename_Wflow_Slope)[1]
				Slope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				Slope_NetCDF .= Array(Slope_Mask)

				Slope_NetCDF.attrib["units"] = "deg"
				Slope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER input ==========================================
				Keys = splitext(Filename_Wflow_Rivers)[1]
				River_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0)

				River_NetCDF .= Array(River_Mask)

				River_NetCDF.attrib["units"] = "0/1"
				River_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == RIVER-SLOPE input ==========================================
				Keys = splitext(Filename_Wflow_RiverSlope)[1]

				RiverSlope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverSlope_NetCDF.= Array(RiverSlope)

				RiverSlope_NetCDF.attrib["units"] = "Slope"
				RiverSlope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-LENGTH input ==========================================
				Keys = splitext(Filename_Wflow_RiverLength)[1]

				RiverLength_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverLength_NetCDF .= Array(RiverLength_Mask)

				RiverLength_NetCDF.attrib["units"] = "m"
				RiverLength_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-WIDTH input ==========================================
				Keys = splitext(Filename_Wflow_RiverWidth)[1]

				RiverWidth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverWidth_NetCDF .= Array(RiverWidth)

				RiverWidth_NetCDF.attrib["units"] = "m"
				RiverWidth_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-DEPTH input ==========================================
				Keys = splitext(Filename_Wflow_RiverDepth)[1]

				RiverDepth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverDepth_NetCDF .= Array(RiverDepth)

				RiverDepth_NetCDF.attrib["units"] = "m"
				RiverDepth_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == IMPERMEABLE input ==========================================
				if 🎏_ImpermeableMap
					Keys = splitext(Filename_Wflow_Impermable)[1]
					Impermeable_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

					Impermeable_NetCDF .= Array(Impermeable_Mask)

					Impermeable_NetCDF.attrib["units"] = "Bool"
					Impermeable_NetCDF.attrib["comments"] = "Derived from roads"
					println(Keys)
				end

			# == SOIL MAPS input ==========================================
				if 🎏_SoilMap
				printstyled("==== SOIL MAPS ====\n"; color=:green)
					for (i, Keys) in enumerate(Soil_Header)

						Soil_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

						Soil_NetCDF .= Array(Soil_Maps[i])

						Soil_NetCDF.attrib["units"] = "$Keys"
						Soil_NetCDF.attrib["comments"] = "Derived from soil classification"
						println(Keys)
					end # for iiHeader in Soil_Header
				end

			# == VEGETATION MAPS input ==========================================
				if 🎏_VegetationMap
				printstyled("==== VEGETATION MAPS ====\n"; color=:green)
					for (i, Keys) in enumerate(Vegetation_Header)

						Vegetation_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

						Vegetation_NetCDF .= Array(Vegetation_Maps[i])

						Vegetation_NetCDF.attrib["units"] = "$Keys"
						Vegetation_NetCDF.attrib["comments"] = "Derived from vegetation classification"
						println(Keys)
					end # for iiHeader in Soil_Header
				end
		close(NetCDF)
		return NetCDF, Path_NetCDF_Full
		end  # function: TIFF_2_NETCDF
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIMESERIES_2_NETCDF
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIMESERIES_2_NETCDF(Latitude, Longitude, Metadatas, Subcatchment; Keys_Precip="precip", Keys_Pet="pet", Keys_Temp="temp", Float_type=Float32, Deflatelevel=0)

			Keys_Forcing = [Keys_Precip, Keys_Pet, Keys_Temp]

			# Reading dates
            Datewflow      = DATES()
            Start_DateTime = Dates.DateTime.(Datewflow.Start_Year, Datewflow.Start_Month, Datewflow.Start_Day, Datewflow.Start_Hour)
            End_DateTime   = Dates.DateTime.(Datewflow.End_Year, Datewflow.End_Month, Datewflow.End_Day, Datewflow.End_Hour)

				printstyled("Starting Dates = $Start_DateTime \n"; color=:green)
				printstyled("Ending Dates = $End_DateTime \n"; color =:green)

			# Read the CSV file
				Path_Input = joinpath(Path_Root, Path_Forcing, Filename_Input_Forcing)
				println(Path_Input)

				Data₀      = CSV.File(Path_Input, header=true)

				Year       = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
				Month      = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
				Day        = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
				Hour       = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

				Time_Array = Dates.DateTime.(Year, Month, Day, Hour) #  <"standard"> "proleptic_gregorian" calendar

			# Selecting time which is between Start_DateTime and End_DateTime
				Nit₀  = length(Year)
				True = fill(false::Bool, Nit₀)

				for iT=1:Nit₀
					if (Start_DateTime ≤ Time_Array[iT] ≤ End_DateTime)
						True[iT] = true
					end
					if Time_Array[iT] > End_DateTime
						break
					end
				end # for iT=1:Nit

				Nit  = count(True[:])
				printstyled("Number of time steps = $Nit \n"; color =:green)

				Precip     = convert(Vector{Float64}, Tables.getcolumn(Data₀, :precip))
				Pet        = convert(Vector{Float64}, Tables.getcolumn(Data₀, :pet))
				Temp       = convert(Vector{Float64}, Tables.getcolumn(Data₀, :temp))

			# Reducing the size of the time series
            Precip     = Precip[True[:]]
            Pet        = Pet[True[:]]
            Temp       = Temp[True[:]]
            Time_Array = Time_Array[True[:]]

			# Create a 3D array for the time series
				Precip_Array_iT = fill(NaN, Metadatas.N_Width, Metadatas.N_Height)
				Pet_Array_iT    = fill(NaN, Metadatas.N_Width, Metadatas.N_Height)
				Temp_Array_iT   = fill(NaN, Metadatas.N_Width, Metadatas.N_Height)

			# Netcdf
				Path_NetCDFmeteo_Output  = joinpath(Path_Root, Path_TimeSeriesWflow, Filename_NetCDF_Forcing)
				isfile(Path_NetCDFmeteo_Output) && rm(Path_NetCDFmeteo_Output, force=true)
				println(Path_NetCDFmeteo_Output)

			# Create a NetCDFmeteo file
				# NetCDFmeteo = NCDatasets.NCDataset(Path_NetCDFmeteo_Output,"c")
				NetCDFmeteo = CREATE_TRACKED_NETCDF(Path_NetCDFmeteo_Output)

			# Define the dimension "x" and "y" and time
				NCDatasets.defDim(NetCDFmeteo,"time", Nit)
				NCDatasets.defDim(NetCDFmeteo,"y", Metadatas.N_Height)
				NCDatasets.defDim(NetCDFmeteo,"x", Metadatas.N_Width)

			# Define a global attribute
				NetCDFmeteo.attrib["title"]   = "climate dataset"
				NetCDFmeteo.attrib["creator"] = "Joseph A.P. POLLACCO"
				NetCDFmeteo.attrib["units"]   = "mm"
				NetCDFmeteo.attrib["crs"]   = string(Metadatas.Crs_GeoFormat)

			# Fixing longitude and latitude
            Longitude₁ = Vector(Float64.(Longitude))
            Latitude₁  = Vector(Float64.(Latitude))

			# == LATITUDE_X input ==========================================
				Keys = "x"
				NCDatasets.defVar(NetCDFmeteo, "x", Longitude₁, ("x",); attrib = [
                "long_name" => "x coordinate of projection",
                "standard_name" => "projection_x_coordinate",
                "axis" => "X",
                "units" => "m",],
            deflatelevel = Deflatelevel, )
				println(Keys)

			# == lONGITUDE_Y input ==========================================
				Keys = "y"
				NCDatasets.defVar(NetCDFmeteo,"y", Latitude₁, ("y",);
            attrib = [
                "long_name" => "y coordinate of projection",
                "standard_name" => "projection_y_coordinate",
                "axis" => "Y",
                "units" => "m",],
            deflatelevel = Deflatelevel, )
				println(Keys)

			# == TIME input ==========================================
				Keys = "time"
				NCDatasets.defVar(NetCDFmeteo, Keys, Time_Array[1:Nit], ("time",); deflatelevel=Deflatelevel, )
				println(Keys)

			# == Climate input ==========================================
				for iKey ∈ Keys_Forcing
				    NCDatasets.defVar(NetCDFmeteo, iKey, Float_type, ("x", "y", "time"); attrib = ["_FillValue" => Float_type(NaN)], deflatelevel = Deflatelevel, )
				end

			# == Data -> 2D array
				for iT=1:Nit
					Threads.@threads for iX=1:Metadatas.N_Width
						Threads.@threads for iY=1:Metadatas.N_Height
							if Subcatchment[iX,iY] == 1
								Precip_Array_iT[iX,iY] = Precip[iT]
								Pet_Array_iT[iX,iY]    = Pet[iT]
								Temp_Array_iT[iX,iY]   = Temp[iT]
							end # if Subcatchment[iX,iY] == 1
						end # for iY=1:Metadatas.N_Height
					end # for iX=1:Metadatas.N_Width

					for iKey ∈ Keys_Forcing
						NetCDFmeteo[iKey][:,:,iT] = Precip_Array_iT
					end
				end #for iT=1:Nit

		close(NetCDFmeteo)
		println(Keys_Forcing)
		println("========== FINISHED ======================")
		return NetCDFmeteo, Path_NetCDFmeteo_Output
		end  # function: TIMESERIES_2_NETCDF
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIMESERIES_2_NetCDFmeteo
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIMESERIES_2_NETCDF_B(Latitude, Longitude, Metadatas, Subcatchment)
			# Reading dates
				Datewflow = DATES()
				Start_DateTime = Dates.DateTime.(Datewflow.Start_Year, Datewflow.Start_Month, Datewflow.Start_Day, Datewflow.Start_Hour)
				End_DateTime = Dates.DateTime.(Datewflow.End_Year, Datewflow.End_Month, Datewflow.End_Day, Datewflow.End_Hour)

				printstyled("Starting Dates = $Start_DateTime \n"; color=:green)
				printstyled("Ending Dates = $End_DateTime \n"; color =:green)

			# Read the CSV file
				Path_Input = joinpath(Path_Root, Path_Forcing, Filename_Input_Forcing)
				println(Path_Input)

				Data₀      = CSV.File(Path_Input, header=true)

				Year       = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
				Month      = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
				Day        = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
				Hour       = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

				Time_Array = Dates.DateTime.(Year, Month, Day, Hour) #  <"standard"> "proleptic_gregorian" calendar

			# Selecting time which is between Start_DateTime and End_DateTime
				Nit₀  = length(Year)
				True = fill(false::Bool, Nit₀)

				for iT=1:Nit₀
					if (Start_DateTime ≤ Time_Array[iT] ≤ End_DateTime)
						True[iT] = true
					end
					if Time_Array[iT] > End_DateTime
						break
					end
				end # for iT=1:Nit

				Nit  = count(True[:])

				printstyled("Number of time steps = $Nit \n"; color =:green)

				Precip     = convert(Vector{Float64}, Tables.getcolumn(Data₀, :precip))
				Pet        = convert(Vector{Float64}, Tables.getcolumn(Data₀, :pet))
				Temp       = convert(Vector{Float64}, Tables.getcolumn(Data₀, :temp))

			# Reducing the size of the time series
            Precip     = Precip[True[:]]
            Pet        = Pet[True[:]]
            Temp       = Temp[True[:]]
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
							# iYcor = Metadatas.N_Height - iY + 1
							iYcor = iY

							Threads.@threads for iT=1:Nit
								Precip_Array[iX,iYcor,iT] = Precip[iT]
								Pet_Array[iX,iYcor,iT]    = Pet[iT]
								Temp_Array[iX,iYcor,iT]   = Temp[iT]
							end # Threads.@threads for iT=1:Nit

						end # if Subcatchment[iX,iY] == 1
					end # for iY=1:Metadatas.N_Height
				end # for iX=1:Metadatas.N_Width

			# NETCDF
				Path_NetCDFmeteo_Output  = joinpath(Path_Root, Path_NetCDF, Filename_NetCDF_Forcing)
				isfile(Path_NetCDFmeteo_Output) && rm(Path_NetCDFmeteo_Output, force=true)
				println(Path_NetCDFmeteo_Output)

			# Create a NetCDFmeteo file
				NetCDFmeteo = NCDatasets.NCDataset(Path_NetCDFmeteo_Output,"c")

			# Define the dimension "x" and "y" and time
				NCDatasets.defDim(NetCDFmeteo,"time", Nit)
				NCDatasets.defDim(NetCDFmeteo,"y", Metadatas.N_Height)
				NCDatasets.defDim(NetCDFmeteo,"x", Metadatas.N_Width)

			# Define a global attribute
				NetCDFmeteo.attrib["title"]   = "Timoleague climate dataset"
				NetCDFmeteo.attrib["creator"] = "Joseph A.P. POLLACCO"
				NetCDFmeteo.attrib["units"]   = "mm"
				NetCDFmeteo.attrib["crs"]   = string(Metadatas.Crs_GeoFormat)

			# Fixing longitude and latitude
            Longitude₁ = Vector(Float64.(Longitude))
            Latitude₁  = Vector(Float64.(Latitude))

			# == LATITUDE input ==========================================
				Keys = "lon"
				Longitude_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Longitude₁, ("x",))

				Longitude_NetCDF.attrib["units"] = "m"
				Longitude_NetCDF.attrib["comments"] = "Longitude"
				println(Keys)

			# == lONGITUDE input ==========================================
				Keys = "lat"
				Latitude_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Latitude₁,("y",))

				Latitude_NetCDF.attrib["units"] = "m"
				Latitude_NetCDF.attrib["comments"] = "Latitude₁"
				println(Keys)

			# == time input ==========================================
				Keys = "time"
				Time_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Time_Array[1:Nit], ("time",), deflatelevel=9, shuffle=true, fillvalue=NaN)

				# Time_NetCDF[:] = Time_Array[1:Nit]
				# Time_NetCDF.attrib["units"] = "Dates.DateTime({Int64})"
				Time_NetCDF.attrib["calendar"] = "proleptic_gregorian"
				println(Keys)

			# == LATITUDE input ==========================================
				Keys = "x"

				Longitude_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Longitude₁, ("x",), deflatelevel=9, shuffle=true, fillvalue=NaN)

				Longitude_NetCDF.attrib["units"] = "m"
				Longitude_NetCDF.attrib["comments"] = "lon"
				println(Keys)

			# == lONGITUDE input ==========================================
				Keys = "y"
				Latitude_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Latitude₁,("y",))

				Latitude_NetCDF.attrib["units"] = "m"
				Latitude_NetCDF.attrib["comments"] = "lat"
				println(Keys)


			# == Precipitation input ==========================================
				Keys = "precip"
				println(Keys)

				Precip_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Float32, ("x", "y", "time"), deflatelevel=9, shuffle=true, fillvalue=NaN)
				Precip_NetCDF[:,:,:] = Precip_Array

				Precip_NetCDF.attrib["unit"] = "mm"
				Precip_NetCDF.attrib["comments"] = "precipitation"


			# == Potential evapotranspiration input ==========================================
				Keys = "pet"
				println(Keys)

				Pet_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys, Float32, ("x", "y", "time"), deflatelevel=9, shuffle=true, fillvalue=NaN)
				Pet_NetCDF[:,:,:] = Pet_Array

				Pet_NetCDF.attrib["unit"] = "mm"
				Pet_NetCDF.attrib["comments"] = "potential evapotranspiration"

			# == Potential temperature input ==========================================
				Keys_Temp = "temp"
				println(Keys)

				Temp_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys_Temp, Float32, ("x", "y", "time"), deflatelevel=9, shuffle=true, fillvalue=NaN)
				Temp_NetCDF[:,:,:] = Temp_Array

				Temp_NetCDF.attrib["unit"] = " degree C."
				Temp_NetCDF.attrib["comments"] = "Temperature"

			close(NetCDFmeteo)

		return NetCDFmeteo, Path_NetCDFmeteo_Output
		end  # function: TIMESERIES_2_NETCDF
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : COPYPASTE_LARTGE_FILES
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		""" stevengj """
# function mycp(src::AbstractString, dst::AbstractString; force::Bool=false)
#     cmd = Sys.iswindows() ? `copy` : `cp`
#     force_option = Sys.iswindows() ? (force ? `/y` : `/-y`) : (force ? `-f` : `-n`)
#     cmd = `$cmd $force_option`
#     run(`$cmd $src $dst`)
# end
	function COPYPASTE_LARGE_FILES(;Path_Copy, Path_Paste, Force=true)
		@assert isfile(Path_Copy)
		isfile(Path_Paste) && rm(Path_Paste, force=true)

		cmd = Sys.iswindows() ? `copy` : `cp`
		force_option = Sys.iswindows() ? (Force ? `/y` : `/-y`) : (Force ? `-f` : `-n`)
		cmd = `$cmd $force_option`
		run(`$cmd $Path_Copy $Path_Paste`)
	end
end  # module: geoNetcdf
# ............................................................