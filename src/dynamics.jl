## Dynamics for the graphical ideology model

function getnewid(g, v, c, selfweight = 1)
    selfid = props(g, v, :ideology)
    neighborid = [props(g, w, :ideology) for w in neighbors(g, v)]
    map!(x -> (abs(x - selfid) < c) * x, neighborid, neighborid)
    (sum(neighborid) + selfweight * selfid) / (length(a) + 1)
end

function updateg!(g, c)
    newids = [getnewid(g,v,c) for v in vertices(g)]
    m = max([abs(newids[v] - props(g, v, :ideology)) for v in vertices(g)])
    for v in vertices(g)
        set_prop!(g, v, :ideology, newids[v])
    end
    (newids, m)
end
