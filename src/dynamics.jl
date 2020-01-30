## Dynamics for the graphical ideology model

function getnewid_noq(g, v, c, selfweight = 1)
    selfid = props(g, v)[:ideology]
    neighborid = [props(g, w)[:ideology] for w in neighbors(g, v)]
    map!(x -> (abs(x - selfid) < c) * x, neighborid, neighborid)
    (sum(neighborid) + selfweight * selfid) / (length(neighborid) + 1)
end

function minq(selfid, otherid, c, dist)

end

function getnewid_q(g, v, c, selfweight = 1)
    selfid = props(g, v)[:ideology]
    neighborid = [props(g, w)[:ideology] for w in neighbors(g, v)]
    map!(x -> (abs(x - selfid) < c) * x, neighborid, neighborid)
    (sum(neighborid) + selfweight * selfid) / (length(neighborid) + 1)
end

function updateg!(g, c)
    newids = [getnewid(g,v,c) for v in vertices(g)]
    m = maximum([abs(newids[v] - props(g, v)[:ideology]) for v in vertices(g)])
    for v in vertices(g)
        set_prop!(g, v, :ideology, newids[v])
    end
    (newids, m)
end

function fullsim(g, c, tol = 10^(-4))
    m = 1
    ids = [props(g, v)[:ideology] for v in vertices(g)]
    while m > tol
        (newids, m) = updateg!(g, c)
        ids = hcat(ids, newids)
    end
    ids
end