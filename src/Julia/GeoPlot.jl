
module geoPlot
	using CairoMakie, Colors, ColorSchemes
	using NCDatasets

	include("Parameters.jl")
	include("PlotParameter.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAP
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function HEATMAP(;🎏_Colorbar=true, Input, Label="", Title, Xlabel= L"$Latitude$", Ylabel=L"$Longitude$", titlecolor=titlecolor,  titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=:viridis, Yreversed=false, ColorReverse=false, MinValue =NaN, MaxValue=NaN, Categorical=false)

			CairoMakie.activate!()
			Fig_100 =  CairoMakie.Figure()

			Axis_100 = CairoMakie.Axis(Fig_100[1, 1], title=Title, xlabel= Xlabel, ylabel=Ylabel,  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor)

			Axis_100.yreversed = Yreversed

			if isnan(MinValue)
				MinValue = minimum(X for X ∈ Input if !isnan(X))
			end
			if isnan(MaxValue)
				MaxValue = maximum(X for X ∈ Input if !isnan(X))
			end
			Ncategories =  Int64(floor(MaxValue - MinValue)+1)

			if ColorReverse
				Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=Reverse(cgrad(colormap, 12, categorical=Categorical)), colorrange=(MinValue, MaxValue))
			else
				Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=cgrad(colormap, Ncategories, categorical=Categorical),  colorrange=(MinValue, MaxValue))
			end

			if 🎏_Colorbar
				CairoMakie.Colorbar(Fig_100[1,2], Map_100, label=Label, width=15, ticksize=15, tickalign=0.5)
			end

			CairoMakie.display(Fig_100)
		return nothing
		end  # function: HEATMAP
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAP_TIME
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function HEATMAP_TIME(;Path=Path, NameOutput="temp", Layer=1, 🎏_Reverse=false)
			Output_NCDatasets = NCDatasets.NCDataset(Path)

			# using GLMakie
			GLMakie.activate!()
			Makie.inline!(false)  # Make sure to inline plots into Documenter output!

			Data = Output_NCDatasets[NameOutput]
			Data = Array(Data)
			Dimensions = length(size(Data))

			if Dimensions == 3
				N_Lon  = size(Data)[1]
				N_Lat  = size(Data)[2]
				N_Time = size(Data)[3]

			elseif Dimensions == 4
				N_Lon  = size(Data)[1]
				N_Lat  = size(Data)[2]
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
					return Data[:,:, Layer, iTime]
				elseif Dimensions == 3
					return Data[:,:, iTime]
				end
			end

			# Fig = GLMakie.Figure(Width=800, Height=600)
			Fig = GLMakie.Figure()

				if Dimensions == 4
					Title = "$NameOutput , Layer = $Layer"
				elseif Dimensions == 3
					return Data[:,:, iTime]
				end

			Ax_1 = GLMakie.Axis(Fig[1, 1], title=Title, xlabelsize=xlabelSize, ylabelsize=xlabelSize, xticksize=xticksize, xgridvisible=xgridvisible, ygridvisible=xgridvisible, aspect=1)

			Ax_1.yreversed = 🎏_Reverse

			sg = GLMakie.SliderGrid(Fig[2, 1],
			(label="iTime", range=1:1:N_Time, startvalue=1),
			width=550, tellheight=true)

			iTime = sg.sliders[1].value

			Data_Time = GLMakie.lift((iTime) -> DATA_3D_2_2D(Data; iTime=iTime, Layer=Layer), iTime)

			Data_Plot = GLMakie.heatmap!(Ax_1, 1:N_Lon, 1:N_Lat, Data_Time, colorrange=(Pmin, Pmax), colormap =:hawaii50)

			GLMakie.Colorbar(Fig[1, 2], Data_Plot; label=NameOutput, width=20, ticks = Pmin:(Pmax-Pmin)/5:Pmax)
			GLMakie.colsize!(Fig.layout, 1, GLMakie.Aspect(1, 1.0))

			Fig
	 	end # HEATMAP_TIME
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PLOT_LAI
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


	function HEATMAP_LAI(;colormap=:viridis, DaySentinel₁, Fapar_2, Fvc_2, Lai_2, MonthSentinel₁, Ndvi_2, Path_Plot, titlecolor=titlecolor, titlesize=titlesize, Xlabel= L"$Latitude$", xlabelSize=xlabelSize, xticksize=xticksize, YearSentinel₁, Ylabel=L"$Longitude$", ylabelsize=ylabelsize, yticksize=yticksize, Width=800, Height=400, Dpi=200, Lai_Raw, Fapar_Raw, Ndvi_Raw, Fvc_Raw
		)

		CairoMakie.activate!(type="svg", px_per_unit=0.75)
		#  size = (800, 1200),
		Fig =  CairoMakie.Figure(;size=(2 * Width, 4 * Height), font="Sans", titlesize=20, labelsize=18, fontsize=18)

		TitlePage = "TIMOLEAGUE Year=$(YearSentinel₁) Month=$(MonthSentinel₁), Day=$(DaySentinel₁))"


		Axis_Lai = CairoMakie.Axis(Fig[1, 1], title="Lai Cloud Corrected", xlabel= Xlabel, ylabel=Ylabel,  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

		Label(Fig[1, 1:2, Top()], TitlePage, valign=:bottom, font=:bold, padding = (0, 0, 20, 0), fontsize=titlesize)

			Plot_Lai = CairoMakie.heatmap!(Axis_Lai, Lai_2; colormap=colormap, colorrange=(0, 10))

			Axis_Lai_B = CairoMakie.Axis(Fig[1, 2], title="Lai Raw",  xlabel= Xlabel, ylabel=Ylabel,  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Lai_B = CairoMakie.heatmap!(Axis_Lai_B, Lai_Raw; colormap=colormap, colorrange=(0, 10))

			CairoMakie.Colorbar(Fig[1,3], Plot_Lai, label="Lai", width=15, ticksize=15, tickalign=0.5)

		Title = "FAPAR_CORRECTED Year=$(YearSentinel₁) Month=$(MonthSentinel₁), Day=$(DaySentinel₁))"

		Axis_Fapar =  CairoMakie.Axis(Fig[2, 1], title="Fapar Cloud Corrected", xlabel= Xlabel, ylabel=Ylabel,  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Fapar = CairoMakie.heatmap!(Axis_Fapar, Fapar_2; colormap, colorrange=(0, 1))

			Axis_Fapar_B =  CairoMakie.Axis(Fig[2, 2], title="Fapar Raw", xlabel= Xlabel, ylabel=Ylabel,  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Fapar_B = CairoMakie.heatmap!(Axis_Fapar_B, Fapar_Raw; colormap, colorrange=(0, 1))

			CairoMakie.Colorbar(Fig[2,3], Plot_Fapar, label="Fapar", width=15, ticksize=15, tickalign=0.5)

		Title = "NDVI_CORRECTED Year=$(YearSentinel₁) Month=$(MonthSentinel₁), Day=$(DaySentinel₁))"

		Axis_Ndvi = CairoMakie.Axis(Fig[3, 1], title="Ndvi Cloud Corrected",  xlabel= Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Ndvi = CairoMakie.heatmap!(Axis_Ndvi, Ndvi_2; colormap, colorrange=(0, 1))

			CairoMakie.Colorbar(Fig[3,3], Plot_Ndvi, label="Ndvi", width=15, ticksize=15, tickalign=0.5)

			Axis_Ndvi_B = CairoMakie.Axis(Fig[3, 2], title="Ndvi Raw",  xlabel= Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Ndvi_B = CairoMakie.heatmap!(Axis_Ndvi_B, Ndvi_Raw; colormap, colorrange=(0, 1))


		# Title = "FVC_CORRECTED Year=$(YearSentinel₁) Month=$(MonthSentinel₁), Day=$(DaySentinel₁))"

		Axis_Fvc = CairoMakie.Axis(Fig[4, 1], title="Fvc Cloud Corrected",  xlabel= Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Fvc = CairoMakie.heatmap!(Axis_Fvc, Fvc_2; colormap, colorrange=(0, 1))

			Axis_Fvc_B = CairoMakie.Axis(Fig[4, 2], title="Fvc Raw",  xlabel= Xlabel, ylabel=Ylabel, ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor, aspect=DataAspect())

			Plot_Fvc_B = CairoMakie.heatmap!(Axis_Fvc, Fvc_Raw; colormap, colorrange=(0, 1))

			CairoMakie.Colorbar(Fig[4,3], Plot_Fvc, label="Fvc", width=15, ticksize=15, tickalign=0.5)

		resize_to_layout!(Fig)
		trim!(Fig.layout)
		colgap!(Fig.layout, 15)
		rowgap!(Fig.layout, 15)
		resize_to_layout!(Fig)
		CairoMakie.display(Fig)

		CairoMakie.save(Path_Plot, Fig)

	return nothing
	end  # function: PLOT_LAI
	# ------------------------------------------------------------------
end # geoPlot