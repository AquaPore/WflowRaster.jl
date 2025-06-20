
module geoPlot
	using CairoMakie, Colors, ColorSchemes
	using GLMakie, NCDatasets
	# import ..Parameters
	include("Parameters.jl")
	include("PlotParameter.jl")

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
		return nothing
		end  # function: HEATMAP
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : HEATMAT_NETCDF
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function HEATMAT_NETCDF()
			Output_NCDatasets = NCDatasets.NCDataset(Path_Static);

			Keys = NCDatasets.keys(Output_NCDatasets)
Keys_Select = []

for iiKeys ∈ Keys
	Output = Output_NCDatasets[iiKeys]
	Dimensions = length(size(Output))

	if Dimensions == 2 && length(iiKeys) ≥ 3
		try
			FillValue = Output_NCDatasets[iiKeys].attrib["_FillValue"]
			Data = NetCDF.ncread(Path_Static, iiKeys)

			push!(Keys_Select, String(iiKeys))
		catch
			println("Failed:  ", iiKeys)
		end
	end # Dimensions == 2
end # for iiKeys ∈ Keys

Keys_Select = String.(Keys_Select)

# deleteat!(Keys_Select, "wFlow_pits")

@show Keys_Select

function PLOTTTING(Data, Data_Max, Data_Min, Fig, iCount, iiKeys, X_Data, Y_Data)

	Ax_1 = Mke.Axis(Fig[1, 1], title=iiKeys, width=width, height=height)

	Data_Plot =Mke.heatmap!(Ax_1, 1:X_Data, 1:Y_Data, Data, colorrange=(Data_Min, Data_Max), colormap =:hawaii50)

	# Data_Plot =Mke.heatmap!(Ax_1, 1:X_Data, 1:Y_Data, Data,  colorrange=(0.0, maximum(Data)))

	Mke.Colorbar(Fig[1, 2], Data_Plot, width=20)
	return Fig

end


# Fig = Mke.Figure()
# Mke.CairoMakie.activate!(type="svg", pt_per_unit=1)

iCount=0
for iiKeys in Keys_Select
	Fig =  Mke.Figure()

	iCount += 1
	# println(iiKeys, " ", iCount)

	Data = Output_NCDatasets[iiKeys]
	Data = Array(Data)
	FillValue = Output_NCDatasets[iiKeys].attrib["_FillValue"]
	# Clean data
	Data =  replace(Data, FillValue => NaN)
	Data_Size = size(Data)
	Y_Data =  Data_Size[2]
	X_Data =  Data_Size[1]

	Data_Min = minimum(skipmissing(Data))
	Data_Max = maximum(skipmissing(Data))

	if Data_Min + 0.0001 > Data_Max
		Data_Max += 1
	end

	Fig = PLOTTTING(Data, Data_Max, Data_Min, Fig, iCount, iiKeys, X_Data, Y_Data)

	println(Data[1,1])

	Mke.display(Fig)

end


		return
		end  # function: HEATMAT_NETCDF
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
	# ------------------------------------------------------------------
end # geoPlot