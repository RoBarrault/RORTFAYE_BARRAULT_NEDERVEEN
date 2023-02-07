include("PLNE_solving.jl")

display = false

for instance in readdir("Instances", sort=false)[2:32]
    PLNE_solve(instance, display)
end