#= 
On modelling optimization problems via Julia JuMP

Prof. Mayron César O. Moreira 

Universidade Federal de Lavras (UFLA)
Department of Computer Science
Lavras, Minas Gerais, Brazil

Università degli Studi di Modena e Reggio Emilia (UNIMORE)
Reggio Emilia, Italy

Description: this file contains a data structure to represent an Instance of the Minimum Tool Switching Problem. Moreover, we present functions to read data from the literature.
=#

using DelimitedFiles

# Struct "Instance" models a generic instance for the MTSP
struct Instance
	n :: Int                 			## Number of jobs
	m :: Int					## Number of tools
	J :: Vector{Vector{Int}}			## Set of jobs that requires tool t (the dimension of the vector will be m)
	T :: Vector{Vector{Int}}                 	## Set of tools that required by each job (the dimension of the vector will be n)
	C :: Int		 			## Capacity of the magazine
end

#= Read a MTSP instance.
We have as a parameter:
- io: object that points to the input file (from CVRP)
Returns an object Instance
=#
function readMTSP(io::IO)::Instance
	## Read lines of the file
	l=readlines(io)
	## Now we take the lines we are interested
	l0=readdlm(IOBuffer(join(l[1:end],"\n")),String)
	
	## Reading number of tools, number of jobs and capacity	
	m = parse(Int, l0[1,1])
	n = parse(Int, l0[1,2])
	C = parse(Int, l0[1,3])

	## Now we allocate vectors J and T. Next, we get these data
	J = [Vector{Int}() for _ in 1:m]
	T = [Vector{Int}() for _ in 1:n]
	
	for j=1:n
		for t=1:m
			value = parse(Int, l0[j+1,t])
			if(value==1)
				push!(J[t],j)		
				push!(T[j],t)
			end
		end
		
	end
	return Instance(n, m, J, T, C)	
end
