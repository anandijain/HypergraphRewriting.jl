using Hypergraphs, Graphs, GraphHelpers, HypergraphRewriting, Test
using Symbolics

function base_hg()
    hg = Hypergraph(2)
    add_edge!(hg, [1, 2])
    hg
end

@variables x y z w
@info "RULE 1: {{x, y}} -> {{x, y}, {y, z}}"
rule = [[x, y]] => [[x, y], [y, z]]

hg = Hypergraph(2)
add_edge!(hg, [1, 2])
hg2 = deepcopy(hg)
hg3 = deepcopy(hg)
correct = Hypergraph{Int64}([[1], [1, 2], [2]], [[1, 2], [2, 3]])

add_vertex!(hg3)
add_edge!(hg3, [2, 3])
@test isequal(correct, hg3)
hg = base_hg()
apply_rule!(hg, rule)
@test isequal(correct, hg)

hg = base_hg()
applyf = x -> apply_rule!(deepcopy(x), rule)
res = nest_apply_save(applyf, hg, 4)
@test ne.(res) == 2 .^ (0:4)
@test nv.(res) == (2 .^ (0:4)) .+ 1

@info "RULE 1 self-loop u0"

hg = Hypergraph(1)
add_edge!(hg, [1, 1])
res2 = nest_apply_save(applyf, hg, 4)
@test collect(edges(res2[3])) == [[1, 1], [1, 3], [1, 2], [2, 4]]

@info "RULE 2: {{x, y}} -> {{z, y}, {y, x}}"
rule2 = [[x, y]] => [[z, y], [y, x]]

hg = Hypergraph(2)
add_edge!(hg, [1, 2])
applyf2 = x -> apply_rule!(deepcopy(x), rule2)
res = nest_apply_save(applyf2, hg, 4)
#todo add test

@info "RULE 3: {{x, y}} -> {{y, z}, {z, x}}"
rule3 = [[x, y]] => [[y, z], [z, x]]
hg = Hypergraph(1)
add_edge!(hg, [1, 1])
applyf3 = x -> apply_rule!(deepcopy(x), rule3)
res = nest_apply_save(applyf3, hg, 4)
dg = SimpleDiGraph(res[3])
@test is_cyclic(dg)
@test length(simplecycles(dg)) == 1
@test ne.(res) == 2 .^ (0:4)

@info "RULE 4: {{x, x}} -> {{y, y}, {y, y}, {x, y}}"
rule4 = [[x, x]] => [[y, y], [y, y], [x, y]]
hg = Hypergraph(1)
add_edge!(hg, [1, 1])
applyf4 = x -> apply_rule!(deepcopy(x), rule4)
res = nest_apply_save(applyf4, hg, 4)
@test edges(res[3]) == [[1, 2], [3, 3], [3, 3], [2, 3], [4, 4], [4, 4], [2, 4]]
dg = SimpleDiGraph(res[3])
GraphHelpers.rem_self_loops!(dg)
@test GraphHelpers.is_tree(dg)

@info "RULE 5: {{x, y}} -> {{x, z}, {x, z}, {y, z}}"
rule5 = [[x, y]] => [[x, z], [x, z], [y, z]]
hg = Hypergraph(1)
add_edge!(hg, [1, 1])
applyf5 = x -> apply_rule!(deepcopy(x), rule5)
res = nest_apply_save(applyf5, hg, 4)
@test collect(edges(res[3])) == [[1, 3], [1, 3], [2, 3], [1, 4], [1, 4], [2, 4], [1, 5], [1, 5], [2, 5]]

@info "RULE 6: {{x, y}} -> {{x, z}, {z, w}, {y, z}}"
rule6 = [[x, y]] => [[x, z], [z, w], [y, z]]
hg = Hypergraph(1)
add_edge!(hg, [1, 1])
applyf6 = x -> apply_rule!(deepcopy(x), rule6)
res = nest_apply_save(applyf6, hg, 4)
@test collect(edges(res[3])) == [[1, 4], [4, 5], [2, 4], [2, 6], [6, 7], [3, 6], [1, 8], [8, 9], [2, 8]]

@info "RULE 7 : {{x, y, z}} -> {{x, y, w}, {y, w, z}}"
rule7 = [[x, y, z]] => [[x, y, w], [y, w, z]]
hg = Hypergraph(1)
add_edge!(hg, [1, 1])
applyf7 = x -> apply_rule!(deepcopy(x), rule7)
@test_throws ArgumentError nest_apply_save(applyf7, hg, 4)
hg = Hypergraph(1)
add_edge!(hg, [1, 1, 1])
res = nest_apply_save(applyf7, hg, 4)
@test edges(res[4]) == [[1, 1, 5], [1, 5, 3], [1, 3, 6], [3, 6, 2], [1, 2, 7], [2, 7, 4], [2, 4, 8], [4, 8, 1]]

@info "RULE 8 : {{x}} -> {{x, y}, {y}, {y}}"
rule8 = [[x]] => [[x, y], [y], [y]]
hg = Hypergraph(1)
add_edge!(hg, [1])
applyf8 = x -> apply_rule!(deepcopy(x), rule8)
res = nest_apply_save(applyf8, hg, 4)
@test edges(res[4]) == [[1, 2], [2, 3], [2, 4], [3, 5], [5], [5], [3, 6], [6], [6], [4, 7], [7], [7], [4, 8], [8], [8]]

@info "RULE 9: {{x, y}, {x, z}} -> {{x, y}, {x, w}, {y, w}, {z, w}}"
rule9 = [[x, y], [x, z]] => [[x, y], [x, w], [y, w], [z, w]]
hg = Hypergraph(4)
add_edges!(hg, [[1, 2], [1, 3], [1, 4], [1, 4]])
applyf9 = x -> apply_rule!(deepcopy(x), rule9)
# not supporting multiple edges on LHS
@test_throws ArgumentError nest_apply_save(applyf9, hg, 4)


@info "RULE 10: {{x, y, z}, {u, x}} -> {{x, u, v}, {z, y}, {z, u}}"
@test_broken 1 == 0

@info "RULE 11: {{x, y}} -> {{y, y}, {x, z}}"


@info "RULE 11: {{x, y}} -> {{x, x}, {z, x}}"
