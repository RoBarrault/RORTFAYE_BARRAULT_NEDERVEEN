using JuMP
using CPLEX

include("Parser.jl")

path = "instance_expl.txt"

objet = Parse(path)
println(objet)


function Solve()

    m = Model(CPLEX.Optimizer)

    #Variables primales
    @variable(m, x[(i,j) in arc_1[:,[1,2]], k in 1:nb_pair], Int)
    @variable(m, T[(i,j) in arc_1[:,[1,2]]] >= 0)

    #Variables duales
    @variable(m, lambda[v in 1:n, k in 1:nb_pair] >= 0)

    #Variables pour linéarisation
    @variable(m, z[(i,j) in arc_1[:,[1,2]], k in 1:nb_pair], Int)

    #Contraintes primales
    @constraint(m, [i in 1:n, j in i+1:n, k in 1:K], z[k, k] <= 1+x[i,j])
    @constraint(m, [i in 1:n, j in i+1:n, k in 1:K], y[k,i] - y[k,j] <= 1-x[i,j])
    @constraint(m, [i in 1:n, j in i+1:n, k in 1:K], -y[k,i] + y[k,j] <= 1-x[i,j])

    @constraint(m, [i in 1:n], sum(y[k,i] for k in 1:K) == 1)

    #Contraintes duales
    @constraint(m, [i in 1:nb_arc_1, k in 1:nb_pair], lambda[A1[i,2],k] - lambda[A1[i,1],k] <= c_1[i])
    @constraint(m, [i in 1:nb_arc_2, k in 1:nb_pair], lambda[A2[i,2],k] - lambda[A2[i,1],k] <= c_2[i])



    #Contraintes de dualité forte

    #Objectif
    @objective(m, Min, L*alpha + sum(l[i,j]*x[i,j] + 3*beta[i,j] for i in 1:n,j in i+1:n))

    #Résolution
    optimize!(m)

    # Récupération du status de la résolution
    feasibleSolutionFound = primal_status(m) == MOI.FEASIBLE_POINT
    isOptimal = termination_status(m) == MOI.OPTIMAL
    if feasibleSolutionFound
            # Récupération des valeurs d’une variable
            vx = JuMP.value.(x)
            vy = JuMP.value.(y)
            vOpt = JuMP.objective_value(m)
    end

    #Affichage de solution
    println("Valeur optimale :", vOpt," obtenue avec les clusters : ")
    for k in 1:K
        println(findall(!iszero, vy[k,:]))
    end
    println(m)
end
