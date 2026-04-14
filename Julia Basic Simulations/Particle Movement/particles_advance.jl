# Particle Movement (Advanced)
# Particles launch horizontally, fall under gravity, lose energy on
# each floor bounce via a friction multiplier, and collide elastically
# with each other using an equal-mass assumption.

using GLMakie
using LinearAlgebra

# Display window
const WIDTH = 640
const HEIGHT = 360

# Particle count (try 1, 10, 100, 1000)
const particle_count = 10

# Particle radius (pixels)
const RADIUS = 20.0

# Physics constants
const GRAVITY = 0.2 # downward acceleration (pixels / frame^2)
const FRICTION = 0.9 # speed multiplier applied on each floor bounce

# Random initial positions
# Particles are spaced far enough apart so none start overlapping
px = collect(range(RADIUS * 3, WIDTH - RADIUS * 3, length = particle_count)) .+ rand(-5.0:1.0:5.0, particle_count)
py = rand((HEIGHT ÷ 2):5.0:(HEIGHT - RADIUS * 2), particle_count)

# Initial velocities
# Each particle starts with a random horizontal kick, no vertical velocity
vx = [rand((-5.0, 5.0)) for _ in 1:particle_count]
vy = zeros(Float64, particle_count)

# Random colors from palette
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

# Ball-to-ball elastic collision resolver
# For two equal-mass balls in contact, we swap the velocity components
# along the collision normal (the line joining their centres).
# This conserves both momentum and kinetic energy.
function resolve_collisions!(px, py, vx, vy, n, radius)
    for i in 1:n
        for j in i+1:n

            # Vector from ball i to ball j
            dx = px[j] - px[i]
            dy = py[j] - py[i]
            dist = sqrt(dx^2 + dy^2)

            # Only process if the balls are overlapping
            if dist < 2 * radius && dist > 0

                # Unit normal along the collision axis
                nx = dx / dist
                ny = dy / dist

                # Positional correction: push the balls apart equally
                # so they no longer overlap before resolving velocities
                overlap = 2 * radius - dist
                px[i] -= nx * overlap / 2
                py[i] -= ny * overlap / 2
                px[j] += nx * overlap / 2
                py[j] += ny * overlap / 2

                # Velocity exchange along the normal
                # Project both velocity vectors onto the collision normal,
                # swap those projections, leave tangential components untouched.
                dv_n = (vx[i] - vx[j]) * nx + (vy[i] - vy[j]) * ny

                # Only resolve if the balls are actually approaching each other
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

    for i in 1:particle_count

        # Floor collision
        if py[i] <= RADIUS
            if abs(vy[i]) < 2.0
                # Particle has nearly stopped bouncing — rest it on the floor
                py[i] = RADIUS
                vy[i] = 0.0
                vx[i] = vx[i] * FRICTION
            else
                # Normal bounce: reverse and dampen vertical velocity
                vy[i] = -vy[i] * FRICTION
                vx[i] = vx[i] * FRICTION
                py[i] = RADIUS + vy[i]
            end
        else
            # Free flight: apply gravity
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
            px[i] = WIDTH - RADIUS
        elseif px[i] - RADIUS <= 0
            vx[i] = abs(vx[i])
            px[i] = RADIUS
        end

        # Horizontal bleed-off when nearly stopped
        if abs(vx[i]) < 0.5
            px[i] += sign(vx[i])
            vx[i] = round(vx[i] - 0.001 * sign(vx[i]), digits = 3)
        else
            px[i] += vx[i]
        end

    end

    # Ball-to-ball collisions
    resolve_collisions!(px, py, vx, vy, particle_count, RADIUS)

    # Push updated positions to the plot
    pos_x[] = copy(px)
    pos_y[] = copy(py)

    sleep(1/60)
end
