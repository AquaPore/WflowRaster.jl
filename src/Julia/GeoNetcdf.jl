# =============================================================
#		module: geoNetcdf
# =============================================================
module geoNetcdf
	using NCDatasets, Dates, CSV, Tables
	include("Parameters.jl")
	include("PlotParameter.jl")

	using Rasters, GeoTIFF

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

		return
		end  # function: NetCDF_2_GeoTIFF
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : CONVERT_2_NETCDF
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIFF_2_NETCDF(Gauge, Impermable_Wflow, Impermeable_Mask, Latitude, Ldd_Mask, Longitude, Metadatas, River_Mask, River_Wflow, RiverDepth, RiverDepth_Wflow, RiverLength_Mask, RiverSlope, RiverSlope_Wflow, RiverWidth, RiverWidth_Wflow, Slope_Mask, Soil_Header, Soil_Maps, Subcatch_Wflow, Subcatchment, Vegetation_Header, Vegetation_Maps)

			Path_NetCDF_Full  = joinpath(Path_Root_NetCDF, NetCDF_Instates)

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

			# == LDD input ==========================================
				Keys = splitext(Ldd_Wflow)[1]
				Ldd_NetCDF = NCDatasets.defVar(NetCDF, Keys, UInt8, ("x","y"), fillvalue=0)

				Ldd_NetCDF .= Array(Ldd_Mask)

				Ldd_NetCDF.attrib["units"] = "1-9"
				Ldd_NetCDF.attrib["comments"] = "Derived from hydromt.flw.d8_from_dem"
				Ldd_NetCDF.attrib["long_name"] = "ldd flow direction"
				println(Keys)

			# == SUBCATCHMENT input ==========================================
				Keys = splitext(Subcatch_Wflow)[1]
				Subcatchment_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0)

				Subcatchment_NetCDF .= Array(Subcatchment)

				Subcatchment_NetCDF.attrib["units"] = "1/0"
				Subcatchment_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)

			# == GAUGES input ==========================================
				Keys = splitext(Gauge_Wflow)[1]
				Gauge_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0)

				Gauge_NetCDF .= Array(Gauge)

				Gauge_NetCDF.attrib["units"] = "1/0"
				Gauge_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == SLOPE input ==========================================
				Keys = splitext(Slope_Wflow)[1]
				Slope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				Slope_NetCDF .= Array(Slope_Mask)

				Slope_NetCDF.attrib["units"] = "deg"
				Slope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER input ==========================================
				Keys = splitext(River_Wflow)[1]
				River_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int32, ("x","y"), fillvalue=0)

				River_NetCDF .= Array(River_Mask)

				River_NetCDF.attrib["units"] = "0/1"
				River_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-SLOPE input ==========================================
				Keys = splitext(RiverSlope_Wflow)[1]

				RiverSlope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverSlope_NetCDF.= Array(RiverSlope)

				RiverSlope_NetCDF.attrib["units"] = "Slope"
				RiverSlope_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-LENGTH input ==========================================
				Keys = splitext(RiverLength_Wflow)[1]

				RiverLength_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverLength_NetCDF .= Array(RiverLength_Mask)

				RiverLength_NetCDF.attrib["units"] = "m"
				RiverLength_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-WIDTH input ==========================================
				Keys = splitext(RiverWidth_Wflow)[1]

				RiverWidth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverWidth_NetCDF .= Array(RiverWidth)

				RiverWidth_NetCDF.attrib["units"] = "m"
				RiverWidth_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == RIVER-DEPTH input ==========================================
				Keys = splitext(RiverDepth_Wflow)[1]

				RiverDepth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("x","y"), fillvalue=NaN)

				RiverDepth_NetCDF .= Array(RiverDepth)

				RiverDepth_NetCDF.attrib["units"] = "m"
				RiverDepth_NetCDF.attrib["comments"] = "Derived from hydromt"
				println(Keys)


			# == IMPERMEABLE input ==========================================
				if 🎏_ImpermeableMap
					Keys = splitext(Impermable_Wflow)[1]
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
	#		FUNCTION : TIMESERIES_2_NetCDFmeteo
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIMESERIES_2_NETCDF(Latitude, Longitude, Metadatas, Subcatchment)
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
				Path_NetCDFmeteo_Output  = joinpath(Path_Root_NetCDF, NetCDF_Forcing)
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
	#		FUNCTION : TIMESERIES_2_NetCDFmeteo
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIMESERIES_2_NETCDF_B(Metadatas, Subcatchment; Keys_Precip="precip", Keys_Pet="pet", Keys_Temp="temp", Keys_Time="time" )

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
				Precip_Array_iT = fill(NaN::Float64, Metadatas.N_Width, Metadatas.N_Height)
				Pet_Array_iT    = fill(NaN::Float64, Metadatas.N_Width, Metadatas.N_Height)
				Temp_Array_iT   = fill(NaN::Float64, Metadatas.N_Width, Metadatas.N_Height)

			# Netcdf
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
				NetCDFmeteo.attrib["units"]   = "mm"
				NetCDFmeteo.attrib["crs"]   = string(Metadatas.Crs_GeoFormat)

			# == time input ==========================================
				Time_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys_Time, Time_Array[1:Nit], ("time",))
				Time_NetCDF.attrib["calendar"] = "proleptic_gregorian"

			# == Precipitation input ==========================================
				Precip_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys_Precip, Float32, ("x", "y", "time"), deflatelevel=9, shuffle=true, fillvalue=NaN)
					Precip_NetCDF.attrib["unit"] = "mm"
					Precip_NetCDF.attrib["comments"] = "precipitation"

			# == Potential evapotranspiration input ==========================================
				Pet_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys_Pet, Float32, ("x", "y", "time"), deflatelevel=9, shuffle=true, fillvalue=NaN)
					Pet_NetCDF.attrib["unit"] = "mm"
					Pet_NetCDF.attrib["comments"] = "potential evapotranspiration"

			# == temperature input ==========================================
				Temp_NetCDF = NCDatasets.defVar(NetCDFmeteo, Keys_Temp, Float32, ("x", "y", "time"), deflatelevel=9, shuffle=true, fillvalue=NaN)
					Temp_NetCDF.attrib["unit"] = " degree C."
					Temp_NetCDF.attrib["comments"] = "Temperature"

			# Transform the data to a 3D array
				for iT=1:Nit
					for iX=1:Metadatas.N_Width
						for iY=1:Metadatas.N_Height
							if Subcatchment[iX,iY] == 1
								Precip_Array_iT[iX,iY] = Precip[iT]
								Pet_Array_iT[iX,iY]    = Pet[iT]
								Temp_Array_iT[iX,iY]   = Temp[iT]
							else
								Precip_Array_iT[iX,iY] = NaN
								Pet_Array_iT[iX,iY]    = NaN
								Temp_Array_iT[iX,iY]   = NaN
							end # if Subcatchment[iX,iY] == 1
						end # for iY=1:Metadatas.N_Height
					end # for iX=1:Metadatas.N_Width

					Precip_NetCDF[:,:,iT] = Precip_Array_iT
					Pet_NetCDF[:,:,iT] = Pet_Array_iT
					Temp_NetCDF[:,:,iT] = Temp_Array_iT
				end #for iT=1:Nit

		close(NetCDFmeteo)
		return NetCDFmeteo, Path_NetCDFmeteo_Output
		end  # function: TIMESERIES_2_NETCDF
	# ------------------------------------------------------------------

end  # module: geoNetcdf
# ............................................................