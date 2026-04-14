#  Particle Movement — Advanced (Gravity + Friction + Collisions)
#  Particles launch horizontally, fall under gravity, lose
#  energy on each floor bounce, and collide elastically with
#  each other (equal mass assumption).

# Add needed packages
using GLMakie
using LinearAlgebra

# Display window
const WIDTH = 640
const HEIGHT = 360

# Particle count
# Change n to 1, 10, 100, or 1000
const particle_count = 10

# Particle radius
const RADIUS = 20.0

# Physics constants
const GRAVITY = 0.2   # pixels / frame^2 downward acceleration
const FRICTION = 0.9   # horizontal speed multiplier on each floor bounce

# Random initial positions
# Space particles far enough apart so none start overlapping
px = collect(range(RADIUS * 3, WIDTH - RADIUS * 3, length = particle_count)) .+ rand(-5.0:1.0:5.0, n)
py = rand((HEIGHT ÷ 2):5.0:(HEIGHT - RADIUS * 2), particle_count)

# Initial velocities
vx = [rand((-5.0, 5.0)) for _ in 1:particle_count]
vy = zeros(Float64, particle_count)

# Random colors
palette = [:red, :green, :blue, :orange, :purple, :cyan,
               :pink, :yellow, :lime, :teal]
part_colors = [palette[mod1(i, length(palette))] for i in 1:particle_count]

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

# Ball-to-ball elastic collision
# For two equal-mass balls, on contact we swap the velocity
# components along the collision normal (the line joining
# their centres).  This conserves both momentum and energy.
function resolve_collisions!(px, py, vx, vy, n, radius)
    for i in 1:n
        for j in i+1:n

            # Vector from ball i to ball j
            dx = px[j] - px[i]
            dy = py[j] - py[i]
            dist = sqrt(dx^2 + dy^2)

            # Check overlap
            if dist < 2 * radius && dist > 0

                # Positional correction
                # Push the two balls apart so they no longer overlap,
                # splitting the overlap equally between them.
                overlap = 2 * radius - dist
                nx = dx / dist # unit normal x
                ny = dy / dist # unit normal y

                px[i] -= nx * overlap / 2
                py[i] -= ny * overlap / 2
                px[j] += nx * overlap / 2
                py[j] += ny * overlap / 2

                # Velocity exchange along the normal
                # Project both velocity vectors onto the collision
                # normal, swap those projections, leave the
                # tangential components untouched.
                dv_n = (vx[i] - vx[j]) * nx + (vy[i] - vy[j]) * ny

                # Only resolve if balls are actually approaching
                if dv_n > 0
                    vx[i] -= dv_n * nx
                    vy[i] -= dv_n * ny
                    vx[j] += dv_n * nx
                    vy[j] += dv_n * ny
                end
            end
        end
    end
end

# Animation loop
while isopen(fig.scene)

    # Per-particle wall + gravity update
    for i in 1:particle_count

        # Floor collision
        if py[i] <= RADIUS
            if abs(vy[i]) < 2.0
                py[i] = RADIUS
                vy[i] = 0.0
                vx[i] = vx[i] * FRICTION
            else
                vy[i] = -vy[i] * FRICTION
                vx[i] = vx[i] * FRICTION
                py[i] = RADIUS + vy[i]
            end
        else
            vy[i] -= GRAVITY
            py[i] += vy[i]
        end

        # Ceiling collision
        if py[i] + RADIUS >= HEIGHT
            vy[i] = -abs(vy[i])
            py[i] = HEIGHT - RADIUS
        end

        # Side wall collisions
        if px[i] + RADIUS >= WIDTH
            vx[i] = -abs(vx[i])
            px[i]  = WIDTH - RADIUS
        elseif px[i] - RADIUS <= 0
            vx[i] =  abs(vx[i])
            px[i]  = RADIUS
        end

        # Horizontal bleed-off when nearly stopped
        if abs(vx[i]) < 0.5
            px[i] += sign(vx[i])
            vx[i]  = round(vx[i] - 0.001 * sign(vx[i]), digits = 3)
        else
            px[i] += vx[i]
        end

    end

    # Ball-to-ball collisions
    resolve_collisions!(px, py, vx, vy, particle_count, RADIUS)

    # Push to plot
    pos_x[] = copy(px)
    pos_y[] = copy(py)

    sleep(1/60)
end