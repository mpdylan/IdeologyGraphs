## Dynamics for the graphical ideology model

function id_update(g::IGraph, v, c, selfweight = 1)
    selfid = props(g.g, v)[:ideology]
    neighborid = [props(g.g, w)[:ideology] for w in neighbors(g.g, v) 
                        if g.distance(props(g.g, w)[:ideology], selfid) <= c]
    (sum(neighborid) + selfweight * selfid) / (length(neighborid) + 1)
end

function id_update(g::IQGraph, v, c, selfweight = 1)
    selfid = props(g.g, v)[:ideology]
    neighborid = [props(g.g, w)[:ideology] for w in neighbors(g.g, v)
                        if getminq(g, v, w, c) <= props(g.g, w)[:quality]]
    (sum(neighborid) + selfweight * selfid) / (length(neighborid) + 1)
end

function q_update(g::IQGraph, v, c, selfweight = 1)
    selfq = props(g.g, v)[:quality]
    neighborq = [props(g.g, w)[:quality] for w in neighbors(g.g, v)
                        if getminq(g, v, w, c) <= props(g.g, w)[:quality]]
    (sum(neighborq) + selfweight * selfq) / (length(neighborq) + 1)
end

function getminq(g::IQGraph, v, w, c)
    d = g.distance(props(g.g, v)[:ideology], props(g.g, w)[:ideology])
    d / c
end

function updateg!(g::IGraph, c)
    newids = [id_update(g.g,v,c) for v in vertices(g.g)]
    m = maximum([abs(newids[v] - props(g.g, v)[:ideology]) for v in vertices(g.g)])
    for v in vertices(g.g)
        set_prop!(g.g, v, :ideology, newids[v])
    end
    (newids, m)
end

function updateg!(g::IQGraph, c)
    newids = [id_update(g.g, v, c) for v in vertices(g.g)]
    newqs = [q_update(g.g, v, c) for v in vertices(g.g)]
    m = maximum([abs(newids[v] - props(g.g, v)[:ideology]) for v in vertices(g.g)])
    for v in vertices(g.g)
        set_prop!(g.g, v, :ideology, newids[v])
    end
    (newids, newqs, m)
end

function fullsim(g::IGraph, c, tol = 10^(-4), verbose = false)
    m = 1
    ids = [props(g.g, v)[:ideology] for v in vertices(g.g)]
    while m > tol
        (newids, m) = updateg!(g, c)
        ids = hcat(ids, newids)
    end
    ids
end