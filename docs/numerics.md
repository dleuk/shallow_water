# Numerical Methods

## Governing equations

The 2-D shallow water equations in conservation form:

```
∂h/∂t   + ∂(hu)/∂x  + ∂(hv)/∂y  = 0
∂(hu)/∂t + ∂(hu²+½gh²)/∂x + ∂(huv)/∂y = −gh ∂b/∂x
∂(hv)/∂t + ∂(huv)/∂x + ∂(hv²+½gh²)/∂y = −gh ∂b/∂y
```

- `h`  – water depth (m)
- `u`, `v` – depth-averaged velocity components (m/s)
- `b`  – bed elevation (m)
- `g`  – gravitational acceleration (9.81 m/s²)

## Implemented schemes

| Module | Scheme | Order (space × time) | Status |
|--------|--------|----------------------|--------|
| `euler_mod` | Forward Euler | 2 × 1 | ✅ Working |
| `runge_kutta_mod` | Classical RK4 | 2 × 4 | ✅ Working |
| `lax_wendroff_mod` | Lax-Wendroff / Richtmyer | 2 × 2 | 🚧 Placeholder |

## Flux evaluation

The `flux_mod` module implements the **Rusanov (local Lax-Friedrichs)** flux,
which is stable and simple to implement while remaining suitable for
capturing shocks (bores).

## Stability

The time step must satisfy the CFL condition:

```
Δt ≤ CFL × min(Δx, Δy) / s_max
```

where `s_max = max |u| + c`, `c = √(gh)` is the wave celerity.
`CFL ≤ 0.5` is recommended.

## Planned extensions

- MUSCL (piecewise-linear) reconstruction for higher-order accuracy
- Wetting & drying treatment for dry-bed problems
- Cylindrical / spherical geometry options
