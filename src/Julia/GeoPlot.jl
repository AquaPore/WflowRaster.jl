
module geoPlot
using CairoMakie, Colors, ColorSchemes, GLMakie, Dates
using NCDatasets, Statistics


include("Parameters.jl")
include("PlotParameter.jl")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : HEATMAP
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function HEATMAP(; 🎏_Colorbar=true, Input, Label="", Title, Xlabel=L"$Latitude$", Ylabel=L"$Longitude$", titlecolor=titlecolor, titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=:viridis, Yreversed=false, ColorReverse=false, MinValue=NaN, MaxValue=NaN, Categorical=false)

   CairoMakie.activate!()
   Fig_100 = CairoMakie.Figure()

   Axis_100 = CairoMakie.Axis(Fig_100[1, 1], title=Title, xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor)

   Axis_100.yreversed = Yreversed

   Ncategories = 1

   if isnan(MinValue)
      MinValue = minimum(X for X ∈ Input if !isnan(X) && !ismissing(X))
      #  MinValue = minimum(skipmissing(Input))
   end
   if isnan(MaxValue)
      MaxValue = maximum(X for X ∈ Input if !isnan(X) && !ismissing(X))
      #  MaxValue = maximum(skipmissing(Input))
   end
   Ncategories = Int64(floor(MaxValue - MinValue) + 1)
   # Ncategories=10

   if ColorReverse
      Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=Reverse(cgrad(colormap, 12, categorical=Categorical)), colorrange=(MinValue, MaxValue))
   else
      Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=cgrad(colormap, Ncategories, categorical=Categorical), colorrange=(MinValue, MaxValue))
      println(Ncategories)
   end

   if 🎏_Colorbar
      CairoMakie.Colorbar(Fig_100[1, 2], Map_100, label=Label, width=15, ticksize=15, tickalign=0.5)
   end

   CairoMakie.display(Fig_100)
   return nothing
end  # function: HEATMAP
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : HEATMAP_TIME
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function HEATMAP_TIME(; Path=Path, NameOutput="temp", Layer=1, 🎏_Reverse=false, Multiply=1)
   Output_NCDatasets = NCDatasets.NCDataset(Path)

   iTime = 1
   # using GLMakie
   GLMakie.activate!()
   Makie.inline!(false)  # Make sure to inline plots into Documenter output!

   Data = Output_NCDatasets[NameOutput]
   Data = Array(Data)
   Dimensions = length(size(Data))

   Data =  Data .* Multiply

   if Dimensions == 3
      N_Lon = size(Data)[1]
      N_Lat = size(Data)[2]
      N_Time = size(Data)[3]

   elseif Dimensions == 4
      N_Lon = size(Data)[1]
      N_Lat = size(Data)[2]
      N_Time = size(Data)[4]
   end

   println(Dimensions)
   @show N_Lon N_Lat N_Time Layer

   Pmin, Pmax = extrema(x for x ∈ skipmissing(Data) if !isnan(x))
   @show Pmin, Pmax

   if Pmax < Pmin + 0.0001
      Pmax = Pmax * 1.1 + 0.0001
      println(" max == Pmin")
   end

   # # Pmin = minimum(skipmissing(Data))
   # # Pmax = maximum(skipmissing(Data))

   function DATA_3D_2_2D(Data; iTime=iTime, Layer=Layer)
      if Dimensions == 4
         return Data[:, :, Layer, iTime]
      elseif Dimensions == 3
         return Data[:, :, iTime]
      end
   end

   # Fig = GLMakie.Figure(Width=800, Height=600)
   Fig = GLMakie.Figure()

   if Dimensions == 4
      Title = "$NameOutput , Layer = $Layer"
   elseif Dimensions == 3
      return Data[:, :, iTime]
   end

   Ax_1 = GLMakie.Axis(Fig[1, 1], title=Title, xlabelsize=xlabelSize, ylabelsize=xlabelSize, xticksize=xticksize, xgridvisible=xgridvisible, ygridvisible=xgridvisible, aspect=1)

   Ax_1.yreversed = 🎏_Reverse

   sg = GLMakie.SliderGrid(Fig[2, 1],
      (label="iTime", range=1:1:N_Time, startvalue=1),
      width=550, tellheight=true)

   iTime = sg.sliders[1].value

   Data_Time = GLMakie.lift((iTime) -> DATA_3D_2_2D(Data; iTime=iTime, Layer=Layer), iTime)

   Data_Plot = GLMakie.heatmap!(Ax_1, 1:N_Lon, 1:N_Lat, Data_Time, colorrange=(Pmin, Pmax), colormap=:hawaii50)

   GLMakie.Colorbar(Fig[1, 2], Data_Plot; label=NameOutput, width=20, ticks=Pmin:(Pmax-Pmin)/5:Pmax)
   GLMakie.colsize!(Fig.layout, 1, GLMakie.Aspect(1, 1.0))

   Fig
end # HEATMAP_TIME
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : HEATMAP_LAI
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function HEATMAP_LAI(; colormap=:viridis, DaySentinel₁, Fapar_2, Fvc_2, Lai_2, MonthSentinel₁, Ndvi_2, Path_Plot, titlecolor=titlecolor, titlesize=titlesize, Xlabel=L"$Latitude$", xlabelSize=xlabelSize, xticksize=xticksize, YearSentinel₁, Ylabel=L"$Longitude$", ylabelsize=ylabelsize, yticksize=yticksize, Width=600, Height=400, Dpi=100, Lai_Raw, Fapar_Raw, Ndvi_Raw, Fvc_Raw, LaiCloudTrue_2, FaparCloudTrue_2, FvcCloudTrue_2, ΔMaxMin_Lai, Rasterize=0.5, CloudCoverPercent, TransperencyCloud=0.1)

   ylabelsize = 14
   xlabelSize = 14

   CairoMakie.activate!(type="svg", px_per_unit=0.5)

   # size=(3 * Width, 4 * Height)
   Fig = Makie.Figure(; font="Sans", titlesize=15, labelsize=10, fontsize=10, backgroundcolor=:transparent)

   TitlePage = "TIMOLEAGUE: Year=$(YearSentinel₁), Month=$(MonthSentinel₁), Day=$(DaySentinel₁), ΔchangeMax= $(string(floor(ΔMaxMin_Lai*100))), CloudCover=$(floor(CloudCoverPercent*100)) %"

   #__________________________________________________________________________________________________


   Axis_Lai_B = Makie.Axis(Fig[1, 1], title="Lai Raw", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height, backgroundcolor=:transparent)

   Plot_Lai_B = Makie.heatmap!(Axis_Lai_B, Lai_Raw; colormap=Reverse(colormap), colorrange=(0, 10), rasterize=Rasterize)

   Plot_Lai_C = Makie.heatmap!(Axis_Lai_B, LaiCloudTrue_2; colormap=(:reds, TransperencyCloud), colorrange=(0, 1), rasterize=Rasterize, transparency=true)

   Axis_Lai = Makie.Axis(Fig[1, 2], title="Lai FreeCloud", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height, backgroundcolor=:transparent)

   Plot_Lai = Makie.heatmap!(Axis_Lai, Lai_2; colormap=Reverse(colormap), colorrange=(0, 10), rasterize=Rasterize)

   Makie.Colorbar(Fig[1, 3], Plot_Lai, label="Lai", width=15, ticksize=15, tickalign=1, tickwidth=2, height=Relative(0.85))

   Label(Fig[0, :], TitlePage, font=:bold, fontsize=20, color=:navyblue)

   # Axis_Lai_C = Makie.Axis(Fig[1, 2], title="LaiCloudTrue", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height, backgroundcolor=:transparent)

   #__________________________________________________________________________________________________

   Axis_Fapar_B = Makie.Axis(Fig[2, 1], title="Fapar Raw", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height, backgroundcolor=:transparent)

   Plot_Fapar_B = Makie.heatmap!(Axis_Fapar_B, Fapar_Raw; colormap=Reverse(colormap), colorrange=(0, 1), rasterize=Rasterize)

   Plot_Fapar_C = Makie.heatmap!(Axis_Fapar_B, FaparCloudTrue_2; colormap=(:reds, TransperencyCloud), colorrange=(0, 1), rasterize=Rasterize)

   Axis_Fapar = Makie.Axis(Fig[2, 2], title="Fapar FreeCloud", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height, backgroundcolor=:transparent)

   Plot_Fapar = Makie.heatmap!(Axis_Fapar, Fapar_2; colormap=Reverse(colormap), colorrange=(0, 1), rasterize=Rasterize)

   Makie.Colorbar(Fig[2:4, 3], Plot_Fapar, label="Lai", width=15, ticksize=15, tickalign=1, tickwidth=2, height=Relative(0.9))

   #__________________________________________________________________________________________________

   Axis_Fvc_B = Makie.Axis(Fig[3, 1], title="Fvc Raw", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height)

   Plot_Fvc_B = Makie.heatmap!(Axis_Fvc_B, Fvc_Raw; colormap=Reverse(colormap), colorrange=(0, 1), rasterize=Rasterize)

   Plot_Fvc_C = Makie.heatmap!(Axis_Fvc_B, FvcCloudTrue_2; colormap=(:reds, TransperencyCloud), colorrange=(0, 1), rasterize=Rasterize)

   Axis_Fvc = Makie.Axis(Fig[3, 2], title="Fvc FreeCloud", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height)

   Plot_Fvc = Makie.heatmap!(Axis_Fvc, Fvc_2; colormap=Reverse(colormap), colorrange=(0, 1), rasterize=Rasterize)

   #__________________________________________________________________________________________________

   Axis_Ndvi_B = Makie.Axis(Fig[4, 1], title="Ndvi Raw", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height)

   Plot_Ndvi_B = Makie.heatmap!(Axis_Ndvi_B, Ndvi_Raw; colormap=Reverse(colormap), colorrange=(0, 1), rasterize=Rasterize)

   Axis_Ndvi = Makie.Axis(Fig[4, 2], title="Ndvi FreeCloud", xlabel=Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height)

   Plot_Ndvi = Makie.heatmap!(Axis_Ndvi, Ndvi_2; colormap=Reverse(colormap), colorrange=(0, 1), rasterize=Rasterize)

   # 	Makie.Colorbar(Fig[4, 4], Plot_Ndvi, label="Ndvi", width=15, ticksize=15, tickalign=0.5)

   #__________________________________________________________________________________________________

   colgap!(Fig.layout, 0.5)
   rowgap!(Fig.layout, 1)
   trim!(Fig.layout)
   resize_to_layout!(Fig)
   Makie.save(Path_Plot, Fig,)
   Makie.update_state_before_display!(Fig)
   # Makie.display(Fig)
   # px_per_unit=Dpi / 96

   GC.gc()
   return nothing
end  # function: PLOT_LAI
# ------------------------------------------------------------------


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#		FUNCTION : WFLOW_TIME
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   function WFLOW_TIME(; DatesWflow, InfiltrationSoil_Mm, PotentialEvaporation_Mm, Evapotranspiration_Mm, Precipitation_Mm, QriverObs_Day_Mm, QriverWflow_Day_Mm, θlayer_Aver, InfiltrationWflow_Mm, Nlayer, OverlandFlow_Mm, SubsurfaceFlow_Mm, 🎏_CatchmentName="Timoleague", 🎏_GLMakie=false, Forcing_ΔT="Daily", 🎏_Plot_θ_2D=true, Efficiency_Kge, OverlandFlow_2_River_Mm, OverlandDepth_Mm, OverlandFlow_Model_Mm)

      ylabelsize = 15

      N_Dates = length(QriverWflow_Day_Mm)

      if 🎏_GLMakie
         GLMakie.activate!()
      else
         CairoMakie.activate!(type="svg", pt_per_unit=1)
      end
      Fig = Figure(font="Sans", titlesize=24, labelsize=30, fontsize=10)

      # Dates
      X = 1:N_Dates
      X_Ticks = 1:30:N_Dates
      Time_Dates = Date.(DatesWflow[X_Ticks])

      Title = "Wflow output: per unit area of m²" * 🎏_CatchmentName * " (KGE = $Efficiency_Kge)"

      # ~~~~~~ Precipitation, Infiltration, PotentialEvaporation, EvapoTranspiration ~~~~~~
      Axis_1 = Axis(Fig[1, 1], yautolimitmargin=(0, 0), height=200, title=Title, titlecolor=:navyblue, width=800, xaxisposition=:top, xgridvisible=false, xtickalign=0.9, yaxisposition=:left, ygridvisible=false, ylabel=L"$\Delta Precip$ $[mm \ day^{-1}]$", ylabelcolor=:blue3, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, ytickcolor=:darkblue, yticklabelcolor=:darkblue)

         hidexdecorations!(Axis_1, grid=false, ticks=false, ticklabels=true)

         barplot!(Axis_1, X, Precipitation_Mm, strokecolor=:navy, strokewidth=1., color=:blue3, label="Precipitation")

         barplot!(Axis_1, X, InfiltrationSoil_Mm, strokecolor=:navy, strokewidth=1., color=:chocolate3, label="ThroughfallStremflow")

         lines!(Axis_1, X, PotentialEvaporation_Mm, linewidth=2.5, color=:darkgreen, label="PotentialEvaporation")

         lines!(Axis_1, X, Evapotranspiration_Mm, linewidth=2., color=:olivedrab, linestyle=(:dash, :dense), label="EvapoTranspiration")

         # text!( Axis_1, text="Forcing: $Forcing_ΔT", align=(:left,:top), fontsize=10, color=:darkblue, position=(0.0, 15.0))
         text!(
         Axis_1, 0, 1,
         text = "a)",
         font = :bold,
         align = (:left, :top),
         offset = (4, -2),
         space = :relative,
         fontsize = 18,
         color=:purple4
      )

         Legend(Fig[1, 2], Axis_1, framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)


      # ~~~~~~ Effective soil moisture ~~~~~~
      Axis_2 = Axis(Fig[2, 1], height=150, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\theta$ $[m \ m^{-1}]$", ylabelcolor=:blue3, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

         # ylims!(Axis_2, 0.0, 1.0)

         hidexdecorations!(Axis_2, grid=false, ticks=false, ticklabels=true)

         for iLayer = 1:Nlayer-1
            lines!(Axis_2, X, θlayer_Aver[:, iLayer], linewidth=3.0, colormap=(:Spectral_10, 0.85), label=" θ_ Layer_$iLayer")
         end

         Legend(Fig[2, 2], Axis_2, framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)

         text!(
         Axis_2, 0, 1,
         text = "b)",
         font = :bold,
         align = (:left, :top),
         offset = (4, -2),
         space = :relative,
         fontsize = 18,
         color=:purple4
      )


      if 🎏_Plot_θ_2D
         Axis_3 = Axis(Fig[3, 1], height=100, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"Soil \ Layers", ylabelcolor=:darkblue, ylabelsize=ylabelsize, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3, ytickcolor=:darkblue, yticklabelcolor=:darkblue)

            Axis_3.yticks = (1:3, string.(Nlayer-1:-1:1))
            hidexdecorations!(Axis_3, grid=false, ticks=false, ticklabels=true)

         Plot_θ = heatmap!(Axis_3, X, 1:1:Nlayer-1, reverse(θlayer_Aver[:,1:Nlayer-1],dims=2); colorrange=(0.0, 1.0), colormap=Reverse(:linear_kbc_5_95_c73_n256))

         Colorbar(Fig[3, 2], Plot_θ; label=L"$\theta$ $[m \ m^{-1}]$", width=20, ticks=0:0.25:1, labelsize=10)

         text!(
            Axis_3, 0, 1,
            text="c)",
            font=:bold,
            align=(:left, :top),
            offset=(4, -2),
            space=:relative,
            fontsize=18,
            color=:purple4
         )

      end

      # ~~~~~~ Overland flow and Subsurface flow ~~~~~~
      Axis_4 = Axis(Fig[4, 1], height=200, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta Qav$ $[mm \ m^{-2} \ day^{-1}]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3, yaxisposition = :left)

         hidexdecorations!(Axis_4, grid=false, ticks=false, ticklabels=true)
         Correction = 1
         # lines!(Axis_4, X, InfiltrationSoil_Mm, linewidth=2, color=:chocolate3, label=L"$InfiltrationSoil$")
         lines!(Axis_4, X, OverlandFlow_Mm / Correction, linewidth=2, color=:indigo, label=L"$OverlandFlow$")

         text!(
            Axis_4, 0, 1,
            text="d)",
            font=:bold,
            align=(:left, :top),
            offset=(4, -2),
            space=:relative,
            fontsize=18,
            color=:purple4
         )

      # Axis_4b = Axis(Fig[4, 1], xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta SubsurfaceFlow$ $[mm \ day^{-1}]$", ylabelcolor=:darkgreen, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:darkgreen, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3, yaxisposition = :right)

      #    hidexdecorations!(Axis_4b, grid=false, ticks=false, ticklabels=true)

      #    lines!(Axis_4b, X, SubsurfaceFlow_Mm, linewidth=2, color=:darkgreen, label=L"$SubsurfaceFlow$")

      #    Legend(Fig[4, 2], [Axis_4, Axis_4b], framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)


      # ~~~~~~ WflowInfiltration ~~~~~~
      Axis_5 = Axis(Fig[5, 1], height=200, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$OverlandDepth \ [mm]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

            hidexdecorations!(Axis_5, grid=false, ticks=false, ticklabels=true)

            lines!(Axis_5, X, OverlandDepth_Mm, linewidth=2, color=:aquamarine4, label=L"$OverlandDepth$")
            barplot!(Axis_5, X, InfiltrationSoil_Mm, strokecolor=:navy, strokewidth=1., color=:chocolate3, label="ThroughfallStremflow")

            Legend(Fig[5, 2], Axis_5, framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)

            text!(
            Axis_5, 0, 1,
            text = "(e)",
            font = :bold,
            align = (:left, :top),
            offset = (4, -2),
            space = :relative,
            fontsize = 18,
            color=:purple4
         )

      # ~~~~~~  Overland_2_River  ~~~~~~
      Axis_6 = Axis(Fig[6, 1], height=200, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta Overlandflow2River$ $[mm \ day^{-1}]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

         hidexdecorations!(Axis_6, grid=false, ticks=false, ticklabels=true)

         lines!(Axis_6, X, OverlandFlow_2_River_Mm, linewidth=2, color=:indigo, label=L"$OverlandFlow2River$")
         # lines!(Axis_7, X, OverlandFlow_Mm, linewidth=2, color=:indigo, label=L"$OverlandFlow$")

         text!(
         Axis_6, 0, 1,
         text = "f)",
         font = :bold,
         align = (:left, :top),
         offset = (4, -2),
         space = :relative,
         fontsize = 18,
         color=:purple4
      )

         # ~~~~~~  Overland_Model  ~~~~~~
      Axis_7 = Axis(Fig[7, 1], height=200, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta h . Cell $ $[mm \ day^{-1}]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

         hidexdecorations!(Axis_7, grid=false, ticks=false, ticklabels=true)

         lines!(Axis_7, X, OverlandFlow_Model_Mm[:,1], linewidth=2, color=:blue, label=L"$Qmodel_Depth$")
         lines!(Axis_7, X, OverlandFlow_Model_Mm[:,2], linewidth=2, color=:red, label=L"$Qmodel_Q$", linestyle=Linestyle([0, 2, 4, 12, 14]))

         Legend(Fig[7, 2], Axis_7, framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)


         text!(
         Axis_7, 0, 1,
         text = "g)",
         font = :bold,
         align = (:left, :top),
         offset = (4, -2),
         space = :relative,
         fontsize = 18,
         color=:purple4
      )


      # ~~~~~~  Q observed vs Q Wflow  ~~~~~~
      Axis_8 = Axis(Fig[8, 1], height=250, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta Qriver$ $[mm \ day^{-1}]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

         Axis_8.xticks = (X_Ticks, string.(Time_Dates))

         lines!(Axis_8, X, QriverWflow_Day_Mm, linewidth=2, color=:blue2, label=L"$Qriver_{Wflow}$", linestyle=Linestyle([0, 2, 4, 12, 14]))

         lines!(Axis_8, X, QriverObs_Day_Mm, linewidth=2, color=:firebrick2, label=L"$Qriver_{Obs}$")

         Legend(Fig[8, 2], Axis_8, framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)

         text!(
         Axis_8, 0, 1,
         text = "h)",
         font = :bold,
         align = (:left, :top),
         offset = (4, -2),
         space = :relative,
         fontsize = 18,
         color=:purple4
      )



         # Legend(Fig[13, 1], Axis_8, framecolor=(:gray63, 0.5), labelsize=12, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=3, backgroundcolor=:gray100)

      #    text!(
      #      Axis_8, 0, 1,
      #      text = "g)",
      #      font = :bold,
      #      align = (:left, :top),
      #      offset = (4, -2),
      #      space = :relative,
      #      fontsize = 18,
      #      color=:purple4
      #  )



      colgap!(Fig.layout, 5)
      rowgap!(Fig.layout, 15)
      resize_to_layout!(Fig)
      trim!(Fig.layout)
      display(Fig)

      return nothing
   end  # function: WFLOW_TIME
   # ------------------------------------------------------------------


   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #		FUNCTION : WFLOW_PLOTTING_KS
   # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      function WFLOW_PLOTTING_KS()

         CairoMakie.activate!(type="svg", pt_per_unit=1)
         Fig = Figure(font="Sans", titlesize=24, labelsize=30, fontsize=10)

         Axis_1 = Axis(Fig[1, 1], height=250, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, xlabel=L"$Ks$  $[mm \ day^{-1}]$", ylabel=L"$Depth \ [mm]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

         colgap!(Fig.layout, 5)
         rowgap!(Fig.layout, 15)
         resize_to_layout!(Fig)
         trim!(Fig.layout)
         display(Fig)

      return nothing
      end
   # -----------------------------------------------------------------


   function a()
      let
      # Define colors and styles
      csep = "#999999"
      croot = "#993404"
      cwater = "#1f78b4"
      lssep = :dash

      layers = [0, 150, 250, 325]
      all_layers = copy(layers)

      rootdepth = 230
      waterdepth = 300

      availcap = Float64[]
      usl = Float64[]

      # Calculate available capacity and unsaturated layer
      for i in 1:(length(layers) - 1)
            usl_i = min(layers[i + 1], waterdepth) - layers[i]
            push!(usl, usl_i)
            if usl_i > 0
               cap = min(1.0, max(0.0, (rootdepth - layers[i]) / usl_i))
               push!(availcap, cap)
            else
               push!(availcap, 0.0)
            end
      end

      # Create figure
      padding = 10
      w, h = (400, 400)

      fig = Figure(; size = (w, h))
      ax = Axis(
            fig;
            bbox = BBox(50, 100, padding, h - padding),
            xgridvisible = false,
            ygridvisible = false,
            xticksvisible = false,
            xticklabelsvisible = false,
            yticks = all_layers,
            yreversed = true,
            xlabel = "",
            ylabel = "",
      )

      # Show lines for different layers and depth values
      for i in 1:(length(all_layers) - 1)
            layer = all_layers[i]
            y_mean = mean([all_layers[i + 1], all_layers[i]])
            hlines!(ax, [layer]; color = csep, linestyle = lssep)
            text!(
               fig.scene,
               Point2f(0.09, 1 - (y_mean / maximum(layers)));
               text = string(all_layers[i + 1] - all_layers[i]),
               space = :relative,
               align = (:center, :center),
               rotation = pi / 2,
               color = "#b3b3b3",
            )

            text!(
               fig.scene,
               Point2f(0.8, 1 - (y_mean / maximum(layers)));
               text = "maxextr = \n $(round(availcap[i], digits = 2)) ⋅ soilwater",
               space = :relative,
               align = (:center, :center),
            )
      end

      # Add lines indicating water level and rootzone depth
      hlines!(ax, [rootdepth]; color = croot, linewidth = 2)
      poly!(ax, [0, 0, 1, 1], [waterdepth, 375, 375, waterdepth]; color = cwater, alpha = 0.5)
      text!(
            fig.scene,
            "Rooting depth";
            position = (0.27, 1.01 - (rootdepth / maximum(layers))),
            color = croot,
            space = :relative,
            align = (:left, :center),
      )

      text!(
            fig.scene,
            "Water table depth";
            position = (0.27, 1.01 - (waterdepth / maximum(layers))),
            color = cwater,
            space = :relative,
            align = (:left, :center),
      )

      # Format axes
      xlims!(ax, 0, 1)
      ylims!(ax, layers[end], 0)

      # Display the figure
         display(fig)
      end

      return nothing
      end  # function: WFLOW_PLOTTING_KS
      # ------------------------------------------------------------------

end # geoPlot