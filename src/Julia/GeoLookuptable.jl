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
		function LOOKUPTABLE_2_MAPS(;Dem_Resample, Latitude, Longitude, ShpLayer, Metadatas, Param_Crs, Path_Input_Map, Path_Lookup, Path_Root, Subcatchment, TitleMap, ΔX, 🎏_Plots, 🎏_Progress=false, Boundary=:touches, Colormap=:plasma, Missingval=NaN)

			# Is the map a shapefile?
				if split(Path_Input_Map, ".")[end] == "shp" || split(Path_Input_Map, ".")[end] == "gdb"
					🎏_MapShapefile = true
				else
					🎏_MapShapefile = false
				end
				@info "🎏_MapShapefile = $🎏_MapShapefile"

			# === READING LOOKUP TABLE ===
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
               N_Class            = length(Lookup[!,:CLASS])
               Class_Vector       = 1:1:N_Class
               Dict_Class_2_Index = Dict(Lookup[!,:CLASS] .=> Class_Vector)
					println(Lookup[!,:CLASS])

			# === VECTOR FILE ===
			Maps_Output = []

			if 🎏_MapShapefile
				MapGeoDataFrames = GeoDataFrames.read(Path_Input_Map)
				println(Path_Input_Map)
				MapGeoDataFrames[!,:Output] .= 1.0 # Initializing a new column
			else
				MapInput = Rasters.Raster(Path_Input_Map)
				Map = Rasters.Raster((Longitude, Latitude), crs=Metadatas.Crs_GeoFormat)
			end

			for iiHeader in Header
				println(iiHeader)

				if 🎏_MapShapefile
					for (i, iiClass) in enumerate(MapGeoDataFrames[!, ShpLayer])
						if ismissing(iiClass)
							iiClass = "missing"
						end
						iClass = Dict_Class_2_Index[iiClass]
						MapGeoDataFrames[!,:Output][i] = Lookup[!,iiHeader][iClass]
					end

					# Rasterizing
						Map = Rasters.rasterize(last, MapGeoDataFrames; fill=:Output, res=ΔX, to=Dem_Resample, missingval=Missingval, crs=Param_Crs, boundary=Boundary, shape=:polygon, progress=🎏_Progress, verbose=false)

					# Masking
						Map = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Map, Latitude, Longitude, Mask=Subcatchment, Missing=NaN)
				else
					for iX=1:Metadatas.N_Width
						for iY=1:Metadatas.N_Height
							if MapInput[iX,iY] > 0
								iClass = Dict_Class_2_Index[Int64.(MapInput[iX,iY])]
								Map[iX,iY]  = Lookup[!,iiHeader][iClass]
							else
								Map[iX,iY] = NaN
							end
						end # for iY=1:Metadatas.N_Height
					end # for iX=1:Metadatas.N_Width
				end # if 🎏_MapShapefile

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