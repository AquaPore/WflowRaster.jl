
module geoPlot
	using CairoMakie, Colors, ColorSchemes
	using GLMakie, NCDatasets
	# import ..Parameters
	include("Parameters.jl")
	include("PlotParameter.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAP
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function HEATMAP(;🎏_Colorbar=true, Input, Label="", Title, Xlabel= L"$Latitude$", Ylabel=L"$Longitude$", titlecolor=titlecolor,  titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=:viridis, Yreversed=false)

			CairoMakie.activate!()
			Fig_100 =  CairoMakie.Figure()

			Axis_100 = CairoMakie.Axis(Fig_100[1, 1], title=Title, xlabel= Xlabel, ylabel=Ylabel,  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor)

			Axis_100.yreversed = Yreversed

			Map_100 = CairoMakie.heatmap!(Axis_100, Input, colormap=colormap)

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
		function HEATMAP_TIME(;Path=Path, NameOutput="temp", Layer=1)
			Output_NCDatasets = NCDatasets.NCDataset(Path)

			# using GLMakie
			GLMakie.activate!()
			Makie.inline!(false)  # Make sure to inline plots into Documenter output!

			Data = Output_NCDatasets[NameOutput]
			Data = Array(Data)

			N_Lon = size(Data)[1]
			N_Lat  = size(Data)[2]
			N_Time  = size(Data)[3]

			Pmin, Pmax = extrema(x for x ∈ skipmissing(Data) if !isnan(x))
			@show Pmin Pmax

			function DATA_3D_2_2D(Data; iTime=iTime, Layer=Layer)
				return Data[:,:, iTime]
			end

			Fig = GLMakie.Figure(Width=800, Height=600)

			Ax_1 = GLMakie.Axis(Fig[1, 1], title=NameOutput, xlabelsize=xlabelSize, ylabelsize=xlabelSize, xticksize=xticksize, xgridvisible=xgridvisible, ygridvisible=xgridvisible)

			Ax_1.yreversed = true

			sg = GLMakie.SliderGrid(Fig[2, 1],
			(label="iTime", range=1:1:N_Time, startvalue=1),
			width=550, tellheight=true)

			iTime = sg.sliders[1].value

			Data_Time = GLMakie.lift((iTime) -> DATA_3D_2_2D(Data; iTime=iTime), iTime)

			Data_Plot = GLMakie.heatmap!(Ax_1, 1:N_Lon, 1:N_Lat, Data_Time, colorrange=(Pmin, Pmax), colormap =:hawaii50)

			GLMakie.Colorbar(Fig[1, 2], Data_Plot; label=NameOutput, width=20, ticks = Pmin:(Pmax-Pmin)/5:Pmax)

			Fig
	 	end # HEATMAP_TIME
	# ------------------------------------------------------------------
end # geoPlot