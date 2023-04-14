#Définition de la classe Reseau, comportant toutes les grandeurs intéressantes du problème

mutable struct Reseau 
    n               :: Int64                                #|V|
    nb_pair         :: Int64                                #kmax
    pairs           :: Vector{Tuple{Int64,Int64}}           #Ensemble des (ok, dk)
    Demands         :: Vector{Int64}                        #Dk
    Vertices        :: Vector{Int64}                        #V
    Branches        :: Vector{Tuple{Int64,Int64}}           #A
    Costs           :: Vector{Int64}                        #c_a : de la même taille que A
    Taxed_branches  :: Vector{Bool}                         #A1 (note : A2 = A\A1) : de la même taille que Branches, l'élément i est true Ssi l'arête i est dans A1
    Taxes           :: Vector{Float64}                      #T_a : de la même taille que Branches, l'élément i est égal à la taxe sur l'arête i

    Reseau() = new()
end
    
function init_res()
    res = Reseau()
    res.n = 0
    res.nb_pair = 0
    res.pairs = Vector{Tuple{Int64,Int64}}()
    res.Demands = Vector{Int64}()
    res.Vertices = Vector{Int64}()
    res.Branches = Vector{Tuple{Int64,Int64}}()
    res.Costs = Vector{Int64}()
    res.Taxed_branches = Vector{Bool}()
    res.Taxes = Vector{Int64}()

    return res
end

function add_pair!(res::Reseau, ok::Int64, dk::Int64 ; Demand::Int64 = 0)
    res.nb_pair += 1
    push!(res.pairs,(ok,dk))
    push!(res.Demands, Demand)
end

function modify_demand!(res::Reseau, index::Int64, Demand::Int64)
    if index > res.nb_pair || index < 1
        println("Erreur : l'indice de cette demande ne correspond pas aux données du réseau.")
        return -1
    end
    res.Demands[index] = Demand
end

function add_Vertex!(res::Reseau, k::Int64)
    res.n += 1
    push!(res.Vertices,k)
end

function add_Branch!(res::Reseau, u::Int64, v::Int64, cost::Int64 ; taxed_branch::Bool = false, tax::Int64 = 0)
    if !in(u, res.Vertices)
        println("Erreur ; veuillez indiquer une arête entre deux sommets existants.")
        return -1
    end
    if !in(v, res.Vertices)
        println("Erreur ; veuillez indiquer une arête entre deux sommets existants.")
        return -1
    end
    push!(res.Branches,(u,v))
    push!(res.Costs, cost)
    if taxed_branch
        push!(res.Taxed_branches,1)
        push!(res.Taxes, tax)
    else
        push!(res.Taxed_branches,0)
        push!(res.Taxes, 0)
    end
end

function in_A1(res::Reseau, branch::Tuple{Int64,Int64})
    ind = findfirst(b -> b == branch, res.Branches)
    if isnothing(ind)
        println("Erreur : cette branche ne fait pas partie du réseau tout court.")
        return -1
    end
    return res.Taxed_branches[ind]
end

function modify_tax!(res::Reseau, branch::Tuple{Int64,Int64}, tax::Int64)
    if tax > 0 && !inA1(res, branch)
        println("Erreur : la branche ne peut pas avoir une taxe strictement positive puisqu'elle n'est pas dans A1.")
        return -1
    end
    ind = findfirst(b -> b == branch, res.Branches)
    res.Taxes[ind] = tax
end

function cost(res::Reseau, branch::Tuple{Int64,Int64})
    ind = findfirst(b -> b == branch, res.Branches)
    if isnothing(ind)
        println("Erreur : cette branche ne fait pas partie du réseau tout court.")
        return -1
    end
    return res.Costs[ind]
end

function tax(res::Reseau, branch::Tuple{Int64,Int64})
    ind = findfirst(b -> b == branch, res.Branches)
    if isnothing(ind)
        println("Erreur : cette branche ne fait pas partie du réseau tout court.")
        return -1
    end
    return res.Taxes[ind]
end

function print(res::Reseau)
    println("n = ",res.n)
    println("nb_pair = ",res.nb_pair)
    println("pairs = ",res.pairs)
    println("Demands = ",res.Demands)
    println("Vertices = ",res.Vertices)
    println("Branches = ",res.Branches)
    println("Costs = ",res.Costs)
    println("Taxed_branches = ",res.Taxed_branches)
    println("Taxes = ",res.Taxes)
end

function deltaplus(res::Reseau, u::Int64)
    if u < 1 || u > res.n
        println("Erreur : sommet non présent dans le graphe.")
        return []
    end
    dp = []
    for b in res.Branches
        if b[1] == u
            push!(dp, b)
        end
    end
    return dp
end

function deltaminus(res::Reseau, u::Int64)
    if u < 1 || u > res.n
        println("Erreur : sommet non présent dans le graphe.")
        return []
    end
    dm = []
    for b in res.Branches
        if b[2] == u
            push!(dm, b)
        end
    end
    return dm
end





