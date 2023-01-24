using JuMP
using CPLEX

include("Parser.jl")

path = "instance_expl.txt"

function Solve_Primal(filenameInput::String)

    G = Parse(filenameInput)
    print(G)

    A1 = G.Branches[findall(!iszero, G.Taxed_branches)]
    A2 = G.Branches[findall(iszero, G.Taxed_branches)]

    println("here it is", deltaminus(G, 4))

    m = Model(CPLEX.Optimizer)

    #Variables primales
    @variable(m, x[a in G.Branches, k in 1:G.nb_pair], Bin)

    #Variables duales
    @variable(m, lambda[v in G.Vertices, k in 1:G.nb_pair] >= 0)

    #Variables pour linéarisation
    #@variable(m, z[a in A1, k in 1:nb_pair], Int)

    #Contraintes primales
    
    for k in 1:G.nb_pair
        ok = G.pairs[k][1]
        dk = G.pairs[k][2]
        @constraint(m, sum(x[a,k] for a in deltaplus(G, ok)) - sum(x[a,k] for a in deltaminus(G, ok)) == 1)
        @constraint(m, sum(x[a,k] for a in deltaplus(G, dk)) - sum(x[a,k] for a in deltaminus(G, dk)) == -1)
        
        for v in G.Vertices
            if v != ok && v!=dk
                @constraint(m, sum(x[a,k] for a in deltaplus(G, v)) - sum(x[a,k] for a in deltaminus(G, v)) == 0)
            end
        end
    end

    
    #Contraintes duales
    @constraint(m, [a1 in A1, k in 1:G.nb_pair], lambda[a1[2],k] - lambda[a1[1],k] <= cost(G,a1))
    @constraint(m, [a2 in A2, k in 1:G.nb_pair], lambda[a2[2],k] - lambda[a2[1],k] <= cost(G,a2))

    #Contraintes de dualité forte
    @constraint(m, [k in 1:G.nb_pair], sum(cost(G,a)*x[a,k] for a in G.Branches) <= G.Demands[k]*(lambda[G.pairs[k][2],k] - lambda[G.pairs[k][1],k]))

    #Objectif
    @objective(m, Min, 1)


    println(m)
    #Résolution
    optimize!(m)

    # Récupération du status de la résolution
    feasibleSolutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    isOptimal = termination_status(m) == MOI.OPTIMAL
    if feasibleSolutionFound
            # Récupération des valeurs d’une variable
            vx = JuMP.value.(x)
            vOpt = JuMP.objective_value(m)
    end

    #Affichage de solution
    println("Valeur optimale :", vOpt)
    for k in 1:G.nb_pair
        println(" ")
        #println(findall(!iszero, vy[k,:]))
    end
    println(m)
    println("Solution x : ", vx)
end

Solve_Primal(path)