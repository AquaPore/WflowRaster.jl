module geoLookuptable
	using CSV, DataFrames, GeoDataFrames, Rasters, Revise, GeometryOps, GeoFormatTypes
	include("Parameters.jl")
	include("GeoPlot.jl")
	include("PlotParameter.jl")
	include("GeoRaster.jl")

	export LOOKUPTABLE_2_MAPS

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LOOKUPTABLE_2_MAPS
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	`""" boundary: for polygons, include pixels; <:center>: inside the polygon;
			polygon <:touches> the pixel, completely <:inside> the polygon"""`
		function LOOKUPTABLE_2_MAPS(;🎏_Plots, 🎏_Progress=false, Boundary=:touches, Colormap=:viridis, Dem_Resample, Filename_Map, Latitude, Longitude, LookupTable, Map_Value, Metadatas, Missingval=NaN, Param_Crs, Path_Gis, Path_Root, Path_Root_LookupTable, Subcatchment, TitleMap, ΔX)

			# === READING LOOKUP TABLE ===
				Path_Home = @__DIR__
				cd(Path_Home)
				Path₀ = abspath(joinpath(Path_Home, ".."))
				Path = abspath(joinpath(Path₀, ".."))
 				Path_Lookup = joinpath(Path, Path_Root_LookupTable, LookupTable)

				Lookup = DataFrames.DataFrame(CSV.File(Path_Lookup, header=true))
				println(Path_Lookup)

				# Cleaning headers
					Header₀ = DataFrames.names(Lookup)
					Remove = .!(occursin.("NO", Header₀))
					Header₁  =  Header₀[Remove]
					Remove = .!(occursin.("DESCRIPTION", Header₁))
					Header₂  =  Header₁[Remove]
					Remove = .!(occursin.("CLASS", Header₂))
					Header  =  Header₂[Remove]

				# Creating dictionary
					N_Class = length(Lookup[!,:CLASS])
					Class_Vector = 1:1:N_Class
					Dict_Class_2_Index = Dict(Lookup[!,:CLASS] .=> Class_Vector)
					println(Lookup[!,:CLASS])

			# === VECTOR FILE ===
				Path_Input = joinpath(Path_Root, Path_Gis, Filename_Map)
				MapGeoDataFrames = GeoDataFrames.read(Path_Input)
				println(Path_Input)

				# Creating new columns of the lookup table
					Maps_Output = []
					MapGeoDataFrames[!, :Output] .= 1.0 # Initializing a new column
					for iiHeader in Header
						println(iiHeader)

						for (i, iiClass) in enumerate(MapGeoDataFrames[!, Map_Value])
							if ismissing(iiClass)
								iiClass = "missing"
							end
							iClass = Dict_Class_2_Index[iiClass]
							MapGeoDataFrames[!,:Output][i] = Lookup[!,iiHeader][iClass]
						end

				# Rasterizing
					Map = Rasters.rasterize(last, MapGeoDataFrames; fill=:Output, res=ΔX, to=Dem_Resample, missingval=Missingval, crs=Param_Crs, boundary=Boundary, shape=:polygon, progress=🎏_Progress, verbose=false);

				# Masking
					Map = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Map, Latitude, Longitude, Mask=Subcatchment, Missing=NaN);

						Maps_Output = push!(Maps_Output, Map);

				# SAVING MAPS
					Path_Output = joinpath(Path_Root, Path_Wflow, iiHeader * ".tiff")
						Rasters.write(Path_Output, Map; ext=".tiff", force=true, verbose=false);
						println(Path_Output)

				# PLOTTING MAPS
					if 🎏_Plots
						geoPlot.HEATMAP(;🎏_Colorbar=true, Input=Map, Label="$iiHeader", Title="$TitleMap : $iiHeader", titlecolor=titlecolor,  titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=Colormap)
					end
				end # for iiHeader in Header

			# CLEANING
				Dict_Class_2_Index = Lookup = Map = MapGeoDataFrames = empty

		return Header, Maps_Output
		end  # function: LOOKUPTABLE_2_MAPS
	# ------------------------------------------------------------------

end # module geoLookuptable