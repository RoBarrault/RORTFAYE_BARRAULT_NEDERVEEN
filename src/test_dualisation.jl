using JuMP
using CPLEX

include("Parser.jl")

path = "instance_expl.txt"

function Solve(filenameInput::String)

    G = Parse(filenameInput)
    print(G)

    A1 = G.Branches[findall(!iszero, G.Taxed_branches)]
    A2 = G.Branches[findall(iszero, G.Taxed_branches)]

    m = Model(CPLEX.Optimizer)

    #Variables primales
    @variable(m, x[a in G.Branches, k in 1:G.nb_pair], Bin)

    #Variables duales
    @variable(m, lambda[v in G.Vertices, k in 1:G.nb_pair] >= 0)

    #Variables pour linéarisation
    #@variable(m, z[a in A1, k in 1:nb_pair], Int)

    #Contraintes primales
    

    #Contraintes duales
    @constraint(m, [a1 in A1, k in 1:G.nb_pair], lambda[a1[2],k] - lambda[a1[1],k] <= cost(G,a1))
    @constraint(m, [a2 in A2, k in 1:G.nb_pair], lambda[a2[2],k] - lambda[a2[1],k] <= cost(G,a2))

    #Contraintes de dualité forte


    #Objectif
    @objective(m, Max, sum(lambda[G.pairs[k][2],k] - lambda[G.pairs[k][1],k] for k in 1:G.nb_pair))


    println(m)
    #Résolution
    optimize!(m)

    # Récupération du status de la résolution
    feasibleSolutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    isOptimal = termination_status(m) == MOI.OPTIMAL
    if feasibleSolutionFound
            # Récupération des valeurs d’une variable
            vlambda = JuMP.value.(lambda)
            vOpt = JuMP.objective_value(m)
    end

    #Affichage de solution
    println("Valeur optimale :", vOpt)
    for k in 1:G.nb_pair
        println(" ")
        #println(findall(!iszero, vy[k,:]))
    end
    println(m)
end

Solve(path)