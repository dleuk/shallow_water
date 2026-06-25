# Documentation

## Architecture overview

```
shallow_water/
├── src/                      Fortran 90 source tree
│   ├── main.f90              Program entry point
│   ├── utils/                Physical constants & run-time parameters
│   ├── grid/                 Grid types (Cartesian, …)
│   ├── terrain/              Bathymetry / bed-elevation routines
│   ├── equations/            SWE state type, RHS & flux modules
│   ├── numerics/             Time-integration schemes
│   └── io/                   Namelist input & CSV output
├── tests/                    Fortran test suite (test_runner)
├── ui/
│   ├── streamlit/            Python/Streamlit visualisation app
│   └── react/                React visualisation placeholder
├── data/                     Sample terrain & initial-condition files
├── examples/                 Ready-to-run example configurations
├── docs/                     This documentation
└── Makefile                  Build system (gfortran)
```

See `numerics.md` for details on the implemented schemes.
