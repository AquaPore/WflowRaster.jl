# =============================================================
#		module: wflowModelProcess
# =============================================================
module wflowModelProcess

using CSV, Dates, Tables, NCDatasets, Dates, FLoops

include("GeoPlot.jl")

const M_2_Mm = 1000.0
const Mm_2_M = 0.001
const Seconds_2_Days = 1.0 / (60.0 * 60.0 * 24.0)
const Days_2_Second = 60.0 * 60.0 * 24.0

Threads.nthreads() = 32


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : WFLOW_PROCESS_OUTPUT()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function WFLOW_PROCESS_OUTPUT(; EndDate, Param_ΔX₁, Param_ΔX₂, Path_AverageFluxes_Csv, Path_Qobs, Path_Wflow_Csv_Output, Path_Wflow_NetCDF_Output, StartDate, StartDay, StartMonth, StartYear, Precipitation_NetCDF="atmosphere_water__precipitation_volume_flux", PotentialEvapotranspiration_NetCDF="land_surface_water__potential_evaporation_volume_flux", Interception_NetCDF="vegetation_canopy_water__interception_volume_flux", Evapotranspiration_NetCDF="land_surface__evapotranspiration_volume_flux", OverlandFlow_NetCDF="land_surface_water__volume_flow_rate", SoilLayerSoilMoisture_NetCDF="soil_layer_water__volume_fraction", SubsurfaceFlow_NetCDF="subsurface_water__volume_flow_rate", 🎏_Plotting=true, 🎏_CatchmentName, 🎏_Qobs=true, QwflowName)

   # Reading NetCDF output files
   @assert isfile(joinpath(Path_Wflow_NetCDF_Output))
   println(Path_Wflow_NetCDF_Output)
   WflowOutput                 = NCDatasets.NCDataset(Path_Wflow_NetCDF_Output)
   Precipitation               = Array(WflowOutput[Precipitation_NetCDF])
   PotentialEvapotranspiration = Array(WflowOutput[PotentialEvapotranspiration_NetCDF])
   Interception                = Array(WflowOutput[Interception_NetCDF])
   Evapotranspiration          = Array(WflowOutput[Evapotranspiration_NetCDF])
   OverlandFlow                = Array(WflowOutput[OverlandFlow_NetCDF])
   θlayer                      = Array(WflowOutput[SoilLayerSoilMoisture_NetCDF])
   SubsurfaceFlow              = Array(WflowOutput[SubsurfaceFlow_NetCDF])
   close(WflowOutput)

   Nx, Ny, Nt = size(Precipitation)

   # Number of soil layers
   Nlayer = size(θlayer)[3]
   printstyled("	Number of soil layers = $Nlayer \n", color=:green)

   # Initializing variables
   θlayer_Aver                     = zeros(Float64, Nt, Nlayer)
   ∑Precipitation_M3               = zeros(Float64, Nt)
   Precipitation_Mm                = copy(∑Precipitation_M3)
   ∑PotentialEvapotranspiration_M3 = copy(∑Precipitation_M3)
   PotentialEvaporation_Mm         = copy(∑Precipitation_M3)
   ∑Interception_M3                = copy(∑Precipitation_M3)
   ∑InfiltrationSoil_M3            = copy(∑Precipitation_M3)
   InfiltrationSoil_Mm             = copy(∑Precipitation_M3)
   ∑Evapotranspiration_M3          = copy(∑Precipitation_M3)
   Evapotranspiration_Mm           = copy(∑Precipitation_M3)
   ∑OverlandFlow_M3                = copy(∑Precipitation_M3)
   OverlandFlow_Mm                 = copy(∑Precipitation_M3)
   ∑SubsurfaceFlow_M3              = copy(∑Precipitation_M3)
   SubsurfaceFlow_Mm               = copy(∑Precipitation_M3)

   Interception_Mm = 0.0

   DatesWflow = fill(Date(StartYear, StartMonth, StartDay), Nt)

   # Counting active cells
   NotMissing = fill(false, Nx, Ny)
   CountCell = Threads.Atomic{Int}(0)
   Threads.@threads for iX = 1:Nx
      Threads.@threads for iY = 1:Ny
         if Precipitation[iX, iY, 2] !== missing
            Threads.atomic_add!(CountCell, 1) # Safe addition
            NotMissing[iX, iY] = true
         end
      end
   end
   CountCell = CountCell[] # convert atomic to regular integer

   CellSize_M2 = Param_ΔX₁ * Param_ΔX₁
   CatchmentArea = CountCell * CellSize_M2  # m2
   printstyled("	Number of grids = $CountCell , CatchmentSize = $CatchmentArea  m² \n", color=:green)

   # Summing up every fluxes and calculating average fluxes in mm/day for each time step
   DatesWflow[1] = StartDate

   #   Threads.@threads
   for iT = 1:Nt

      for iX = 1:Nx
         for iY = 1:Ny
            if NotMissing[iX, iY]

               ∑Precipitation_M3[iT]               += Precipitation[iX, iY, iT] * Mm_2_M * CellSize_M2
               ∑PotentialEvapotranspiration_M3[iT] += PotentialEvapotranspiration[iX, iY, iT] * Mm_2_M * CellSize_M2
               ∑Interception_M3[iT]                += Interception[iX, iY, iT] * Mm_2_M * CellSize_M2
               ∑Evapotranspiration_M3[iT]          += Evapotranspiration[iX, iY, iT] * Mm_2_M * CellSize_M2

               ∑OverlandFlow_M3[iT]                += OverlandFlow[iX, iY, iT] * CellSize_M2 / Seconds_2_Days # m3/s to m3/day
               ∑SubsurfaceFlow_M3[iT]              += SubsurfaceFlow[iX, iY, iT] * CellSize_M2 # m3/day

               for iLayer = 1:Nlayer-1
                  θlayer_Aver[iT, iLayer] += θlayer[iX, iY, iLayer, iT]
               end

               ∑InfiltrationSoil_M3[iT] = ∑Precipitation_M3[iT] - ∑Interception_M3[iT]
               #          # ∑GroundwaterFlow_M3[iT]       += GroundwaterFlow[iX, iY, iT]
            end # if NotMissing[iX, iY]
         end # for iX=1:Nx
      end # for  iY=1:Ny

      Precipitation_Mm[iT]        = ∑Precipitation_M3[iT] * M_2_Mm / CatchmentArea
      PotentialEvaporation_Mm[iT] = ∑PotentialEvapotranspiration_M3[iT] * M_2_Mm / CatchmentArea
      Interception_Mm             = ∑Interception_M3[iT] * M_2_Mm / CatchmentArea
      InfiltrationSoil_Mm[iT]     = ∑InfiltrationSoil_M3[iT] * M_2_Mm / CatchmentArea
      Evapotranspiration_Mm[iT]   = ∑Evapotranspiration_M3[iT] * M_2_Mm / CatchmentArea

      InfiltrationSoil_Mm[iT]     = Precipitation_Mm[iT] - Interception_Mm

      OverlandFlow_Mm[iT]         = ∑OverlandFlow_M3[iT] * M_2_Mm / CatchmentArea
      SubsurfaceFlow_Mm[iT]       = ∑SubsurfaceFlow_M3[iT] * M_2_Mm / CatchmentArea

      for iLayer = 1:Nlayer-1
         θlayer_Aver[iT, iLayer] = θlayer_Aver[iT, iLayer] / CountCell
      end

      DatesWflow[iT] += Dates.Day(iT)
   end # for iT=1:Nt

   InterceptionLost = 100.0 * sum(∑Interception_M3) / sum(∑Precipitation_M3)
   printstyled("	Interception lost = $(floor(InterceptionLost)) %  \n", color=:green)


   # ~~~~~~~~~~~~~~~~  READING OBSERVATIONS ~~~~~~~~~~~~~~~~
   if 🎏_Qobs
      # Reading climate data
      println(Path_Qobs)
      @assert isfile(Path_Qobs)
      Data₀ = CSV.File(Path_Qobs; header=true)
      Year = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
      Month = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
      Day = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
      Hour = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

      QriverObs_Day_M3 = convert(Vector, Tables.getcolumn(Data₀, :RiverDischarge_cumec))

      Time_Forcing = Date.(Year, Month, Day) #  <"standard"> "proleptic_gregorian" calendar

      # Selecting time which is between Start_DateTime and End_DateTime
      True = fill(false::Bool, length(Year))
      Threads.@threads for iT = 1:length(Year)
         if (DatesWflow[1] ≤ Time_Forcing[iT] ≤ DatesWflow[end])
            True[iT] = true
         end
         if Time_Forcing[iT] > EndDate
            break
         end
      end # for iT=1:Nit

      QriverObs_Day_M3 = QriverObs_Day_M3[True[:]] # m3/day
      QriverObs_Day_Mm = (QriverObs_Day_M3 ./ CatchmentArea) .* 1000.0 # cumec to mm/ m2 / day
   else
      QriverObs_Day_M3 = zeros(Float64, Nt)
      QriverObs_Day_Mm = zeros(Float64, Nt)
   end # if 🎏_Qobs

   # ~~~~~~~~~~~~~~~~  READING WFLOW OUTPUT  ~~~~~~~~~~~~~~~~
   DataWflow          = CSV.File(Path_Wflow_Csv_Output; header=true)
   Time_Wflow         = convert(Vector, Tables.getcolumn(DataWflow, :time))
   Qriver_Wflow       = convert(Vector{Float64}, Tables.getcolumn(DataWflow, QwflowName))
   QriverWflow_Day_M3 = Qriver_Wflow ./ Seconds_2_Days # cumec to m3/day
   QriverWflow_Day_Mm = (QriverWflow_Day_M3 ./ CatchmentArea) .* M_2_Mm # cumec to mm/ m2 / day


   # # ~~~~~~~~~~~~~~~~ PLOTTING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if 🎏_Plotting

      printstyled("	Plotting Wflow output... \n", color=:green)

      geoPlot.WFLOW_TIME(; 🎏_CatchmentName, 🎏_GLMakie=false, DatesWflow, Evapotranspiration_Mm, Forcing_ΔT="Daily", InfiltrationSoil_Mm, Nlayer, OverlandFlow_Mm, PotentialEvaporation_Mm, Precipitation_Mm, QriverObs_Day_Mm, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver)
   end

   # ~~~~~~~~~~~~~~~~  WRITTING CSV WFLOW OUTPUT  ~~~~~~~~~~~~~~~~
   # Water balance
   # [Precipitation_Mm] - Interception_Average[iT] = Stemflow_Average[iT] + Throughfall_Average[iT]

   Header = ["Date", "∑Precipitation[M3]", "∑PotentialEvapotranspiration[M3]", "∑InfiltrationSoil[M3]", "∑Evapotranspiration[M3]", "∑OverlandFlow[M3]", "∑SubsurfaceFlow[M3]", "QriverWflow_Day[M3]", "QriverObs_Day[M3]", "Precipitation[Mm]", "PotentialEvapotranspiration[Mm]", "InfiltrationSoil[Mm]", "Evapotranspiration[Mm]", "OverlandFlow[Mm]", "∑SubsurfaceFlow[Mm]", "QriverWflow[Mm]", "QriverObs[mm]"]

   CSV.write(Path_AverageFluxes_Csv, Tables.table([DatesWflow ∑Precipitation_M3 ∑PotentialEvapotranspiration_M3 ∑InfiltrationSoil_M3 ∑Evapotranspiration_M3 ∑OverlandFlow_M3 ∑SubsurfaceFlow_M3 QriverWflow_Day_M3 QriverObs_Day_M3 Precipitation_Mm PotentialEvaporation_Mm InfiltrationSoil_Mm Evapotranspiration_Mm OverlandFlow_Mm SubsurfaceFlow_Mm QriverWflow_Day_Mm QriverObs_Day_Mm]), writeheader=true, header=Header, bom=true)

   return ∑PotentialEvapotranspiration_M3, ∑Precipitation_M3, ∑SubsurfaceFlow_M3, DatesWflow, Evapotranspiration_Mm, InfiltrationSoil_Mm, Interception_Mm, OverlandFlow_Mm, PotentialEvaporation_Mm, QriverObs_Day_M3, QriverObs_Day_Mm, QriverWflow_Day_M3, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver
end  # function: WFLOW_PROCESS_OUTPUT()
# ------------------------------------------------------------------

end  # module: wflowModelProcess
# ............................................................