#
# WARNING: This file does Pkg.add. Run it in a private depot to not pollute the default one.
# E.g.: JULIA_DEPOT_PATH=. julia resurrect.jl
#

@info "Starting resurrect.jl. Using packages..."

using CSV, Pkg, DataFrames #, Query

@info "... done."

parts(ty) = split(ty,".")

unqualified_type(ty) = string(last(parts(ty)))
root_module(ty) = string(first(parts(ty)))

evalp(s::String) = eval(Meta.parse(s))

"""
addpackage: (tyrow : {modl, tyname, occurs}) -> IO ()

The function tries to update the current environment in a way that it's possible to
`Core.eval(tyrow.modl, tyrow.tyname)`.
"""
addpackage(tyRow) = begin
    tyRow.modl in ["Core", "Base"] && return true

    try
        rm=root_module(tyRow.tyname)
        @info "Try to Pkg.add package $(rm)... (may take some time)"
        Pkg.add(rm;io=devnull)
        @info "... done"
    catch err
        @warn "Couldn't add package for type $(tyRow.tyname) (module: $(tyRow.modl))"
        errio=stderr
        showerror(errio, err)
        println(errio)
        return false
    end

    return true
end

main() = begin
    @info "Reading in data..."

    intypesCsvFile = "all-types-merged.csv"
    intypesCsv = CSV.read(intypesCsvFile, DataFrame)

    @info "... done."

    failed=[]
    i=0
    fi=0
    gi=0
    for tyRow in eachrow(intypesCsv)

        # Special cases (skip for now):
        # - function types
        startswith(tyRow.tyname, "typeof") && (fi += 1; continue)
        # - generic types
        '{' in tyRow.tyname && (gi += 1; continue)

        i+=1
        @info "[$i] Processing: $(tyRow.tyname) from $(tyRow.modl)"

        if addpackage(tyRow)
            evalp("using $(tyRow.modl)")
            m = evalp(tyRow.modl)
            ty = Core.eval(m, unqualified_type(tyRow.tyname))
        else
            push!(failed, tyRow)
        end
    end
    (i,fi,gi)
end
