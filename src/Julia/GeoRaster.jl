
module geoRaster
	using Revise, Rasters, GeoDataFrames, GeoFormatTypes, DimensionalData, Geomorphometry, CSV
	# using GeoFormatTypes, GeoTIFF, ArchGDAL, GeoDataFrames, DataFrames, Shapefile, CSV
	using NCDatasets


	# using Base
	# using CairoMakie, Colors, ColorSchemes
	# using Geomorphometry

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
		  Param_Crs       :: Int64
		  Crs_GeoFormat
	 end # struct METADATA


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : DEM_DERIVE_COASTLINES
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function DEM_DERIVE_COASTLINES(;Dtm,  Longitude, Latitude, Crs, Missing=NaN, ϵ=0.001, DtmMin=0.001)
			Dtm_Coastline = Rasters.Raster((Longitude, Latitude); crs=Crs)

			N_Width, N_Height = size(Dtm_Coastline)

			Dtm_Corrected = deepcopy(Dtm)

			# Removing small islands
				Threads.@threads for iX=1:N_Width
					Threads.@threads for iY=1:N_Height
						if Dtm[iX, iY] < 0.001
                     Dtm[iX,iY]           = Missing
                     Dtm_Corrected[iX,iY] = Missing
						end # Dtm[iX, iY] > 0
					end # iY=1:N_Height
				end # for iiX=1:N_Width

			Threads.@threads for iX=1:N_Width
				Threads.@threads for iY=1:N_Height
					if Dtm[iX, iY] > 0
						if (iX ≠ 1 && iX ≠ N_Width && iY ≠ 1 && iY ≠ N_Height)
							# if Dtm[iX-1, iY] ≤ ZseaMeanLevel || (Dtm[min(iX+1, N_Width), iY]) ≤ ZseaMeanLevel || (Dtm[iX, iY-1]) ≤ ZseaMeanLevel || (Dtm[iX, iY+1]) ≤ ZseaMeanLevel
							if isnan(Dtm[iX-1, iY]) || isnan(Dtm[min(iX+1, N_Width), iY]) || isnan(Dtm[iX, iY-1]) || isnan(Dtm[iX, iY+1])
								Dtm_Coastline[iX,iY] = 1
								Dtm_Corrected[iX,iY] = Dtm_Corrected[iX,iY] + DtmMin
							else
								Dtm_Coastline[iX,iY] = Missing
							end
						else
							Dtm_Coastline[iX,iY] = 1
							Dtm_Corrected[iX,iY] = Dtm_Corrected[iX,iY] + DtmMin
						end
					else
						Dtm_Coastline[iX,iY] = Missing
					end # Dtm[iX, iY] > 0
				end # iY=1:N_Height
			end # for iiX=1:N_Width

		return Dtm_Coastline, Dtm_Corrected
		end  # function: DEM_DERIVE_COASTLINES
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : DEM_CORRECT_BOARDERS_1!
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function DEM_CORRECT_BOARDERS_1!(;Dtm, Latitude, Longitude, Crs, ΔZadjust=10.0, iiParam_GaugeCoordinate)

			N_Width, N_Height  = size(Dtm)

			iiX = iiParam_GaugeCoordinate[1]
			iiY = iiParam_GaugeCoordinate[2]

			Dtm_Boarder = Rasters.Raster((Longitude, Latitude); crs=Crs)
			for iX=1:N_Width
				for iY=1:N_Height
					if Dtm[iX, iY] > 0
						if (iX ≠ 1 && iX ≠ N_Width && iY ≠ 1 && iY ≠ N_Height)
							if isnan(Dtm[iX-1, iY]) || isnan(Dtm[min(iX+1, N_Width), iY]) || isnan(Dtm[iX, iY-1]) || isnan(Dtm[iX, iY+1])
								Dtm_Boarder[iX,iY] = 1
							else
								Dtm_Boarder[iX,iY] = NaN
							end
						else
							Dtm_Boarder[iX,iY] = 1
						end
					else
						Dtm_Boarder[iX,iY] = NaN
					end # Dtm[iX, iY] > 0
				end # iY=1:N_Height
			end # for iiX=1:N_Width

			for iX=1:N_Width
				for iY=1:N_Height
					if Dtm_Boarder[iX,iY] > 0
						if !(iX == iiX && iY== iiY && iX == min(iiX + 1, N_Width) && iY== min(iiY + 1, N_Height) && iX == max(iiX - 1, 1) && iY== max(iiY - 1,1))

							Dtm[iX,iY] = Dtm[iX,iY] + ΔZadjust
						end
					end # Dtm[iX, iY] > 0
				end # iY=1:N_Height
			end # for iiX=1:N_Width

		return Dtm, Dtm_Boarder
		end  # function: CORRECT_BOARDERS
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
	#		FUNCTION : LAI
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function LAI()

		return
		end  # function: LAI
	# ------------------------------------------------------------------

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
		function MASK(; Input, Latitude, Longitude, Mask, Missing=NaN, Param_Crs, MissingData=0.001)

			N_Width, N_Height  = size(Input)

			Output_Mask = Rasters.Raster((Longitude, Latitude); crs=Param_Crs)
			for iX=1:N_Width
				for iY=1:N_Height
					# if Mask[iX,iY] > 0.0001 || !(isnan(Mask[iX,iY]))
					if Mask[iX,iY] > 0
						# This is not normal
						if isnan(Input[iX, iY])
							Input[iX, iY] = MissingData
						end
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
	#		FUNCTION : MOSAIC
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function MOSAIC(;Path_Root_Mosaic, Missing=NaN, ZseaMeanLevel=0.01, 🎏_CleanData=true)

			FilesList = readdir(Path_Root_Mosaic,)

			# Combining maps
			Maps = []
			for iiFile in FilesList
				Dtm_Map₀ = Rasters.Raster(joinpath(Path_Root_Mosaic, iiFile))
				Dtm_Map  = Rasters.replace_missing(Dtm_Map₀, missingval=NaN)
				Maps     = push!(Maps, Dtm_Map)
			end

			Mosaic = Rasters.mosaic(first, Maps; missingval=Missing, progress=true)

			if 🎏_CleanData
				N_Width, N_Height  = size(Mosaic)

				for iX=1:N_Width
					for iY=1:N_Height
						if (Mosaic[iX,iY] < ZseaMeanLevel) || (Mosaic[iX,iY] <0.)
							Mosaic[iX,iY] = Missing
						end
					end # for iY=1:Metadatas.N_Height
				end # for iX=1:Metadatas.N_Width
			end

			Mosaic     = Rasters.replace_missing(Mosaic, missingval=NaN)

		printstyled("					==== MOSAIC READY ===", color=:cyan)
		return Mosaic
		end  # function: MOSAIC
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : POINT_2_RASTER
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function POINTS_2_RASTER(;PathInput, PathOutputShp, PathOutputRaster, EPSG_Output=29902, Dtm, Metadatas, Param_ΔX, Longitude, Latitude, River=[], 🎏_Method_Index ="Rasters", 🎏_PointOnRiver =false)

		   # READ DATA
            Data        = CSV.File(PathInput, header=true)
            Header      = string.(Tables.columnnames(Data))
            Longitude_X = convert(Vector{Float64}, Tables.getcolumn(Data, :X))
            Latitude_Y  = convert(Vector{Float64}, Tables.getcolumn(Data, :Y))
            Site        = convert(Vector{String}, Tables.getcolumn(Data, :SITE))
            Epsg        = convert(Vector{Int64}, Tables.getcolumn(Data, :EPSG))
            Id          = convert(Vector{Int64}, Tables.getcolumn(Data, :ID))

				if length(unique!(Epsg)) ≥ 2
					@error("EPSGmust be all unique")
				end

				N = length(Longitude_X)

			# CONVERT TO SHAPEFILE
				Points = GeoDataFrames.GeoInterface.Point.(Longitude_X, Latitude_Y; crs=GeoDataFrames.EPSG(Epsg[1]))
				Df = DataFrames.DataFrame(Coordinates=Points, Site=Site)
				Df = GeoDataFrames.metadata!(Df, "GEOINTERFACE:geometrycolumns", (:Coordinates,); style=:note) # required because of the custom geometry column nam
				Df = GeometryOps.reproject(Df, GeoDataFrames.EPSG(Epsg[1]), GeoDataFrames.EPSG(EPSG_Output);  always_xy=false) # this set the crs metadata
				GeoDataFrames.write(PathOutputShp, Df; force=true,)
				println(PathOutputShp)

			# CONVERT TO RASTER
				Points_Raster = Rasters.Raster((Longitude, Latitude); crs=Metadatas.Crs_GeoFormat)
				Points_Raster = Rasters.set(Points_Raster, Rasters.Center)
				Points_Raster .= 0::Int64

				iX_Gauge = 1
				iY_Gauge = 1
				for i = 1:N
					if 🎏_Method_Index == "Joseph"
						iX_Gauge, iY_Gauge = geoRaster.LAT_LONG_2_INDEX(;Map=Points_Raster, Param_GaugeCoordinate=[Longitude_X[i], Latitude_Y[i]])

					elseif 🎏_Method_Index == "Rasters"
						iX_Gauge, iY_Gauge = Rasters.dims2indices(Points_Raster, (X(Rasters.Near(Longitude_X[i])), Y(Rasters.Near(Latitude_Y[i]))))

					else
						@error("🎏_Method_Index == $🎏_Method_Index not available")
					end

					Points_Raster[iX_Gauge, iY_Gauge] = Id[i]

					N_iY = size(Points_Raster)[2]
					println(  "Id =" , Id[i], " , " , [iX_Gauge, iY_Gauge] , "; Wflow= ", [iX_Gauge, N_iY - iY_Gauge + 1])

					# Assuring that the observation point is on a river
					if 🎏_PointOnRiver
							if River[iX_Gauge, iY_Gauge] ≠ 1
								@error "Site = $(Site[i]) not on river network River[iX_Gauge, iY_Gauge] ≠ 1"
							end
					end
				end # for i = 1:N

				Rasters.write(PathOutputRaster, Points_Raster; ext=".tiff", force=true, verbose=false, missingval=0)
				println(PathOutputRaster)

			# CONVERT TO RASTER (not accurate)
			   # Points_Shp = Shapefile.Handle(PathOutputShp)

				# Dtm = DimensionalData.shiftlocus(DimensionalData.Center(), Dtm)
				# Dtm = Rasters.set(Dtm, Rasters.Center)

				# Points_Raster = Rasters.rasterize(last, Points_Shp; shape=:point, fill=1, missingval=0, to=Dtm, threaded=false, boundary=:touches, progress=false)

				# Rasters.write(PathOutputRaster, Points_Raster; ext=".tiff", force=true, verbose=false, missingval=0)
				# println(PathOutputRaster)
		return Points_Raster
		end  # function: POINT_2_RASTER
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : REPROJECTION
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function REPROJECTION(;PathOutputShp, PathOutputCsv, Longitude_X, Latitude_Y, Site, EPSG_Input=4326, EPSG_Output=29902)
			Points = GeoDataFrames.GeoInterface.Point.(Latitude_Y, Longitude_X)

			Df = GeoDataFrames.DataFrame(Coordinates=Points, Site=Site)
			Df = GeoDataFrames.metadata!(Df, "GEOINTERFACE:geometrycolumns", (:Coordinates,); style=:note) # required because of the custom geometry column name
			Df = GeometryOps.reproject(Df, GeoDataFrames.EPSG(EPSG_Input), GeoDataFrames.EPSG(EPSG_Output);  always_xy=false) # this set the crs metadata
			GeoDataFrames.write(PathOutputShp, Df)
			CSV.write(PathOutputCsv, Df)
		return Df
		end  # function: REPROJECTION
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

end # module geoRaster