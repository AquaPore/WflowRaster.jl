
module geoRaster
    using Revise
    using ArchGDAL
        const AG = ArchGDAL
    using Rasters, GeoTIFF, Extents, Geomorphometry
    using Base

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


end #module geoRaster