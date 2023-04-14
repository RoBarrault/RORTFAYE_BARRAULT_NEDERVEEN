#Paramètres :
#- Caractéristiques de l'instance
#- Nombre de particules
#- Nombre d'itérations
#- Vitesse maximale autorisée
#- Inertie w (caractérise la constance du vecteur vitesse)
#- Facteur max d'attirance vers la meilleure solution globale Phi1 et locale Phi2
#- 
#Pseudo code de la métaheuristique de PSO :
#- Initialisation : 
#for particule do
#   Instancier T aléatoirement
#   Déterminer aléatoirement une vitesse initiale réalisable
#   Résoudre le PLNE associé pour déterminer les x flots optimaux maximisant les coûts des péages
#   Pi <- T
#Pg <- arg max (Pi)
#while stop criterion not met do
#   for particule do
#       b1 = rand(0, Phi1)
#       b2 = rand(0, Phi2)
#       V = wV + b1(Pi - T) + b2(Pg - T)
#       T = T + V
#       Résoudre le PLNE associé pour déterminer les x flots optimaux maximisant les coûts des péages
#       Si objectif supérieur à celui de Pi
#           Mise à jour de Pi
#           Si objectif supérieur à celui de Pg
#               Mise à jour de Pg (ou alors après avoir mis à jour toutes les particules ?)

include("Parser.jl")

using JuMP
using CPLEX
using Gurobi
using Random

mutable struct particule
    res::Reseau
    speed::Vector{Float64}
    currObj::Float64
    bestT::Vector{Float64}
    bestObj::Float64

    particule() = new()
end

function part_parser(filename::String)
    part = particule()
    res = Parse(filename)
    part.res = res
    part.currObj = 0
    part.bestT = res.Taxes
    part.bestObj = 0
    return part
end

function update_speed!(part::particule, w::Float64, Phi1::Float64, Phi2::Float64, bestGlobalT::Vector{Float64})
    b1 = Phi1*rand()
    b2 = Phi2*rand()
    V = copy(part.speed)
    part.speed = trunc.(w*V + b1*(part.bestT - part.res.Taxes) + b2*(bestGlobalT - part.res.Taxes),digits=3)
end

function update_T!(part::particule)
    T = copy(part.res.Taxes)
    part.res.Taxes = trunc.(max.(T + part.speed, 0),digits=3)
end


function update_obj!(part::particule)
    res = part.res

    A1 = res.Branches[findall(!iszero, res.Taxed_branches)]
    A2 = res.Branches[findall(iszero, res.Taxed_branches)]

    T = res.Taxes
    D = sum(res.Demands[k] for k in 1:res.nb_pair)
    M = 1000*D*sum(T[k] for k in findall(res.Taxed_branches))

    m = Model(Gurobi.Optimizer)
    set_silent(m)

    @variable(m, x[a in res.Branches, k in 1:res.nb_pair], Int)

    @expression(m, real_obj, sum(tax(res,a1)*sum(x[a1, k] for k in 1:res.nb_pair) for a1 in A1))

    @constraint(m, [a in res.Branches, k in 1:res.nb_pair], res.Demands[k] >= x[a,k] >= 0)
    #Contraintes de multiflot
    @constraint(m, [k in 1:res.nb_pair], sum(x[a,k] for  a in deltaplus(res, res.pairs[k][1])) - sum(x[a,k] for a in deltaminus(res, res.pairs[k][1])) == res.Demands[k])
    @constraint(m, [k in 1:res.nb_pair], sum(x[a,k] for a in deltaplus(res, res.pairs[k][2])) - sum(x[a,k] for a in deltaminus(res, res.pairs[k][2])) == -res.Demands[k])

    for k in 1:res.nb_pair
        for v in res.Vertices
            if v != res.pairs[k][1] && v != res.pairs[k][2]
                @constraint(m, sum(x[a,k] for a in deltaplus(res, v)) - sum(x[a,k] for a in deltaminus(res, v)) == 0)
            end
        end
    end

    #Objectif
    @objective(m, Min, M*sum(sum((cost(res, a1) + tax(res, a1))*x[a1,k] for a1 in A1) + sum(cost(res, a2)*x[a2,k] for a2 in A2) for k in 1:res.nb_pair) - real_obj)

    optimize!(m)

    # Récupération du status de la résolution
    feasibleSolutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    isOptimal = termination_status(m) == MOI.OPTIMAL
    obj_val = JuMP.value.(real_obj)
    part.currObj = obj_val

    return JuMP.value.(x)
end

function PSO(filename::String, npart::Int64, nit::Int64, w::Float64, Phi1::Float64, Phi2::Float64)
    Random.seed!(1234)
    start = time()
    CV_time = 0

    #Initialisation des particules
    #Ajout du contenu de l'instance
    particules = [part_parser(filename) for _ in 1:npart]
    part1 = particules[1]
    A1 = part1.res.Branches[findall(!iszero, part1.res.Taxed_branches)]
    A2 = part1.res.Branches[findall(iszero, part1.res.Taxed_branches)]

    max_cost_A2 = maximum(part1.res.Costs[1+length(A1):length(A1)+length(A2)])
    min_cost_A1 = minimum(part1.res.Costs[1:length(A1)])

    max_tax = div(max_cost_A2 - min_cost_A1,2)
    cardA = length(part1.res.Costs)

    #Initialisation des positions
    for part in particules
        part.res.Taxes = trunc.(max_tax*rand(cardA),digits=3)
        for k in 1:length(A2)
            part.res.Taxes[length(A1)+k] = 0
        end
        #Taxe aléatoire 
        part.speed = trunc.(rand([-1/2, 1/2])*part.res.Taxes,digits=3)
        x = update_obj!(part)
        part.bestT = part.res.Taxes
        part.bestObj = part.currObj
    end

    bestGlobalObj = maximum([part.bestObj for part in particules])
    bestInd = findfirst(lamb -> lamb==bestGlobalObj, [part.bestObj for part in particules])
    bestGlobalT = particules[bestInd].bestT

    """
    println(bestGlobalObj)
    println(computation_time)
    println(bestGlobalT)"""
    initialBestObj = bestGlobalObj

    used_x = nothing

    for it in 1:nit
        bestItObj = 0
        bestItT = bestGlobalT
        it_x = nothing
        for part in particules 
            update_speed!(part, w, Phi1, Phi2, bestGlobalT)
            update_T!(part)
            x = update_obj!(part)
            if part.currObj > part.bestObj
                part.bestT = part.res.Taxes
                part.bestObj = part.currObj
            end
            if part.currObj > bestItObj
                bestItObj = part.currObj
                bestItT = part.res.Taxes
                it_x = x
                #De cette manière, on fait en sorte que les "décisions" sur les vitesses des particules s'actualisent toutes en
                #même temps
                #On pourrait aussi modifier la meilleure solution globale dès maintenant, ce qui aurait une influence différente
                #sur la définition des vitesses des autres particules de l'itération actuelle
            end
        end
        if bestItObj > bestGlobalObj
            CV_time = time() - start
            bestGlobalObj = bestItObj
            bestGlobalT = bestItT
            used_x = it_x
        end
    end
    computation_time = time()-start

    finalBestObj = bestGlobalObj
    ameliorationGap = (finalBestObj-initialBestObj)/initialBestObj
    println("Objectif final :",finalBestObj)
    println("Amélioration de l'objectif initial :",ameliorationGap)
    println("Temps de calcul :",computation_time)
    println("Temps pour trouver l'optimum approché :", CV_time)
end

files = ["taxe_grille_8x9.txt", "taxe_grille_8x10.txt", "taxe_grille_8x11.txt", "taxe_grille_8x12.txt", "taxe_grille_8x13.txt",
    "taxe_grille_8x14.txt", "taxe_grille_9x10.txt","taxe_grille_9x11.txt","taxe_grille_9x12.txt","taxe_grille_9x13.txt",
    "taxe_grille_10x3.txt","taxe_grille_10x4.txt","taxe_grille_10x5.txt","taxe_grille_10x6.txt","taxe_grille_10x7.txt",
    "taxe_grille_10x8.txt","taxe_grille_10x9.txt","taxe_grille_10x10.txt","taxe_plat_grille_2x3.txt","taxe_plat_grille_3x4.txt",
    "taxe_plat_grille_4x5.txt","taxe_plat_grille_5x6.txt","taxe_plat_grille_6x7.txt","taxe_plat_grille_6x8.txt","taxe_plat_grille_6x9.txt",
    "taxe_plat_grille_6x10.txt","taxe_plat_grille_7x8.txt","taxe_plat_grille_7x9.txt","taxe_plat_grille_7x10.txt",
    "taxe_plat_grille_7x11.txt"]

for filename in files
    PSO(filename, 50, 300, 1.0, 0.5, 0.5)
end

