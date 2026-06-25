# Flat Bottom Example

Uniform water depth (h = 1 m), no terrain, fluid at rest.

**Expected behaviour:** the solution should remain constant (RHS = 0 for
interior cells), making this a useful sanity check for any new scheme.

## Run

```bash
./build/shallow_water examples/flat_bottom/config.nml
```
