include("Reseau.jl")

function Parse_grille(filename::String)
    instance = open("../instances/"*filename, "r")
    inst_reseau = Reseau()
    for (index,line) in enumerate(eachline(instance))
        
    end
end