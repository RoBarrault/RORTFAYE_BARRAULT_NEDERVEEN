include("Reseau.jl")

function Parse_grille(filename::String)
    instance = open("Instances/"*filename, "r")
    inst_reseau = init_res()
    lines = readlines(instance)
    index = 3
    line = lines[index]
    l = split(line)
    while l[1] != ";"
        add_pair!(inst_reseau, parse(Int64, l[2]), parse(Int64, l[3]))
        index += 1
        line = lines[index]
        l = split(line)
    end
    #All pairs added

    index += 2
    #Skip useless lines

    line = lines[index]
    l = split(line)
    while l[1] != ";"
        modify_demand!(inst_reseau, parse(Int64, l[1]), parse(Int64, l[2]))
        index += 1
        line = lines[index]
        l = split(line)
    end
    #All demands corrected

    index += 1
    line = lines[index]
    #Format : line = "param n:=65 ;"
    l = split(line, "=")
    #l = ["param n:=", "65 ;"]
    n = parse(Int64, split(l[2])[1])
    for k in 1:n
        add_Vertex!(inst_reseau, k)
    end
    inst_reseau.n = n

    index += 5
    line = lines[index]
    l = split(line)
    while l[1] != ";"
        add_Branch!(inst_reseau, parse(Int64, l[2]), parse(Int64, l[3]), parse(Int64, l[4]) ; taxed_branch = true)
        index += 1
        line = lines[index]
        l = split(line)
    end
    #All A1 branches added

    index += 2
    line = lines[index]
    l = split(line)
    while l[1] != ";"
        add_Branch!(inst_reseau, parse(Int64, l[2]), parse(Int64, l[3]), parse(Int64, l[4]) ; taxed_branch = false)
        index += 1
        line = lines[index]
        l = split(line)
    end

    return inst_reseau
end