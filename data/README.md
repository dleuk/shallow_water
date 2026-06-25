# Data Directory

Place terrain / bathymetry files and initial-condition data here.

## Supported formats (planned)

| Format | Extension | Description |
|--------|-----------|-------------|
| Fortran namelist | `.nml` | Simulation configuration |
| ASCII grid | `.asc` | ESRI ASCII raster – bed elevation |
| NetCDF | `.nc` | CF-compliant field data (future) |

## Example: flat_100x100.nml

```fortran
&sim_params
  nx    = 100,
  ny    = 100,
  x_max = 1000.0,
  y_max = 1000.0,
  t_end = 200.0,
  dt    = 0.05,
/
```
