
module geoRaster
    using Revise
    using ArchGDAL
        const AG = ArchGDAL
    using Rasters, GeoTIFF, Extents, Geomorphometry
    using Base
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

                   Crs=29902

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
    #		FUNCTION : iXY_2_COORD
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        using GeoArrays
        function iXY_2_COORD(iX, iY, Path)
            Grid = GeoArrays.read(Path)

            Coord_X, Coord_Y = GeoArrays.coords(Grid, (iX, iY))

            println(Coord_X," " ,Coord_Y)
        end
    # ----------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : CONVERT_2_NETCDF(
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\Parameters.jl")
    using NCDatasets

    function TIFF_2_NETCDF(Ldd_Mask, Metadatas, River_Mask, River_Wflow, RiverDepth, RiverDepth_Wflow, RiverSlope, RiverSlope_Wflow, RiverWidth, RiverWidth_Wflow, Slope_Mask, Subcatch_Wflow, Subcatchment)

        Path_NetCDF_Full  = joinpath(Path_Root, Path_NetCDF, NetCDF_Instates)

        isfile(Path_NetCDF_Full) && rm(Path_NetCDF_Full, force=true)
        println(Path_NetCDF_Full)

        # Create a NetCDF file
            NetCDF = NCDatasets.NCDataset(Path_NetCDF_Full,"c")

        # Define the dimension "lon" and "lat"
            NCDatasets.defDim(NetCDF,"lon", Metadatas.N_Width)
            NCDatasets.defDim(NetCDF,"lat", Metadatas.N_Height)

        # Define a global attribute
            NetCDF.attrib["title"]   = "Timoleague instates dataset"
            NetCDF.attrib["creator"] = "Joseph A.P. POLLACCO"


        # == LDD input ==========================================
         	Keys = splitext(Ldd_Wflow)[1]
				println(Keys)
         	Ldd_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int64, ("lon","lat"))

            Ldd_NetCDF[:,:] = Ldd_Mask

            Ldd_NetCDF.attrib["units"] = "1-9"
            Ldd_NetCDF.attrib["comments"] = "Derived from hydromt.flw.d8_from_dem"

        # == SUBCATCHMENT input ==========================================
            Keys = splitext(Subcatch_Wflow)[1]
				println(Keys)
            Subcatchment_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int64, ("lon","lat"))

            Subcatchment_NetCDF[:,:] = Subcatchment

            Subcatchment_NetCDF.attrib["units"] = "1"
            Subcatchment_NetCDF.attrib["comments"] = "Derived from hydromt"

        # == SLOPE input ==========================================
		      Keys = splitext(Slope_Wflow)[1]
				println(Keys)
            Slope_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("lon","lat"))

            Slope_NetCDF[:,:] = Slope_Mask

            Slope_NetCDF.attrib["units"] = "-"
            Slope_NetCDF.attrib["comments"] = "Derived from hydromt"

        # == RIVER input ==========================================
				Keys = splitext(River_Wflow)[1]
				println(Keys)
            River_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int64, ("lon","lat"))

            River_NetCDF[:,:] = River_Mask

            River_NetCDF.attrib["units"] = "0/1"
            River_NetCDF.attrib["comments"] = "Derived from hydromt"

        # == RIVER-SLOPE input ==========================================
		  		Keys = splitext(RiverSlope_Wflow)[1]
				println(Keys)

            River_NetCDF = NCDatasets.defVar(NetCDF, Keys, Float64, ("lon","lat"))

            River_NetCDF[:,:] = RiverSlope

            River_NetCDF.attrib["units"] = "Slope"
            River_NetCDF.attrib["comments"] = "Derived from hydromt"

        # == RIVER-WIDTH input ==========================================
		  		Keys = splitext(RiverWidth_Wflow)[1]
				println(Keys)

            RiverWidth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int64, ("lon","lat"))

            RiverWidth_NetCDF[:,:] = RiverWidth

            RiverWidth_NetCDF.attrib["units"] = "m"
            RiverWidth_NetCDF.attrib["comments"] = "Derived from hydromt"

        # == RIVER-DEPTH input ==========================================
		  		Keys = splitext(RiverDepth_Wflow)[1]
				println(Keys)

            RiverDepth_NetCDF = NCDatasets.defVar(NetCDF, Keys, Int64, ("lon","lat"))

            RiverDepth_NetCDF[:,:] = RiverDepth

            RiverDepth_NetCDF.attrib["units"] = "Slope"
            RiverDepth_NetCDF.attrib["comments"] = "Derived from hydromt"

    close(NetCDF)
    return NetCDF, Path_NetCDF_Full
    end  # function: TIFF_2_NETCDF
    # ------------------------------------------------------------------



	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIMESERIES_2_NETCDF
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIMESERIES_2_NETCDF()

		return
		end  # function: TIMESERIES_2_NETCDF
	# ------------------------------------------------------------------
end #module geoRaster