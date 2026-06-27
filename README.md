# Shallow Water Equations Solver

A Fortran 90 solver for the 2-D shallow water equations (SWE) supporting
multiple numerical schemes, grid types and terrain geometries, paired with
lightweight visualisation front-ends.

---

## Equations

Derived from conservation of mass:

\begin{equation}
\frac {\delta \rho}{\delta t} + \nabla \dot (\rho v) = 0
\end{equation}

rho: density, v: velocity vector (u,v,w)

Derived from conservation of momentum:

\begin{equation}
\frac{\delta}{delta t}(\rho v) + \nabla \dot (\rho v \rot v + pl) = \rho g


### Simplified form:

\begin{equation}
\frac{\delta h}{\delta t} + H (\frac{\delta u}{\delta x}+\frac{\delta v}{\delta y}) = 0
\frac{\delta u}{\delta t} - fv = -g \frac{\delta h}{\delta x} - ku
\frac{\delta v}{\delta t} + fu = -g \frac{\delta h}{\delta y} - kv
\end{equation}

## Directory structure

```
shallow_water/
├── src/                      Fortran 90 source tree
│   ├── main.f90              Program entry point
│   ├── utils/                Physical constants & run-time parameters
│   ├── grid/                 Grid types (Cartesian, …)
│   ├── terrain/              Bathymetry / bed-elevation routines
│   ├── equations/            SWE state, RHS and flux modules
│   ├── numerics/             Time-integration schemes (Euler, RK4, …)
│   └── io/                   Namelist input & CSV output
├── tests/                    Fortran test suite
├── ui/
│   ├── streamlit/            Python / Streamlit visualisation app
│   └── react/                React visualisation placeholder
├── data/                     Sample terrain & initial-condition files
├── examples/                 Ready-to-run example configurations
├── docs/                     Architecture & numerics documentation
└── Makefile                  Build system (gfortran)
```

## Requirements

| Tool | Purpose | Install |
|------|---------|---------|
| `gfortran` ≥ 9 | Fortran compiler | `sudo apt install gfortran` |
| `python` ≥ 3.10 | Streamlit viewer | system / pyenv |
| `node` ≥ 18 | React viewer (future) | nvm / system |

## Build

```bash
# Build the solver executable
make

# Run the test suite
make tests

# Remove build artefacts
make clean
```

The solver binary is written to `build/shallow_water`.

## Running a simulation

```bash
# Default parameters (100×100 grid, flat bottom, 100 s)
./build/shallow_water

# Custom namelist configuration
./build/shallow_water examples/flat_bottom/config.nml

# Use the repository template (edit nx/ny, dx/dy, etc.)
./build/shallow_water sim_params.nml
```

Output CSV files are written to `output/` by default.

The solver grid is defined by `nx`, `ny`, `dx`, and `dy` from the namelist.
`x_min` and `y_min` are fixed at `0.0`; `x_max` and `y_max` are derived from
`nx*dx` and `ny*dy`. `t_start` is fixed at `0.0`.

## Numerics selection

The namelist also controls the numerical method with two integer switches:

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `discretization_scheme` | `1` | Central differences |
| `discretization_scheme` | `2` | Rusanov (local Lax-Friedrichs) flux |
| `time_integration_scheme` | `1` | Forward Euler |
| `time_integration_scheme` | `2` | Classical RK4 |

Example:

```nml
discretization_scheme   = 2
time_integration_scheme = 2
```

## Visualisation

```bash
cd ui/streamlit
pip install -r requirements.txt
streamlit run app.py
```

Point the sidebar to your `output/` directory to explore the results.

## Documentation

- [Architecture](docs/architecture.md)
- [Numerical methods](docs/numerics.md)
- [Examples](examples/README.md)

## Licence

See [LICENSE](LICENSE).
