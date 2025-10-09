module geoLookuptable
	using CSV, DataFrames, GeoDataFrames, Rasters, Revise, GeometryOps, GeoFormatTypes
# 	import GeoInterface as GI

# Crs_Input = GI.crs(Map)


	include("Parameters.jl")
	include("GeoPlot.jl")
	include("PlotParameter.jl")
	include("GeoRaster.jl")

	export LOOKUPTABLE_2_MAPS

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LOOKUPTABLE_2_MAPS
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function LOOKUPTABLE_2_MAPS(;🎏_Plots, Colormap=:viridis, Param_Crs, Dem_Resample, Latitude, Longitude, LookupTable, Map_Shp, Map_Value, Metadatas, Path_Gis, Path_Root, Path_Root_LookupTable, Subcatchment, TitleMap, ΔX, Missingval=NaN, 🎏_Progress=false, Crs_Input=Param_Crs)

			# READING THE LOOKUP TABLE
				Path_Home = @__DIR__
				cd(Path_Home)
				Path₀ = abspath(joinpath(Path_Home, ".."))
				Path = abspath(joinpath(Path₀, ".."))
 				Path_Lookup = joinpath(Path, Path_Root_LookupTable, LookupTable)
				println(Path_Lookup)

				Lookup = DataFrames.DataFrame(CSV.File(Path_Lookup, header=true))

				# Cleaning the headers with only the variables of interest
					Header₀ = DataFrames.names(Lookup)
					Remove = .!(occursin.("NO", Header₀))
					Header₁  =  Header₀[Remove]
					Remove = .!(occursin.("DESCRIPTION", Header₁))
					Header₂  =  Header₁[Remove]
					Remove = .!(occursin.("CLASS", Header₂))
					Header  =  Header₂[Remove]

				# Creating a dictionary
					N_Class = length(Lookup[!,:CLASS])
					Class_Vector = 1:1:N_Class
					Dict_Class_2_Index = Dict(Lookup[!,:CLASS] .=> Class_Vector)
					println(Lookup[!,:CLASS])

			# READING THE SHAPEFILE
				Path_Input = joinpath(Path_Root, Path_Gis, Map_Shp)

				Map = GeoDataFrames.read(Path_Input)
				println(Path_Input)

				# Reproject if not in the correct CRS
					# if Param_Crs ≠ Crs_Input
					# 	@info  "Reprojecting the map fron CRS=$(Crs_Input) to CRS=$(Param_Crs)"

                  # Param_CrsInput_GeoFormat  = GeoFormatTypes.convert(WellKnownText, EPSG(Crs_Input))
                  # Param_CrsOutput_GeoFormat = GeoFormatTypes.convert(WellKnownText, EPSG(Param_Crs))

					#  	Map = GeometryOps.reproject(Map; source_crs=EPSG(Param_CrsInput_GeoFormat), target_crs=EPSG(Param_CrsOutput_GeoFormat))
					# end

				# Creating new columns from the Lookup table
					for iiHeader in Header
						println(iiHeader)
						# Initializing a new column
						Map[!, Symbol(iiHeader)] .= 1.0

						for (i, iiDrainage) in enumerate(Map[!, Map_Value])
							if ismissing(iiDrainage)
								iiDrainage = "missing"
							end
							iClass = Dict_Class_2_Index[iiDrainage]
							Map[!, Symbol(iiHeader)][i] = Lookup[!,iiHeader][iClass]
						end
					end

			# SAVING MAPS
				Maps_Output = []
				for iiHeader in Header
					Map₁ = Rasters.rasterize(last, Map;  fill=Symbol(iiHeader), res=ΔX, to=Dem_Resample, missingval=Missingval, crs=Param_Crs, boundary=:center, shape=:polygon, progress=🎏_Progress, verbose=false)

						Map = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Map₁, Latitude, Longitude, Mask=Subcatchment)

						Maps_Output = push!(Maps_Output, Map)

					Path_Output = joinpath(Path_Root, Path_Wflow, iiHeader * ".tiff")
						Rasters.write(Path_Output, Map; ext=".tiff", force=true, verbose=false)
						println(Path_Output)

					# Plotting the maps
					if 🎏_Plots
						geoPlot.HEATMAP(;🎏_Colorbar=true, Input=Map, Label="$iiHeader", Title="$TitleMap : $iiHeader", titlecolor=titlecolor,  titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=Colormap)
					end
				end # for iiHeader in Header

			Dict_Class_2_Index = Lookup = empty

		return Header, Maps_Output
		end  # function: LOOKUPTABLE_2_MAPS
	# ------------------------------------------------------------------



	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LOOKUPTABLE_2_MAPS
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function LOOKUPTABLE_2_MAPS_B(;🎏_Plots, Colormap=:viridis, Param_Crs, Dem_Resample, Latitude, Longitude, LookupTable, Map_Shp, Map_Value, Metadatas, Path_Gis, Path_Root, Path_Root_LookupTable, Subcatchment, TitleMap, ΔX, Missingval=NaN, 🎏_Progress=false, Crs_Input=Param_Crs)

			# READING THE LOOKUP TABLE
				Path_Home = @__DIR__
				cd(Path_Home)
				Path₀ = abspath(joinpath(Path_Home, ".."))
				Path = abspath(joinpath(Path₀, ".."))
 				Path_Lookup = joinpath(Path, Path_Root_LookupTable, LookupTable)
				println(Path_Lookup)

				Lookup = DataFrames.DataFrame(CSV.File(Path_Lookup, header=true))

				# Cleaning the headers with only the variables of interest
					Header₀ = DataFrames.names(Lookup)
					Remove = .!(occursin.("NO", Header₀))
					Header₁  =  Header₀[Remove]
					Remove = .!(occursin.("DESCRIPTION", Header₁))
					Header₂  =  Header₁[Remove]
					Remove = .!(occursin.("CLASS", Header₂))
					Header  =  Header₂[Remove]

				# Creating a dictionary
					N_Class = length(Lookup[!,:CLASS])
					Class_Vector = 1:1:N_Class
					Dict_Class_2_Index = Dict(Lookup[!,:CLASS] .=> Class_Vector)
					println(Lookup[!,:CLASS])

			# READING THE SHAPEFILE
				Path_Input = joinpath(Path_Root, Path_Gis, Map_Shp)
				Map = GeoDataFrames.read(Path_Input)
				println(Path_Input)

				# Reproject if not in the correct CRS
					# if Param_Crs ≠ Crs_Input
					# 	@info  "Reprojecting the map fron CRS=$(Crs_Input) to CRS=$(Param_Crs)"

                  # Param_CrsInput_GeoFormat  = GeoFormatTypes.convert(WellKnownText, EPSG(Crs_Input))
                  # Param_CrsOutput_GeoFormat = GeoFormatTypes.convert(WellKnownText, EPSG(Param_Crs))

					#  	Map = GeometryOps.reproject(Map; source_crs=EPSG(Param_CrsInput_GeoFormat), target_crs=EPSG(Param_CrsOutput_GeoFormat))
					# end

				# Creating new columns from the Lookup table
					Maps_Output = []
					Map[!,:Data] .= 1.0 # Initializing a new column
					for iiHeader in Header
						println(iiHeader)

						for (i, iiDrainage) in enumerate(Map[!, Map_Value])
							if ismissing(iiDrainage)
								iiDrainage = "missing"
							end
							iClass = Dict_Class_2_Index[iiDrainage]
							Map[!, :Data][i] = Lookup[!,iiHeader][iClass]
						end

						Map₁ = Rasters.rasterize(last, Map; fill=:Data, res=ΔX, to=Dem_Resample, missingval=Missingval, crs=Param_Crs, boundary=:center, shape=:polygon, progress=🎏_Progress, verbose=false)

							Map = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Map₁, Latitude, Longitude, Mask=Subcatchment)

							Map₁ = empty

							Maps_Output = push!(Maps_Output, Map)

						Path_Output = joinpath(Path_Root, Path_Wflow, iiHeader * ".tiff")
							Rasters.write(Path_Output, Map; ext=".tiff", force=true, verbose=false)
							println(Path_Output)

					# Plotting the maps
					if 🎏_Plots
						geoPlot.HEATMAP(;🎏_Colorbar=true, Input=Map, Label="$iiHeader", Title="$TitleMap : $iiHeader", titlecolor=titlecolor,  titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=Colormap)
					end
				end # for iiHeader in Header

			Dict_Class_2_Index = Lookup = Map = empty

		return Header, Maps_Output
		end  # function: LOOKUPTABLE_2_MAPS
	# ------------------------------------------------------------------

end # module geoLookuptable