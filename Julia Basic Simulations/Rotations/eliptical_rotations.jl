# Rotations (Elliptical)
# Two balls orbit the same ellipse at the same speed.
# Red travels clockwise, blue travels counter-clockwise.
# A reference crosshair and the orbit ellipse are drawn for context.
#
# Ellipse parametric equations:
#   x(θ) = cx + a·cos(θ)
#   y(θ) = cy + b·sin(θ)
# where a = semi-major axis (horizontal) and b = semi-minor axis (vertical).
 
using GLMakie
 
# Display window
const WIDTH = 640
const HEIGHT = 360
 
# Orbit and ball geometry
const CX = WIDTH / 2 # orbit centre x
const CY = HEIGHT / 2 # orbit centre y
const A = 150 # semi-major axis (horizontal, pixels)
const B = 80 # semi-minor axis (vertical, pixels)
const R_PLANET = 10 # ball radius (pixels)
 
# Speed (degrees per frame)
const SPEED = 2.0
 
# Initial angles
# Start the two balls on opposite sides of the ellipse so they
# are never stacked on top of each other at t = 0
theta_red = Observable(0.0) # clockwise (angle decreases)
theta_blue = Observable(180.0) # counter-clockwise (angle increases)
 
# Derived positions
# Each Observable position is computed from its angle Observable
# so GLMakie automatically recomputes whenever the angle changes
pos_red = @lift Point2f(CX + cosd($theta_red) * A,
                        CY + sind($theta_red) * B)
 
pos_blue = @lift Point2f(CX + cosd($theta_blue) * A,
                         CY + sind($theta_blue) * B)
 
# Build the figure
fig = Figure(size = (WIDTH, HEIGHT), backgroundcolor = :antiquewhite)
 
ax = Axis(fig[1, 1],
    limits = (0, WIDTH, 0, HEIGHT),
    aspect = DataAspect(),
    backgroundcolor = :antiquewhite,
    xgridvisible = false,
    ygridvisible = false,
    xticksvisible = false,
    yticksvisible = false,
    xticklabelsvisible = false,
    yticklabelsvisible = false,
)
 
# Reference crosshair at orbit centre
hlines!(ax, [CY], color = :black, linewidth = 1)
vlines!(ax, [CX], color = :black, linewidth = 1)
 
# Orbit ellipse (drawn as a dense set of points around the ellipse)
orbit_angles = range(0, 360, length = 360)
orbit_xs = CX .+ cosd.(orbit_angles) .* A
orbit_ys = CY .+ sind.(orbit_angles) .* B
lines!(ax, orbit_xs, orbit_ys, color = :black, linewidth = 1)
 
# Balls
scatter!(ax, @lift([$pos_red]), color = :red, markersize = R_PLANET * 2)
scatter!(ax, @lift([$pos_blue]), color = :blue, markersize = R_PLANET * 2)
 
# Legend
Legend(fig[1, 1],
    [MarkerElement(color = :red, marker = :circle, markersize = 12),
     MarkerElement(color = :blue, marker = :circle, markersize = 12)],
    ["Clockwise", "Counter-clockwise"],
    tellwidth = false,
    tellheight = false,
    halign = :right, valign = :top,
    margin = (0, 40, 40, 0))
 
display(fig)
 
# Animation loop
while isopen(fig.scene)
    theta_red[] -= SPEED # clockwise: angle decreases
    theta_blue[] += SPEED # counter-clockwise: angle increases
    sleep(1/60)
end
