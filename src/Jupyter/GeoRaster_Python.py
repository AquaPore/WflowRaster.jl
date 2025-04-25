def python_sum(i, j):
	 return i+j

def get_ith_element(n):
	 a = [0,1,2,3,4,5,6,7,8,9]
	 return a[n]



i = 3
pyexec(read("python_code.py", String),Main)
@pyexec (i=3, j=4) => "f = python_sum(i,j)" => (f::Float64)

  https://discourse.julialang.org/t/how-to-evaluate-python-custom-code-in-pythoncall/116113/6


  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #		FUNCTION : DEM_2_FLOWDIRECTION
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        function DEM_2_FLOWDIRECTION(Path_Input, Path_Output)

            rasterio = PythonCall.pyimport("rasterio")
            pyflwdir = PythonCall.pyimport("pyflwdir")

            # PythonCall.@pyexec """
            #     def DEM_2_FLOWDIRECTION(Path_Input, Path_Output):
            #         with rasterio.open(Path_Input, "r") as src:
            #             elevtn = src.read(1)
            #             nodata = src.nodata
            #             transform = src.transform
            #             crs = src.crs
            #             #  extent = np.array(src.bounds)[[0, 2, 1, 3]]
            #             latlon = src.crs.is_geographic
            #             prof = src.profile

            #         # returns FlwDirRaster object
            #         FlowDirection_Pyflwdir = pyflwdir.from_dem(data=elevtn, nodata=src.nodata, transform=transform, latlon=latlon, outlets="min")

            #         FlowDirection_Array = FlowDirection_Pyflwdir.to_array(ftype="ldd")

            #         # Write to tiff file
            #         prof.update(dtype=FlowDirection_Array.dtype, nodata=False)
            #         with rasterio.open(Path_Output, "w", **prof) as src:
            #             src.write(FlowDirection_Array, 1)

            #         return FlowDirection_Array, FlowDirection_Pyflwdir
            #         """ => DEM_2_FLOWDIRECTION

            #     FlowDirection_Array, FlowDirection_Pyflwdir = PythonCall.pyconvert(Any, DEM_2_FLOWDIRECTION(Path_Input, Path_Output))

        FlowDirection_Array=0; FlowDirection_Pyflwdir=0
        return FlowDirection_Array, FlowDirection_Pyflwdir
        end  # function: DEM_2_FLOWDIRECTION
    # ------------------------------------------------------------------



    function PYTHON_2_JULIA(P_Int, P_Float, P_String, P_Vector)
        PythonCall.@pyexec """
            import numpy as np
            global np
            def PYTHON_2_JULIA(P_Int, P_Float, P_String, P_Vector):
                P_Int1 = P_Int + 1
                P_Float1 = P_Float * 2.0
                P_String1 = P_String + P_String
                P_Vector1 = P_Vector + P_Vector
                return P_Int1, P_Float1, P_String1, P_Vector1
            """=> PYTHON_2_JULIA

        P_Int1, P_Float1, P_String1, P_Vector1 = PythonCall.pyconvert(Any, PYTHON_2_JULIA(P_Int, P_Float, P_String, P_Vector))

    return P_Int1, P_Float1, P_String1, P_Vector1
    end