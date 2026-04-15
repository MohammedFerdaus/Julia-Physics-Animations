# Julia Physics Animations

A collection of real-time physics animations built in Julia using GLMakie. Each file is a standalone simulation covering a different physical system — from simple kinematics to elastic collisions and wave mechanics. Every animation runs at 60 fps in a live GLMakie window and is built around GLMakie's Observable/`@lift` reactive pattern.

---

## Repository Structure

```
julia-physics-animations/
├── boids/
│   └── boids_flocking.jl
├── particle_movement/
│   ├── particles_advance.jl
│   └── particles_simple.jl
├── pendulum_movement/
│   └── pendulum_swinging.jl
├── rotations/
│   ├── circular_rotations.jl
│   └── elliptical_rotations.jl 
└── waves/
    └── sine_cosine_wave.jl
```

---

## Animations

### Boids Flocking

An implementation of Craig Reynolds' 1987 boids algorithm. Each boid steers every frame by applying three weighted rules: separation (steer away from neighbours within a close radius), alignment (match the average heading of nearby boids), and cohesion (steer toward the average position of nearby boids). Positions wrap toroidally — boids crossing an edge reappear on the opposite side. Each boid is coloured by its current heading angle using the HSV colormap, and a short motion trail fades behind every boid. Wrap-crossing trail segments are culled to prevent full-screen artefact lines.

Key Julia concepts: `Observable`, `toroidal boundary conditions`, `steering force composition`, `LinearAlgebra`, GLMakie scatter and linesegments updates.

![boids](Julia%20Basic%20Simulations/Gifs/boids.gif)

---

### Coral L-System Growth

A Lindenmayer system (L-system) that generates and animates branching coral 
geometry. The axiom `F` is rewritten iteratively using the rule 
`F → FF+[+F-F-F]-[-F+F+F]` to produce a fractal branching string. A turtle 
graphics interpreter walks the final string — `F` draws a segment, `+`/`-` 
rotate the heading, and `[`/`]` push and pop the turtle state to form branches. 
All geometry is precomputed once before the animation starts; the growth effect 
is achieved by revealing segments incrementally each frame via a single 
Observable counter. Segments are coloured by branch depth using a brown-to-cyan 
gradient — thick trunk at the base fading to fine cyan tips.

Key Julia concepts: `Observable`, `@lift`, L-system string rewriting, turtle 
graphics state stack, precomputed geometry with incremental reveal.

![coral_system](Julia%20Basic%20Simulations/Gifs/coral_lsystem.gif)

---

### Circular Rotations

Two balls orbit the same circle at constant speed — red clockwise, blue counter-clockwise. The balls start on opposite sides of the orbit so they are never stacked at t = 0. A reference crosshair and the orbit ring are drawn for context. Orbit radius, ball size, and speed are all adjustable via top-level constants.

Key Julia concepts: `Observable`, `@lift`, `cosd`/`sind`, GLMakie reactive rendering.

![circular_rotations](Julia%20Basic%20Simulations/Gifs/circular_rotations.gif)

---

### Elliptical Rotations

Same setup as circular rotations but the orbit is an ellipse defined by a semi-major axis `A` and semi-minor axis `B`. Demonstrates the parametric ellipse equations `x(θ) = cx + A·cos(θ)`, `y(θ) = cy + B·sin(θ)` directly in the position Observables.

Key Julia concepts: `Observable`, `@lift`, parametric curves, GLMakie reactive rendering.

![elliptical_rotations](Julia%20Basic%20Simulations/Gifs/elliptical_rotations.gif)

---

### Sine and Cosine Waves

A planet orbits a circle on the left half of the screen. Its vertical position traces a scrolling sine wave (red) and its horizontal position traces a scrolling cosine wave (blue) on the right half — showing how both waves emerge directly from circular motion. Dotted connector lines link the planet to the leading edge of each wave in real time.

Key Julia concepts: `Observable`, `@lift`, phase offsets, vectorised broadcasting, GLMakie reactive rendering.

![sine_cosine_wave](Julia%20Basic%20Simulations/Gifs/sine_cosine_wave.gif)

---

### Pendulum Swinging

A single pendulum swings from a fixed pivot under gravity, losing energy each frame via a friction multiplier until it comes to rest at the vertical equilibrium. The angular acceleration is computed from `−g·sin(θ) / L` each frame; the friction term damps the angular velocity multiplicatively. Initial angle, rod length, gravity, and friction are all adjustable.

Key Julia concepts: `Observable`, `@lift`, trigonometric physics, `global` mutable state in animation loop.

![pendulum_swinging](Julia%20Basic%20Simulations/Gifs/pendulum_swinging.gif)

---

### Particle Movement (Simple)

Particles bounce around the screen at constant velocity with no physics beyond wall reflection. Each particle gets a random position, velocity, and color at startup. Corner collisions (hitting two walls simultaneously) reverse both velocity components. Position is clamped after every step so particles can never escape the boundary.

Key Julia concepts: `Observable`, wall collision detection, `clamp`, GLMakie scatter updates.

![particles_simple](Julia%20Basic%20Simulations/Gifs/particles_simple.gif)

---

### Particle Movement (Advanced)

Extends the simple simulation with gravity, floor friction, and elastic ball-to-ball collisions. Particles launch with a random horizontal kick, fall under gravity, lose energy on each floor bounce, and collide elastically with each other using an equal-mass model. The collision resolver applies positional correction to separate overlapping balls before swapping velocity components along the collision normal.

Key Julia concepts: `Observable`, elastic collision physics, positional correction, `LinearAlgebra`, nested O(n²) collision loop.

![particles_advance](Julia%20Basic%20Simulations/Gifs/particles_advance.gif)

---

## Stack

| Area | Library |
| --- | --- |
| Visualization | GLMakie.jl |
| Linear Algebra | LinearAlgebra (stdlib) |
| Core | Julia 1.12.5 standard library |

---

## How to Run

**Requirements:** Julia 1.12.5, VS Code with Julia extension

Install dependencies:

```
using Pkg
Pkg.add("GLMakie")
```

Run any animation:

```
julia boids_flocking.jl
julia circular_rotations.jl
julia elliptical_rotations.jl
julia sine_cosine_wave.jl
julia pendulum_swinging.jl
julia particles_simple.jl
julia particles_advance.jl
```

Each file opens a live 640×360 GLMakie window running at 60 fps. Close the window to stop the animation. Constants at the top of each file (radius, speed, gravity, particle count, etc.) are the intended way to experiment with different behaviours.

---

## Notes

All animations were written and tested in Julia 1.12.5 on Windows 10 with VS Code and the Julia extension. Written entirely from scratch with no starter code.
