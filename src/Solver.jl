using JuMP
using CPLEX

param nb_pair:=2 ;
param pair: 1 2 := 
1   1  8  
2   2  7  
; 
param demand := 
1   1  
2   1  
; 
param n:=8 ;
# la proba_arc_tax sur 10 est 4 
param nb_arc_1:=4 ;
param nb_arc_2:=10 ;
param arc_1: 1 2 3 :=
1   2  4  1 
2   3  5  2 
3   5  4  4 
4   5  6  3 
;
param arc_2: 1 2 3 :=
1   1  2  0 
2   1  3  0 
3   2  5  10 
4   3  4  2 
5   4  5  2 
6   4  6  8 
7   4  7  8 
8   5  7  4 
9   6  8  0 
10   7  8  0 
;

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
    @constraint(m, [i in 1:n, j in i+1:n, k in 1:K], y[k,i] + y[k,j] <= 1+x[i,j])
    @constraint(m, [i in 1:n, j in i+1:n, k in 1:K], y[k,i] - y[k,j] <= 1-x[i,j])
    @constraint(m, [i in 1:n, j in i+1:n, k in 1:K], -y[k,i] + y[k,j] <= 1-x[i,j])

    @constraint(m, [i in 1:n], sum(y[k,i] for k in 1:K) == 1)

    #Contraintes duales
    @constraint(m, [i in 1:n, j in i+1:n], alpha + beta[i,j] >= (lh[i] + lh[j])*x[i,j])
    @constraint(m, [k in 1:K], W*gamma[k] + sum(w_v[i]*y[k,i] + W_v[i]*zeta[k,i] for i in 1:n) <= B)

    @constraint(m, [i in 1:n, k in 1:K], gamma[k] + zeta[k,i] >= w_v[i]*y[k,i])

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

dualisation(path)