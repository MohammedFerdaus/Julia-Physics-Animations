# Rotations (Circular)
# Two balls orbit the same circle at the same speed.
# Red travels clockwise, blue travels counter-clockwise.
# A reference crosshair and the orbit ring are drawn for context.

using GLMakie

# Display window
const WIDTH = 640
const HEIGHT = 360

# Orbit and ball geometry
const CX = WIDTH / 2 # orbit centre x
const CY = HEIGHT / 2 # orbit centre y
const R_ORBIT = 100 # orbit radius (pixels)
const R_PLANET = 10 # ball radius (pixels)

# Speed (degrees per frame)
const SPEED = 2.0

# Initial angles
# Start the two balls on opposite sides of the orbit so they
# are never stacked on top of each other at t = 0
theta_red = Observable(0) # clockwise (angle decreases)
theta_blue = Observable(180) # counter-clockwise (angle increases)

# Derived positions
# Each Observable position is computed from its angle Observable
# so GLMakie automatically recomputes whenever the angle changes
pos_red = @lift Point2f(CX + cosd($theta_red) * R_ORBIT,
                        CY + sind($theta_red) * R_ORBIT)

pos_blue = @lift Point2f(CX + cosd($theta_blue) * R_ORBIT,
                         CY + sind($theta_blue) * R_ORBIT)

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

# Orbit ring (drawn as a dense set of points around the circle)
orbit_angles = range(0, 360, length = 360)
orbit_xs = CX .+ cosd.(orbit_angles) .* R_ORBIT
orbit_ys = CY .+ sind.(orbit_angles) .* R_ORBIT
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
