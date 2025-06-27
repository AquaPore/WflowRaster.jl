
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

	include("Parameters.jl")
	include("GeoPlot.jl")
	include("PlotParameter.jl")

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
		function LAT_LONG_2_iCOORD(;Map, GaugeCoordinate)
         Longitude_X = GaugeCoordinate[1]
         Latitude_Y  = GaugeCoordinate[2]

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
		function LOOKUPTABLE_2_MAPS(;🎏_Plots, Colormap=:viridis, Crs, Dem_Resample_Mask, Lat, Lon, LookupTable, Map_Shp, Map_Value, Metadatas, Missingval=NaN, Path_InputGis, Path_Root, Path_Root_LookupTable, Subcatchment, TitleMap, ΔX)

			# READING THE LOOKUP TABLE
				Path_Home = @__DIR__
				cd(Path_Home)
				Path = abspath(joinpath(Path_Home, ".."))
 				Path_Lookup= joinpath(Path, Path_Root_LookupTable, LookupTable)
				println(Path_Lookup)

				Lookup = DataFrames.DataFrame(CSV.File(Path_Lookup, header=true))

				# Cleaning the headers with only the variables of interest
					Header₀ = DataFrames.names(Lookup)
					Remove = .!(occursin.("CODE_CLASS", Header₀))
					Header₁  =  Header₀[Remove]
					Remove = .!(occursin.("CLASS", Header₁))
					Header  =  Header₁[Remove]

				# Creating a dictionary
					N_Class = length(Lookup[!,:CLASS])
					Class_Vector = 1:1:N_Class
					Dict_Class_2_Index = Dict(Lookup[!,:CLASS] .=> Class_Vector)
					println(Lookup[!,:CLASS])

			# READING THE SHAPEFILE
				Path_Input = joinpath(Path_Root, Path_InputGis, Map_Shp)
				println(Path_Input)

				Map_Shapefile= GeoDataFrames.read(Path_Input)

				# Creating new columns from the Lookup table
					for iiHeader in Header
						# Initializing a new column
						Map_Shapefile[!, Symbol(iiHeader)] .= 1.0

						for (i, iiDrainage) in enumerate(Map_Shapefile[!, Map_Value])
							if ismissing(iiDrainage)
								iiDrainage = "missing"
							end
							iClass = Dict_Class_2_Index[iiDrainage]
							Map_Shapefile[!, Symbol(iiHeader)][i] = Lookup[!,iiHeader][iClass]
						end
					end

			# SAVING MAPS
				Maps_Output = []
				for iiHeader in Header
					Map₁ = Rasters.rasterize(last, Map_Shapefile;  fill =Symbol(iiHeader), res=ΔX, to=Dem_Resample_Mask, missingval=Missingval, crs=Crs, boundary=:center, shape=:polygon, progress=true, verbose=true)

						Map = geoRaster.MASK(;Crs=Metadatas.Crs_GeoFormat, Input=Map₁, Lat=Lat, Lon=Lon, Mask=Subcatchment, N_Height=Metadatas.N_Height, N_Width=Metadatas.N_Width)

						Maps_Output = push!(Maps_Output, Map)

					Path_Output = joinpath(Path_Root, Path_OutputWflow, iiHeader * ".tiff")
						Rasters.write(Path_Output, Map; ext=".tiff", force=true, verbose=true)
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

end #module geoRaster