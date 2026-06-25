# Examples

Ready-to-run configurations demonstrating the solver on canonical test cases.

| Directory | Description |
|-----------|-------------|
| `flat_bottom/` | Uniform depth, no terrain – useful as a sanity check (RHS = 0) |
| `gaussian_hill/` | Circular hill at domain centre generates radial waves |

## Running an example

```bash
# Build the solver
make

# Run a specific example
./build/shallow_water examples/flat_bottom/config.nml

# View results (requires Python + Streamlit)
cd ui/streamlit
pip install -r requirements.txt
streamlit run app.py
```
