#  Coral growth — L-system tree (Animated)
#  A plant-like fractal grows segment by segment from the bottom center.
#  Color shifts from brown (trunk) to cyan (tips) based on branch depth.

# Add needed packages
using GLMakie

# Display window
const WIDTH = 640
const HEIGHT = 360

# L-system parameters
const N_ITER = 4
const ANGLE_DEG = 25
const SEG_LEN = 4

# Animation speed (segments revealed per frame)
const GROW_SPEED = 3

# Expand the L-system string for n iterations
function expand(axiom, rules, n)
    s = axiom
    for _ in 1:n
        s = join(get(rules, c, c) for c in s)
    end
    return s
end

# Interpret the L-system string into drawable segments
function interpret(lstring)
    segments = Vector{Tuple{Point2f, Point2f}}()
    depths   = Vector{Int}()
    x, y  = WIDTH / 2, 20.0
    angle = 90.0
    depth = 0
    stack = Vector{Tuple{Float64, Float64, Float64, Int}}()
    for c in lstring
        if c == 'F'
            x2 = x + SEG_LEN * cosd(angle)
            y2 = y + SEG_LEN * sind(angle)
            push!(segments, (Point2f(x, y), Point2f(x2, y2)))
            push!(depths, depth)
            x, y = x2, y2
        elseif c == '+'
            angle -= ANGLE_DEG
        elseif c == '-'
            angle += ANGLE_DEG
        elseif c == '['
            push!(stack, (x, y, angle, depth))
            depth += 1
        elseif c == ']'
            x, y, angle, depth = pop!(stack)
        end
    end
    return segments, depths
end

# Map branch depth to a brown-to-cyan color gradient
function depth_to_color(d, max_depth)
    brown = RGBAf(0.55, 0.27, 0.07, 1.0)
    cyan  = RGBAf(0.0,  0.80, 0.70, 1.0)
    t = d / max_depth
    return RGBAf(
        brown.r * (1 - t) + cyan.r * t,
        brown.g * (1 - t) + cyan.g * t,
        brown.b * (1 - t) + cyan.b * t,
        1.0
    )
end

# Generate L-system geometry
axiom = "F"
rules = Dict('F' => "FF+[+F-F-F]-[-F+F+F]")

lstring          = expand(axiom, rules, N_ITER)
segments, depths = interpret(lstring)
max_depth        = maximum(depths)
colors           = [depth_to_color(d, max_depth) for d in depths]

# Observables for animated reveal
n_vis = Observable(0)

visible_segs = @lift begin
    pts = Point2f[]
    for k in 1:min($n_vis, length(segments))
        push!(pts, segments[k][1])
        push!(pts, segments[k][2])
    end
    pts
end

visible_colors = @lift begin
    cols = RGBAf[]
    for k in 1:min($n_vis, length(segments))
        push!(cols, colors[k])
        push!(cols, colors[k])
    end
    cols
end

# Build the figure
fig = Figure(size = (WIDTH, HEIGHT), backgroundcolor = :black)

ax = Axis(fig[1, 1],
    limits = (0, WIDTH, 0, HEIGHT),
    backgroundcolor = :black,
)

hidedecorations!(ax)
hidespines!(ax)

linesegments!(ax, visible_segs,
    color = visible_colors,
    linewidth = 1.2,
)

display(fig)

# Animation loop
while isopen(fig.scene)
    if n_vis[] < length(segments)
        n_vis[] = min(n_vis[] + GROW_SPEED, length(segments))
    end
    sleep(1/60)
end
