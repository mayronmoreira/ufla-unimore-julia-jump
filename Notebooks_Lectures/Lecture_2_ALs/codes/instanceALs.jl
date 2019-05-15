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

# Constant associated with task x worker infeasibility
const incompatible = 10000

# Struct "Instance" models a generic instance for Assembly Line Balancing Problems
struct Instance
	n :: Int                 ## Number of tasks
	w :: Int                 ## Number of workers (equal to number of stations)
	p :: Array{Int,2}        ## task x worker execution time matrix, infeasible tasks have time `incompatible`

	c :: Int 		 # Cycle time

	## immediate relations
	d :: Array{Bool,2}       ## task x task precedence matrix
	P :: Vector{Vector{Int}} ## predecessors
	F :: Vector{Vector{Int}} ## followers

	## immediate and transitive relations
	cD :: Array{Bool,2}       ## task x task precedence matrix
	cP :: Vector{Vector{Int}} ## predecessors
	cF :: Vector{Vector{Int}} ## followers
end

#= Read an ALWABP instance.
We have as a parameter:
- io: object that points to the input file (from ALWABP)
Returns an object Instance
=#
function readALWABP(io::IO)::Instance
	## (1) Read processing time and list of precedences
	l=readlines(io)

	## Converting the number of tasks to an integer
	n=parse(Int,l[1])

	#= Convert strings into IOBuffer, in order to handle
	with streams. Note that the streams are separated by
	'breakline'. t0 is converted, in the end, to a string
	=#
	p0=readdlm(IOBuffer(join(l[2:n+1],"\n")),String)

	## Maps strings of each lines to integers
	p=map(x->if x=="Inf" incompatible else parse(Int,x) end,p0)

	#= Test if there is some valeu of t that is greater than
	incompatible value
	=#
	@assert maximum(p)<=incompatible

	#= Maps the remaining lines containing precedence relations
	among tasks
	=#
	if (map(x->parse(Int,x),split(l[end]))==[-1,-1])
		D=readdlm(IOBuffer(join(l[n+2:end-1],"\n")),Int)
	else
		D=readdlm(IOBuffer(join(l[n+2:end],"\n")),Int)
	end

	## Auxiliary data

	## Number of workers will be the number of columns of t
	wk=size(p,2)

	## Initialize d with false values
	d=falses(n,n)

	## Set of predecessors of each task
	P=[Vector{Int}() for _ in 1:n]

	## Set of followers of each task
	F=[Vector{Int}() for _ in 1:n]

	for di in 1:size(D,1)
		## [di,1] and [di,2] have precedence relationships
		d[D[di,1],D[di,2]]=true
		push!(F[D[di,1]],D[di,2])
		push!(P[D[di,2]],D[di,1])
	end

	## Transitive closure
	cD=copy(d)
	for i=1:n,j=1:n,k=1:n
		cD[i,j]=cD[i,j] || cD[i,k] && cD[k,j]
	end

	cP=[Vector{Int}() for _ in 1:n]
	cF=[Vector{Int}() for _ in 1:n]

	for i=1:n,j=1:n
		if cD[i,j]
			push!(cF[i],j)
			push!(cP[j],i)
		end
	end

	# Return an object with all input data of the problem
	return Instance(n,wk,p,-1,d,P,F,cD,cP,cF)
end

#=
Auxiliary function used to skip some "xml" tags from Otto et al. (2013) input pattern.
Otto, A., Otto, C., & Scholl, A. (2013). Systematic data generation and test design for solution algorithms on the example of SALBPGen for assembly line balancing. European Journal of Operational Research, 228(1), 33-45.
=#
function skipToSection(name,cl,l)
	while chomp(l[cl])!=name
		cl += 1
    	end
    	cl+1
end

#= 
Read a SALBP instance in the format of Otto et al. (2013)
=#
function readSALBP(io::IO)::Instance
	## Read processing time and list of precedences
    	l=readlines(io)
    	cl=1

    	cl=skipToSection("<number of tasks>",cl,l)
    	n=parse(Int,l[cl])

	cl=skipToSection("<cycle time>",cl,l)
    	c=parse(Int,l[cl])
    
    	cl=skipToSection("<task times>",cl,l)
    	p0=readdlm(IOBuffer(join(l[cl:cl+n-1],"\n")),Int)
	p=reshape(p0[:,2], (n, 1))
	@assert maximum(p)<=incompatible
	
	cl=skipToSection("<precedence relations>",cl,l)
    	el=skipToSection("<end>",cl,l)-3
    
    	D=readdlm(IOBuffer(join(l[cl:el],"\n")),',',Int)

    	## Auxiliary data
	d=falses(n,n)
    	P=[Vector{Int}() for _ in 1:n]
	F=[Vector{Int}() for _ in 1:n]
    	for di in 1:size(D,1)
        	d[D[di,1],D[di,2]]=true
        	push!(F[D[di,1]],D[di,2])
        	push!(P[D[di,2]],D[di,1])
    	end
  
	## Transitive closure
	cD=copy(d)
	for i=1:n,j=1:n,k=1:n
		cD[i,j]=cD[i,j] || cD[i,k] && cD[k,j]
	end

	cP=[Vector{Int}() for _ in 1:n]
	cF=[Vector{Int}() for _ in 1:n]

	for i=1:n,j=1:n
		if cD[i,j]
			push!(cF[i],j)
			push!(cP[j],i)
		end
	end


    	return Instance(n,1,p,c,d,P,F,cD,cP,cF)
end

function printInstance(instance::Instance)
	println("w: ", instance.w)
	println("n: ", instance.n)

	println("p")
	for i=1:instance.n
		for w=1:instance.w
			print(instance.p[i,w], " ")
		end
		println()
	end
	
	println("Immediate predecessors")
	for i=1:instance.n
		print("Task ", i, ": ")
		for j=instance.P[i]
			print(j, " ")
		end
		println()
	end
	println("*** *** ***")

	println("Immediate followers")
	for i=1:instance.n
		print("Task ", i, ": ")
		for j=instance.F[i]
			print(j, " ")
		end
		println()
	end
	println("*** *** ***")
end

