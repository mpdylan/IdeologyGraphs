###################################
# models.jl
# A collection of generative models for ideology graphs.
# Includes Erdos-Renyi type graphs, ring graphs, 
# and several graphs from the SNAP graph datasets.
###################################

using LightGraphs, MetaGraphs, SNAPDatasets, Random

### Core types and utility functions

abstract type IdeologyGraph <: AbstractGraph end

struct IGraph <: IdeologyGraph
    g::MetaGraph{Int64, Float64}
    dynamic::Bool
end

struct IQGraph <: IdeologyGraph
    g::MetaGraph{Int64, Float64}
    dynamic::Bool
end

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

function SNAPIdeog(name::Symbol, type::DataType, dynamic::Bool)
    mg = MetaGraph(loadsnap(name))
    graph = type(mg, dynamic)
end

### Graph generation models

