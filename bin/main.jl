include("../src/Parser.jl")

res = Parse_grille("taxe_grille_2x3.txt")
print(res)
println(deltaminus(res,3))