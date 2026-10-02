
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
      MinValue = minimum(X for X ∈ Input if !ismissing(X) && !isnan(X))
      #  MinValue = minimum(skipmissing(Input))
   end
   if isnan(MaxValue)
      MaxValue = maximum(X for X ∈ Input if !ismissing(X) && !isnan(X))
      #  MaxValue = maximum(skipmissing(Input))
   end
   Ncategories = Int64(floor(MaxValue - MinValue) + 1)
   # Ncategories=10

   if ColorReverse
      Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=Reverse(cgrad(colormap, 12, categorical=Categorical)), colorrange=(MinValue, MaxValue))
   else
      Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=cgrad(colormap, Ncategories, categorical=Categorical), colorrange=(MinValue, MaxValue))
      # println(Ncategories)
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

   Data = Data .* Multiply

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
function WFLOW_TIME(; 🎏_CatchmentName="Timoleague", 🎏_GLMakie=false, 🎏_Plot_θ_2D=true, DatesWflow, Efficiency_Kge, Evapotranspiration_Mm, flags, Forcing_ΔT="Daily", ThroughfallStemflow_Mm, SoilInfiltration_Mm, Nlayer, Runoff_Mm, OverlandFlow_2_River_Mm, PotentialEvaporation_Mm, Precipitation_Mm, QriverObs_Day_Mm, QriverWflow_Day_Mm, SubsurfaceFlow_Mm, θlayer_Aver, GroundwaterFlow_2_River_Mm)

   ylabelsize = 15

   N_Dates = length(QriverWflow_Day_Mm)

   CairoMakie.activate!(type="svg", pt_per_unit=0.5)
   Fig = Figure(font="Sans", labelsize=30, fontsize=10)

   # Dates
   X = 1:N_Dates
   X_Ticks = 1:30:N_Dates
   Time_Dates = Date.(DatesWflow[X_Ticks])

   Title =  🎏_CatchmentName * ": Wflow output per unit m²" * " (KGE = $Efficiency_Kge)"

   iFigure = 0

   # ~~~~~~ Precipitation, Infiltration, PotentialEvaporation, EvapoTranspiration ~~~~~~
   if flags.🎏_Precipitation || flags.🎏_ThroughfallStemflow || flags.🎏_SoilInfiltration || flags.🎏_Runoff || flags.🎏_PotentialEvapotranspiratio || flags.🎏_Evapotranspiration

      iFigure += 1

      Axis_1 = Axis(Fig[iFigure, 1], yautolimitmargin=(0, 0), height=200, title=Title, titlecolor=:navyblue, titlesize=20, width=800, xaxisposition=:top, xgridvisible=false, xtickalign=0.9, yaxisposition=:left, ygridvisible=false, ylabel=L"$\Delta Fluxes$ $[mm \ day^{-1}]$", ylabelcolor=:blue3, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, ytickcolor=:darkblue, yticklabelcolor=:darkblue)

      hidexdecorations!(Axis_1, grid=false, ticks=false, ticklabels=true)

      if flags.🎏_Precipitation
         barplot!(Axis_1, X, Precipitation_Mm, strokecolor=:navyblue, strokewidth=1., color=:blue3, label=L"$Precipitation$")
      end

      if flags.🎏_ThroughfallStemflow
         barplot!(Axis_1, X, ThroughfallStemflow_Mm, strokecolor=:navyblue, strokewidth=1., color=:cyan3, label=L"$ThroughfallStemflow$")
      end

      if flags.🎏_SoilInfiltration
         barplot!(Axis_1, X, SoilInfiltration_Mm, strokecolor=:yellow, strokewidth=1., color=:salmon4, label=L"$SoilInfiltration$")
      end

      if flags.🎏_Runoff
         barplot!(Axis_1, X, -Runoff_Mm, strokecolor=:navy, strokewidth=1., color=:darkred, label=L"$Runoff$")
      end

      if flags.🎏_PotentialEvapotranspiration
         lines!(Axis_1, X, PotentialEvaporation_Mm, linewidth=2.5, color=:darkgreen, label=L"$PotentialEvaporation$")
      end

      if flags.🎏_Evapotranspiration
         lines!(Axis_1, X, Evapotranspiration_Mm, linewidth=2., color=:olivedrab, linestyle=(:dash, :dense), label=L"$EvapoTranspiration$")
      end

      text!(Axis_1, 0, 1, text=string(Char(96 + iFigure)), font=:bold, align=(:left, :top), offset=(4, -2), space=:relative, fontsize=18, color=:purple4)

      Legend(Fig[iFigure, 2], Axis_1, framecolor=(:gray63, 0.5), labelsize=12, valign=:center, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)
   end

   # ~~~~~~ Effective soil moisture ~~~~~~
   if flags.🎏_θ

      iFigure += 1

      Axis_2 = Axis(Fig[iFigure, 1], height=150, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\theta$ $[m \ m^{-1}]$", ylabelcolor=:blue3, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

      # ylims!(Axis_2, 0.0, 1.0)

      hidexdecorations!(Axis_2, grid=false, ticks=false, ticklabels=true)

      for iLayer = 1:Nlayer-1
         lines!(Axis_2, X, θlayer_Aver[:, iLayer], linewidth=3.0, colormap=(:Spectral_10, 0.85), label=" θ_ Layer_$iLayer")
      end

      Legend(Fig[iFigure, 2], Axis_2, framecolor=(:gray63, 0.5), labelsize=12, valign=:center, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)

      text!(Axis_2, 0, 1, text=string(Char(96 + iFigure)), font=:bold, align=(:left, :top), offset=(4, -2), space=:relative, fontsize=18, color=:purple4)

      if 🎏_Plot_θ_2D
         iFigure += 1

         Axis_3 = Axis(Fig[iFigure, 1], height=100, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"Soil \ Layers", ylabelcolor=:darkblue, ylabelsize=ylabelsize, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3, ytickcolor=:darkblue, yticklabelcolor=:darkblue)

         Axis_3.yticks = (1:3, string.(Nlayer-1:-1:1))
         hidexdecorations!(Axis_3, grid=false, ticks=false, ticklabels=true)

         Plot_θ = heatmap!(Axis_3, X, 1:1:Nlayer-1, reverse(θlayer_Aver[:, 1:Nlayer-1], dims=2); colorrange=(0.0, 1.0), colormap=Reverse(:linear_kbc_5_95_c73_n256))

         Colorbar(Fig[iFigure, 2], Plot_θ; label=L"$\theta$ $[m \ m^{-1}]$", width=20, ticks=0:0.25:1, labelsize=10)


         text!(Axis_3, 0, 1, text=string(Char(96 + iFigure)), font=:bold, align=(:left, :top), offset=(4, -2), space=:relative, fontsize=18, color=:purple4)
      end
   end # flags.🎏_θ

   # ~~~~~~  Flows -> Rivers  ~~~~~~
   if flags.🎏_OverlandFlow2River || flags.🎏_SubsurfaceFlow2River || flags.🎏_GroundwaterFlow2River

      iFigure += 1

      Axis_4 = Axis(Fig[iFigure, 1], height=200, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta Overlandflow$ $[mm \ day^{-1}]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

      hidexdecorations!(Axis_4, grid=false, ticks=false, ticklabels=true)

      if flags.🎏_OverlandFlow2River && flags.🎏_SubsurfaceFlow2River && flags.🎏_GroundwaterFlow2River
         band!(Axis_4, X, X .* 0.0, GroundwaterFlow_2_River_Mm, color=:orange, label=L"$GroundwaterFlow2River$")

         GroundwaterFlow_SubsurfaceFlow = GroundwaterFlow_2_River_Mm .+ SubsurfaceFlow_Mm
         band!(Axis_4, X, GroundwaterFlow_2_River_Mm, GroundwaterFlow_SubsurfaceFlow, color=:darkgreen, label=L"$SubsurfaceFlow$")

         GroundwaterFlow_SubsurfaceFlow_OverlandFlow = GroundwaterFlow_SubsurfaceFlow .+ OverlandFlow_2_River_Mm
         band!(Axis_4, X, GroundwaterFlow_SubsurfaceFlow, GroundwaterFlow_SubsurfaceFlow_OverlandFlow, color=:indigo, label=L"$OverlandFlow2River$")
      else
         if flags.🎏_GroundwaterFlow2River
            lines!(Axis_4, X, GroundwaterFlow_2_River_Mm, linewidth=2, color=:orange, label=L"$GroundwaterFlow2River$")
         end

         if flags.🎏_SubsurfaceFlow2River
            lines!(Axis_4, X, SubsurfaceFlow_Mm, linewidth=2, color=:darkgreen, label=L"$SubsurfaceFlow$")
         end

         if flags.🎏_OverlandFlow2River
            lines!(Axis_4, X, OverlandFlow_2_River_Mm, linewidth=2, color=:indigo, label=L"$OverlandFlow2River$")
         end
      end

      text!(Axis_4, 0, 1, text=string(Char(96 + iFigure)), font=:bold, align=(:left, :top), offset=(4, -2), space=:relative, fontsize=18, color=:purple4)

      Legend(Fig[iFigure, 2], [Axis_4], framecolor=(:gray63, 0.5), labelsize=12, valign=:center, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)
   end


   # ~~~~~~  Q observed vs Q Wflow  ~~~~~~
   iFigure += 1

   Axis_5 = Axis(Fig[iFigure, 1], height=250, width=800, xgridvisible=false, xticklabelrotation=π / 2.0, xticksize=5, yautolimitmargin=(0, 0), ygridvisible=false, ylabel=L"$\Delta Qriver$ $[mm \ day^{-1}]$", ylabelcolor=:darkblue, ylabelsize=ylabelsize, yminortickalign=0.95, yminorticks=IntervalsBetween(5), yminorticksvisible=true, ytickalign=0.9, yticklabelcolor=:blue3, yticksize=5, xminortickalign=0.95, xminorticks=IntervalsBetween(5), xminorticksvisible=true, xtickalign=0.9, xticklabelcolor=:blue3)

   Axis_5.xticks = (X_Ticks, string.(Time_Dates))

   lines!(Axis_5, X, QriverWflow_Day_Mm, linewidth=2, color=:blue2, label=L"$Qriver_{Wflow}$", linestyle=Linestyle([0, 2, 4, 12, 14]))

   lines!(Axis_5, X, QriverObs_Day_Mm, linewidth=2, color=:firebrick2, label=L"$Qriver_{Obs}$")

   # lines!(Axis_5, X, OverlandFlow_2_River_Mm, linewidth=2, color=:indigo, label=L"$OverlandFlow2River$")

   Legend(Fig[iFigure, 2], Axis_5, framecolor=(:gray63, 0.5), labelsize=12, valign=:center, padding=1, tellheight=true, tellwidt=true, nbanks=1, backgroundcolor=:gray100)

   text!(Axis_5, 0, 1, text=string(Char(96 + iFigure)), font=:bold, align=(:left, :top), offset=(4, -2), space=:relative, fontsize=18, color=:purple4)

   colgap!(Fig.layout, 10)
   rowgap!(Fig.layout, 15)
   resize_to_layout!(Fig)
   trim!(Fig.layout)
   display(Fig)

return nothing
end  # function: WFLOW_TIME
# ------------------------------------------------------------------



end # geoPlot