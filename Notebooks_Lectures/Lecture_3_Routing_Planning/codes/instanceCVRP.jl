#= 
On modelling optimization problems via Julia JuMP

Prof. Mayron César O. Moreira 

Universidade Federal de Lavras (UFLA)
Department of Computer Science
Lavras, Minas Gerais, Brazil

Università degli Studi di Modena e Reggio Emilia (UNIMORE)
Reggio Emilia, Italy

Description: this file contains a data structure to represent an Instance of Assembly Line Balancing Problems. Moreover, we present functions to read and print (on the screen) data from the literature.
=#

using DelimitedFiles

# Struct "Instance" models a generic instance for CVRP
struct Instance
	n :: Int                 			## Number of nodes
	nodes :: Vector{Tuple{Float64,Float64}}		## Vertices coordinates
	K :: Int                 			## Number of vehicles
	Q :: Float64		 			## Capacity od vehicles
	w :: Array{Float64,2}        			## Travel distance matrix
	q :: Vector{Float64}	 			## Demand of each node of the graph
end

## Euclidian Distance
EUC2D(p1::Tuple{Float64,Float64}, p2::Tuple{Float64,Float64}) = sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)

#= Read a CVRP instance.
We have as a parameter:
- io: object that points to the input file (from CVRP)
- K: number of vehicles
Returns an object Instance
=#
function readCVRP(io::IO, K::Int)
	## Read lines of the file
	l=readlines(io)
	## Now we take the lines we are interested
	l0=readdlm(IOBuffer(join(l[1:end],"\n")),String)
	#println(l0)

	## Line and column where DIMENSION, CAPACITY, NODE_COORD_SECTION, DEPOT_SECTION  appear
	lnColDim = findall(x->x=="DIMENSION", l0)
	lnColCap = findall(x->x=="CAPACITY", l0)
	lnColNd = findall(x->x=="NODE_COORD_SECTION", l0)
	lnColDem = findall(x->x=="DEMAND_SECTION", l0)

	## Number of nodes
	n = parse(Int, l0[lnColDim[1,1] + CartesianIndex{2}(0,2)])
	
	## Capacity
	Q = parse(Float64, l0[lnColCap[1,1] + CartesianIndex{2}(0,2)])

	## Getting the node coordinates (we take
	nodes = Vector{Tuple{Float64,Float64}}()
	for i=1:n
		x = parse(Float64, l0[lnColNd[1,1] + CartesianIndex{2}(i,1)])
		y = parse(Float64, l0[lnColNd[1,1] + CartesianIndex{2}(i,2)])
		tpl = (x,y)
		push!(nodes, tpl)
	end 

	## Getting the demand of the clients
	q = Vector{Float64}()
	for i=1:n
		push!(q, parse(Float64, l0[lnColDem[1,1] + CartesianIndex{2}(i,1)]))
	end

	## We do not consider the reading of depot section, since we work with a single depot (first one)
	################# --- ################### --- ###############

	# Evaluating Euclidian distance between each node
	w = zeros(Float64, n, n)
	for i=1:n, j=1:n
		w[i,j] = EUC2D(nodes[i], nodes[j])
	end

	return Instance(n, nodes, K, Q, w, q)	
end
