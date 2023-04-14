using JuMP
using CPLEX
using Gurobi

include("Parser.jl")

function PLNE_solve(filenameInput::String, display::Bool)
    
    start = time()

    G = Parse(filenameInput)

    A1 = G.Branches[findall(!iszero, G.Taxed_branches)]
    A2 = G.Branches[findall(iszero, G.Taxed_branches)]

    M = sum(cost(G,a) for a in G.Branches)

    m = Model(Gurobi.Optimizer)
    set_silent(m)

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

    # Desactive les sorties de CPLEX (optionnel)
    #set_optimizer_attribute(m, "CPX_PARAM_SCRIND", 0)

    #Résolution
    optimize!(m)

    computation_time = time()-start

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

    if display
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
    end

    vz_converted = zeros(G.n,G.n,G.nb_pair)
    for a1 in A1
        for k in 1:G.nb_pair
            vz_converted[a1[1],a1[2],k] = vz[a1,k]
        end
    end

    a_tax = findall(!iszero, vz_converted)
    T_values =  zeros(G.n,G.n)
    for index in a_tax
        T_values[index[1],index[2]] = vT[(index[1],index[2])]
    end

    #Affichage de solution
    println("Traitement de l'instance ",filenameInput)
    println("Valeur optimale :", vOpt, " trouvée en ", computation_time, " secondes")
    for index in findall(!iszero, T_values)
        println("arc (", index[1],", ",index[2],") taxé à ", T_values[index])
    end
end

#filename = "taxe_grille_6x8.txt"
#PLNE_solve(filename,true)