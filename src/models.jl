###################################
# models.jl
# A collection of generative models for ideology graphs.
# Includes Erdos-Renyi type graphs, ring graphs, 
# and several graphs from the SNAP graph datasets.
###################################

using LightGraphs, MetaGraphs, SNAPDatasets, Random

### Core types, constants, and utility functions

abstract type IdeologyGraph{T} <: AbstractGraph{T} end

struct IGraph{T} <: IdeologyGraph{T}
    g::MetaGraph{T, Float64}
    id_dim::Int64
    dynamic::Bool
    distance::Function
end

struct IQGraph{T} <: IdeologyGraph{T}
    g::MetaGraph{T, Float64}
    id_dim::Int64
    dynamic::Bool
    distance::Function 
end

const DEFAULT_DIST = Dict(
                     1 => (x, y) -> abs(x - y),
                     2 => (x, y) -> sqrt((x[1] - y[1])^2 + (x[2] - y[2])^2)
                     )

function assignid!(graph::IdeologyGraph)
    ids = shuffle(collect(range(-1, 1, step=2/nv(g))))
    for v in vertices(graph.g)
        set_prop!(graph.g, v, :ideology, ids[v])
    end
end

function assignid!(graph::IdeologyGraph, iv::Array{Float64}, randomize = true)
    randomize && shuffle!(iv)
    for v in vertices(graph.g)
        set_prop!(graph.g, v, :ideology, iv[v])
    end
end

function assignq!(graph::IQGraph)
    for v in vertices(graph.g)
        set_prop!(graph.g, v, :quality, rand())
    end
end

function assignq!(graph::IQGraph, qv::Array{Float64}, randomize = true)
    randomize && shuffle!(qv)
    for v in vertices(graph.g)
        set_prop!(graph.g, v, :quality, qv[v])
    end
end

function SNAPIdeog(name::Symbol, type::DataType, id_dim = 1, dynamic = false)
    mg = MetaGraph(loadsnap(name))
    graph = type(mg, dynamic)
end

### Graph generation models

function ermodel(n, p, type::DataType, is_directed = false, id_dim = 1, dynamic = false, distance = nothing)
    g = MetaGraph(erdos_renyi(n, p, is_directed))
    if distance == nothing
        distance = DEFAULT_DIST[id_dim]
    end
    return type(g, id_dim, dynamic, distance)
end

function wsmodel(n, k, beta, type::DataType, id_dim = 1, dynamic = false, distance = nothing)
    g = MetaGraph(watts_strogatz(n, k, beta))
    if distance == nothing
        distance = DEFAULT_DIST[id_dim]
    end
    return IQGraph(g, id_dim, dynamic, distance)
end

