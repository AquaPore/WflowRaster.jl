# =============================================================
#		module: wflowModelProcess
# =============================================================
module wflowModelProcess

using CSV, Dates, Tables, NCDatasets, Dates

include("GeoPlot.jl")
include("Efficiency.jl")

const M_2_Mm = 1000.0
const Mm_2_M = 0.001
const Seconds_2_Days = 60.0 * 60.0 * 24.0
const Days_2_Second = 1.0 / (60.0 * 60.0 * 24.0)

Threads.nthreads() = 32

Base.@kwdef mutable struct FLAGS
   🎏_Precipitation = false
   🎏_θ::Bool = false
   🎏_ThroughfallStemflow = false
   🎏_PotentialEvapotranspiration::Bool = false
   🎏_Evapotranspiration = false
   🎏_SoilInfiltration = false

   🎏_Runoff::Bool = false
   🎏_OverlandFlow2River::Bool = false
   🎏_SubsurfaceFlow2River::Bool = false
   🎏_GroundwaterFlow2River::Bool = false
end

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : WFLOW_PROCESS_OUTPUT()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
Plotting of Wflow output and writting csv file of average fluxes. The function also returns the average fluxes and soil moisture for each layer.
```
function WFLOW_PROCESS_OUTPUT(; EndDate,
   Path_AverageFluxes_Csv,
   Path_Qobs,
   Path_Wflow_Csv_Output,
   Path_Wflow_NetCDF_Output,
   StartDate,
   StartDay,
   StartMonth,
   StartYear,
   Precipitation_NetCDF               = "atmosphere_water__precipitation_volume_flux",
   PotentialEvapotranspiration_NetCDF = "land_surface_water__potential_evaporation_volume_flux",
   Evapotranspiration_NetCDF          = "land_surface__evapotranspiration_volume_flux",
   RainfallInterception_NetCDF        = "vegetation_canopy_water__interception_volume_flux",
   SoilLayerSoilMoisture_NetCDF       = "soil_layer_water__volume_fraction",
   SoilInfiltration_NetCDF            = "soil_water__infiltration_volume_flux",
   OverlandFlow_2_River_NetCDF        = "land_surface_water__to_river_volume_flow_rate",
   Runoff_NetCDF                      = "soil_surface_water__runoff_volume_flux",
   SubsurfaceFlow_2_River_NetCDF      = "subsurface_water__to_river_volume_flow_rate",
   GroundwaterFlow_2_River_NetCDF     = "river_water__to_subsurface_volume_flow_rate",
   🎏_Plotting                        = true,
   🎏_CatchmentName,
   🎏_Qobs                            = true,
   QwflowName,
   🎏_cell_length_in_meter__flag      = true,
   🎏_Table                           = false)

   # READING NETCDF OUTPUT FILES
      @assert isfile(joinpath(Path_Wflow_NetCDF_Output))
      println(Path_Wflow_NetCDF_Output)
      WflowOutput = NCDatasets.NCDataset(Path_Wflow_NetCDF_Output, "r", maskingvalue=NaN)

      if 🎏_cell_length_in_meter__flag
         Xcoordinate = Array(WflowOutput["x"])
         Ycoordinate = Array(WflowOutput["y"])
      else
         Xcoordinate = Array(WflowOutput["lat"])
         Ycoordinate = Array(WflowOutput["lon"])
      end

   # READING AVAILABILITY OF WFLOW OUTPUT

      # Keys of NetCDF variables
      Keys = NCDatasets.keys(WflowOutput)

      # Reading flags for the availability of Wflow output
      flags = FLAGS()

      if Precipitation_NetCDF ∈ Keys
         flags.🎏_Precipitation = true
         Precipitation = Array(WflowOutput[Precipitation_NetCDF]) # [mm Δt⁻¹]
      else
         Precipitation = []
      end # if Precipitation_NetCDF ∈ Keys

      if RainfallInterception_NetCDF ∈ Keys
         flags.🎏_ThroughfallStemflow = true
         RainfallInterception = Array(WflowOutput[RainfallInterception_NetCDF]) # [mm Δt⁻¹]
      else
         RainfallInterception = []
      end # if RainfallInterception_NetCDF ∈ Keys

      if PotentialEvapotranspiration_NetCDF ∈ Keys
         flags.🎏_PotentialEvapotranspiration = true
         PotentialEvapotranspiration = Array(WflowOutput[PotentialEvapotranspiration_NetCDF]) # [mm Δt⁻¹]
      else
         PotentialEvapotranspiration = []
      end # if PotentialEvapotranspiration_NetCDF ∈ Keys

      if Evapotranspiration_NetCDF ∈ Keys
         flags.🎏_Evapotranspiration = true
         Evapotranspiration = Array(WflowOutput[Evapotranspiration_NetCDF]) # [mm Δt⁻¹]
      else
         Evapotranspiration = []
      end  # if: Evapotranspiration_NetCDF

      if SoilInfiltration_NetCDF ∈ Keys
         flags.🎏_SoilInfiltration = true
         SoilInfiltration = Array(WflowOutput[SoilInfiltration_NetCDF]) # [mm Δt⁻¹]
      else
         SoilInfiltration = []
      end # if SoilInfiltration_NetCDF ∈ Keys

      if SoilLayerSoilMoisture_NetCDF ∈ Keys
         θlayer = Array(WflowOutput[SoilLayerSoilMoisture_NetCDF]) # [m³ m⁻³]
         flags.🎏_θ = true
      else
         θlayer = []
      end # if SoilLayerSoilMoisture_NetCDF ∈ Keys

      if Runoff_NetCDF ∈ Keys
         Runoff = Array(WflowOutput[Runoff_NetCDF]) # [mm day⁻³]
         flags.🎏_Runoff = true
      else
         Runoff = []
      end # if Runoff_NetCDF ∈ Keys

      if OverlandFlow_2_River_NetCDF ∈ Keys
         flags.🎏_OverlandFlow2River = true
         OverlandFlow_2_River = Array(WflowOutput[OverlandFlow_2_River_NetCDF]) # [m³ s⁻¹]
      else
         OverlandFlow_2_River = []
      end  # if OverlandFlow_2_River_NetCDF ∈ Keys

      if SubsurfaceFlow_2_River_NetCDF ∈ Keys
         SubsurfaceFlow = Array(WflowOutput[SubsurfaceFlow_2_River_NetCDF]) # [m³ day⁻¹]
         flags.🎏_SubsurfaceFlow2River = true
      else
         SubsurfaceFlow = []
      end # if SubsurfaceFlow_2_River_NetCDF ∈ Keys

      if GroundwaterFlow_2_River_NetCDF ∈ Keys
         GroundwaterFlow = Array(WflowOutput[GroundwaterFlow_2_River_NetCDF]) # [m³ day⁻¹]
         flags.🎏_GroundwaterFlow2River = true
      else
         GroundwaterFlow = []
      end # if GroundwaterFlow_2_River_NetCDF ∈ Keys

      close(WflowOutput)

   # OverlandFlow = Array(WflowOutput[OverlandFlow_NetCDF])  # [m³ s⁻¹]
   # OverlandVolume              = Array(WflowOutput[OverlandVolume_NetCDF]) # [m³] per cell
   # OverlandFlowInflow = Array(WflowOutput[OverlandFlowInflow_NetCDF]) # [m³s⁻¹ cell]
   # Inwater = Array(WflowOutput[Inwater_NetCDF])


   # METADATA
      Nx, Ny, Nt = size(Precipitation)
      Nlayer = size(θlayer)[3] # Number of soil layers
      printstyled("	Number of soil layers = $Nlayer \n", color=:green)

      ΔX = Xcoordinate[3] - Xcoordinate[2]
      ΔY = Ycoordinate[3] - Ycoordinate[2]

      # Counting active cells
      NotMissing = fill(false, Nx, Ny)
      CountCell = Threads.Atomic{Int}(0)
      Threads.@threads for iX = 1:Nx
         Threads.@threads for iY = 1:Ny
            if !isnan(Precipitation[iX, iY, 10])
               Threads.atomic_add!(CountCell, 1) # Safe addition
               NotMissing[iX, iY] = true
            end
         end
      end
      CountCell = CountCell[] # convert atomic to regular integer
      # OverlandVolume[v] / Runoff[v] = FlowLength_SurfaceFlowWidth[v]

      # Cell size and catchment area
      CellSize_M2 = ΔX * ΔY
      printstyled("	Grid resolution $CellSize_M2 m² = $ΔX m x $ΔY m \n", color=:green)
      CatchmentArea = CountCell * CellSize_M2  # m2
      printstyled("	Number of grids = $CountCell , CatchmentSize = $CatchmentArea  m² \n", color=:green)


   # INITIALIZING ARRAYS
      DatesWflow = fill(Date(StartYear, StartMonth, StartDay), Nt)

      if flags.🎏_Precipitation
         ∑Precipitation_M3 = zeros(Float64, Nt)
         Precipitation_Mm = copy(∑Precipitation_M3)
      else
         ∑Precipitation_M3 = []
         Precipitation_Mm = []
      end

      if flags.🎏_ThroughfallStemflow
         RainfallInterception_Mm = 0.0
         ∑RainfallInterception_M3 = copy(∑Precipitation_M3)
         ∑ThroughfallStemflow_M3 = copy(∑Precipitation_M3)
         ThroughfallStemflow_Mm = copy(∑Precipitation_M3)
      else
         RainfallInterception_Mm = 0.0
         ∑ThroughfallStemflow_M3 = []
         ThroughfallStemflow_Mm = []
      end

      if flags.🎏_PotentialEvapotranspiration
         PotentialEvaporation_Mm = copy(∑Precipitation_M3)
         ∑PotentialEvapotranspiration_M3 = copy(∑Precipitation_M3)
      else
         PotentialEvaporation_Mm = []
         ∑PotentialEvapotranspiration_M3 = []
      end

      if flags.🎏_Evapotranspiration
         ∑Evapotranspiration_M3 = copy(∑Precipitation_M3)
         Evapotranspiration_Mm = copy(∑Precipitation_M3)
      else
         ∑Evapotranspiration_M3 = []
         Evapotranspiration_Mm = []
      end

      if flags.🎏_SoilInfiltration
         SoilInfiltration_Mm = copy(∑Precipitation_M3)
         ∑SoilInfiltration_M3 = copy(∑Precipitation_M3)
      else
         SoilInfiltration_Mm = []
         ∑SoilInfiltration_M3 = []
      end

      if flags.🎏_Runoff
         Runoff_Mm = copy(∑Precipitation_M3)
         ∑Runoff_M3 = copy(∑Precipitation_M3)
      else
         Runoff_Mm = []
         ∑Runoff_M3 = []
      end

      if flags.🎏_θ
         θlayer_Aver = zeros(Float64, Nt, Nlayer)
      else
         θlayer_Aver = []
      end

      if flags.🎏_OverlandFlow2River
         OverlandFlow_2_River_Mm  = copy(∑Precipitation_M3)
         ∑OverlandFlow_2_River_M3 = copy(∑Precipitation_M3)
      else
         OverlandFlow_2_River_Mm  = []
         ∑OverlandFlow_2_River_M3 = []
      end

      if flags.🎏_SubsurfaceFlow2River
         SubsurfaceFlow_Mm  = copy(∑Precipitation_M3)
         ∑SubsurfaceFlow_M3 = copy(∑Precipitation_M3)
      else
         SubsurfaceFlow_Mm  = []
         ∑SubsurfaceFlow_M3 = []
      end

      if flags.🎏_GroundwaterFlow2River
         GroundwaterFlow_2_River_Mm  = copy(∑Precipitation_M3)
         ∑GroundwaterFlow_2_River_M3 = copy(∑Precipitation_M3)
      else
         GroundwaterFlow_2_River_Mm  = []
         ∑GroundwaterFlow_2_River_M3 = []
      end

   # ∑OverlandFlow_M3 = copy(∑Precipitation_M3)
   # ∑OverlandFlow_Model_M3          = zeros(Float64, Nt, 2)
   # ∑OverlandVolume_M3              = copy(∑Precipitation_M3)
   # ∑OverlandFlowInflow_M3 = copy(∑Precipitation_M3)
   # OverlandFlow_Model_Mm           = zeros(Float64, Nt, 2)
   # OverlandVolume_Mm               = copy(∑Precipitation_M3)
   # OverlandFlow_Mm                 = copy(∑Precipitation_M3)
   # OverlandFlowInflow_Mm = copy(∑Precipitation_M3)

   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   # Summing up every fluxes and calculating average fluxes in m³ /day/m² for each time step
   DatesWflow[1] = StartDate
   Count = 0
   Threads.@threads for iT = 1:Nt
      # CountRiver = Threads.Atomic{Int}(0)
      for iX = 1:Nx
         for iY = 1:Ny
            if NotMissing[iX, iY]

               if flags.🎏_Precipitation
                  ∑Precipitation_M3[iT] += Precipitation[iX, iY, iT] * Mm_2_M * CellSize_M2
               end

               if flags.🎏_ThroughfallStemflow
                  ∑RainfallInterception_M3[iT] += RainfallInterception[iX, iY, iT] * Mm_2_M * CellSize_M2
                  ∑ThroughfallStemflow_M3[iT] = ∑Precipitation_M3[iT] - ∑RainfallInterception_M3[iT]
               end

               if flags.🎏_PotentialEvapotranspiration
                  ∑PotentialEvapotranspiration_M3[iT] += PotentialEvapotranspiration[iX, iY, iT] * Mm_2_M * CellSize_M2
               end

               if flags.🎏_Evapotranspiration
                  ∑Evapotranspiration_M3[iT] += Evapotranspiration[iX, iY, iT] * Mm_2_M * CellSize_M2
               end

               if flags.🎏_SoilInfiltration
                  ∑SoilInfiltration_M3[iT] += SoilInfiltration[iX, iY, iT] * Mm_2_M * CellSize_M2
               end

               if flags.🎏_Runoff
                  ∑Runoff_M3[iT] += Runoff[iX, iY, iT] * Mm_2_M * CellSize_M2
               end

               if flags.🎏_θ
                  for iLayer = 1:Nlayer-1
                     θlayer_Aver[iT, iLayer] += θlayer[iX, iY, iLayer, iT]
                  end
               end

               if flags.🎏_OverlandFlow2River
                  if OverlandFlow_2_River[iX, iY, iT] > 0.0
                     ∑OverlandFlow_2_River_M3[iT] += OverlandFlow_2_River[iX, iY, iT] * Seconds_2_Days # [m³ s⁻¹] to [m³ day⁻¹]
                     # Threads.atomic_add!(CountRiver, 1) # Safe addition
                  end
               end

               if flags.🎏_SubsurfaceFlow2River
                  ∑SubsurfaceFlow_M3[iT] += SubsurfaceFlow[iX, iY, iT]  # [m³ day⁻¹]
               end

               if flags.🎏_GroundwaterFlow2River
                  if !isnan(GroundwaterFlow[iX, iY, iT])
                     ∑GroundwaterFlow_2_River_M3[iT] += GroundwaterFlow[iX, iY, iT]  # [m³ day⁻¹]
                  end
               end

               # ∑OverlandFlow_M3[iT] += OverlandFlow[iX, iY, iT] * Seconds_2_Days # m3/s to m3/day
               # ∑OverlandFlowInflow_M3[iT] += OverlandFlowInflow[iX, iY, iT] * Seconds_2_Days # m3/s to m3/day
               # ∑OverlandVolume_M3[iT]                 += OverlandVolume[iX, iY, iT]

               # if iT ≥ 2
               #    ΔT =1.0 # day
               #       ∑OverlandFlow_Model_M3[iT,1] += (Runoff[iX, iY, iT] - Runoff[iX, iY, iT-1]) * CellSize_M2 / ΔT # m3/day

               #    ∑OverlandFlow_Model_M3[iT,2] += ((OverlandFlowInflow[iX, iY, iT] + Inwater[iX, iY, iT]) - OverlandFlow[iX, iY, iT] ) * Seconds_2_Days
               # end

            end # if NotMissing[iX, iY]

         end # for iX=1:Nx
      end # for  iY=1:Ny m³ s⁻¹ m²


      if flags.🎏_Precipitation
         Precipitation_Mm[iT] = ∑Precipitation_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_ThroughfallStemflow
         ThroughfallStemflow_Mm[iT] = ∑ThroughfallStemflow_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_PotentialEvapotranspiration
         PotentialEvaporation_Mm[iT] = ∑PotentialEvapotranspiration_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_Evapotranspiration
         Evapotranspiration_Mm[iT] = ∑Evapotranspiration_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_SoilInfiltration
         SoilInfiltration_Mm[iT] = ∑SoilInfiltration_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_Runoff
         Runoff_Mm[iT] = ∑Runoff_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_θ
         for iLayer = 1:Nlayer-1
            θlayer_Aver[iT, iLayer] = θlayer_Aver[iT, iLayer] / CountCell
         end
      end

      if flags.🎏_OverlandFlow2River
         OverlandFlow_2_River_Mm[iT] = ∑OverlandFlow_2_River_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_SubsurfaceFlow2River
         SubsurfaceFlow_Mm[iT] = ∑SubsurfaceFlow_M3[iT] * M_2_Mm / CatchmentArea
      end


      if flags.🎏_GroundwaterFlow2River
         GroundwaterFlow_2_River_Mm[iT] += ∑GroundwaterFlow_2_River_M3[iT] * M_2_Mm / CatchmentArea # [m³ day⁻¹]
      end

      # OverlandVolume_Mm[iT]       = ∑OverlandVolume_M3[iT] * M_2_Mm / CatchmentArea
      # OverlandFlow_Mm[iT]         = ∑OverlandFlow_M3[iT] * M_2_Mm / CatchmentArea

      # RainfallInterception_Mm             = ∑RainfallInterception_M3[iT] * M_2_Mm / CatchmentArea
      #  ThroughfallStemflow_Mm[iT]     = Precipitation_Mm[iT] - RainfallInterception_Mm

      # if iT ≥ 2
      #    ΔT =1.0 # day
      #    OverlandFlow_Model_Mm[iT,1] = ∑OverlandFlow_Model_M3[iT,1] * M_2_Mm / CatchmentArea
      #    OverlandFlow_Model_Mm[iT,2] = ∑OverlandFlow_Model_M3[iT,2] * M_2_Mm / CatchmentArea
      # end

      DatesWflow[iT] += Dates.Day(iT)
      # println("CountRiver=$CountRiver[]")
   end # for iT=1:Nt

   # Printing
   if flags.🎏_OverlandFlow2River
      sum_OverlandFlow_2_River_Mm = sum(OverlandFlow_2_River_Mm)
      printstyled("    OverlandFlow_2_River_Mm = $sum_OverlandFlow_2_River_Mm \n", color=:green)
   end

   if flags.🎏_ThroughfallStemflow
      InterceptionLost = 100.0 * sum(∑RainfallInterception_M3) / sum(∑Precipitation_M3)
      printstyled("	RainfallInterception lost = $(floor(InterceptionLost)) %  \n", color=:green)
   end

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
      QriverObs_Day_Mm = (QriverObs_Day_M3 ./ CatchmentArea) .* M_2_Mm # cumec to mm/ m2 / day
   else
      QriverObs_Day_M3 = zeros(Float64, Nt)
      QriverObs_Day_Mm = zeros(Float64, Nt)
   end # if 🎏_Qobs

   # ~~~~~~~~~~~~~~~~  READING WFLOW OUTPUT  ~~~~~~~~~~~~~~~~
   DataWflow = CSV.File(Path_Wflow_Csv_Output; header=true)
   Time_Wflow = convert(Vector, Tables.getcolumn(DataWflow, :time))
   Qriver_Wflow = convert(Vector{Float64}, Tables.getcolumn(DataWflow, QwflowName))

   QriverWflow_Day_M3 = Qriver_Wflow .* Seconds_2_Days # cumec to m3/day
   QriverWflow_Day_Mm = (QriverWflow_Day_M3 ./ CatchmentArea) .* M_2_Mm # cumec to mm/ m2 / day


   # ~~~~~~~~~~~~~~~~  STATISCIS  ~~~~~~~~~~~~~~~~
   # Calculating Kling-Gupta efficiency (KGE) between observed and simulated river discharge
   Efficiency_Kge = efficiency.KLING_GUPTA_EFFICIENCY(; Qobs=QriverObs_Day_Mm, Qsim=QriverWflow_Day_Mm)
   printstyled("	Kling-Gupta efficiency (KGE) between observed and simulated river discharge = $Efficiency_Kge", color=:green)


   # # ~~~~~~~~~~~~~~~~ PLOTTING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if 🎏_Plotting
      printstyled("\n	=== Plotting Wflow output... === \n", color=:red)

      geoPlot.WFLOW_TIME(; 🎏_CatchmentName, 🎏_GLMakie=false, DatesWflow, Efficiency_Kge, Evapotranspiration_Mm, flags, Forcing_ΔT="Daily", ThroughfallStemflow_Mm, SoilInfiltration_Mm, Nlayer, Runoff_Mm, OverlandFlow_2_River_Mm, PotentialEvaporation_Mm, Precipitation_Mm, QriverObs_Day_Mm, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver, GroundwaterFlow_2_River_Mm)
   end

   # ~~~~~~~~~~~~~~~~  WRITTING CSV WFLOW OUTPUT  ~~~~~~~~~~~~~~~~
   # Water balance
   # [Precipitation_Mm] - Interception_Average[iT] = Stemflow_Average[iT] + Throughfall_Average[iT]

   if 🎏_Table
      Header = ["Date", "∑Precipitation[M3]", "∑PotentialEvapotranspiration[M3]", "∑InfiltrationSoil[M3]", "∑Evapotranspiration[M3]", "∑OverlandFlow[M3]", "∑SubsurfaceFlow[M3]", "QriverWflow_Day[M3]", "QriverObs_Day[M3]", "Precipitation[Mm]", "PotentialEvapotranspiration[Mm]", "InfiltrationSoil[Mm]", "Evapotranspiration[Mm]", "∑SubsurfaceFlow[Mm]", "QriverWflow[Mm]", "QriverObs[mm]"]

      CSV.write(Path_AverageFluxes_Csv, Tables.table([DatesWflow ∑Precipitation_M3 ∑PotentialEvapotranspiration_M3 ∑ThroughfallStemflow_M3 ∑Evapotranspiration_M3 ∑SubsurfaceFlow_M3 QriverWflow_Day_M3 QriverObs_Day_M3 Precipitation_Mm PotentialEvaporation_Mm ThroughfallStemflow_Mm Evapotranspiration_Mm SubsurfaceFlow_Mm QriverWflow_Day_Mm QriverObs_Day_Mm]), writeheader=true, header=Header, bom=true)
   end

   # Cleaning up
   GC.gc()
   GC.gc()

   return nothing
   # return ∑PotentialEvapotranspiration_M3, ∑Precipitation_M3, ∑SubsurfaceFlow_M3, DatesWflow, Efficiency_Kge, Evapotranspiration_Mm, ThroughfallStemflow_Mm, RainfallInterception_Mm, PotentialEvaporation_Mm, QriverObs_Day_M3, QriverObs_Day_Mm, QriverWflow_Day_M3, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver
end  # function: WFLOW_PROCESS_OUTPUT()
# ------------------------------------------------------------------

end  # module: wflowModelProcess
# ............................................................



