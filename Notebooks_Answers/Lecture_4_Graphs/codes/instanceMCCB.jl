#=
On modelling optimization problems via Julia JuMP

Prof. Mayron César O. Moreira

Universidade Federal de Lavras (UFLA)
Department of Computer Science
Lavras, Minas Gerais, Brazil

Università degli Studi di Modena e Reggio Emilia (UNIMORE)
Reggio Emilia, Italy

Description: this file contains a data structure to represent an Instance of Maximum Dispersion Problem (MaxDP).
=#

# Struct "Instance" models a generic instance for the MCCB
struct Instance
    s :: String                 ## String s
    t :: String			## String t
    A :: Array{Int64,2}		## Matrix A (matching matrix)
    F :: Array{Int64,2}		## Matrix F (forward matching matrix)
    B :: Array{Int64,2}		## Matrix B (backward matching matrix)
end

#= Read a MCCB instance.
We have as a parameter:
- io: object that points to the input file
Returns an object Instance
=#
function readMCCB(io::IO)::Instance
	(s, t) = split(readline(io))
	s = String(s)
	t = String(t)
	A = evalMatchingA(s, t)
	F = evalMatchingF(A, length(s), length(t))
	B = evalMatchingB(A, length(s), length(t))
   	return Instance(s, t, A, F, B)
end

# Generate matching matrix A
function evalMatchingA(s::String, t::String)::Array{Int64,2}
	A = zeros(Int64, length(s), length(t))
	for i=1:length(s), j=1:length(t)
		if(s[i] == t[j])
			A[i,j] += 1
		end
	end
	return A
end

# Generate forward matching matrix F
function evalMatchingF(A::Array{Int64,2}, x::Int64, y::Int64)::Array{Int64,2}
	F = zeros(Int, x, y)
	for i=1:x
		for j=1:y
			if(A[i,j] == 1 && F[i,j] == 0)
				F[i,j] += 1
				k1 = i+1
				k2 = j+1
				while(k1 <= x && k2 <= y)
					if(A[k1,k2] == 1)
						F[k1,k2] = F[k1-1,k2-1] + 1
						k1 += 1
						k2 += 1
					else
						break
					end
				end
			end	
		end
	end
	return F
end

# Generate forward matching matrix B
function evalMatchingB(A::Array{Int64,2}, x::Int64, y::Int64)::Array{Int64,2}
	B = zeros(Int64, x, y)
	for i=x:-1:1
		for j=y:-1:1
			if(A[i,j] == 1 && B[i,j] == 0)
				B[i,j] += 1
				k1 = i-1
				k2 = j-1
				while(k1 >= 1 && k2 >= 1)
					if(A[k1,k2] == 1)
						B[k1,k2] = B[k1+1,k2+1] + 1
						k1 -= 1
						k2 -= 1
					else
						break
					end
				end
			end	
		end
	end
	return B
end
