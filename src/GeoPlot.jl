module geoPlot


# ================================================================
		# Plotting parameters
			ColourOption_No    = 1
			Linewidth          = 2
			height             = 400
			labelsize          = 20
			textcolor          = :blue
			textsize           = 20
			titlecolor         = :navyblue
			titlesize          = 18.0
			width              = height * 1.0
			xgridstyle         = :dash
			xgridvisible       = true
			xlabelSize         = 20
			xlabelpadding      = 5
			xminortickalign    = 1.0
			xminorticksvisible = true
			xtickalign         = 0.9 # 0 is inside and 1 is outside
			xticklabelrotation = π / 4.0
			xticksize          = 10
			xticksmirrored     = false
			xtickwidt          = 0.5
			xtrimspine         = false
			ygridstyle         = :dash
			ygridvisible       = false
			ylabelpadding      = xlabelpadding
			ylabelsize         = xlabelSize
			yminortickalign    = xminortickalign
			yminorticksvisible = true
			ytickalign         = xtickalign
			yticksize          = xticksize
			yticksmirrored     = false
			ytickwidt          = xtickwidt
			ytrimspine         = false
			Linewidth = 4
			xlabelSize = 30
			xticksize = 10
			xgridvisible = false
			Width = 800 # 800
			Height = 200


	 	 include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\Parameters.jl")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAP_TIME
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		using GLMakie, NCDatasets
		function HEATMAP_TIME(;Path=Path, NameOutput="q_land", Layer=1)
			Output_NCDatasets = NCDatasets.NCDataset(Path)

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

		  Fig = Figure(size=(Width, Height * 4.0))

		  Ax_1 = Axis(Fig[1, 1], title=NameOutput, xlabelsize=xlabelSize, ylabelsize=xlabelSize, xticksize=xticksize, xgridvisible=xgridvisible, ygridvisible=xgridvisible)

		  sg = SliderGrid(Fig[2, 1],
		  (label="iTime", range=1:1:N_Time, startvalue=1),
		  width=550, tellheight=true)

		  iTime = sg.sliders[1].value

		  Data_Time = lift((iTime) -> DATA_3D_2_2D(Data; iTime=iTime), iTime)

		  Data_Plot = heatmap!(Ax_1, 1:N_Lon, 1:N_Lat, Data_Time, colorrange=(Pmin, Pmax), colormap =:hawaii50)

		  Colorbar(Fig[1, 2], Data_Plot; label=NameOutput, width=20, ticks = Pmin:(Pmax-Pmin)/5:Pmax)

		  Fig
	 end # HEATMAP_TIME



end # plotRaster