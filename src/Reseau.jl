#Définition de la classe Reseau, comportant toutes les grandeurs intéressantes du problème

mutable struct Reseau 
    n               :: Int64                                #|V|
    nb_pair         :: Int64                                #kmax
    pairs           :: Vector{Tuple{Int64}}                 #Ensemble des (ok, dk)
    Demands         :: Vector{Int64}                        #Dk
    Vertices        :: Vector{Int64}                        #V
    Branches        :: Vector{Tuple{Int64,Int64}}           #A
    Costs           :: Vector{Int64}                        #c_a
    Taxed_branches  :: Vector{Bool}                         #A1 (note : A2 = A\A1)
    Taxes           :: Vector{Int64}                        #T_a

    Reseau() = new()
end
    
function init()
    res = Reseau()
    res.n = 0
    res.nb_pair = 0
    res.pairs = Vector{Tuple{Int64}}()
    res.Demands = Vector{Int64}()
    res.Vertices = Vector{Int64}()
    res.Branches = Vector{Tuple{Int64,Int64}}()
    res.Costs = Vector{Int64}()
    res.Taxed_branches = Vector{Bool}()
    res.Taxes = Vector{Int64}()

    return res
end

function add_Vertex!(res::Reseau, k::Int64)
    res.n += 1
    push!(res.Vertices,k)
end

function add_Branch!(res::Reseau, u::Int64, v::Int64, cost::Int64 ; taxed_branch::Bool = false ; tax::Int64 = 0)
    if !in(u, Reseau.Vertices)
        println("Erreur ; veuillez indiquer une arête entre deux sommets existants.")
        return -1
    end
    if !in(v, Reseau.Vertices)
        println("Erreur ; veuillez indiquer une arête entre deux sommets existants.")
        return -1
    end
    push!(res.Branches,(u,v))
    push!(res.Costs, cost)
    if taxed_branch
        push!(res.Taxed_branches,(u,v))
        push!(res.Taxes, tax)
    end
end












