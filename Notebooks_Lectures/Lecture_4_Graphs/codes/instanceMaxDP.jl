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

# Struct "Instance" models a generic instance for MaxDP
struct Instance
    n :: Int                 		## Number of objects
    m :: Int                 		## Number of groups
    a :: Array{Float64}      		## Weights of the objects
    M :: Array{Float64}      		## Target weights of the groups
    d :: Array{Float64,2}    		## Target matrix of distances between objects
    E :: Array{Tuple{Int,Int,Float64}} 	## Edge list in descending order (by its weight)
    ud :: Array{Float64} ## Unique values of distances (used in Model 2)
end

#= Read a MaxDP instance.
We have as a parameter:
- io: object that points to the input file
Returns an object Instance
=#
function readMaxDP(io::IO)::Instance
    # Reding number of items (students) and number of groups
    (n, m) = map(x->parse(Int,x), split(readline(io)))

    #= Reading tolerance (alpha) and discarding other parameters
    (We won´t work now with other instance types)
    =#
    (insType, seeds, beta)= split(readline(io))

    # Reading target group values and weights of objects
    M = map(x->parse(Float64,x), split(readline(io)))
    a = map(x->parse(Float64,x), split(readline(io)))

    # Creating matrix of distances
    d = zeros(Float64, n, n)

    # Likert scale: matrix to keep these values for each object (students, in our case)
    L = zeros(Int, n, 25) # 25: According to Likert scale
    for i=1:n
      aux = map(x->parse(Int,x), split(readline(io))) # Auxiliary vector
      for j in 1:25
        L[i,j] = aux[j]
      end
    end

    #= Now we evaluate distance of two objects (Likert, 1932):
    Absolute deviation between each value of Likert scale, for each
    pair of items
    =#
    for u=1:n, v=1:n, k=1:25
      d[u,v] += abs(L[u,k] - L[v,k])
    end

    # Creating set of edges, sorted in descending order of distances
    E = Tuple{Int,Int,Float64}[]
    ud = Float64[]

    for u=1:n, v=u+1:n
      push!(E, (u, v, d[u,v])) # We deal with a undirected graph
      push!(ud, d[u,v])
    end

    E = sort(E, lt = (a,b)->a[3]<b[3])
    ud = sort(unique(ud))

    return Instance(n, m, a, M, d, E, ud)
end

function printInstance(instance::Instance)
	println("Objects (n): ", instance.n)
	println("Groups (m): ", instance.m)

	println("Weights")
	for i=1:instance.n
		println("a[", i, "]: ", instance.a[i])
	end

	println("Target values")
	for i=1:instance.m
		println("M[", i, "]: ", instance.M[i])
	end

	println("Distance")
	for i=1:instance.n,j=1:instance.n
		println("d[", i, ",", j , "]: ", instance.d[i,j])
	end

	println("Edges")
	for e in instance.E
		println(e)
	end
end
