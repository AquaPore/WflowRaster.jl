# =============================================================
#		module: wflowModelProcess
# =============================================================
module wflowModelProcess

using CSV, Dates, Tables, NCDatasets, Dates, FLoops

include("GeoPlot.jl")
include("Efficiency.jl")

const M_2_Mm = 1000.0
const Mm_2_M = 0.001
const Seconds_2_Days = 60.0 * 60.0 * 24.0
const Days_2_Second = 1.0 / (60.0 * 60.0 * 24.0)

Threads.nthreads() = 32

Base.@kwdef mutable struct FLAGS
   🎏_PotentialEvapotranspiration::Bool = false
   🎏_θ::Bool = false
   🎏_ThroughfallStemflow = false

   🎏_OverlandDepth::Bool = false
   🎏_OverlandFlow::Bool = false
   🎏_SubsurfaceFlow::Bool = false
   🎏_Infiltration::Bool = false
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
   Evapotranspiration_NetCDF="land_surface__evapotranspiration_volume_flux",
   InfiltrationWflow_NetCDF="soil_water__infiltration_volume_flux",
   RainfallInterception_NetCDF="vegetation_canopy_water__interception_volume_flux",
   OverlandDepth_NetCDF="land_surface_water__depth",
   OverlandFlow_2_River_NetCDF="land_surface_water__to_river_volume_flow_rate",
   OverlandFlow_NetCDF="land_surface_water__volume_flow_rate",
   # OverlandVolume_NetCDF              = "land_surface_water__volume",
   PotentialEvapotranspiration_NetCDF="land_surface_water__potential_evaporation_volume_flux",
   Precipitation_NetCDF="atmosphere_water__precipitation_volume_flux",
   SoilLayerSoilMoisture_NetCDF="soil_layer_water__volume_fraction",
   SubsurfaceFlow_NetCDF="subsurface_water__volume_flow_rate",
   OverlandFlowInflow_NetCDF="land_qin_av",
   # Inwater_NetCDF = "inwater",
   🎏_Plotting=true,
   🎏_CatchmentName,
   🎏_Qobs=true,
   QwflowName,
   🎏_cell_length_in_meter__flag=true)


   # Reading NetCDF output files
   @assert isfile(joinpath(Path_Wflow_NetCDF_Output))
   println(Path_Wflow_NetCDF_Output)
   WflowOutput = NCDatasets.NCDataset(Path_Wflow_NetCDF_Output, "r", maskingvalue=NaN)

   # Keys of NetCDF variables
   Keys = NCDatasets.keys(WflowOutput)

   # Reading the availability of Wflow output
   flags = FLAGS()

   if RainfallInterception_NetCDF ∈ Keys
      flags.🎏_ThroughfallStemflow = true
      RainfallInterception = Array(WflowOutput[RainfallInterception_NetCDF]) # [mm Δt⁻¹]
   else
      RainfallInterception = []
   end

   if PotentialEvapotranspiration_NetCDF ∈ Keys
      flags.🎏_PotentialEvapotranspiration = true
      PotentialEvapotranspiration = Array(WflowOutput[PotentialEvapotranspiration_NetCDF]) # [mm Δt⁻¹]
   else
      PotentialEvapotranspiration = []
   end

   if SoilLayerSoilMoisture_NetCDF ∈ Keys
      θlayer = Array(WflowOutput[SoilLayerSoilMoisture_NetCDF]) # [m³ m⁻³]
      flags.🎏_θ = true
   else
      θlayer_Aver = []
   end

   if OverlandDepth_NetCDF ∈ Keys
      OverlandDepth = Array(WflowOutput[OverlandDepth_NetCDF]) # [m]
      flags.🎏_OverlandDepth = true
   else
      OverlandDepth_Mm = []
   end

   Precipitation = Array(WflowOutput[Precipitation_NetCDF]) # [mm Δt⁻¹]
   Evapotranspiration = Array(WflowOutput[Evapotranspiration_NetCDF]) # [mm Δt⁻¹]
   InfiltrationWflow = Array(WflowOutput[InfiltrationWflow_NetCDF]) # [mm Δt⁻¹]


   OverlandFlow = Array(WflowOutput[OverlandFlow_NetCDF])  # [m³ s⁻¹]
   OverlandFlow_2_River = Array(WflowOutput[OverlandFlow_2_River_NetCDF]) # [m³ s⁻¹]
   # OverlandVolume              = Array(WflowOutput[OverlandVolume_NetCDF]) # [m³] per cell

   SubsurfaceFlow = Array(WflowOutput[SubsurfaceFlow_NetCDF]) # [m³ day⁻¹]
   OverlandFlowInflow = Array(WflowOutput[OverlandFlowInflow_NetCDF]) # [m³s⁻¹ cell]

   # Inwater = Array(WflowOutput[Inwater_NetCDF])

   if 🎏_cell_length_in_meter__flag
      Xcoordinate = Array(WflowOutput["x"])
      Ycoordinate = Array(WflowOutput["y"])
   else
      Xcoordinate = Array(WflowOutput["lat"])
      Ycoordinate = Array(WflowOutput["lon"])
   end

   close(WflowOutput)

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


   # OverlandVolume[v] / OverlandDepth[v] = FlowLength_SurfaceFlowWidth[v]

   # Cell size and catchment area
   CellSize_M2 = ΔX * ΔY
   printstyled("	Grid resolution $CellSize_M2 m² = $ΔX m x $ΔY m \n", color=:green)
   CatchmentArea = CountCell * CellSize_M2  # m2
   printstyled("	Number of grids = $CountCell , CatchmentSize = $CatchmentArea  m² \n", color=:green)


   # INITIALIZING VARIABLES
   ∑Precipitation_M3 = zeros(Float64, Nt)
   Evapotranspiration_Mm = copy(∑Precipitation_M3)

   InfiltrationWflow_Mm = copy(∑Precipitation_M3)

   OverlandFlow_2_River_Mm = copy(∑Precipitation_M3)
   # OverlandFlow_Mm                 = copy(∑Precipitation_M3)
   OverlandFlowInflow_Mm = copy(∑Precipitation_M3)

   # OverlandFlow_Model_Mm           = zeros(Float64, Nt, 2)
   # OverlandVolume_Mm               = copy(∑Precipitation_M3)


   Precipitation_Mm = copy(∑Precipitation_M3)
   SubsurfaceFlow_Mm = copy(∑Precipitation_M3)

   ∑Evapotranspiration_M3 = copy(∑Precipitation_M3)

   ∑InfiltrationWflow_M3 = copy(∑Precipitation_M3)


   ∑OverlandFlow_2_River_M3 = copy(∑Precipitation_M3)
   ∑OverlandFlow_M3 = copy(∑Precipitation_M3)
   # ∑OverlandFlow_Model_M3          = zeros(Float64, Nt, 2)
   # ∑OverlandVolume_M3              = copy(∑Precipitation_M3)
   ∑OverlandFlowInflow_M3 = copy(∑Precipitation_M3)


   ∑SubsurfaceFlow_M3 = copy(∑Precipitation_M3)
   DatesWflow = fill(Date(StartYear, StartMonth, StartDay), Nt)

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
   end
   if flags.🎏_OverlandDepth
      OverlandDepth_Mm = copy(∑Precipitation_M3)
      ∑OverlandDepth_M3 = copy(∑Precipitation_M3)
   end
   if flags.🎏_θ
      θlayer_Aver = zeros(Float64, Nt, Nlayer)
   else
      θlayer_Aver = []
   end

   # Summing up every fluxes and calculating average fluxes in m³ /day/m² for each time step
   DatesWflow[1] = StartDate
   Count = 0
   Threads.@threads for iT = 1:Nt
      for iX = 1:Nx
         for iY = 1:Ny
            if NotMissing[iX, iY]
               ∑Precipitation_M3[iT] += Precipitation[iX, iY, iT] * Mm_2_M * CellSize_M2

               ∑Evapotranspiration_M3[iT] += Evapotranspiration[iX, iY, iT] * Mm_2_M * CellSize_M2

               ∑OverlandFlow_M3[iT] += OverlandFlow[iX, iY, iT] * Seconds_2_Days # m3/s to m3/day
               ∑OverlandFlowInflow_M3[iT] += OverlandFlowInflow[iX, iY, iT] * Seconds_2_Days # m3/s to m3/day

               ∑SubsurfaceFlow_M3[iT] += SubsurfaceFlow[iX, iY, iT]  # m3/day
               ∑InfiltrationWflow_M3[iT] += InfiltrationWflow[iX, iY, iT] * Mm_2_M * CellSize_M2
               # ∑OverlandVolume_M3[iT]                 += OverlandVolume[iX, iY, iT]

               if flags.🎏_ThroughfallStemflow
                  ∑RainfallInterception_M3[iT] += RainfallInterception[iX, iY, iT] * Mm_2_M * CellSize_M2
                  ∑ThroughfallStemflow_M3[iT] = ∑Precipitation_M3[iT] - ∑RainfallInterception_M3[iT]
               end

               if flags.🎏_PotentialEvapotranspiration
                  ∑PotentialEvapotranspiration_M3[iT] += PotentialEvapotranspiration[iX, iY, iT] * Mm_2_M * CellSize_M2
               end

               if flags.🎏_OverlandDepth
                  ∑OverlandDepth_M3[iT] += OverlandDepth[iX, iY, iT] * CellSize_M2
               end

               if flags.🎏_θ
                  for iLayer = 1:Nlayer-1
                     θlayer_Aver[iT, iLayer] += θlayer[iX, iY, iLayer, iT]
                  end
               end

               Count = 0
               if !isnan(OverlandFlow_2_River[iX, iY, iT])
                  ∑OverlandFlow_2_River_M3[iT] += OverlandFlow_2_River[iX, iY, iT] * CellSize_M2 * Seconds_2_Days # m3/s to m3/day
               end



               # if iT ≥ 2
               #    ΔT =1.0 # day
               #       ∑OverlandFlow_Model_M3[iT,1] += (OverlandDepth[iX, iY, iT] - OverlandDepth[iX, iY, iT-1]) * CellSize_M2 / ΔT # m3/day

               #    ∑OverlandFlow_Model_M3[iT,2] += ((OverlandFlowInflow[iX, iY, iT] + Inwater[iX, iY, iT]) - OverlandFlow[iX, iY, iT] ) * Seconds_2_Days
               # end

            end # if NotMissing[iX, iY]

         end # for iX=1:Nx
      end # for  iY=1:Ny m³ s⁻¹ m²

      Precipitation_Mm[iT] = ∑Precipitation_M3[iT] * M_2_Mm / CatchmentArea

      # RainfallInterception_Mm             = ∑RainfallInterception_M3[iT] * M_2_Mm / CatchmentArea

      # ThroughfallStemflow_Mm[iT]     = Precipitation_Mm[iT] - RainfallInterception_Mm

      InfiltrationWflow_Mm[iT] = ∑InfiltrationWflow_M3[iT] * M_2_Mm / CatchmentArea
      Evapotranspiration_Mm[iT] = ∑Evapotranspiration_M3[iT] * M_2_Mm / CatchmentArea


      # OverlandFlow_Mm[iT]         = ∑OverlandFlow_M3[iT] * M_2_Mm / CatchmentArea

      OverlandFlow_2_River_Mm[iT] = ∑OverlandFlow_2_River_M3[iT] * M_2_Mm / CatchmentArea

      SubsurfaceFlow_Mm[iT] = ∑SubsurfaceFlow_M3[iT] * M_2_Mm / CatchmentArea



      # OverlandVolume_Mm[iT]       = ∑OverlandVolume_M3[iT] * M_2_Mm / CatchmentArea

      if flags.🎏_ThroughfallStemflow
         ThroughfallStemflow_Mm[iT] = ∑ThroughfallStemflow_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_PotentialEvapotranspiration
         PotentialEvaporation_Mm[iT] = ∑PotentialEvapotranspiration_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_OverlandDepth
         OverlandDepth_Mm[iT] = ∑OverlandDepth_M3[iT] * M_2_Mm / CatchmentArea
      end

      if flags.🎏_θ
         for iLayer = 1:Nlayer-1
            θlayer_Aver[iT, iLayer] = θlayer_Aver[iT, iLayer] / CountCell
         end
      end

      # if iT ≥ 2
      #    ΔT =1.0 # day
      #    OverlandFlow_Model_Mm[iT,1] = ∑OverlandFlow_Model_M3[iT,1] * M_2_Mm / CatchmentArea
      #    OverlandFlow_Model_Mm[iT,2] = ∑OverlandFlow_Model_M3[iT,2] * M_2_Mm / CatchmentArea
      # end

      DatesWflow[iT] += Dates.Day(iT)
   end # for iT=1:Nt

   sum_OverlandFlow_2_River_Mm = sum(OverlandFlow_2_River_Mm)
   printstyled("    OverlandFlow_2_River_Mm = $sum_OverlandFlow_2_River_Mm \n", color=:green)

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
      QriverObs_Day_Mm = (QriverObs_Day_M3 ./ CatchmentArea) .* 1000.0 # cumec to mm/ m2 / day
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
   🎏_Plotting = true
   if 🎏_Plotting
      printstyled("	Plotting Wflow output... \n", color=:green)

      geoPlot.WFLOW_TIME(; 🎏_CatchmentName, 🎏_GLMakie=false, DatesWflow, Efficiency_Kge, Evapotranspiration_Mm, flags, Forcing_ΔT="Daily", ThroughfallStemflow_Mm, InfiltrationWflow_Mm, Nlayer, OverlandDepth_Mm, OverlandFlow_2_River_Mm, PotentialEvaporation_Mm, Precipitation_Mm, QriverObs_Day_Mm, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver)
   end

   # ~~~~~~~~~~~~~~~~  WRITTING CSV WFLOW OUTPUT  ~~~~~~~~~~~~~~~~
   # Water balance
   # [Precipitation_Mm] - Interception_Average[iT] = Stemflow_Average[iT] + Throughfall_Average[iT]

   Header = ["Date", "∑Precipitation[M3]", "∑PotentialEvapotranspiration[M3]", "∑InfiltrationSoil[M3]", "∑Evapotranspiration[M3]", "∑OverlandFlow[M3]", "∑SubsurfaceFlow[M3]", "QriverWflow_Day[M3]", "QriverObs_Day[M3]", "Precipitation[Mm]", "PotentialEvapotranspiration[Mm]", "InfiltrationSoil[Mm]", "Evapotranspiration[Mm]", "OverlandFlow[Mm]", "∑SubsurfaceFlow[Mm]", "QriverWflow[Mm]", "QriverObs[mm]"]

   CSV.write(Path_AverageFluxes_Csv, Tables.table([DatesWflow ∑Precipitation_M3 ∑PotentialEvapotranspiration_M3 ∑ThroughfallStemflow_M3 ∑Evapotranspiration_M3 ∑OverlandFlow_M3 ∑SubsurfaceFlow_M3 QriverWflow_Day_M3 QriverObs_Day_M3 Precipitation_Mm PotentialEvaporation_Mm ThroughfallStemflow_Mm Evapotranspiration_Mm SubsurfaceFlow_Mm QriverWflow_Day_Mm QriverObs_Day_Mm]), writeheader=true, header=Header, bom=true)

   # Cleaning up
   GC.gc()
   GC.gc()

   return ∑PotentialEvapotranspiration_M3, ∑Precipitation_M3, ∑SubsurfaceFlow_M3, DatesWflow, Efficiency_Kge, Evapotranspiration_Mm, ThroughfallStemflow_Mm, RainfallInterception_Mm, PotentialEvaporation_Mm, QriverObs_Day_M3, QriverObs_Day_Mm, QriverWflow_Day_M3, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver
end  # function: WFLOW_PROCESS_OUTPUT()
# ------------------------------------------------------------------

end  # module: wflowModelProcess
# ............................................................



