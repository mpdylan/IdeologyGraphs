# Data visualization for the ideology graph model.

using LightGraphs, MetaGraphs, GraphPlot, Compose, Colors, Plots

const colorlist = ["blue1", "steelblue3", "lightskyblue2", "lightsteelblue1", "gray85",
                   "lightsalmon", "coral2", "firebrick2", "red2"]
const colorbreaks = [-0.8, -0.6, -0.4, -0.2, 0.2, 0.4, 0.6, 0.8]

function getcolor(x)
    for i in 1:length(colorbreaks)
        if x < colorbreaks[i]
            return colorlist[i]
        end
    end
    colorlist[end]
end

function colornet!(g::IdeologyGraph)
    for v in vertices(g.g)
        set_prop!(g.g, v, :color, getcolor(props(g.g, v)[:ideology]))
    end
end

function drawcolorgraph(g::IdeologyGraph)
    nodefillc = [parse(Colorant, props(g.g, v)[:color]) for v in vertices(g.g)]
    gplot(g.g, nodefillc = nodefillc)
end
