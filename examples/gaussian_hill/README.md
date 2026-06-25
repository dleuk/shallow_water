# Gaussian Hill Example

A Gaussian-shaped mound (amplitude = 0.5 m, σ = 150 m) at the domain
centre disturbs an otherwise flat 2 m deep water body, generating
outward-propagating radial waves.

## Run

```bash
./build/shallow_water examples/gaussian_hill/config.nml
```

## Notes

- The terrain is initialised in `main.f90` by calling
  `init_terrain_gaussian_hill`.
- Modify `amplitude` and `sigma` in `src/main.f90` or expose them
  as namelist parameters (future enhancement).
