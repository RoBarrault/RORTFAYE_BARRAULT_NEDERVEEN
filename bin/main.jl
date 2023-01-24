include("../src/Parser.jl")

res = Parse("taxe_grille_2x3.txt")
print(res)
println(deltaminus(res,4))

res = Parse("taxe_plat_grille_2x3.txt")
print(res)
println(deltaminus(res,4))