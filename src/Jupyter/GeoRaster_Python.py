def python_sum(i, j):
	 return i+j

def get_ith_element(n):
	 a = [0,1,2,3,4,5,6,7,8,9]
	 return a[n]



i = 3
pyexec(read("python_code.py", String),Main)
@pyexec (i=3, j=4) => "f = python_sum(i,j)" => (f::Float64)

  https://discourse.julialang.org/t/how-to-evaluate-python-custom-code-in-pythoncall/116113/6