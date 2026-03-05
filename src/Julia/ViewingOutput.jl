using Pkg
cd(raw"C:\Users\jpollacco.local\.julia\dev\Wflow")
Pkg.activate(".")


using Pkg
using NCDatasets
# using NetCDF
using GLMakie
# using CairoMakie, ColorSchemes# Annimating raster plots

	#===============================================]update=================#
	# Plotting parameters
   ColourOption_No    = 1
   Linewidth          = 2
   labelsize          = 20
   textcolor          = :blue
   textsize           = 20
   titlecolor         = :navyblue
   titlesize          = 18.0
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
   xlabelSize         = 30
   xticksize          = 10
   xgridvisible       = false
   Width              = 800 # 800
   Height             = 200

	Path = raw"C:\Users\jpollacco.local\.julia\dev\Wflow\data\data\output"

   Path_Output = joinpath(Path, "output_moselle.nc")
   Path_Scalar = joinpath(Path, "output_scalar_moselle.nc")
   Path_Outstates = joinpath(Path, "outstates-moselle.nc")

	function HEATMAP_TIME(;Path=Path, NameOutput="q_land", Layer=1)
      cd(raw"C:\Users\jpollacco.local\.julia\dev\Wflow")
      Pkg.activate(".")

		GLMakie.activate!()
		Makie.inline!(false)  # Make sure to inline plots into Documenter output!
		

		Output_NCDatasets = NCDatasets.NCDataset(Path_Output)
		
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

		Pmin, Pmax = extrema(x for x ∈ skipmissing(Data) if !isnan(x))
		@show Pmin, Pmax

	
		function DATA_3D_2_2D(Data; iTime=iTime, Dimensions=Dimensions, Layer=Layer)
			if Dimensions == 4
				return Data[:,:, Layer, iTime]
			elseif Dimensions == 3
				return Data[:,:, iTime]
			end
		end
		
		
		Fig = Figure(size=(Width, Height * 4.0))

		Ax_1 = Axis(Fig[1, 1],  title=NameOutput, xlabelsize=xlabelSize, ylabelsize=xlabelSize, xticksize=xticksize, xgridvisible=xgridvisible, ygridvisible=xgridvisible)
		
		sg = SliderGrid(Fig[2, 1],
		(label="iTime", range=1:1:N_Time, startvalue=1),
		width=550, tellheight=true)
		
		iTime = sg.sliders[1].value
		
		Data_Time = lift((iTime) -> DATA_3D_2_2D(Data; iTime=iTime, Dimensions), iTime)
	
		Data_Plot = heatmap!(Ax_1, 1:N_Lon, 1:N_Lat, Data_Time, colorrange=(Pmin, Pmax), colormap =:hawaii50)
	
		Colorbar(Fig[1, 2], Data_Plot; label=NameOutput, width=20, ticks = Pmin:(Pmax-Pmin)/5:Pmax)

      Fig
	
		makie_window = display(GLMakie.Screen(), Fig)

      wait(makie_window)
	end

	HEATMAP_TIME(;Path=Path_Output, NameOutput="q_av_land")