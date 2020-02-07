## Dynamics for the graphical ideology model


function id_update(g::IGraph, v, c, selfweight = 1)
    selfid = props(g.g, v)[:ideology]
    neighborid = [props(g.g, w)[:ideology] for w in neighbors(g.g, v) 
                        if g.distance(props(g.g, w)[:ideology], selfid) <= c]
    length(neighborid) > 0 ? ((sum(neighborid) + selfweight * selfid) / (length(neighborid) + 1)) : selfid
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
    newids = Array{Float64, 1}()
    for v in vertices(g.g) append!(newids, id_update(g, v, c)) end
    # newids = [id_update(g,v,c) for v in vertices(g.g)]
    m = maximum([abs(newids[v] - props(g.g, v)[:ideology]) for v in vertices(g.g)])
    for v in vertices(g.g)
        if !has_prop(g.g, v, :media)
            set_prop!(g.g, v, :ideology, newids[v])
        end
    end
    (newids, m)
end

function updateg!(g::IQGraph, c)
    newids = [id_update(g, v, c) for v in vertices(g.g)]
    newqs = [q_update(g, v, c) for v in vertices(g.g)]
    m = maximum([abs(newids[v] - props(g.g, v)[:ideology]) for v in vertices(g.g)])
    for v in vertices(g.g)
        if !has_prop(g.g, v, :media)
            set_prop!(g.g, v, :ideology, newids[v])
        end
    end
    (newids, newqs, m)
end

function fullsim!(g::IGraph, c, tol = 10^(-4), maxsteps = 1000, verbose = false)
    m = 1
    ids = [props(g.g, v)[:ideology] for v in vertices(g.g)]
    steps = 0
    while m > tol && steps < maxsteps
        (newids, m) = updateg!(g, c)
        ids = hcat(ids, newids)
        steps += 1
    end
    return ids, steps
end

function fullsim_gif(g::IGraph, c, len = 400, tol = 10^(-4), verbose = false)
    m = 1
    ids = [props(g.g, v)[:ideology] for v in vertices(g.g)]
    steps = 0
    @gif for i = 1:len
        (newids, m) = updateg!(g, c)
        ids = hcat(ids, newids)
        steps += 1
        colornet!(g)
        drawcolorgraph(g)
    end
end