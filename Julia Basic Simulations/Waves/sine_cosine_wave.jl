#  Waves (Sine and Cosine Animation)
#  A planet orbits a circle on the left half of the screen.
#  Its vertical position traces a sine wave (red) scrolling
#  rightward, and its horizontal position traces a cosine
#  wave (blue) scrolling rightward simultaneously.
#
#  Sine wave: y(θ) = sin(θ) — reads off the vertical axis
#  Cosine wave: y(θ) = cos(θ) — reads off the horizontal axis

# Add needed packages
using GLMakie

# Display window
const WIDTH = 640
const HEIGHT = 360

# Orbit and planet geometry
const CX = WIDTH / 4
const CY = HEIGHT / 2
const R_ORBIT = 120
const R_PLANET = 12

# Wave geometry
const N_WAVE = 2 # number of wave cycles visible (try 1, 2, 3)
const R_WAVE = 6
const WAVE_X0 = WIDTH / 2
const WAVE_X1 = Float64(WIDTH)
const LEN = 120

# Speed
const SPEED = 2

# Compute fixed x positions for wave dots
wave_xs = range(WAVE_X0, WAVE_X1, length = LEN)

# Phase offsets so each dot starts at the right angle
base_angles = [360.0 * N_WAVE * (i - 1) /
              (LEN - 1) for i in 1:LEN]

# Mutable angle state
theta = Observable(0.0)

# Planet position (computed from theta)
planet_pos = @lift Point2f(CX + cosd($theta) * R_ORBIT,
                           CY + sind($theta) * R_ORBIT)

# Sine wave dot positions
sine_ys = @lift begin
    [CY + sind($theta + base_angles[i]) * R_ORBIT for i in 1:LEN]
end

# Cosine wave dot positions
cosine_ys = @lift begin
    [CY + cosd($theta + base_angles[i]) * R_ORBIT for i in 1:LEN]
end

# Connector lines (Observable vector of Point2f — @lift with two args is not supported)
sine_connector = @lift [Point2f($planet_pos[1], $planet_pos[2]),
                        Point2f(WAVE_X0, $sine_ys[1])]

cosine_connector = @lift [Point2f($planet_pos[1], $planet_pos[2]),
                          Point2f(WAVE_X0, $cosine_ys[1])]

# Plot figure
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

# Guide lines
hlines!(ax, [CY], color = :black, linewidth = 1) # centreline
hlines!(ax, [CY + R_ORBIT], color = :black, linewidth = 1, linestyle = :dash) # upper bound
hlines!(ax, [CY - R_ORBIT], color = :black, linewidth = 1, linestyle = :dash) # lower bound
vlines!(ax, [CX], color = :black, linewidth = 1) # orbit centre
vlines!(ax, [WAVE_X0], color = :black, linewidth = 1, linestyle = :dash) # wave start

# Orbit ring
orbit_angles = range(0, 360, length = 360)
orbit_xs = CX .+ cosd.(orbit_angles) .* R_ORBIT
orbit_ys = CY .+ sind.(orbit_angles) .* R_ORBIT
lines!(ax, orbit_xs, orbit_ys, color = :black, linewidth = 1)

# Connector lines (pass Observable of Point2f vector directly — one expression per @lift)
lines!(ax, sine_connector,   color = :red,  linewidth = 1, linestyle = :dot)
lines!(ax, cosine_connector, color = :blue, linewidth = 1, linestyle = :dot)

# Sine wave dots
scatter!(ax, collect(wave_xs),
    sine_ys, color = :red,
    markersize = R_WAVE * 2,
)

# Cosine wave dots
scatter!(ax, collect(wave_xs),
    cosine_ys, color = :blue,
    markersize = R_WAVE * 2,
)

# Planet dot
scatter!(ax, @lift([$planet_pos]),
    color = :black,
    markersize = R_PLANET * 2,
)

# Legend
Legend(fig[1, 1],
    [MarkerElement(color = :red, marker = :circle, markersize = 12),
     MarkerElement(color = :blue, marker = :circle, markersize = 12),
     MarkerElement(color = :black, marker = :circle, markersize = 12)],
    ["Sine wave", "Cosine wave", "Planet"],
    tellwidth = false, tellheight = false,
    halign = :right, valign = :top,
    margin = (0, 40, 40, 0),
)
display(fig)

# Animation loop
while isopen(fig.scene)
    theta[] += SPEED
    sleep(1/60)
end