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

using DelimitedFiles

# Struct that models a vertex of this problem
struct Vertex
    id :: Int		## Vertex id
    x  :: Float64	## x-coordinate of the vertex
    y  :: Float64	## y-coordinate of the vertex
end

# Struct that models an edge of the graph
struct Edge
    id :: Int		## Edge id
    i  :: Vertex	## Vertex i
    j  :: Vertex	## Vertex j
    d  :: Float64	## Demand of the edge (i,j)
end

# Struct "Instance" models a generic instance for MaxDP
struct Instance
    n :: Int                 			## Number of vertices
    V :: Vector{Vertex}  			## Vector of vertices
    m :: Int					## Number of edges
    E :: Vector{Edge}				## Array of edges
    k :: Int                 			## Number of districts (depots)
    b :: Array{Float64,2}			## Minimum distance from a depot to a vertex 
    f :: Array{Float64,2}			## Shortest-path between each pair i and j 
    sgmE :: Array{Vector{Int}}			## Set of indexes of edges adjacent to edge e
    delta :: Array{Vector{Int}}			## Set of indexes of edges incident to vertex i
    davg :: Float64				## Average demand per depot (district)
end

function isAdjacent(e1::Edge, e2::Edge)::Bool
	return (e1.i.id == e2.i.id || e1.i.id == e2.j.id || e1.j.id == e2.i.id || e1.j.id == e2.j.id)
end

#= Read a Arc Routing instance.
We have as a parameter:
- io: object that points to the input file
Returns an object Instance
=#
function readAR(io::IO)
	# Read all lines of the file
	l = readlines(io)

	# Line count
	cnt = 1
	
	# Get the number of vertices
        n = parse(Int, l[cnt])
	cnt += 1

	# Create the set of vertices
	V = Vector{Vertex}()
	
	# Read the vertex lines and get the informations
	l0 = readdlm(IOBuffer(join(l[cnt:n+1],"\n")), String)
	for i=1:n
		id = parse(Int, l0[i,1])
		x = parse(Float64, l0[i,2])
		y = parse(Float64, l0[i,3])
		v = Vertex(id, x, y)
		push!(V, v)
		cnt += 1
	end

	# Get the number of depots (districts)
        k = parse(Int, l[cnt])
	cnt += 1

	# Get the number of edges
	m = parse(Int, l[cnt])
	cnt += 1

	# Read the edges
	l1 = readdlm(IOBuffer(join(l[cnt:end],"\n")), String)
	E = Vector{Edge}()

	# Set of adjacent edges of each id (we identify them by their ids)
	sgmE = [Vector{Int}() for i=1:m]

	# Set of incident edges for each vertex (we identify them by ther ids) 
	delta = [Vector{Int}() for i=1:n]
	
	# Reading edges from input file
	davg = 0.0
	for u=1:m
		id = parse(Int, l1[u,1]) 
		i = parse(Int, l1[u,2])
		j = parse(Int, l1[u,3])
		d = parse(Float64, l1[u,4])
		davg += d

		e = Edge(id, V[i], V[j], d)
		push!(E, e)			
		
		# Edges incident to vertex i and j	
		push!(delta[i], id)
		push!(delta[j], id)

		for e1 in E
			# Test if an edge e1 is adjacent to edge e
			if(isAdjacent(e, e1))
				push!(sgmE[id], e1.id)
				push!(sgmE[e1.id], id)
			end
		end
	end
	
	# Average demand per depot (district)
	davg = davg/k

	# Calculating the matrix of shortest-paths (to simplify, we will use Eulerian distance instead of Floyd-Warshall algorithm)
	f = zeros(Float64, n, n)
	for i=1:n, j=1:n
		f[i,j] = sqrt((V[i].x - V[j].x)^2 + (V[i].y - V[j].y)^2)
	end

	# Calculating the minimum distance from a depot to a vertex 
	b = zeros(Float64, k, m)
	for p=1:k, e=1:m
		i = E[e].i.id # Get vertex i id
		j = E[e].j.id # Get vertex j id
		b[p,e] = min(f[p,i],f[p,j])
	end

   	return Instance(n, V, m, E, k, b, f, sgmE, delta, davg)
end
