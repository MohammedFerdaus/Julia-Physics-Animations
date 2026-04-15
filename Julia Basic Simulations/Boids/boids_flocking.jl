# Boids Flocking (Craig Reynolds, 1987)
# Each boid steers using three rules applied simultaneously:
# separation — avoid crowding neighbours within SEP_R,
# alignment  — steer toward the average heading of neighbours,
# cohesion   — steer toward the average position of neighbours.
# Positions wrap toroidally so boids crossing an edge reappear on the other side.
# A short trail is drawn by keeping the last TRAIL_LENGTH position snapshots.
# Trail segments that cross a wrap boundary are dropped via NaN sentinels
# to prevent lines spanning the full screen width or height.

# Add needed packages
using GLMakie
using LinearAlgebra

# Display window
const WIDTH = 640
const HEIGHT = 360

# Flock size
const N_BOIDS = 50

# Steering limits
const MAX_SPEED = 3.0
const MAX_FORCE = 0.15

# Neighbourhood radii
const PERCEPTION_R = 50.0
const SEP_R = 15.0

# Rule weights
const SEP_WEIGHT = 1.8
const ALI_WEIGHT = 1.0
const COH_WEIGHT = 1.0

# Trail length in frames
const TRAIL_LENGTH = 12

# GIF recording: set RECORD = true to capture a GIF instead of running live.
# The file is written to the current directory as boids.gif.
const GIF_FRAMES = 300
const GIF_FRAMERATE = 60

# Random initial positions and velocities
positions = rand(Float64, N_BOIDS, 2) .* [WIDTH HEIGHT]
velocities = (rand(Float64, N_BOIDS, 2) .- 0.5) .* MAX_SPEED

# Ring buffer of position snapshots for trail rendering
trail_buf = Vector{Matrix{Float64}}()
push!(trail_buf, copy(positions))

# Separation: steer away from boids closer than SEP_R
function separation_force(i, positions, velocities)
    steer = [0.0, 0.0]
    count = 0
    for j in 1:N_BOIDS
        j == i && continue
        dx = positions[j, 1] - positions[i, 1]
        dy = positions[j, 2] - positions[i, 2]
        dx -= WIDTH * round(dx / WIDTH)
        dy -= HEIGHT * round(dy / HEIGHT)
        dist = sqrt(dx^2 + dy^2)
        (dist > SEP_R || dist == 0) && continue
        steer += [-dx, -dy] / dist
        count += 1
    end
    count == 0 && return [0.0, 0.0]
    steer /= count
    norm(steer) == 0 && return [0.0, 0.0]
    return (steer / norm(steer)) * MAX_FORCE
end

# Alignment: steer toward the average velocity of neighbours
function alignment_force(i, positions, velocities)
    avg_vel = [0.0, 0.0]
    count = 0
    for j in 1:N_BOIDS
        j == i && continue
        dx = positions[j, 1] - positions[i, 1]
        dy = positions[j, 2] - positions[i, 2]
        dx -= WIDTH * round(dx / WIDTH)
        dy -= HEIGHT * round(dy / HEIGHT)
        dist = sqrt(dx^2 + dy^2)
        dist > PERCEPTION_R && continue
        avg_vel += velocities[j, :]
        count += 1
    end
    count == 0 && return [0.0, 0.0]
    avg_vel /= count
    steer = avg_vel - velocities[i, :]
    norm(steer) == 0 && return [0.0, 0.0]
    return (steer / norm(steer)) * MAX_FORCE
end

# Cohesion: steer toward the average position of neighbours
function cohesion_force(i, positions, velocities)
    center = [0.0, 0.0]
    count = 0
    for j in 1:N_BOIDS
        j == i && continue
        dx = positions[j, 1] - positions[i, 1]
        dy = positions[j, 2] - positions[i, 2]
        dx -= WIDTH * round(dx / WIDTH)
        dy -= HEIGHT * round(dy / HEIGHT)
        dist = sqrt(dx^2 + dy^2)
        dist > PERCEPTION_R && continue
        center += positions[i, :] + [dx, dy]
        count += 1
    end
    count == 0 && return [0.0, 0.0]
    center /= count
    steer = center - positions[i, :]
    norm(steer) == 0 && return [0.0, 0.0]
    return (steer / norm(steer)) * MAX_FORCE
end

# Apply steering forces, clamp speed, wrap positions
function update!(positions, velocities)
    snapshot = copy(positions)
    for i in 1:N_BOIDS
        f_sep = SEP_WEIGHT * separation_force(i, snapshot, velocities)
        f_ali = ALI_WEIGHT * alignment_force(i, snapshot, velocities)
        f_coh = COH_WEIGHT * cohesion_force(i, snapshot, velocities)

        velocities[i, :] += f_sep + f_ali + f_coh

        speed = norm(velocities[i, :])
        if speed > MAX_SPEED
            velocities[i, :] = (velocities[i, :] / speed) * MAX_SPEED
        end

        positions[i, :] += velocities[i, :]
        positions[i, 1] = mod(positions[i, 1], WIDTH)
        positions[i, 2] = mod(positions[i, 2], HEIGHT)
    end
end

# Build trail segments, inserting a NaN break whenever a segment crosses a wrap
# boundary (i.e. the raw screen-space jump is more than half the domain width/height).
# Without this check, a boid teleporting from x≈640 to x≈0 draws a full-width line.
function build_trail_points(trail_buf)
    result = Point2f[]
    n = length(trail_buf)
    for i in 1:N_BOIDS
        for t in 1:(n - 1)
            x0 = trail_buf[t][i, 1]
            y0 = trail_buf[t][i, 2]
            x1 = trail_buf[t + 1][i, 1]
            y1 = trail_buf[t + 1][i, 2]
            if abs(x1 - x0) > WIDTH / 2 || abs(y1 - y0) > HEIGHT / 2
                push!(result, Point2f(NaN, NaN))
                push!(result, Point2f(NaN, NaN))
            else
                push!(result, Point2f(x0, y0))
                push!(result, Point2f(x1, y1))
            end
        end
        push!(result, Point2f(NaN, NaN))
    end
    return result
end

# Observables
pos_obs = Observable([Point2f(positions[i, 1], positions[i, 2]) for i in 1:N_BOIDS])
color_obs = Observable([atan(velocities[i, 2], velocities[i, 1]) for i in 1:N_BOIDS])
trail_obs = Observable(build_trail_points(trail_buf))

# Build the figure
fig = Figure(size = (WIDTH, HEIGHT))
ax = Axis(fig[1, 1], limits = (0, WIDTH, 0, HEIGHT))
hidedecorations!(ax)
hidespines!(ax)

linesegments!(ax, trail_obs, color = RGBAf(0.5, 0.5, 0.5, 0.4), linewidth = 0.8)
scatter!(ax, pos_obs,
    color = color_obs,
    colormap = :hsv,
    colorrange = (-π, π),
    markersize = 24,
)

# One shared step used by both the live loop and the GIF recorder
function step!()
    push!(trail_buf, copy(positions))
    if length(trail_buf) > TRAIL_LENGTH
        popfirst!(trail_buf)
    end
    update!(positions, velocities)
    pos_obs[] = [Point2f(positions[i, 1], positions[i, 2]) for i in 1:N_BOIDS]
    color_obs[] = [atan(velocities[i, 2], velocities[i, 1]) for i in 1:N_BOIDS]
    trail_obs[] = build_trail_points(trail_buf)
end

display(fig)

while isopen(fig.scene)
    step!()
    sleep(1/60)
end
