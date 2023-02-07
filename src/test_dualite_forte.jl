using JuMP
using CPLEX

include("Parser.jl")

path = "instance_expl.txt"
path = "taxe_grille_7x11.txt"

function Solve_Primal(filenameInput::String)

    G = Parse(filenameInput)
    print(G)

    A1 = G.Branches[findall(!iszero, G.Taxed_branches)]
    A2 = G.Branches[findall(iszero, G.Taxed_branches)]

    M = sum(cost(G,a) for a in G.Branches)

    #println("here it is", deltaminus(G, 4))

    m = Model(CPLEX.Optimizer)

    #Variables primales
    @variable(m, x[a in G.Branches, k in 1:G.nb_pair], Bin)
    @variable(m, T[a in A1] >= 0)

    #Variables duales
    @variable(m, lambda[v in G.Vertices, k in 1:G.nb_pair] >= 0)

    #Variables pour linéarisation
    @variable(m, z[a in A1, k in 1:G.nb_pair] >=0)

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
    @constraint(m, [a1 in A1, k in 1:G.nb_pair], lambda[a1[2],k] - lambda[a1[1],k] <= cost(G,a1) + G.Demands[k]*T[a1])
    @constraint(m, [a2 in A2, k in 1:G.nb_pair], lambda[a2[2],k] - lambda[a2[1],k] <= cost(G,a2))

    #Contraintes de linéarisation
    @constraint(m, [a1 in A1, k in 1:G.nb_pair], z[a1,k] <= G.Demands[k]*T[a1])
    @constraint(m, [a1 in A1, k in 1:G.nb_pair], z[a1,k] <= M*x[a1,k])
    @constraint(m, [a1 in A1, k in 1:G.nb_pair], G.Demands[k]*T[a1]-z[a1,k] <= M*(1-x[a1,k]))
    
    #Contraintes de dualité forte
    @constraint(m, [k in 1:G.nb_pair], G.Demands[k]*sum(cost(G,a)*x[a,k] for a in G.Branches) + sum(z[a1,k] for a1 in A1) <= G.Demands[k]*(lambda[G.pairs[k][2],k] - lambda[G.pairs[k][1],k]))

    #Objectif
    @objective(m, Max, sum(z[a1,k] for a1 in A1, k in 1:G.nb_pair))

    #Résolution
    optimize!(m)

    # Récupération du status de la résolution
    feasibleSolutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    isOptimal = termination_status(m) == MOI.OPTIMAL
    if feasibleSolutionFound
            # Récupération des valeurs d’une variable
            vx = JuMP.value.(x)
            vlambda = JuMP.value.(lambda)
            vT = JuMP.value.(T)
            vz = JuMP.value.(z)
            vOpt = JuMP.objective_value(m)
    end


    vx_converted = zeros(G.n,G.n,G.nb_pair)
    for a in G.Branches 
        for k in 1:G.nb_pair
            vx_converted[a[1],a[2],k] = vx[a,k]
        end
    end

    for k in 1:G.nb_pair
        println("Chemin emprunté pour la commodité n°",k, " avec départ en ", G.pairs[k][1], " et arrivée en ", G.pairs[k][2]," : ")
        println(findall(!iszero, vx_converted[:,:,k]))
    end

    #Affichage de solution
    #println("Solution T : ", vT[findall(!iszero, vz)])
    println("Valeur optimale :", vOpt)
end

Solve_Primal(path)