
module geoRaster

    using Revise
    using ArchGDAL
        const AG = ArchGDAL
    using Rasters, GeoTIFF
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
        Bands          :: Int64
    end # struct METADATA



    """
        Deriving metadata of the GeoTiff file
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
                Coord_X_Left   = first(dims(Grid, X))
                Coord_X_Right  = last(dims(Grid, X))
                Coord_Y_Top    = first(dims(Grid ,Y))
                Coord_Y_Bottom = last(dims(Grid,Y))

            Grid_GeoTIFF = GeoTIFF.load(Path)
                Grid_GeoTIFF_Metadata = GeoTIFF.metadata(Grid_GeoTIFF)
                    Crs =GeoTIFF.epsgcode(Grid_GeoTIFF_Metadata) |>Int

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

            Metadata = METADATA(N_Width, N_Height, ΔX, ΔY, Coord_X_Left, Coord_X_Right,Coord_Y_Top, Coord_Y_Bottom, Crs, Bands)

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