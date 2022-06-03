module HypergraphRewriting

using Hypergraphs, Graphs, GraphHelpers
using Symbolics#, SymbolicUtils
using Symbolics: unwrap, get_variables, toexpr, symtype

Symbolics.get_variables(arr::AbstractArray) = union(get_variables.(arr)...)
Symbolics.substitute(arr::Array{Num}, dict::Dict) = map(x -> substitute(x, dict), arr)
function Symbolics.substitute(p::Pair, dict::Dict)
    Pair(map(p_ -> map(x -> substitute(x, dict), p_), collect(p))...)
end
Base.isequal(hg::Hypergraphs.AHG, hg2::Hypergraphs.AHG) = hg.he2v == hg2.he2v && hg.v2he == hg2.v2he

"

[x, x] => ... cannot match [1, 2]
but 
[x, y] => ... can match [1, 1]

i don't handle more than one edge on LHS yet
https://www.wolframphysics.org/technical-introduction/basic-form-of-models/rules-depending-on-more-than-one-relation/
"
function apply_rule!(hg, rule)
    l, r = rule
    lvars = get_variables(l)
    rvars = get_variables(r)
    newvs = setdiff(rvars, lvars)
    curr_edges = copy(edges(hg))
    for e in curr_edges
        if length(unique(e)) <= length(unique(l[1]))
            ids = []
            for newv in newvs
                add_vertex!(hg)
                push!(ids, newv => nv(hg))
            end

            for (eid, var) in zip(e, l[1])
                push!(ids, var => eid)
            end
            curr = substitute(rule, Dict(ids))
            rem_edge!(hg, e)
            for new_es in curr[2]
                # has_edge(hg, new_es) || add_edge!(hg, Int.(Symbolics.value.(new_es)))
                add_edge!(hg, Int.(Symbolics.value.(new_es)))
            end
        end
    end
    hg
end

"Nest"
function nest_apply(f, x, n)
    for i in 1:n
        x = f(x)
    end
    x
end

"NestList"
function nest_apply_save(f, x, n)
    V = Vector{typeof(x)}(undef, n + 1)
    V[1] = x
    for i in 2:(n+1)
        x = f(x)
        V[i] = x
    end
    V
end

export apply_rule!, nest_apply, nest_apply_save

end # module HypergraphRewriting
