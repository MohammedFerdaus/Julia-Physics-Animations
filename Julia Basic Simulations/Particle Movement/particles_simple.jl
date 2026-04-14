# Particle Movement (Simple)
# Particles bounce around the screen at constant velocity.
# No gravity, no friction, no inter-particle interaction.

using GLMakie

# Display window
const WIDTH = 640
const HEIGHT = 360

# Particle count (try 1, 10, 100, 1000)
const particle_count = 10

# Particle radius (pixels)
const RADIUS = 20

# Random initial positions
px = rand(RADIUS:5:WIDTH - RADIUS, particle_count)
py = rand(RADIUS:5:HEIGHT - RADIUS, particle_count)

# Random initial velocities (pixels per frame)
speed_choices = [-5, -3, -1, 1, 3, 5]
vx = rand(speed_choices, particle_count)
vy = rand(speed_choices, particle_count)

# Random colors from palette
palette = [:red, :green, :blue, :orange, :purple, :cyan]
part_colors = [palette[rand(1:end)] for _ in 1:particle_count]

# Observables
pos_x = Observable(copy(px))
pos_y = Observable(copy(py))

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

scatter!(ax, pos_x, pos_y,
    color = part_colors,
    markersize = RADIUS * 2,
)

display(fig)

# Animation loop
while isopen(fig.scene)
    for i in 1:particle_count

        # Move particle
        px[i] += vx[i]
        py[i] += vy[i]

        # Wall collision detection
        in_left = px[i] - RADIUS < 0
        in_right = px[i] + RADIUS > WIDTH
        in_bottom = py[i] - RADIUS < 0
        in_top = py[i] + RADIUS > HEIGHT

        # Reflect off whichever wall(s) were hit
        if (in_left || in_right) && (in_bottom || in_top)
            vx[i] = -vx[i]
            vy[i] = -vy[i]
        elseif in_left || in_right
            vx[i] = -vx[i]
        elseif in_bottom || in_top
            vy[i] = -vy[i]
        end

        # Clamp position so particles can never escape the boundary
        px[i] = clamp(px[i], Float64(RADIUS), Float64(WIDTH - RADIUS))
        py[i] = clamp(py[i], Float64(RADIUS), Float64(HEIGHT - RADIUS))

    end

    pos_x[] = copy(px)
    pos_y[] = copy(py)

    sleep(1/60)
end
