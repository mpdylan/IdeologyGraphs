## Dynamics for the graphical ideology model

# Functions for updating probability

function id_update(g::IGraph, v, c, selfweight = 1)
    selfid = props(g.g, v)[:ideology]
    newid = selfid * selfweight
    n = 0
    for w in neighbors(g.g, v)
        if g.distance(props(g.g, w)[:ideology], selfid) <= c
            newid += props(g.g, w)[:ideology]
            n += 1
        end
    end
    newid / (n + selfweight)
end

function id_update(g::IQGraph, v, c, selfweight = 1)
    selfid = props(g.g, v)[:ideology]
    newq = props(g.g, v)[:quality]
    newid = selfid * selfweight
    n = 0
    for w in neighbors(g.g, v)
        if props(g.g, w)[:quality] >= getminq(g, v, w, c)
            newid += props(g.g, w)[:ideology]
            newq += props(g.g, w)[:quality]
            n += 1
        end
    end
    (newid / (n + selfweight), newq / (n + 1))
end

function getminq(g, v, w, c)
    d = g.distance(props(g.g, v)[:ideology], props(g.g, w)[:ideology])
    d / c
end

function updateg!(g::IGraph, c)
    newids = Array{Float64, 1}()
    # for v in vertices(g.g) append!(newids, id_update(g, v, c)) end
    newids = [id_update(g,v,c) for v in vertices(g.g)]
    m = maximum([abs(newids[v] - props(g.g, v)[:ideology]) for v in vertices(g.g)])
    for v in vertices(g.g)
        if !has_prop(g.g, v, :media)
            set_prop!(g.g, v, :ideology, newids[v])
        end
    end
    (newids, m)
end

function updateg!(g::IQGraph, c)
    newids = zeros(nv(g.g))
    newqs = zeros(nv(g.g))
    for v in vertices(g.g)
        if !has_prop(g.g, v, :media)
            ni, nq = id_update(g, v, c)
            newids[v] = ni
            newqs[v] = nq
        end
    end
    m = maximum([abs(newids[v] - props(g.g, v)[:ideology]) for v in vertices(g.g)])
    for v in vertices(g.g)
        if !has_prop(g.g, v, :media)
            set_prop!(g.g, v, :ideology, newids[v])
            set_prop!(g.g, v, :quality, newqs[v])
        end
    end
    (newids, newqs, m)
end

function fullsim(g::IGraph, c, tol = 10^(-4), maxsteps = 1000)
    h = copy(g)
    m = 1
    ids = [props(h.g, v)[:ideology] for v in vertices(h.g)]
    steps = 0
    while m > tol && steps < maxsteps
        (newids, m) = updateg!(h, c)
        ids = hcat(ids, newids)
        steps += 1
    end
    return h, ids
end

function R_0(g::IGraph, M, c, tol = 10^(-4), maxsteps = 1000)
    h = copy(g)
    N = nv(h.g)
    for i=1:N
        if has_prop(h.g, i, :media)
            rem_vertex!(h.g, i)
        end
    end
    N = nv(h.g)
    ids = fullsim!(h, c, tol, maxsteps)
    R = 0.0
    for i=1:N
        R += h.distance(props(h.g, i)[:ideology], M) / N
    end
    R
end

function R_M(g::IGraph, M, c, tol = 10^(-4), maxsteps = 1000)
    h, ids = fullsim(g, c, tol, maxsteps)
    N = nv(g.g)
    R = 0.0
    for i=1:N
        R += g.distance(props(g.g, i)[:ideology], M) / N
    end
    R
end

function R_multipole(g::IGraph, c, tol = 10^(-4), maxsteps = 1000)
    f = copy(g)
    h = copy(g)
    N = nv(h.g)
    for i=1:N
        if has_prop(h.g, i, :media)
            rem_vertex!(h.g, i)
        end
    end
    N = nv(h.g)
    fullsim!(f)
    fullsim!(h)
    for i=1:N
        R += h.distance(props(h.g, i)[:ideology], props(f.g, i)[:ideology]) / N
    end
    R
end

function fullsim!(g::IGraph, c, tol = 10^(-4), maxsteps = 1000)
    m = 1
    ids = [props(g.g, v)[:ideology] for v in vertices(g.g)]
    steps = 0
    while m > tol && steps < maxsteps
        (newids, m) = updateg!(g, c)
        ids = hcat(ids, newids)
        steps += 1
    end
    return ids
end

function fullsim!(g::IQGraph, c, tol = 10^(-4), maxsteps = 1000)
    m = 1
    ids = [props(g.g, v)[:ideology] for v in vertices(g.g)]
    quals = [props(g.g, v)[:quality] for v in vertices(g.g)]
    steps = 0
    while m > tol && steps < maxsteps
        (newids, newqs, m) = updateg!(g, c)
        ids = hcat(ids, newids)
        quals = hcat(quals, newqs)
        steps += 1
    end
    ids, quals
end

function fullsim_gif(g::IGraph, c, len = 400, tol = 10^(-4))
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

# Graphs with time-dependent network structure

