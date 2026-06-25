# Shallow Water Equations Solver

A Fortran 90 solver for the 2-D shallow water equations (SWE) supporting
multiple numerical schemes, grid types and terrain geometries, paired with
lightweight visualisation front-ends.

---

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
```

Output CSV files are written to `output/` by default.

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
