# Pendulum Swinging (with friction)
# A pendulum swings from a fixed pivot under gravity, losing energy
# each frame via a friction multiplier until it comes to rest at
# the vertical equilibrium position.
#
# Physics:
#   tangential_force    = -gravity * sin(θ)
#   angular_acceleration = tangential_force / l_rod
#   angular_velocity    = (angular_velocity + angular_acceleration) * friction
#   θ                  += angular_velocity

using GLMakie

# Display window
const WIDTH = 640
const HEIGHT = 360

# Pivot point (centre of screen)
const PX = Float64(WIDTH / 2)
const PY = Float64(HEIGHT / 2)

# Pendulum geometry
const R_BOB = 20.0 # bob radius (pixels)
const L_ROD = 200.0 # rod length (try 100, 200, 300)

# Physics constants
const GRAVITY = 10.0
const FRICTION = 0.999

# Initial angle in degrees, measured from vertical downward
# try 45, 90, 120, 179
theta = Observable(120.0)
ang_vel = 0.0

# Bob position derived from theta
# x = pivot_x + sin(θ) * L_ROD  (horizontal displacement)
# y = pivot_y - cos(θ) * L_ROD  (vertical — GLMakie y points up so we subtract)
bob_pos = @lift Point2f(PX + sind($theta) * L_ROD,
                        PY - cosd($theta) * L_ROD)

# Rod as a two-point line from pivot to bob
rod_line = @lift [Point2f(PX, PY), $bob_pos]

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

# Reference crosshair at pivot
hlines!(ax, [PY], color = :black, linewidth = 1)
vlines!(ax, [PX], color = :black, linewidth = 1)

# Orbit ring (shows the full arc the bob can travel)
orbit_angles = range(0, 360, length = 360)
orbit_xs = PX .+ cosd.(orbit_angles) .* L_ROD
orbit_ys = PY .+ sind.(orbit_angles) .* L_ROD
lines!(ax, orbit_xs, orbit_ys, color = :black, linewidth = 1)

# Rod
lines!(ax, rod_line, color = :blue, linewidth = 2)

# Bob
scatter!(ax, @lift([$bob_pos]),
    color = :blue,
    markersize = R_BOB * 2,
)

# Pivot dot
scatter!(ax, [Point2f(PX, PY)],
    color = :black,
    markersize = 8,
)

display(fig)

# Animation loop
while isopen(fig.scene)
    global ang_vel

    # Pendulum physics
    tangential_force = -GRAVITY * sind(theta[])
    ang_acc = tangential_force / L_ROD
    ang_vel = (ang_vel + ang_acc) * FRICTION
    theta[] += ang_vel

    sleep(1/60)
end
