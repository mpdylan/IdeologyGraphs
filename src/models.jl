using LightGraphs, MetaGraphs, SNAPDatasets, Random

### Data structure for storing ideology and quality at once. Not sure if I'll actually use this
struct QIVector
    dim::Integer
    ideology::Array{Float64, 1}
    quality::Float64
end

## Simple versions; assign ideology and quality at random as in the simple example in the Brooks-Porter paper

function assignid!(g)
    ids = shuffle(collect(range(-1, 1, step=2/nv(g))))
    for v in vertices(g)
        set_prop!(g, v, :ideology, ids[v])
    end
end

function assignq!(g)
    for v in vertices(g)
        set_prop!(g, v, :quality, rand())
    end
end

function SNAPIdeog(name::Symbol)
    g = MetaGraph(loadsnap(name))
    assignid!(g)
    assignq!(g)
    g
end

