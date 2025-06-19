		# Plotting parameters
         ColourOption_No    = 1
         Linewidth          = 2
         height             = 400
         labelsize          = 20
         textcolor          = :blue
         textsize           = 20
         titlecolor         = :navyblue
         titlesize          = 20.0
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
         Linewidth          = 4
         xticksize          = 10
         xgridvisible       = false
         Width              = 800 # 800
         Height             = 200
			ColourOption = [ :curl, :magma ,:CMRmap, :Spectral_11, :lajolla, :plasma, :viridis, :greys, :matter, :romaO, :delta, :rain]

module geoPlot

	using CairoMakie, Colors, ColorSchemes
	using GLMakie, NCDatasets
	include(raw"d:\JOE\MAIN\MODELS\WFLOW\WflowDataJoe\WflowRaster.jl\src\Parameters.jl")

	# Plotting parameters
		ColourOption_No    = 1
		Linewidth          = 2
		height             = 400
		labelsize          = 20
		textcolor          = :blue
		textsize           = 20
		titlecolor         = :navyblue
		titlesize          = 20.0
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
		Linewidth          = 4
		xticksize          = 10
		xgridvisible       = false
		Width              = 800 # 800
		Height             = 200
		ColourOption = [ :curl, :magma ,:CMRmap, :Spectral_11, :lajolla, :plasma, :viridis, :greys, :matter, :romaO, :delta, :rain]

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAP
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function HEATMAP(;🎏_Colorbar=true, Input, Label="", Title, titlecolor=titlecolor,  titlesize=titlesize, xlabelSize=xlabelSize, xticksize=xticksize, ylabelsize=ylabelsize, yticksize=yticksize, colormap=:viridis)

   		CairoMakie.activate!()
   		Fig_100 =  CairoMakie.Figure()

   		Axis_100 = CairoMakie.Axis(Fig_100[1, 1], title=Title, xlabel= L"$Latitude$", ylabel=L"$Longitude$",  ylabelsize=ylabelsize, xlabelsize=xlabelSize, xticksize=xticksize, yticksize=yticksize, titlesize=titlesize, titlecolor=titlecolor)

   		Map_100 = CairoMakie.plot!(Axis_100, Input, colormap=colormap)

			if 🎏_Colorbar
   			CairoMakie.Colorbar(Fig_100[1,2], Map_100, label=Label, width=15, ticksize=15, tickalign=0.5)
			end

   		CairoMakie.display(Fig_100)
		# return nothing
		end  # function: HEATMAP
		# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAP_TIME
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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


end # geoPlot