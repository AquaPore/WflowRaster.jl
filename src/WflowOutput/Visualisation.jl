module visualisation
	using CSV, Dates, Tables
	using CairoMakie, GLMakie
"""
    VISUALISATION()
	 To Visualise the output streamflow

	Joseph A.P. POLLACCO
"""

	function VISUALISATION(;🎏_CatchmentName = "Timoleague", 🎏_GLMakie=false, Forcing_ΔT="Daily")
		# Path of observed forcing data
         Path_Root_Data = raw"D:\JOE\MAIN\MODELS\WFLOW\Data"
         Path_Forcing₀  = raw"InputTimeSeries\TimeSeries_Process"
         Path_Forcing   = joinpath(Path_Forcing₀, Forcing_ΔT)

			Path_TimeSeries = joinpath(Path_Root_Data, "$(🎏_CatchmentName)", Path_Forcing, "Forcing_" * "$(Forcing_ΔT)" * "_" * "$(🎏_CatchmentName)" * ".csv" )
			println(Path_TimeSeries)
			@assert isfile(Path_TimeSeries)

		# Path of Qwflow data
         Path_Root_Wflow = raw"D:\JOE\MAIN\MODELS\WFLOW\Wflow.jl\Wflow\Data\output"
         Path_Qwflow     = joinpath(Path_Root_Wflow,  "$(🎏_CatchmentName)", "output_" * "$(🎏_CatchmentName)" * ".csv" )
			println(Path_Qwflow)
			@assert isfile(Path_Qwflow)



		# Reading Wflow data
         DataWflow  = CSV.File(Path_Qwflow; header=true)
         Time_Wflow = convert(Vector, Tables.getcolumn(DataWflow, :time))
         Qwflow     = convert(Vector{Float64}, Tables.getcolumn(DataWflow, :QriverVolumeFlowRate_1))

			Start_DateTime = Time_Wflow[1]
			End_DateTime =  Time_Wflow[end]

			printstyled("Starting Dates = $(Start_DateTime) \n"; color=:green)
			printstyled("Ending Dates = $(End_DateTime) \n"; color =:green)


		# Reading climate data
         Data₀  = CSV.File(Path_TimeSeries; header=true)
         Year   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
         Month  = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
         Day    = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
         Hour   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

         Precip = convert(Vector{Float64}, Tables.getcolumn(Data₀, :precip))
         Pet    = convert(Vector{Float64}, Tables.getcolumn(Data₀, :pet))
         Temp   = convert(Vector{Float64}, Tables.getcolumn(Data₀, :temp))
         Qobs₀  = convert(Vector, Tables.getcolumn(Data₀, :RiverDischarge_cumec))
			Tp₀ =  convert(Vector, Tables.getcolumn(Data₀,:TotalPhosphorus_mg_l))

			Time_Forcing = Dates.DateTime.(Year, Month, Day, Hour) #  <"standard"> "proleptic_gregorian" calendar

		# Selecting time which is between Start_DateTime and End_DateTime
         Nit₀ = length(Year)
         True = fill(false::Bool, Nit₀)
			for iT=1:Nit₀
				if (Start_DateTime ≤ Time_Forcing[iT] ≤ End_DateTime)
					True[iT] = true
				end
				if Time_Forcing[iT] > End_DateTime
					break
				end
			end # for iT=1:Nit

		# Reducing size of the time series
         Precip       = Precip[True[:]]
         Pet          = Pet[True[:]]
         Temp         = Temp[True[:]]
         Time_Forcing = Time_Forcing[True[:]]
         Qobs₀        = Qobs₀[True[:]]
			Tp₀ =Tp₀[True[:]]

		# Solve problem of format
			N  = count(True)
			Qobs = zeros(Float64, N)
			for (i, iiRiverDischarge) in enumerate(Qobs₀)

				if typeof(iiRiverDischarge) ≠ Float64
					Qobs[i] = parse(Float64, iiRiverDischarge)
				else
					Qobs[i] = iiRiverDischarge
				end
			end

			TPobs = zeros(Float64, N)
			for (i, iiTp) in enumerate(Tp₀)
				if Tp₀[i] > 0.0
					TPobs[i] = Tp₀[i]
				else
					TPobs[i] = NaN
				end
			end

			println(length(Qobs))
			println(length(Qwflow))

			@assert length(Precip) == length(Qwflow)

		# =======================
			# # Dimensions of figure
			# 	Height= 600
			# 	Width = 1000

			if 🎏_GLMakie
				GLMakie.activate!()
			else
				CairoMakie.activate!(type="svg", pt_per_unit=1)
			end
			Fig = Figure(font="Sans", titlesize=20,  xlabelsize=20, ylabelsize=20, labelsize=30, fontsize=20)

			Axis_1 = Axis(Fig[1, 1], yticklabelcolor=:black, yaxisposition=:right, rightspinecolor=:black, ytickcolor=:black, ylabel= L"$\Delta ET$ $[mm]$", xgridvisible=false, ygridvisible=false, width=800, height=400)

				hidexdecorations!(Axis_1, grid=false, ticks=true, ticklabels=true)

				Plot_Et = lines!(Axis_1, Time_Forcing, Pet, linewidth=2, color=:darkgreen)

				Axis_1b = Axis(Fig[1,1], ylabel= L"$\Delta Precipitation$ $[mm]$", xgridvisible=false, ygridvisible=false)
					barplot!(Axis_1b, Time_Forcing, Precip, strokecolor=:blue, strokewidth=1.5, color=:cyan)
					hidexdecorations!(Axis_1b, grid=false, ticks=true, ticklabels=true)

			Axis_2 = Axis(Fig[2,1], ylabel= L"$\Delta Qriver$ $[m^{3}]$", xgridvisible=false, ygridvisible=false, xticklabelrotation = π / 2.0, xticksize=5, yticksize=5, width=800, height=400, ) # yscale = Makie.pseudolog10

				# ylims!(Axis_2, low=0.0,high= 3000)
				X =1:N
				X_Ticks= 1:30:N
				Time_Dates = Date.(Time_Forcing[X_Ticks] )

				Axis_2.xticks = (X_Ticks, string.(Time_Dates))
				band!(Axis_2, X, zeros(length(N)), Qobs;  color=:blue, label= "Qobs" )
				# band!(Axis_2, X, zeros(length(N)), Qobs*0.64;  color=:blue, label= "Qbaseflow" )
				# band!(Axis_2, X, Qobs*0.64, Qobs*0.68;  color=:red, label= "Qsubsurface" )
				# band!(Axis_2, X, Qobs*0.68, Qobs;  color=:green, label= "Qrunoff" )


				lines!(Axis_2, X, Qwflow*10000.0, linewidth=2, color=:red, label= "Qwflow_Test")

				# Legend(Fig[3,1], Axis_2, framecolor=(:grey, 0.5), labelsize=8, valign=:top, padding=5, tellheight=true, tellwidt=true, nbanks=2, backgroundcolor=:gray100)

				# Axis_2b = Axis(Fig[2,1], ylabel= L"$\Delta Total Phostphates$ $[mg$ $l^{-1}]$", xgridvisible=false, ygridvisible=false, yaxisposition=:right)
				# 	hidexdecorations!(Axis_2b, grid=false, ticks=true, ticklabels=true)
				# 	lines!(Axis_2b, X, TPobs, linewidth=2, color=:violet, linestyle=:dash, label= "TotalP" )

				Legend(Fig[3,1], Axis_2, framecolor=(:grey, 0.5), labelsize=20, valign=:top, padding=1, tellheight=true, tellwidt=true, nbanks=4 , backgroundcolor=:gray100)

				colgap!(Fig.layout, 15)
				rowgap!(Fig.layout, 15)
				resize_to_layout!(Fig)
				trim!(Fig.layout)

				Path_SaveFig = joinpath(Path_Root_Wflow, "$(🎏_CatchmentName)", "Plot_" * "$(🎏_CatchmentName)" * ".svg" )
				save(Path_SaveFig, Fig, pt_per_unit=0.5) # size = 600 x 450 pt
				display(Fig)


	printstyled(" ==== End ====\n"; color =:red)
	end

		# GLMakie.activate!()
		# Makie.inline!(false)  # Make sure to inline plots into Documenter output!



		# Ax_1 = Makie.Axis(Fig[1, 1])

		# Plot = lines!(Ax_1, Time_Array, RiverDischarge, linestyle=:dash)

end


