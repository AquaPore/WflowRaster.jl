
module geoPlot
using CairoMakie, Colors, ColorSchemes, GLMakie
using NCDatasets

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

   if isnan(MinValue)
      MinValue = minimum(X for X ∈ Input if !isnan(X))
   end
   if isnan(MaxValue)
      MaxValue = maximum(X for X ∈ Input if !isnan(X))
   end
   Ncategories = Int64(floor(MaxValue - MinValue) + 1)

   if ColorReverse
      Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=Reverse(cgrad(colormap, 12, categorical=Categorical)), colorrange=(MinValue, MaxValue))
   else
      Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=cgrad(colormap, Ncategories, categorical=Categorical), colorrange=(MinValue, MaxValue))
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
function HEATMAP_TIME(; Path=Path, NameOutput="temp", Layer=1, 🎏_Reverse=false)
   Output_NCDatasets = NCDatasets.NCDataset(Path)

   # using GLMakie
   GLMakie.activate!()
   Makie.inline!(false)  # Make sure to inline plots into Documenter output!

   Data = Output_NCDatasets[NameOutput]
   Data = Array(Data)
   Dimensions = length(size(Data))

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

      Plot_Fapar_C = Makie.heatmap!(Axis_Fapar_B, FaparCloudTrue_2;  colormap=(:reds, TransperencyCloud), colorrange=(0, 1), rasterize=Rasterize)

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

   Axis_Ndvi_B = Makie.Axis(Fig[4, 1], title="Ndvi Raw",  xlabel= Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height)

         Plot_Ndvi_B = Makie.heatmap!(Axis_Ndvi_B, Ndvi_Raw; colormap=Reverse(colormap), colorrange=(0, 1),  rasterize=Rasterize)

   Axis_Ndvi = Makie.Axis(Fig[4, 2], title="Ndvi FreeCloud",  xlabel= Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlecolor=titlecolor, aspect=DataAspect(), width=Width, height=Height)

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
end # geoPlot