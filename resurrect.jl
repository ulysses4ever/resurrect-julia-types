#
# WARNING: This file does Pkg.add. Run it in a private depot to not pollute the default one.
# E.g.: JULIA_DEPOT_PATH=. julia resurrect.jl
#

using CSV, Pkg # DataFrames, Query

parts(ty) = split(ty,".")

unqualified_type(ty) = last(parts(ty))
root_module(ty) = first(parts(ty))

"""
addpackage: (tyrow : {modl, tyname, occurs}) -> IO ()

The function tries to update the current environment in a way that it's possible to
`Core.eval(tyrow.modl, tyrow.tyname)`.
"""
addpackage(tyrow) = begin
    tyrow.modl in ["Core", "Base"] && return true

    try
        Pkg.add(root_module(ty.name))
    catch e
        @warn "Couldn't add package for type $ty"
        return false
    end

    return true
end

intypesCsvFile = "all-types-merged.csv"
intypesCsv = CSV.read(intypesCsvFile, DataFrame)
for tyRow in eachrow(intypesCsv)
    print(tyRow.tyname)
    if addpackage(tyRow)
        ty = Core.eval(tyRow.modl, unqualified_type(tyRow.tyname))
        print(ty)
    end
end
