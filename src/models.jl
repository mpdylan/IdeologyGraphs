###################################
# models.jl
# A collection of generative models for ideology graphs.
# Includes Erdos-Renyi type graphs, ring graphs, 
# and several graphs from the SNAP graph datasets.
###################################

using LightGraphs, MetaGraphs, SNAPDatasets, Random, DelimitedFiles
import Base.copy

### Core types, constants, and utility functions

abstract type IdeologyGraph{T} <: AbstractGraph{T} end

abstract type DirectedIdeologyGraph{T} <: AbstractGraph{T} end

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

struct IDiGraph{T} <: DirectedIdeologyGraph{T}
    g::MetaDiGraph{T, Float64}
    id_dim::Int64
    dynamic::Bool
    distance::Function
end

struct IQDiGraph{T} <: DirectedIdeologyGraph{T}
    g::MetaDiGraph{T, Float64}
    id_dim::Int64
    dynamic::Bool
    distance::Function 
end

function copy(graph::IdeologyGraph)
    T = typeof(graph)
    newg = copy(graph.g)
    newid_dim = graph.id_dim
    newdynamic = graph.dynamic
    newdist = graph.distance
    return T(newg, newid_dim, newdynamic, newdist)
end

function copy(graph::DirectedIdeologyGraph)
    T = typeof(graph)
    newg = copy(graph.g)
    newid_dim = graph.id_dim
    newdynamic = graph.dynamic
    newdist = graph.distance
    return T(newg, newid_dim, newdynamic, newdist)
end

const path_to_fb100 = "/home/dylan/code/facebook100/"

const DEFAULT_DIST = Dict(
                     1 => (x, y) -> abs(x - y),
                     2 => (x, y) -> sqrt((x[1] - y[1])^2 + (x[2] - y[2])^2)
                     )

function assignid!(graph)
    ids = shuffle(collect(range(-1, 1, step=2/nv(graph.g))))
    for v in vertices(graph.g)
        if !has_prop(graph.g, v, :media)
            set_prop!(graph.g, v, :ideology, ids[v])
        end
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

function fbgraph(name::AbstractString, type, id_dim = 1, dynamic = false, distance = nothing)
    edge_array = readdlm(join([path_to_fb100, name, ".csv"]), ',', Int64)
    edge_array += ones(Int64, size(edge_array))
    g = SimpleGraph(maximum(edge_array))
    for i=1:size(edge_array)[1]
        add_edge!(g, edge_array[i,1], edge_array[i,2])
    end
    mg = MetaGraph(g)
    if distance == nothing
        distance = DEFAULT_DIST[id_dim]
    end
    graph = type(mg, id_dim, dynamic, distance)
end

function SNAPIdeog(name::Symbol, type, id_dim = 1, dynamic = false, distance = nothing)
    mg = MetaGraph(loadsnap(name))
    if distance == nothing
        distance = DEFAULT_DIST[id_dim]
    end
    graph = type(mg, id_dim, dynamic, distance)
end

### Graph generation models

function ermodel(n, p, type, is_directed = false, id_dim = 1, dynamic = false, distance = nothing)
    if is_directed
        g = MetaDiGraph(erdos_renyi(n, p, is_directed = is_directed))
    else
        g = MetaGraph(erdos_renyi(n, p, is_directed = is_directed))
    end
    if distance == nothing
        distance = DEFAULT_DIST[id_dim]
    end
    return type(g, id_dim, dynamic, distance)
end

function wsmodel(n, k, beta, type, id_dim = 1, dynamic = false, distance = nothing)
    g = MetaGraph(watts_strogatz(n, k, beta))
    if distance == nothing
        distance = DEFAULT_DIST[id_dim]
    end
    return type(g, id_dim, dynamic, distance)
end

### Adding media accounts

# One approach: connect the media account to a given number of accounts, selected uniformly at random

# Utility function: select a random subset of the vertices

function random_verts(g, n)
    verts = Array{Int64, 1}()
    maxvert = nv(g)
    while length(verts) < n
        choice = convert(Int64, ceil(maxvert*rand()))
        if !(choice in verts)
            append!(verts, choice)
        end
    end
    verts
end

function addmedia_rand!(graph::IdeologyGraph, n_accounts, n_followers, ideology, quality = nothing)
    n = nv(graph.g)
    verts = random_verts(graph.g, n_followers)
    for i=1:n_accounts-1 verts = hcat(verts, random_verts(graph.g, n_followers)) end
    add_vertices!(graph.g, n_accounts)
    for i=n+1:n+n_accounts
        set_prop!(graph.g, i, :ideology, ideology)
        if quality != nothing set_prop!(graph.g, i, :quality, quality) end
        set_prop!(graph.g, i, :media, true)
        for vert in verts[:,i-n] add_edge!(graph.g, vert, i) end
    end
    true
end

# Another approach: connect the media account to a given number of accounts,
# selected to be the ideologically nearest

function addmedia_nearest!(graph::IdeologyGraph, n_accounts, n_followers, ideology, quality = nothing)
    n = nv(graph.g)
    add_vertices!(graph.g, n_accounts)
    for i=n+1:n+n_accounts
        followers = sort(collect(1:n), by = 
                         v -> graph.distance(props(graph.g, v)[:ideology], ideology[i-n]))[1:n_followers]
        set_prop!(graph.g, i, :ideology, ideology[i-n])
        if quality != nothing set_prop!(graph.g, i, :quality, quality[i-n]) end
        set_prop!(graph.g, i, :media, true)
        for vert in followers add_edge!(graph.g, vert, i) end
    end
    true
end    

# For repeating experiments without regenerating graphs: strip media accounts

function stripmedia!(graph::IdeologyGraph)
    n = nv(graph.g)
    to_strip = Array{Int64, 1}(undef, 0)
    for i = 1:n
        if has_prop(graph.g, i, :media)
            append!(to_strip, i)
        end
    end
    rem_vertices!(graph.g, to_strip)
end