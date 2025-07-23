
module geoRaster
	using Revise
	using Rasters, GeoFormatTypes, GeoTIFF, ArchGDAL
	using NCDatasets
	using CSV, DataFrames, GeoDataFrames

	# using Base
	# using CairoMakie, Colors, ColorSchemes
	# using Geomorphometry


	include("Parameters.jl")
	# include("GeoPlot.jl")
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
		  Param_Crs       :: Int64
		  Crs_GeoFormat
	 end # struct METADATA


	 """
		  Deriving metadata from the GeoTiff file
	 """
	 # ================================================================
	 #		FUNCTION : RASTER_METADATA
	 # ================================================================
		function RASTER_METADATA(Map; Verbose=true)
			# Grid = Rasters.Raster(Path, lazy=true)
			N_Width, N_Height  = size(Map)
			ΔX       = step(dims(Map, X))
			ΔY       = step(dims(Map, Y))

			# Crs_Rasters = Rasters.crs(Map)

			Coord_X_Left   = first(dims(Map, X))
			Coord_X_Right  = last(dims(Map, X))
			Coord_Y_Top    = first(dims(Map ,Y))
			Coord_Y_Bottom = last(dims(Map,Y))

			Crs_GeoFormat = GeoFormatTypes.convert(WellKnownText, EPSG(Param_Crs))

			if Verbose
				println("Param_Crs = $Param_Crs")
				println("ΔX = $ΔX")
				println("ΔY = $ΔY")
				println("N_Width  = $N_Width")
				println("N_Height = $N_Height")
				println("Coord_X_Left = $Coord_X_Left, Coord_X_Right = $Coord_X_Right")
				println("Coord_Y_Top = $Coord_Y_Top, Coord_Y_Bottom = $Coord_Y_Bottom")
			end

			@assert(N_Width == Int32((Coord_X_Right - Coord_X_Left) / ΔX +1))
			@assert(N_Height == Int32((Coord_Y_Top - Coord_Y_Bottom) / -ΔY + 1))

			Metadata = METADATA(N_Width, N_Height, ΔX, ΔY, Coord_X_Left, Coord_X_Right,Coord_Y_Top, Coord_Y_Bottom, Param_Crs, Crs_GeoFormat)

		return Metadata
		end # function RASTER_METADATA
	# ----------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : MASK
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function MASK(; Input, Latitude, Longitude, Mask, Missing=NaN, Param_Crs)

			N_Width, N_Height  = size(Input)

			Output_Mask = Rasters.Raster((Longitude, Latitude), crs=Param_Crs)
			for iX=1:N_Width
				for iY=1:N_Height
					# if Mask[iX,iY] > 0.0001 || !(isnan(Mask[iX,iY]))
					if Mask[iX,iY] > 0
						Output_Mask[iX,iY] = Input[iX,iY]
					else
						Output_Mask[iX,iY] = Missing
					end
				end # for iY=1:Metadatas.N_Height
			end # for iX=1:Metadatas.N_Width
		return Output_Mask
		end  # function: mask
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LAT_LONG_2_INDEX
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function LAT_LONG_2_INDEX(;Map, Param_GaugeCoordinate)
         Longitude_X = Param_GaugeCoordinate[1]
         Latitude_Y  = Param_GaugeCoordinate[2]

         Longitude   = Rasters.lookup(Map, X)
         Latitude    = Rasters.lookup(Map, Y)

         Nlongitude  = length(Longitude)
         Nlatitude   = length(Latitude)

			# Longitude
				ΔX = Longitude[2] - Longitude[1]

				@assert(Longitude[1] ≤ Longitude_X ≤ Longitude[Nlongitude])
				iX = Nlongitude
				for i=1:Nlongitude
					if Longitude[i] - ΔX / 2.0 ≤ Longitude_X < Longitude[i] + ΔX / 2.0
					# if Longitude[i] - ΔX ≤ Longitude_X < Longitude[i]
						iX = i
						break
					end
				end # for i=1:Nlongitude

			# Latitude
			 	ΔY = Latitude[2] - Latitude[1]
				@assert( Latitude[Nlatitude] + ΔY / 2.0  ≤ Latitude_Y ≤ Latitude[1] - ΔY / 2.0)
				iY = 1
				for i=Nlatitude:-1:1
				if Latitude[i] + ΔY / 2.0  ≤ Latitude_Y < Latitude[i] - ΔY / 2.0
					# if Latitude[i]  < Latitude_Y ≤ Latitude[i] - ΔY
						iY = i
						break
					end # if Latitude_Sort[iY] ≥ Lat_Y
				end # i=1:Nlatitude

				println( "LAT_LONG_2_INDEX: [$iX ; $iY]" )
		return iX, iY
		end
	# ----------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : GAUGE
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function GAUGE(;🎏_Method_Index = "Rasters", Latitude=Latitude, Longitude=Longitude, Metadatas=Metadatas, Param_GaugeCoordinate, Path_OutputGauge)

			Gauge₀ = Rasters.Raster((Longitude, Latitude), crs=Metadatas.Crs_GeoFormat)
			Gauge₀ .= 0

			Gauge = Rasters.set(Gauge₀, Rasters.Center)

			iX_Gauge = 1
			iY_Gauge = 1
			if 🎏_Method_Index == "Joseph"
				iX_Gauge, iY_Gauge = geoRaster.LAT_LONG_2_INDEX(;Map=Gauge, Param_GaugeCoordinate)

				println([iX_Gauge, iY_Gauge])

			elseif 🎏_Method_Index == "Rasters"
				iX_Gauge, iY_Gauge = Rasters.dims2indices(Gauge, (X(Rasters.Near(Param_GaugeCoordinate[1])), Y(Rasters.Near(Param_GaugeCoordinate[2]))))
			end
			println([iX_Gauge, iY_Gauge])

			# Inverse
			# 	DimPoints(Gauge)[X(iX_Gauge), Y(iY_Gauge)]

			# Selection of the Gauge
			Gauge[iX_Gauge, iY_Gauge] = 1

			Rasters.write(Path_OutputGauge, Gauge; ext=".tiff", force=true, verbose=true, missingval=0)

		return Gauge, [iX_Gauge, iY_Gauge]
		end  # function: GAUGE
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : CORRECT_BOARDERS
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function DEM_CORRECT_BOARDERS!(;Dem, DemMultiply =1.2, Latitude, Longitude, Crs)

			N_Width, N_Height  = size(Dem)

			Dem_Corrected = Rasters.Raster((Longitude, Latitude), crs=Crs)

			for iX=1:N_Width
				for iY=1:N_Height
					if (iX == 1) ||  (iY == 1) || (iY == N_Width)
						Dem_Corrected[iX,iY] = Dem[iX,iY] * 1.2

					elseif (iX == 2) || (iY == 2) || (iY == N_Width-1)
						Dem_Corrected[iX,iY] = Dem[iX,iY] * 1.5

					elseif (iX == 3) || (iY == 3) || (iY == N_Width-2)
						Dem_Corrected[iX,iY] = Dem[iX,iY] * 1.2

					else
						Dem_Corrected[iX,iY] = Dem[iX,iY]
					end
				end # for iY=1:Metadatas.N_Height
			end # for iX=1:Metadatas.N_Width

		return Dem_Corrected
		end  # function: CORRECT_BOARDERS
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : LOOKUPTABLE_2_MAPS
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function LOOKUPTABLE_2_MAPS(;🎏_Plots, Colormap=:viridis, Param_Crs, Dem_Resample_Mask, Latitude, Longitude, LookupTable, Map_Shp, Map_Value, Metadatas, Missingval=NaN, Path_InputGis, Path_Root, Path_Root_LookupTable, Subcatchment, TitleMap, ΔX)

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
					Map₁ = Rasters.rasterize(last, Map_Shapefile;  fill =Symbol(iiHeader), res=ΔX, to=Dem_Resample_Mask, missingval=Missingval, crs=Param_Crs, boundary=:center, shape=:polygon, progress=true, verbose=true)

						Map = geoRaster.MASK(;Param_Crs=Metadatas.Crs_GeoFormat, Input=Map₁, Latitude, Longitude, Mask=Subcatchment)

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


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TEST_SAMESIZE
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TEST_SAMESIZE(; Map₁, Map₂,  Map₁_Nodata, Map₂_Nodata)
			Nx₁, Ny₁ = size(Map₁)
			Nx₂, Ny₂ = size(Map₂)

			@assert Nx₁ == Nx₂
			@assert Ny₁ == Ny₂

			🎏_Map₁_Eq_Map₂ = true
			for iX = 1:Nx₁
				for iY = 1:Ny₁
					Cond₁ = Map₁[iX, iY]==Map₁_Nodata || isnan(Map₁[iX, iY])
					Cond₂ = Map₂[iX, iY]==Map₂_Nodata || isnan(Map₂[iX, iY])

					if Cond₁ ⊻ Cond₂ #xor
						display("Error [$iX  $iY], Map₁ = $(Map₁[iX, iY]) ≠ Map₂ = $(Map₂[iX, iY])")
						🎏_Map₁_Eq_Map₂ = false
						break
					end
				end
			end

			@assert 🎏_Map₁_Eq_Map₂

		return 🎏_Map₁_Eq_Map₂
		end  # function: TEST_SAMESIZE
	# ------------------------------------------------------------------

end #module geoRaster